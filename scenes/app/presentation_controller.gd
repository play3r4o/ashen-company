extends "res://scenes/app/game_state.gd"

const DENSE_COMBAT_PRESENTATION_INTERVAL: float = 1.0 / 30.0
const STATIC_VISUAL_CHECK_INTERVAL: float = 0.25
const WORLD_PRESENTATION_SYNC_INTERVAL: float = 1.0 / 20.0

var combat_presentation_accumulator: float = 0.0
var combat_presentation_last_screen: int = -1
var static_visual_check_accumulator: float = 0.0
var world_presentation_accumulator: float = 0.0
var world_presentation_last_screen: int = -1
var performance_slow_frames: int = 0
var performance_fast_frames: int = 0
var blackthorn_world_art: Node2D
var _last_world_root_position: Vector2 = Vector2(INF, INF)
var _last_world_tint_color: Color = Color(-INF, -INF, -INF, -INF)


func _update_adaptive_performance(delta: float) -> void:
	if screen != Screen.RUN:
		runtime_cosmetic_density = 1.0
		performance_slow_frames = 0
		performance_fast_frames = 0
		return
	# Cosmetic work is the first thing to shed on a phone. This does not change
	# enemy, projectile, pickup, or combat-state limits; it only lowers the
	# number of transient effects retained and presented while a dense wave is
	# taking longer than the 45 FPS budget.
	if delta >= 0.022:
		performance_slow_frames += 1
		performance_fast_frames = 0
	elif delta <= 0.017:
		performance_fast_frames += 1
		performance_slow_frames = maxi(0, performance_slow_frames - 1)
	else:
		performance_slow_frames = maxi(0, performance_slow_frames - 1)
		performance_fast_frames = maxi(0, performance_fast_frames - 1)
	if performance_slow_frames >= 8:
		runtime_cosmetic_density = 0.5 if performance_slow_frames < 20 else 0.32
	elif performance_fast_frames >= 90:
		runtime_cosmetic_density = minf(1.0, runtime_cosmetic_density + 0.08)
	if is_instance_valid(visual_quality_controller) and visual_quality_controller.has_method("cosmetic_density_cap"):
		runtime_cosmetic_density = minf(runtime_cosmetic_density, float(visual_quality_controller.call("cosmetic_density_cap")))

func _apply_visual_quality_setting(quality_id: String) -> void:
	if is_instance_valid(visual_quality_controller) and visual_quality_controller.has_method("apply_quality_id"):
		visual_quality_controller.call("apply_quality_id", quality_id)
		return
	push_error("GameRoot is missing the authored VisualQualityController.")

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	hud_layout_data = null
	_register_training_runtime_content()
	_refresh_safe_area_inset()
	# Deterministic visual-capture tools opt into a disposable profile through
	# scene metadata. Normal boot always uses the persisted profile.
	save = SaveService.default_data() if bool(get_meta("use_disposable_profile", false)) else SaveService.load_data()
	_sync_active_hero_fields()
	generated_region = RegionGeneratorService.generate_blackthorn(int(save.profile.get("region_seed", 41041)))
	_invalidate_enemy_flow_blockers()
	_request_world_depth_rebuild()
	_configure_world()
	_setup_visual_layers()
	_apply_visual_quality_setting(String(save.settings.get("lighting_quality", "medium")))
	_build_structure_definitions()
	_sync_structure_anchors()
	_sync_visual_layers(true)
	camp_player_position = _safe_camp_spawn_position()
	audio_controller = AshenSceneBindings.optional(self, &"Audio") as AshenAudioController
	ui_controller = AshenSceneBindings.optional(self, &"UIController") as AshenUiController
	if ui_controller == null:
		push_error("GameRoot is missing its authored UIController")
	if audio_controller == null:
		push_error("GameRoot is missing its authored Audio controller")
	else:
		_update_audio_volumes()
	_apply_offline_progress()
	_show_camp()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# On iOS Safari/PWA this is also the lifecycle event raised when the
		# app is swiped away from the app switcher.  The scene may survive and
		# receive focus again, so record what needs rebuilding explicitly.
		app_suspended_for_focus = true
		resume_run_after_focus = false
		recover_camp_after_focus = false
		if screen == Screen.RUN:
			resume_run_after_focus = not run_paused and not choosing_upgrade
			run_paused = true
			_reset_movement_input()
			_snapshot_run()
			SaveService.save_data(save)
		elif screen == Screen.CAMP:
			# Extraction intentionally keeps the field camera for a seamless
			# gate arrival.  That framing is not a stable camp layout after a
			# suspended web page, so it is rebuilt on the next focus-in.
			recover_camp_after_focus = camp_uses_field_camera
			_reset_movement_input()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and app_suspended_for_focus:
		app_suspended_for_focus = false
		call_deferred("_recover_after_focus")

