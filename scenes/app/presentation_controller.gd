extends "res://scenes/app/game_state.gd"
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
	_cache_region_blockers()
	_configure_world()
	_setup_visual_layers()
	_build_structure_definitions()
	_sync_structure_anchors()
	_sync_visual_layers(true)
	camp_player_position = _safe_camp_spawn_position()
	audio_controller = get_node_or_null("Audio") as AshenAudioController
	ui_controller = get_node_or_null("UIController") as AshenUiController
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
	_sync_visual_layers()
	_update_arrival_crest(delta)
	if is_instance_valid(world_root):
		world_root.position = -camera_offset.round()
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
	_sync_actor_presentation()

func _sync_actor_presentation() -> void:
	if not is_instance_valid(actor_presentation):
		return
	var actor_states: Array = []
	var actor_position: Vector2
	var actor_direction: Vector2 = last_move_vector
	var actor_moving: bool
	if screen == Screen.CAMP:
		actor_states.assign(camp_wanderers)
		actor_position = camp_player_position
		actor_moving = camp_move_vector.length_squared() > 0.01
		actor_presentation.position = Vector2.ZERO
	else:
		actor_states.assign(enemies)
		actor_position = player_position
		actor_moving = player_move_vector.length_squared() > 0.01
		actor_presentation.position = shake_offset.round()
	actor_presentation.call("sync_frame", active_class, actor_position, actor_direction, actor_moving, player_hp, player_max_hp, actor_states, actor_position)
	if is_instance_valid(combat_presentation):
		combat_presentation.position = shake_offset.round() if screen == Screen.RUN else Vector2.ZERO
		var projectile_states: Array = []
		if screen == Screen.RUN:
			projectile_states.assign(projectiles)
		combat_presentation.call("sync_projectiles", projectile_states)
		var pickup_states: Array = []
		var damage_states: Array = []
		var effect_states: Array = []
		var hazard_states: Array = []
		var trap_states: Array = []
		if screen == Screen.RUN:
			pickup_states.assign(pickups)
			damage_states.assign(float_texts)
			effect_states.assign(effects)
			hazard_states.assign(hazards)
			trap_states.assign(traps)
		combat_presentation.call("sync_frame", pickup_states, damage_states, effect_states, hazard_states, trap_states)
	if is_instance_valid(world_presentation):
		world_presentation.position = shake_offset.round() if screen == Screen.RUN else Vector2.ZERO
		var landmark_states: Array = []
		if screen == Screen.RUN:
			landmark_states.assign(exploration_points)
		world_presentation.call("sync_frame", screen == Screen.RUN, _frontier_gate_position(), save.get("profile", {}).get("unlocked_biomes", []).has("gloamwood"), landmark_states, run_elapsed)
	_sync_camp_ambience_scene()
	if is_instance_valid(world_tint):
		world_tint.color = Color(0.02, 0.025, 0.027, 0.18 if screen == Screen.RUN else 0.16 if screen == Screen.CAMP else 0.62)
	_sync_collision_debug_scene()


func _sync_camp_ambience_scene() -> void:
	if not is_instance_valid(camp_ambience):
		return
	camp_ambience.visible = screen == Screen.CAMP and _camp_hub_active()
	if not camp_ambience.visible:
		return
	var fire_position: Vector2 = Vector2(active_camp_scene.structure_info("campfire").get("anchor", Vector2.ZERO)) if is_instance_valid(active_camp_scene) else Vector2.ZERO
	var hall_position: Vector2 = Vector2(active_camp_scene.structure_info("veterans_hall").get("anchor", Vector2.ZERO)) if is_instance_valid(active_camp_scene) else Vector2.ZERO
	var smith_position := Vector2.ZERO
	if is_instance_valid(active_camp_scene) and _is_constructed("blacksmith"):
		smith_position = Vector2(active_camp_scene.structure_info("blacksmith").get("anchor", Vector2.ZERO))
	var brazier_position := Vector2.ZERO
	var brazier_visible := false
	for entry: Dictionary in _visible_camp_decor():
		if String(entry.id) == "brazier":
			brazier_position = Vector2(entry.anchor) - Vector2(0.0, 35.0)
			brazier_visible = true
			break
	camp_ambience.call("sync_frame", camp_elapsed + run_elapsed, clampf(float(save.settings.effect_density), 0.0, 1.0), _town_bounds_world(), fire_position, hall_position, smith_position, _is_constructed("blacksmith"), brazier_position, brazier_visible, _camp_interaction_position("gate"))
	if is_instance_valid(active_camp_scene):
		active_camp_scene.set_highlighted(camp_highlighted_structure)

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
	world_content_size = Vector2(size.x * WORLD_CONTENT_WIDTH_SCREENS, size.y * WORLD_CONTENT_HEIGHT_SCREENS)
	world_size = Vector2(size.x * WORLD_WIDTH_SCREENS, size.y * WORLD_HEIGHT_SCREENS)
	world_content_origin = (world_size - world_content_size) * 0.5
	var content_scale := Vector2(world_content_size.x / 1170.0, world_content_size.y / 3376.0)
	# Keep the authored Blackthorn region attached to the same three-by-four
	# content field while the surrounding margin becomes traversable moor.
	region_origin = world_content_origin + Vector2(-7.0 * content_scale.x, 800.0 * content_scale.y)
	camp_world_origin = Vector2.ZERO
	_sync_structure_anchors()
	camera_offset = Vector2.ZERO