func _recover_after_focus() -> void:
	"""Restore a playable scene after a suspended web/PWA page returns.

	The browser can keep the Godot scene in memory while dropping input and
	CanvasItem state.  Rebuilding the live HUD/world state is deliberately
	cheap compared with asking the player to reset their save.
	"""
	if resume_run_after_focus:
		resume_run_after_focus = false
		if not save.active_run.is_empty():
			_resume_run()
		else:
			# A very short run may have been closed before its first autosave.
			# Return safely to camp rather than leaving a paused, inputless field.
			_show_camp("The expedition was safely returned to camp.")
		return
	resume_run_after_focus = false
	if recover_camp_after_focus and screen == Screen.CAMP:
		_recover_camp_arrival()

func _recover_camp_arrival() -> void:
	if screen != Screen.CAMP:
		return
	recover_camp_after_focus = false
	_reset_movement_input()
	camp_uses_field_camera = false
	camp_camera_anchor_x = 0.5
	camp_camera_anchor_y = 0.72
	var gate: Vector2 = _camp_gate_position()
	var gate_corridor: bool = is_instance_valid(active_camp_scene) and active_camp_scene.gate_opening_contains_x(camp_player_position.x) and camp_player_position.y >= gate.y - 54.0 and camp_player_position.y <= gate.y + 40.0
	var inside_town: bool = Geometry2D.is_point_in_polygon(camp_player_position, _camp_boundary_world())
	if (not gate_corridor and not inside_town) or _camp_position_blocked(camp_player_position):
		camp_player_position = _safe_camp_spawn_position()
	_show_camp("The company is back at the gate.")

func _refresh_safe_area_inset() -> void:
	# Installed iOS PWAs expose the notch through CSS env(safe-area-inset-top)
	# once viewport-fit=cover is enabled. Browsers and devices without a notch
	# resolve the same measurement to zero, keeping the compact layout intact.
	safe_area_top = 0.0
	if not OS.has_feature("web"):
		return
	var measured: Variant = JavaScriptBridge.eval("(function(){try{var e=document.createElement('div');e.style.cssText='position:absolute;left:0;top:0;width:1px;height:env(safe-area-inset-top);pointer-events:none;';document.body.appendChild(e);var h=e.getBoundingClientRect().height;e.remove();return Math.ceil(h);}catch(_){return 0;}})()")
	if measured is int or measured is float:
		safe_area_top = maxf(0.0, float(measured))

func _add_safe_area_band(parent: Control) -> void:
	var band := SafeAreaBandScene.instantiate() as ColorRect
	band.position = Vector2.ZERO
	band.size = Vector2(size.x, safe_area_top)
	parent.add_child(band)

func _add_live_hud(mode: String) -> AshenHudLayout:
	var live_hud := HudLayoutScene.instantiate() as AshenHudLayout
	live_hud.name = "LiveHud"
	live_hud.theme = theme_main
	live_hud.configure(mode, safe_area_top)
	ui_root.add_child(live_hud)
	active_hud_layout = live_hud
	hud_layout_data = live_hud
	return live_hud

func _process(delta: float) -> void:
	_update_adaptive_performance(delta)
	# Camp/world composition only changes after purchases, tier changes, or a
	# viewport resize. Those paths already force a sync. Keep a low-frequency
	# safety check for external/editor mutations instead of allocating several
	# profile strings and dictionaries on every rendered frame.
	static_visual_check_accumulator += delta
	if static_visual_check_accumulator >= STATIC_VISUAL_CHECK_INTERVAL:
		static_visual_check_accumulator = fmod(static_visual_check_accumulator, STATIC_VISUAL_CHECK_INTERVAL)
		_sync_visual_layers()
	_update_arrival_crest(delta)
	if is_instance_valid(world_root):
		var next_world_root_position: Vector2 = _world_root_camera_position()
		if world_root.position != next_world_root_position or _last_world_root_position != next_world_root_position:
			world_root.position = next_world_root_position
			_last_world_root_position = next_world_root_position
	if screen == Screen.RUN:
		if not run_paused and not choosing_upgrade:
			_process_run(minf(delta, 0.05))
		else:
			guard_cooldown = maxf(0.0, guard_cooldown - delta)
	elif screen == Screen.CAMP:
		if _camp_hub_active():
			_process_camp(delta)
		if is_instance_valid(active_camp_scene):
			active_camp_scene.set_highlighted(camp_highlighted_structure)
	_sync_actor_presentation(delta)

func _sync_actor_presentation(delta: float = 0.0) -> void:
	if not is_instance_valid(actor_presentation):
		return
	var actor_states: Array = []
	var actor_position: Vector2
	var actor_direction: Vector2 = last_move_vector
	var actor_moving: bool
	# Actor and combat presentation share the same camera rect. Compute it once
	# so dense waves do not construct the same culling rectangle twice per
	# rendered frame.
	var visible_world_rect: Rect2 = _visible_world_rect()
	if screen == Screen.CAMP:
		# Presentation only reads state; passing the live typed array avoids a
		# per-frame copy of every enemy/wanderer.
		actor_states = camp_wanderers
		actor_position = camp_player_position
		actor_moving = camp_move_vector.length_squared() > 0.01
		if actor_presentation.position != Vector2.ZERO:
			actor_presentation.position = Vector2.ZERO
	else:
		actor_states = enemies
		actor_position = player_position
		actor_moving = player_move_vector.length_squared() > 0.01
		var actor_shake_position: Vector2 = shake_offset.round()
		if actor_presentation.position != actor_shake_position:
			actor_presentation.position = actor_shake_position
	var player_attacking: bool = screen == Screen.RUN and player_attack_timer > 0.0
	actor_presentation.call("sync_frame", active_class, actor_position, actor_direction, actor_moving, player_hp, player_max_hp, actor_states, actor_position, visible_world_rect, player_attacking, player_attack_direction)
	if is_instance_valid(combat_presentation):
		var combat_shake_position: Vector2 = shake_offset.round() if screen == Screen.RUN else Vector2.ZERO
		if combat_presentation.position != combat_shake_position:
			combat_presentation.position = combat_shake_position
		combat_presentation_accumulator += delta
		var dense_combat: bool = screen == Screen.RUN and (enemies.size() > 96 or projectiles.size() > 48 or effects.size() > 24 or pickups.size() > 64)
		var screen_changed: bool = combat_presentation_last_screen != int(screen)
		# Projectiles are primary combat feedback and must remain frame-smooth even
		# when cosmetic effects are throttled. The previous dense-wave branch moved
		# arrows and spell bolts at 30 Hz, which looked like general game lag despite
		# the simulation itself running comfortably at 60 Hz.
		var projectile_states: Array = projectiles if screen == Screen.RUN else []
		var combat_visible_rect: Rect2 = visible_world_rect if screen == Screen.RUN else Rect2()
		combat_presentation.call("sync_projectiles", projectile_states, combat_visible_rect)
		if not dense_combat or screen_changed or combat_presentation_accumulator >= DENSE_COMBAT_PRESENTATION_INTERVAL:
			var pickup_states: Array = pickups if screen == Screen.RUN else []
			var damage_states: Array = float_texts if screen == Screen.RUN else []
			var effect_states: Array = effects if screen == Screen.RUN else []
			var hazard_states: Array = hazards if screen == Screen.RUN else []
			var trap_states: Array = traps if screen == Screen.RUN else []
			combat_presentation.call("sync_frame", pickup_states, damage_states, effect_states, hazard_states, trap_states, combat_visible_rect, runtime_cosmetic_density)
			combat_presentation_accumulator = 0.0
		combat_presentation_last_screen = int(screen)
	if is_instance_valid(blackthorn_moor_preview):
		# The canonical Meadow preview owns the authored decoration positions.
		# Its wrapper applies the single viewport-origin transform; never reset it
		# here or the live scene will drift away from the editor composition.
		if blackthorn_moor_preview.has_method("apply_runtime_content_origin"):
			blackthorn_moor_preview.call("apply_runtime_content_origin", world_content_origin)
		# Keep the authored preview scene as the single meadow owner. Its own
		# presentation child receives only the transient shake value; the
		# controller never writes an authored decoration transform directly.
		if blackthorn_moor_preview.has_method("set_runtime_world_presentation_shake"):
			blackthorn_moor_preview.call("set_runtime_world_presentation_shake", shake_offset if screen == Screen.RUN else Vector2.ZERO)
		# Landmarks and the frontier crest are presentation-only. They do not
		# participate in combat, so updating their pulse/labels at 20 Hz is enough
		# and avoids clearing/rebuilding their dictionaries on every render frame.
		world_presentation_accumulator += maxf(0.0, delta)
		var world_presentation_screen: int = int(screen)
		var world_presentation_screen_changed: bool = world_presentation_screen != world_presentation_last_screen
		if world_presentation_screen_changed or (screen == Screen.RUN and world_presentation_accumulator >= WORLD_PRESENTATION_SYNC_INTERVAL):
			var landmark_states: Array = exploration_points if screen == Screen.RUN else []
			blackthorn_moor_preview.call("sync_frame", screen == Screen.RUN, _frontier_gate_position(), save.get("profile", {}).get("unlocked_biomes", []).has("gloamwood"), landmark_states, run_elapsed, false, false)
			world_presentation_accumulator = 0.0
			world_presentation_last_screen = world_presentation_screen
	_sync_camp_authored_state()
	if is_instance_valid(world_tint):
		var next_tint_color: Color = Color(0.02, 0.025, 0.027, 0.18 if screen == Screen.RUN else 0.16 if screen == Screen.CAMP else 0.62)
		if world_tint.color != next_tint_color or _last_world_tint_color != next_tint_color:
			world_tint.color = next_tint_color
			_last_world_tint_color = next_tint_color
	_sync_collision_debug_scene()