func _setup_visual_layers() -> void:
	world_root = get_node_or_null("WorldHost/WorldRoot") as Node2D
	if world_root == null:
		push_error("GameRoot is missing its authored WorldHost/WorldRoot")
		return
	world_root.position = -camera_offset.round()
	for host_name: String in ["TerrainHost", "CampHost", "ActorHost", "CombatHost", "EffectsHost", "DebugHost"]:
		var host := world_root.get_node_or_null(host_name) as Node2D
		if host == null:
			push_error("Authored WorldRoot is missing %s" % host_name)
			continue
		for child: Node in host.get_children():
			child.free()
	terrain_layer = TerrainLayerScene.instantiate() as AshenTerrainLayer
	terrain_layer.name = "TerrainStaticLayer"
	world_root.get_node("TerrainHost").add_child(terrain_layer)
	actor_presentation = ActorPresentationScene.instantiate() as Node2D
	world_root.get_node("ActorHost").add_child(actor_presentation)
	combat_presentation = CombatPresentationScene.instantiate() as Node2D
	world_root.get_node("CombatHost").add_child(combat_presentation)
	world_presentation = WorldPresentationScene.instantiate() as Node2D
	world_root.get_node("EffectsHost").add_child(world_presentation)
	camp_ambience = CampAmbienceScene.instantiate() as Node2D
	world_root.get_node("EffectsHost").add_child(camp_ambience)
	world_tint = get_node_or_null("WorldTint") as ColorRect
	collision_debug_scene = CollisionDebugScene.instantiate() as Node2D
	world_root.get_node("DebugHost").add_child(collision_debug_scene)
	static_visual_signature = ""
	_sync_authored_camp_scene(true)


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
	var signature: String = _visual_state_signature()
	if not force and signature == static_visual_signature:
		return
	static_visual_signature = signature
	terrain_layer.rebuild(
		generated_region,
		region_origin,
		int(generated_region.get("seed", save.get("profile", {}).get("region_seed", 41041))),
		RenderTheme.terrain_config(world_size, _town_bounds_world())
	)
	_sync_authored_camp_scene()


func _sync_authored_camp_scene(force: bool = false) -> void:
	if not is_instance_valid(world_root):
		return
	var desired_tier: int = clampi(_town_level(), 0, AuthoredCampTierScenes.size() - 1)
	if force or not is_instance_valid(active_camp_scene) or int(active_camp_scene.camp_tier) != desired_tier:
		if is_instance_valid(active_camp_scene):
			active_camp_scene.free()
		active_camp_scene = AuthoredCampTierScenes[desired_tier].instantiate() as AshenCampRuntime
		active_camp_scene.name = "ActiveCampTier"
		active_camp_scene.position = world_content_origin
		active_camp_scene.z_index = 0
		active_camp_scene.structure_tapped.connect(_on_authored_camp_structure_tapped)
		active_camp_scene.structure_hovered.connect(_on_authored_camp_structure_hovered)
		var camp_host := world_root.get_node_or_null("CampHost") as Node2D
		if camp_host == null:
			push_error("Authored WorldRoot is missing CampHost")
			return
		camp_host.add_child(active_camp_scene)
	var profile: Dictionary = save.get("profile", {})
	var building_tiers: Dictionary = {
		"armory": int(profile.get("armory_level", 0)),
		"blacksmith": int(profile.get("blacksmith_level", 0)),
		"quartermaster": int(profile.get("quartermaster_level", 0)),
		"training": int(profile.get("training_level", 0)),
	}
	active_camp_scene.bind_state(desired_tier, _building_plots(), building_tiers)
	_sync_structure_definitions_from_authored_camp()


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