func _sync_camp_authored_state() -> void:
	if is_instance_valid(active_camp_scene):
		var prompt_visible: bool = screen == Screen.CAMP and _camp_hub_active()
		if prompt_visible != last_synced_camp_prompt_visible:
			var gate := AshenSceneBindings.optional(active_camp_scene, &"Gate")
			if gate != null and gate.has_method("set_prompt_visible"):
				gate.call("set_prompt_visible", prompt_visible)
			last_synced_camp_prompt_visible = prompt_visible
		if camp_highlighted_structure != last_synced_camp_highlighted_structure:
			active_camp_scene.set_highlighted(camp_highlighted_structure)
			last_synced_camp_highlighted_structure = camp_highlighted_structure

func _update_arrival_crest(delta: float) -> void:
	if not is_instance_valid(camp_arrival_crest) or not camp_arrival_crest.visible:
		return
	camp_arrival_crest_elapsed += delta
	if camp_arrival_crest_elapsed <= 2.6:
		camp_arrival_crest.modulate.a = 1.0
	elif camp_arrival_crest_elapsed < 3.5:
		camp_arrival_crest.modulate.a = 1.0 - (camp_arrival_crest_elapsed - 2.6) / 0.9
	else:
		camp_arrival_crest.visible = false
		camp_arrival_crest.modulate.a = 0.0

func _configure_world() -> void:
	# Keep authored world coordinates stable.  The old implementation scaled
	# this field with the current window width, so a wide Godot debug viewport
	# stretched logic positions while the editable decorations remained in their
	# native 1170x3376 scene.  That produced the apparent decoration offset.
	# Only the outer world margin is responsive; the Meadow/camp composition is
	# always the same field the user edits in blackthorn_moor_preview.tscn.
	world_content_size = AUTHORED_WORLD_CONTENT_SIZE
	world_size = Vector2(size.x * WORLD_WIDTH_SCREENS, size.y * WORLD_HEIGHT_SCREENS)
	# Do not center the authored field inside the expanded debug/window world.
	# The preview scene is authored at (390, 844), and every decoration is
	# relative to that anchor.  Centering it from the current viewport width
	# moved the whole decoration set while the editor scene stayed put.  Keep
	# the native anchor stable and let the camera reveal additional world space.
	world_content_origin = AUTHORED_WORLD_CONTENT_ORIGIN
	# Keep the authored Blackthorn region attached to the same native world
	# coordinates as the Meadow preview. Scaling this offset with the viewport
	# made the generated terrain move while authored trees, rocks, and props did
	# not, which is the decoration drift seen outside the 390x844 reference.
	region_origin = world_content_origin + Vector2(-7.0, 800.0)
	camp_world_origin = Vector2.ZERO
	_sync_structure_anchors()
	camera_offset = Vector2.ZERO


func _setup_visual_layers() -> void:
	visual_quality_controller = AshenSceneBindings.optional(self, &"VisualQualityController")
	world_root = AshenSceneBindings.required(self, &"WorldRoot", "GameRoot") as Node2D
	if world_root == null:
		push_error("GameRoot is missing its authored WorldHost/WorldRoot")
		return
	world_root.scale = Vector2.ONE * WORLD_CAMERA_SCALE
	world_root.position = _world_root_camera_position()
	for host_name: String in ["TerrainHost", "WorldArtHost", "CampHost", "ActorHost", "CombatHost", "EffectsHost", "DebugHost"]:
		var host := AshenSceneBindings.required(world_root, StringName(host_name), "WorldRoot") as Node2D
		if host == null:
			push_error("Authored WorldRoot is missing %s" % host_name)
			continue
		for child: Node in host.get_children():
			child.free()
	blackthorn_moor_preview = BlackthornMoorPreviewScene.instantiate() as Node2D
	blackthorn_moor_preview.name = "BlackthornMoor"
	world_root.add_child(blackthorn_moor_preview)
	# The authored Meadow scene and the live world must share the same content
	# origin before we adopt a camp tier from its CampAuthoring mount.  This
	# makes the scene's global coordinates the runtime coordinates instead of
	# applying the origin a second time after reparenting.
	blackthorn_moor_preview.set("preview_content_origin", world_content_origin)
	terrain_layer = AshenSceneBindings.optional(blackthorn_moor_preview, &"Terrain") as AshenTerrainLayer
	blackthorn_world_art = AshenSceneBindings.optional(blackthorn_moor_preview, &"AuthoredComposition") as Node2D
	world_presentation = AshenSceneBindings.optional(blackthorn_moor_preview, &"WorldPresentation") as Node2D
	if terrain_layer == null or blackthorn_world_art == null or world_presentation == null:
		push_error("BlackthornMoorPreview is missing one of its authored runtime children")
	actor_presentation = ActorPresentationScene.instantiate() as Node2D
	var actor_host := AshenSceneBindings.required(world_root, &"ActorHost", "WorldRoot")
	if actor_host != null:
		actor_host.add_child(actor_presentation)
	combat_presentation = CombatPresentationScene.instantiate() as Node2D
	var combat_host := AshenSceneBindings.required(world_root, &"CombatHost", "WorldRoot")
	if combat_host != null:
		combat_host.add_child(combat_presentation)
	world_tint = AshenSceneBindings.optional(self, &"WorldTint") as ColorRect
	collision_debug_scene = CollisionDebugScene.instantiate() as Node2D
	var debug_host := AshenSceneBindings.optional(world_root, &"DebugHost")
	if debug_host != null:
		debug_host.add_child(collision_debug_scene)
	static_visual_signature = ""
	_sync_authored_camp_scene(true)
	_sync_blackthorn_world_art()
	# The authored ruined-city scene owns its physical polygons. Cache those
	# shapes only after the canonical Meadow scene is mounted so navigation,
	# enemy routing, and projectiles use the exact editor geometry.
	_invalidate_enemy_flow_blockers()


func _sync_blackthorn_world_art() -> void:
	if not is_instance_valid(blackthorn_moor_preview) or not is_instance_valid(blackthorn_world_art):
		return
	# The preview scene is the source of truth.  Move its wrapper once for the
	# active viewport and leave the authored decoration root/children untouched.
	# This prevents the old runtime-only origin from being applied a second time.
	if blackthorn_moor_preview.has_method("apply_runtime_content_origin"):
		blackthorn_moor_preview.call("apply_runtime_content_origin", world_content_origin)
	# World dressing remains visible around the camp arrival view as well as in
	# expeditions; it has no gameplay nodes and sits behind the authored camp.
	blackthorn_world_art.visible = true


func _visual_state_signature() -> String:
	var profile: Dictionary = save.get("profile", {})
	return "%d:%d:%s:%s:%d:%d:%d:%d:%d:%s" % [
		int(generated_region.get("seed", profile.get("region_seed", 41041))),
		_town_level(),
		str(_constructed_buildings()),
		str(_building_plots()),
		int(profile.get("armory_level", 0)),
		int(profile.get("blacksmith_level", 0)),
		int(profile.get("quartermaster_level", 0)),
		int(profile.get("training_level", 0)),
		RenderTheme.VISUAL_VERSION,
		str(size),
	]


func _sync_visual_layers(force: bool = false) -> void:
	if not is_instance_valid(terrain_layer) or save.is_empty():
		return
	_sync_blackthorn_world_art()
	var signature: String = _visual_state_signature()
	if not force and signature == static_visual_signature:
		return
	static_visual_signature = signature
	# The terrain renderer uses the authored camp bounds to decide which
	# surrounding cells are cobbled, road, or Moor ground.  Sync the selected
	# camp scene first so a Hall reset/upgrade cannot rebuild terrain with the
	# previous tier's bounds and leave the ground visually out of step with the
	# walls and structures that were just swapped in.
	_sync_authored_camp_scene()
	blackthorn_moor_preview.call(
		"configure_runtime",
		generated_region,
		world_content_origin,
		region_origin,
		world_size,
		_town_bounds_world(),
		int(generated_region.get("seed", save.get("profile", {}).get("region_seed", 41041)))
	)


func _sync_authored_camp_scene(force: bool = false) -> void:
	if not is_instance_valid(world_root):
		return
	var desired_tier: int = clampi(_town_level(), 0, AuthoredCampTierScenes.size() - 1)
	# The Meadow preview owns a real CampTier0 instance for authoring.  Adopt
	# that exact node on a fresh tier-0 boot so edits made in the combined
	# preview (including scene-instance overrides) are the edits used at runtime.
	# Higher Hall tiers still swap in their authored tier scene normally.
	var needs_replacement: bool = not is_instance_valid(active_camp_scene) or int(active_camp_scene.camp_tier) != desired_tier
	if needs_replacement:
		cached_town_bounds_world = Rect2()
		cached_town_bounds_level = -1
		cached_town_bounds_scene_id = 0
		if is_instance_valid(active_camp_scene):
			active_camp_scene.free()
		active_camp_scene = _take_preview_camp_scene(desired_tier)
		if active_camp_scene == null:
			active_camp_scene = AuthoredCampTierScenes[desired_tier].instantiate() as AshenCampRuntime
		active_camp_scene.name = "ActiveCampTier"
		active_camp_scene.z_index = 0
		active_camp_scene.structure_tapped.connect(_on_authored_camp_structure_tapped)
		active_camp_scene.structure_hovered.connect(_on_authored_camp_structure_hovered)
		last_synced_camp_highlighted_structure = "<unset>"
		last_synced_camp_prompt_visible = not (screen == Screen.CAMP and _camp_hub_active())
		var camp_host := AshenSceneBindings.required(world_root, &"CampHost", "WorldRoot") as Node2D
		if camp_host == null:
			push_error("Authored WorldRoot is missing CampHost")
			return
		if active_camp_scene.get_parent() != camp_host:
			camp_host.add_child(active_camp_scene)
		if not active_camp_scene.has_meta("preview_authored_position"):
			active_camp_scene.position = world_content_origin
		_request_world_depth_rebuild()
	var profile: Dictionary = save.get("profile", {})
	var building_tiers: Dictionary = {
		"armory": int(profile.get("armory_level", 0)),
		"blacksmith": int(profile.get("blacksmith_level", 0)),
		"quartermaster": int(profile.get("quartermaster_level", 0)),
		"training": int(profile.get("training_level", 0)),
	}
	active_camp_scene.bind_state(desired_tier, _building_plots(), building_tiers)
	_sync_structure_definitions_from_authored_camp()
	_apply_visual_quality_setting(String(save.settings.get("lighting_quality", "medium")))


func _request_world_depth_rebuild() -> void:
	if not is_instance_valid(world_root):
		return
	var depth_controller := AshenSceneBindings.optional(world_root, &"WorldDepthSort")
	if depth_controller != null and depth_controller.has_method("request_rebuild"):
		depth_controller.call("request_rebuild")


func _take_preview_camp_scene(desired_tier: int) -> AshenCampRuntime:
	if not is_instance_valid(blackthorn_moor_preview):
		return null
	var mount := AshenSceneBindings.optional(blackthorn_moor_preview, &"CampAuthoring") as Node2D
	if mount == null:
		return null
	var selected: AshenCampRuntime = null
	for child: Node in mount.get_children():
		var candidate := child as AshenCampRuntime
		if candidate == null:
			continue
		if int(candidate.camp_tier) == desired_tier:
			selected = candidate
			break
	if selected == null:
		return null
	var authored_position: Vector2 = Vector2.ZERO
	if blackthorn_moor_preview.has_method("authored_camp_local_position"):
		authored_position = Vector2(blackthorn_moor_preview.call("authored_camp_local_position", selected))
	else:
		authored_position = mount.position + selected.position
	# Duplicate the actual instance embedded in the Meadow preview.  This keeps
	# every editor override (positions, tiles, props, collisions, and child
	# transforms) while leaving all camp tiers available for a later Hall
	# upgrade. Re-instantiating camp_tier_N.tscn here used to discard overrides
	# authored directly in the combined preview.
	var runtime_camp := selected.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as AshenCampRuntime
	if runtime_camp == null:
		push_error("Could not duplicate authored camp tier %d from Meadow preview" % desired_tier)
		return null
	runtime_camp.visible = true
	# Authoring instances must not render or participate in physics at runtime;
	# the duplicated active camp below is the sole live owner.
	mount.visible = false
	for authored_node: Node in mount.find_children("*", "CollisionObject2D", true, false):
		var collision_object := authored_node as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		collision_object.input_pickable = false
	var camp_host := AshenSceneBindings.required(world_root, &"CampHost", "WorldRoot")
	if camp_host == null:
		return null
	camp_host.add_child(runtime_camp)
	runtime_camp.position = world_content_origin + authored_position
	runtime_camp.set_meta("preview_authored_position", true)
	return runtime_camp


func _sync_structure_definitions_from_authored_camp() -> void:
	if not is_instance_valid(active_camp_scene):
		return
	for structure_id: String in camp_structure_definitions:
		if not _is_constructed(structure_id):
			continue
		var info: Dictionary = active_camp_scene.structure_info(structure_id)
		if info.is_empty():
			if structure_id in ["veterans_hall", "campfire"] or not _plot_for_building(structure_id).is_empty():
				push_error("Authored camp tier %d has no live scene for constructed structure '%s'" % [_town_level(), structure_id])
			continue
		var definition := camp_structure_definitions[structure_id] as StructureDefinition
		definition.anchor = Vector2(info.anchor)
		var footprint: PackedVector2Array = info.get("footprint", PackedVector2Array())
		if footprint.size() >= 3:
			definition.footprint = footprint
			var tier_index: int = _structure_tier(structure_id)
			if not definition.tier_footprints.is_empty() and tier_index < definition.tier_footprints.size():
				definition.tier_footprints[tier_index] = footprint
		var interaction: PackedVector2Array = info.get("interaction", PackedVector2Array())
		if interaction.size() >= 3:
			definition.interaction_polygon = interaction
