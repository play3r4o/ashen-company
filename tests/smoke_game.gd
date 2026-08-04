extends SceneTree

const Saves = preload("res://src/save_service.gd")
const Rules = preload("res://src/rules.gd")
const Content = preload("res://src/content.gd")
const Roster = preload("res://src/services/roster_service.gd")
const HudLayoutScene = preload("res://scenes/ui/hud/hud.tscn")

var failures: int = 0

func _init() -> void:
	call_deferred("run_smoke")

func run_smoke() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Control = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_new_run("spear")
	check(game.exploration_points.size() == 10 and game.expedition_interact_button != null, "expedition begins with a regenerated set of searchable Moor landmarks and a contextual action")
	var first_discovery = game.exploration_points[0]
	game.player_position = first_discovery.position
	game._update_exploration()
	var dread_before_discovery: float = game._current_dread()
	game._interact_with_expedition()
	check(first_discovery.discovered and game.run_discoveries == 1 and game.run_exploration_silver > 0 and game._current_dread() > dread_before_discovery, "searching a landmark grants field rewards and advances Dread")
	game.run_discoveries = 2
	game._update_exploration()
	check(game.world_size.x == game.size.x * 5.0 and game.world_size.y == game.size.y * 6.0 and first_discovery.position.y > game.size.y, "town and searchable moor occupy one continuous four-direction world")
	var region_size: Vector2i = game.generated_region.get("size_tiles", Vector2i(36, 78))
	var region_cells: Array = game.generated_region.get("cells", [])
	var opening_indices: Array[int] = [18, 39 * region_size.x + region_size.x - 1, 39 * region_size.x, (region_size.y - 1) * region_size.x + 18]
	var cardinal_openings_clear: bool = true
	for opening_index: int in opening_indices:
		cardinal_openings_clear = cardinal_openings_clear and opening_index < region_cells.size() and String(region_cells[opening_index].get("kind", "barrier")) != "barrier"
	check(cardinal_openings_clear, "Blackthorn Moor keeps passable north, east, west and south frontier openings")
	game.run_discoveries = 1
	var actor_scenes_load: bool = true
	for actor_path: String in [
		"res://scenes/actors/player/player_visual_warrior.tscn",
		"res://scenes/actors/player/player_visual_hunter.tscn",
		"res://scenes/actors/player/player_visual_mage.tscn",
		"res://scenes/actors/player/player_visual_rogue.tscn",
		"res://scenes/actors/enemies/wolf.tscn",
		"res://scenes/actors/enemies/raider.tscn",
		"res://scenes/actors/enemies/archer.tscn",
		"res://scenes/actors/enemies/reaver.tscn",
		"res://scenes/actors/enemies/blighted.tscn",
		"res://scenes/actors/enemies/crow.tscn",
		"res://scenes/actors/enemies/houndmaster.tscn",
		"res://scenes/actors/enemies/grave_guard.tscn",
		"res://scenes/actors/enemies/barrow_knight.tscn",
	]:
		var actor_scene := load(actor_path) as PackedScene
		actor_scenes_load = actor_scenes_load and actor_scene != null
	check(actor_scenes_load, "the four authored hero scenes and complete enemy scene set load")
	var all_spawns_clear_town: bool = true
	var protected_view: Rect2 = game._visible_world_rect().grow(game.ENEMY_SPAWN_VIEW_MARGIN - 1.0)
	for spawn_sample: int in 24:
		var spawn_position: Vector2 = game._random_edge_position()
		all_spawns_clear_town = all_spawns_clear_town and not game._town_bounds_world().has_point(spawn_position) and not protected_view.has_point(spawn_position)
	check(all_spawns_clear_town, "hostile waves spawn beyond both the refuge and the visible camera margin")
	game._spawn_enemy("raider", false)
	var wall_enemy = game.enemies.back()
	var enemy_town_bounds: Rect2 = game._town_bounds_world()
	wall_enemy.position = Vector2(enemy_town_bounds.get_center().x, enemy_town_bounds.end.y + wall_enemy.radius + 5.0)
	var enemy_wall_y: float = wall_enemy.position.y
	game._move_enemy_with_collision(wall_enemy, Vector2(0.0, -40.0))
	check(is_equal_approx(wall_enemy.position.y, enemy_wall_y) and game._enemy_position_blocked(enemy_town_bounds.get_center(), wall_enemy.radius), "mobs collide with the whole protected town instead of walking through its palisade or gate")
	var warrior_frames := load("res://assets/runtime/actors/warrior_frames.tres") as SpriteFrames
	var warrior_textures: Dictionary = {}
	for direction: String in ["down", "left", "right", "up"]:
		var frame := warrior_frames.get_frame_texture(StringName(direction + "_idle"), 0) as AtlasTexture
		warrior_textures[direction] = frame.atlas
	var hero_canvas_consistent: bool = true
	for hero_texture: Texture2D in warrior_textures.values():
		hero_canvas_consistent = hero_canvas_consistent and hero_texture.get_size().y == 64.0 and fmod(hero_texture.get_size().x, 56.0) == 0.0
	var warrior_down_bounds: Rect2i = opaque_bounds(warrior_textures.down)
	var warrior_left_bounds: Rect2i = opaque_bounds(warrior_textures.left)
	var warrior_right_bounds: Rect2i = opaque_bounds(warrior_textures.right)
	var warrior_up_bounds: Rect2i = opaque_bounds(warrior_textures.up)
	check(hero_canvas_consistent and absi(warrior_left_bounds.size.y - warrior_down_bounds.size.y) <= 2 and absi(warrior_right_bounds.size.y - warrior_down_bounds.size.y) <= 2, "every class direction uses one canvas and side turns keep the same character height")
	check(warrior_up_bounds.position.y <= 7 and warrior_up_bounds.size.y >= 55, "the rear-facing Warrior keeps the complete spearhead and ground anchor")
	check(game.health_bar != null, "the active expedition exposes a persistent health bar")
	game._spawn_enemy("raider", false)
	var thrust_target = game.enemies.back()
	game.player_position = thrust_target.position - Vector2(30.0, 0.0)
	game.nearest_target = thrust_target
	game.weapon_timers["spear"] = 0.0
	var thrust_health: float = thrust_target.health
	game._fire_weapon("spear")
	check(game.projectiles.is_empty() and thrust_target.health < thrust_health, "spear attacks in contact range without spawning a projectile")
	var base_attack_interval: float = float(game.weapon_timers.spear)
	game.techniques.quick_hands = 1
	game._recalculate_player_stats()
	game._fire_weapon("spear")
	check(float(game.weapon_timers.spear) < base_attack_interval, "attack speed visibly reduces the time between weapon attacks")
	game._spawn_enemy("reaver", false)
	var stagger_target = game.enemies.back()
	game._damage_enemy(stagger_target, 1.0, false, "stagger", "sling")
	check(stagger_target.stagger >= 0.30, "sling stagger uses the duration stated by its statistics")
	game.player_position = Vector2(195.0, 430.0)
	stagger_target.position = Vector2(195.0, 260.0)
	game.weapons = {"sling": 1}
	game.weapon_timers = {"sling": 0.0}
	game.nearest_target = stagger_target
	game._fire_weapon("sling")
	var sling_projectiles: Array = game.projectiles.filter(func(projectile): return projectile.kind == "sling")
	var sling_spread_dot: float = sling_projectiles[0].velocity.normalized().dot(sling_projectiles[-1].velocity.normalized()) if sling_projectiles.size() >= 3 else 1.0
	check(sling_projectiles.size() == 3 and sling_spread_dot < 0.75, "sling fires a three-stone shotgun burst across a wider fan")
	for projectile in game.projectiles.duplicate():
		game._recycle_projectile(projectile)
	game.weapons = {"spear": 1}
	game.weapon_timers = {"spear": 0.0}
	game._spawn_enemy("archer", false)
	var archer = game.enemies.back()
	game.player_position = game._camp_gate_position() + Vector2(0.0, 160.0)
	game._update_world_camera(game.player_position, false, true)
	var visible_map: Rect2 = game._visible_world_rect()
	archer.position = Vector2(visible_map.end.x + 28.0, game.player_position.y)
	archer.attack_cooldown = 0.0
	var off_map_x: float = archer.position.x
	var arrows_before: int = game.projectiles.size()
	game._update_enemies(0.1)
	check(game.projectiles.size() == arrows_before and archer.position.x < off_map_x, "archers enter the map before they can fire")
	archer.position = game.player_position + Vector2(0.0, 100.0)
	archer.attack_cooldown = 0.0
	archer.path_check_timer = 0.0
	game._update_enemies(0.1)
	check(game.projectiles.size() == arrows_before + 1, "archers can fire after entering the playable map")
	for projectile in game.projectiles.duplicate():
		game._recycle_projectile(projectile)
	for enemy in game.enemies:
		game.enemy_pool.append(enemy)
	game.enemies.clear()
	game.player_position = Vector2(195.0, 430.0)
	for target_position: Vector2 in [Vector2(95.0, 330.0), Vector2(295.0, 330.0), Vector2(195.0, 570.0)]:
		game._spawn_enemy("raider", false)
		game.enemies.back().position = target_position
	game.active_class = "mage"
	game.weapons = {"witchfire": 1}
	game.weapon_timers = {"witchfire": 0.0}
	game.nearest_target = game._find_nearest_enemy(game.player_position)
	game._fire_weapon("witchfire")
	var witchfire_targets: Dictionary = {}
	for projectile in game.projectiles:
		if projectile.kind == "witchfire":
			witchfire_targets[projectile.target_uid] = true
	check(game.projectiles.size() == 2 and witchfire_targets.size() == 2 and not witchfire_targets.has(-1), "mage projectiles split across distinct living targets")
	for projectile in game.projectiles.duplicate():
		game._recycle_projectile(projectile)
	var projectile_weapons: Array[String] = ["bow", "sling", "crossbow", "throwing_knives", "chakrams", "staff", "wand", "runic_orb"]
	var projectile_weapon_failures: Array[String] = []
	var projectile_lifetime_failures: Array[String] = []
	for projectile_weapon: String in projectile_weapons:
		game.weapons = {projectile_weapon: 1}
		game.weapon_timers = {projectile_weapon: 0.0}
		game.nearest_target = game._find_nearest_enemy(game.player_position)
		var before_projectile_count: int = game.projectiles.size()
		game._fire_weapon(projectile_weapon)
		if game.projectiles.size() <= before_projectile_count:
			projectile_weapon_failures.append(projectile_weapon)
		elif int(game.projectiles.back().pierce) <= 0:
			projectile_lifetime_failures.append(projectile_weapon)
		for projectile in game.projectiles.duplicate():
			game._recycle_projectile(projectile)
	check(projectile_weapon_failures.is_empty(), "every projectile weapon creates a live shot")
	check(projectile_lifetime_failures.is_empty(), "every projectile weapon survives until its first collision")
	# Bow ranks use patterned volleys: ordinary shots stay single, the split
	# interval fires two, and the mastered fifth-shot volley fires five. Keep the
	# offer text aligned with those actual per-attack counts.
	game.projectile_bonus = 0
	game.next_ranged_projectiles = 0
	game.weapon_attack_counts.clear()
	game.weapons = {"bow": 3}
	var bow_rank_three_counts: Array[int] = []
	for shot: int in 3:
		var bow_before: int = game.projectiles.size()
		game._fire_weapon("bow")
		bow_rank_three_counts.append(game.projectiles.size() - bow_before)
	for projectile in game.projectiles.duplicate():
		game._recycle_projectile(projectile)
	check(bow_rank_three_counts == [1, 1, 2], "bow rank three fires two arrows only on every third shot")
	var bow_rank_three_text: String = game._ability_rank_delta_text("bow", 3)
	check(bow_rank_three_text.contains("NORMAL SHOT  1 PROJECTILE") and bow_rank_three_text.contains("EVERY 3 ATTACKS  2 PROJECTILES"), "bow split upgrade describes its conditional volley")
	game.weapon_attack_counts.clear()
	game.weapons = {"bow": 5}
	var bow_rank_five_counts: Array[int] = []
	for shot: int in 5:
		var mastered_bow_before: int = game.projectiles.size()
		game._fire_weapon("bow")
		bow_rank_five_counts.append(game.projectiles.size() - mastered_bow_before)
	for projectile in game.projectiles.duplicate():
		game._recycle_projectile(projectile)
	check(bow_rank_five_counts == [1, 1, 2, 1, 5], "bow rank five preserves the split and fifth-shot volley patterns")
	game.active_class = "warrior"
	game.weapons = {"spear": 1}
	game.weapon_timers = {"spear": 0.0}
	game.player_hp = 100000.0
	game.player_max_hp = 100000.0
	game.run_elapsed = 360.0
	for index: int in 180:
		game._spawn_enemy(game._choose_wave_enemy(), false)
	var started: int = Time.get_ticks_msec()
	for frame: int in 120:
		game._process_run(1.0 / 60.0)
	var elapsed_ms: int = Time.get_ticks_msec() - started
	check(game.enemies.size() <= game.MAX_ENEMIES + game.MAX_SPECIALS, "enemy cap remains bounded")
	check(game.projectiles.size() <= game.MAX_PROJECTILES, "projectile cap remains bounded")
	check(game.pickups.size() <= game.MAX_PICKUPS, "pickup cap remains bounded")
	var contract_overlay: Control = game.find_child("ContractOverlay", true, false)
	if contract_overlay != null:
		game._decline_contract(contract_overlay)
	game.player_position = Vector2(195.0, 430.0)
	game.joystick_vector = Vector2.RIGHT
	game._update_player(0.1)
	game.joystick_vector = Vector2.ZERO
	var released_position: Vector2 = game.player_position
	game._update_player(0.1)
	check(game.player_position.is_equal_approx(released_position), "player stops immediately when movement input is released")
	game.guard_cooldown = 0.0
	game._guard_step()
	check(game.guard_cooldown > 5.9 and game.guard_timer > 0.0, "Guard Step activates and enters cooldown")
	game.joystick_touch_id = 7
	game.joystick_vector = Vector2.RIGHT
	game._show_upgrade_choices()
	check(game.joystick_touch_id == -1 and game.joystick_vector == Vector2.ZERO, "opening an upgrade clears the active joystick touch")
	var upgrade_overlay: Control = game.find_child("UpgradeOverlay", true, false)
	check(upgrade_overlay != null, "upgrade overlay is created for the level-up choice")
	if upgrade_overlay != null:
		await process_frame
		var upgrade_description: Label = upgrade_overlay.find_child("CardDescription", true, false) as Label
		var upgrade_stats: Label = upgrade_overlay.find_child("CardStats", true, false) as Label
		check(upgrade_description != null and upgrade_stats != null and upgrade_stats.get_theme_font_size("font_size") < upgrade_description.get_theme_font_size("font_size") and not upgrade_description.get_global_rect().intersects(upgrade_stats.get_global_rect()), "level-up choices separate their descriptions from compact exact statistics")
		game._apply_upgrade({"type": "heal", "id": "rations"}, upgrade_overlay)
		check(not game.choosing_upgrade and game.joystick_touch_id == -1 and game.joystick_vector == Vector2.ZERO, "returning from an upgrade accepts fresh movement input")
	check(elapsed_ms < 4000, "two simulated heavy seconds complete within the smoke-test budget")
	var saved_elapsed: float = game.run_elapsed
	game._snapshot_run()
	check(not game.save.active_run.is_empty(), "active expedition creates a resumable snapshot")
	Saves.save_data(game.save)
	game.save = Saves.load_data()
	game._resume_run()
	check(absf(game.run_elapsed - saved_elapsed) < 0.01 and game.weapons.has("spear") and game.run_discoveries == 1 and game.exploration_points[0].discovered, "serialized expedition restores its timer, build and discoveries")
	# Web/PWA focus changes can suspend the scene without destroying it.  The
	# lifecycle recovery must rebuild a playable run instead of leaving the
	# saved HUD paused with no input path.
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.run_paused and not game.save.active_run.is_empty(), "focus-out pauses and snapshots the active expedition")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	check(game.screen == game.Screen.RUN and not game.run_paused and game.find_child("LiveHud", true, false) != null, "focus-in restores an interrupted expedition and its live controls")
	game.run_elapsed = 479.0
	game.run_kills = 120
	game.run_elites = 2
	game.boss_defeated = true
	game._finish_run(true)
	check(game.screen == game.Screen.RESULTS and not game.save.profile.veteran.is_empty(), "victory creates results and a Veteran Record")
	game.save.profile.hall_level = 0
	game.save.profile.constructed_buildings = ["veterans_hall", "campfire"]
	game.save.profile.building_plots = {}
	game.save.profile.armory_level = 0
	game.save.profile.blacksmith_level = 0
	game.save.profile.training_level = 0
	game.save.profile.quartermaster_level = 0
	game.save.profile.silver = 5000
	game.save.profile.provisions = 5000
	game.camp_player_position = game._safe_camp_spawn_position()
	game._show_camp()
	check(game.find_child("LiveHud", true, false) != null and game.find_child("CampScroll", true, false) == null, "camp uses the actual fixed HUD scene")
	check(game._town_capacity() == 2 and game._constructed_count() == 2 and game._town_definition().bounds.size == Vector2(340.0, 480.0) and game.active_camp_scene.revealed_plot_ids().is_empty(), "a fresh refuge uses the portrait Hall-and-fire footprint from the approved composition")
	check(not game._camp_position_blocked(game.camp_player_position) and game.camp_player_position.distance_to(game._camp_interaction_position("campfire")) > 28.0, "the hero spawns clear of the campfire footprint")
	var camp_interact: Button = game.find_child("CampInteractButton", true, false) as Button
	var camp_start: Vector2 = game._safe_camp_spawn_position()
	game.camp_player_position = camp_start
	var camp_camera_start: Vector2 = game.camera_offset
	game.joystick_vector = Vector2.RIGHT
	game._process_camp(0.1)
	check(camp_interact != null and game.camp_player_position.x > camp_start.x and game.camera_offset.distance_to(camp_camera_start) > 0.1, "the expanded town camera follows direct character movement between building plots")
	var refuge_bounds: Rect2 = game._town_bounds_world()
	var fence_samples: Array[Vector2] = []
	for authored_wall: PackedVector2Array in game.active_camp_scene.wall_collision_polygons_world():
		if authored_wall.size() >= 3:
			var center := Vector2.ZERO
			for point: Vector2 in authored_wall:
				center += point
			fence_samples.append(center / authored_wall.size())
	var fence_samples_blocked: bool = true
	for fence_sample: Vector2 in fence_samples:
		fence_samples_blocked = fence_samples_blocked and game._point_hits_camp_fence(fence_sample)
	var gate_opening: Vector2 = game._camp_gate_position() + Vector2(0.0, 8.0)
	check(game._camp_position_blocked(refuge_bounds.position - Vector2(20.0, 0.0)) and fence_samples_blocked and not game._camp_position_blocked(gate_opening), "the separate physical palisade blocks its visible timber perimeter on every side while leaving only the southern gate open")
	var camp_touch := InputEventScreenTouch.new()
	camp_touch.index = 7
	camp_touch.position = Vector2(92.0, game.size.y * 0.58)
	camp_touch.pressed = true
	game._input(camp_touch)
	var camp_drag := InputEventScreenDrag.new()
	camp_drag.index = 7
	camp_drag.position = camp_touch.position + Vector2(38.0, -12.0)
	game._input(camp_drag)
	check(game.joystick_origin == camp_touch.position and game.joystick_vector.length() > 0.1, "town movement uses an invisible floating drag from the player's first touch")
	camp_touch.pressed = false
	game._input(camp_touch)
	game.joystick_vector = Vector2.ZERO
	game.camp_player_position = game._camp_interaction_position("gate")
	game._process_camp(0.0)
	camp_interact = game.find_child("CampInteractButton", true, false) as Button
	check(game.camp_interaction_target == "gate" and camp_interact.text.contains("CROSS"), "approaching the physical gate explains that crossing begins the expedition")
	game.screen = game.Screen.RESULTS
	game._show_camp()
	await process_frame
	var camp_crest: TextureRect = game.find_child("CampTitleCrest", true, false) as TextureRect
	var silver_icon: TextureRect = game.find_child("SilverIcon", true, false) as TextureRect
	var provisions_icon: TextureRect = game.find_child("ProvisionsIcon", true, false) as TextureRect
	var silver_value: Label = game.find_child("SilverValueLabel", true, false) as Label
	var provisions_value: Label = game.find_child("ProvisionsValueLabel", true, false) as Label
	var currency_bar: TextureRect = game.find_child("ResourceRail", true, false) as TextureRect
	var silver_cell: Control = game.find_child("SilverCell", true, false) as Control
	var provisions_cell: Control = game.find_child("ProvisionsCell", true, false) as Control
	var key_cell: Control = game.find_child("KeyCell", true, false) as Control
	var settings_cog: Button = game.find_child("SettingsCogButton", true, false) as Button
	var authored_hud: AshenHudLayout = HudLayoutScene.instantiate() as AshenHudLayout
	var authored_crest: TextureRect = authored_hud.get_node("SafeAreaTop/CampTitleCrest") as TextureRect
	var authored_rail: TextureRect = authored_hud.get_node("SafeAreaTop/ResourceRail") as TextureRect
	var authored_health: ProgressBar = authored_hud.get_node("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	var authored_silver_cell: Control = authored_hud.get_node("SafeAreaTop/ResourceRail/SilverCell") as Control
	var authored_provisions_cell: Control = authored_hud.get_node("SafeAreaTop/ResourceRail/ProvisionsCell") as Control
	var authored_key_cell: Control = authored_hud.get_node("SafeAreaTop/ResourceRail/KeyCell") as Control
	var authored_settings: Button = authored_hud.get_node("SafeAreaTop/SettingsCogButton") as Button
	check(camp_crest != null and camp_crest.texture != null and camp_crest.visible and is_equal_approx(camp_crest.modulate.a, 1.0) and camp_crest.position == authored_crest.position and camp_crest.size == authored_crest.size and camp_crest.scale == authored_crest.scale, "town uses the exact authored location crest node")
	check(silver_icon != null and silver_icon.texture != null and provisions_icon != null and provisions_icon.texture != null and silver_value != null and provisions_value != null and silver_value.text == str(int(game.save.profile.silver)) and provisions_value.text == str(int(game.save.profile.provisions)), "camp resources use illustrated icons with live numeric values")
	check(currency_bar != null and currency_bar.texture != null and currency_bar.position == authored_rail.position and currency_bar.size == authored_rail.size and currency_bar.scale == authored_rail.scale, "runtime uses the exact authored resource rail")
	check(game.health_bar.position == authored_health.position and silver_cell.position == authored_silver_cell.position and silver_cell.size == authored_silver_cell.size and provisions_cell.position == authored_provisions_cell.position and provisions_cell.size == authored_provisions_cell.size and key_cell.position == authored_key_cell.position and key_cell.size == authored_key_cell.size, "runtime HUD fields exactly match their visible scene nodes")
	var measured_safe_top: float = game.safe_area_top
	var safe_area_layouts_fit: bool = true
	for simulated_inset: float in [0.0, 34.0, 47.0, 59.0]:
		game.safe_area_top = simulated_inset
		game._show_camp()
		await process_frame
		var simulated_safe_bar: TextureRect = game.find_child("ResourceRail", true, false) as TextureRect
		var simulated_safe_band: ColorRect = game.find_child("SafeAreaTopBand", true, false) as ColorRect
		safe_area_layouts_fit = safe_area_layouts_fit and simulated_safe_bar != null and is_equal_approx(simulated_safe_bar.global_position.y, simulated_inset) and simulated_safe_band != null and is_equal_approx(simulated_safe_band.size.y, simulated_inset) and simulated_safe_band.color == Color.BLACK
	check(safe_area_layouts_fit, "notch-safe devices at 0, 34, 47 and 59 pixels keep the treasury rail below a black device band")
	game.safe_area_top = measured_safe_top
	game._show_camp()
	await process_frame
	settings_cog = game.find_child("SettingsCogButton", true, false) as Button
	check(settings_cog != null and settings_cog.icon != null and settings_cog.position == authored_settings.position and settings_cog.size == authored_settings.size and settings_cog.scale == authored_settings.scale and settings_cog.get_theme_stylebox("normal") is StyleBoxEmpty, "settings cog uses its exact authored position, size and scale")
	authored_hud.free()
	var veteran_touch := game.active_camp_scene.get_node_or_null("Structures/VeteransHallAnchor/Content/TouchArea") as Area2D
	check(veteran_touch != null and veteran_touch.get_node_or_null("CollisionPolygon2D") != null, "the Hall owns its real touch-selection shape")
	var live_gate_visual := game.active_camp_scene.get_node("Gate/MainVisual") as Sprite2D
	check(live_gate_visual.texture != null and live_gate_visual.texture.resource_path.begins_with("res://assets/runtime/") and game._camp_boundary_world().size() >= 4 and game.camp_structure_definitions.has("veterans_hall") and game.camp_structure_definitions.has("campfire") and game.active_camp_scene.get_node_or_null("Structures/CampfireAnchor/Content/TouchArea") != null, "camp builds its enclosure and interaction from authored physical scenes")
	var live_campfire := game.active_camp_scene.get_node("Structures/CampfireAnchor/Content") as Node2D
	var live_fire_base := live_campfire.get_node("Base") as Sprite2D
	var live_fire_flame := live_campfire.get_node("Flame") as AnimatedSprite2D
	var live_fire_smoke := live_campfire.get_node("Smoke") as AnimatedSprite2D
	var hall_visual := game.active_camp_scene.get_node("Structures/VeteransHallAnchor/Content/MainVisual") as Sprite2D
	check(hall_visual.texture.resource_path.begins_with("res://assets/runtime/") and live_gate_visual.texture.resource_path.begins_with("res://assets/runtime/") and live_fire_base.texture.resource_path.ends_with("campfire_base.png") and live_fire_flame.sprite_frames != null and live_fire_smoke.sprite_frames != null and not game.active_camp_scene.vegetation_entries().is_empty(), "the Refuge uses only canonical runtime assets through editable camp scenes")
	var authored_hall_info: Dictionary = game.active_camp_scene.structure_info("veterans_hall") if game.active_camp_scene != null else {}
	var authored_fire_info: Dictionary = game.active_camp_scene.structure_info("campfire") if game.active_camp_scene != null else {}
	var authored_camp_matches_runtime: bool = game.active_camp_scene != null and int(game.active_camp_scene.camp_tier) == 0 and game.active_camp_scene.camp_bounds_world().has_area() and not authored_hall_info.is_empty() and not authored_fire_info.is_empty()
	if authored_camp_matches_runtime:
		authored_camp_matches_runtime = game.camp_structure_definitions["veterans_hall"].anchor.is_equal_approx(Vector2(authored_hall_info.anchor)) and game.camp_structure_definitions["campfire"].anchor.is_equal_approx(Vector2(authored_fire_info.anchor))
	check(authored_camp_matches_runtime, "the editable camp tier scene is the source of truth for Refuge anchors and bounds")
	check(game.active_camp_scene.y_sort_enabled and game.active_camp_scene.get_node("ActorSpace").y_sort_enabled, "the authored camp scene sorts actors and structures from their ground anchors")
	var forest_entries: Array[Dictionary] = game.active_camp_scene.vegetation_entries()
	var no_south_trees: bool = true
	for forest_entry: Dictionary in forest_entries:
		no_south_trees = no_south_trees and Vector2(forest_entry.anchor).y < game._town_bounds_world().end.y
	check(no_south_trees, "the Refuge leaves the entire southern wall and gate approach free of trees")
	check(forest_entries.size() >= 3, "the authored Refuge keeps a deliberate irregular forest border")
	var flame_atlas := live_fire_flame.sprite_frames.get_frame_texture("burn", 0) as AtlasTexture
	var smoke_atlas := live_fire_smoke.sprite_frames.get_frame_texture("drift", 0) as AtlasTexture
	var fire_base_image: Image = live_fire_base.texture.get_image()
	var fire_image: Image = flame_atlas.atlas.get_image()
	var smoke_image: Image = smoke_atlas.atlas.get_image()
	var fire_frame_0: Image = fire_image.get_region(Rect2i(0, 0, 112, 96))
	var fire_frame_1: Image = fire_image.get_region(Rect2i(112, 0, 112, 96))
	var fire_frame_2: Image = fire_image.get_region(Rect2i(224, 0, 112, 96))
	var fire_frame_3: Image = fire_image.get_region(Rect2i(336, 0, 112, 96))
	var smoke_frame_0: Image = smoke_image.get_region(Rect2i(0, 0, 112, 96))
	var smoke_frame_1: Image = smoke_image.get_region(Rect2i(112, 0, 112, 96))
	var smoke_frame_2: Image = smoke_image.get_region(Rect2i(224, 0, 112, 96))
	var fire_ground_0: Image = fire_frame_0.get_region(Rect2i(0, 70, 112, 26))
	var fire_ground_1: Image = fire_frame_1.get_region(Rect2i(0, 70, 112, 26))
	var fire_ground_2: Image = fire_frame_2.get_region(Rect2i(0, 70, 112, 26))
	check(fire_base_image.get_size() == Vector2i(112, 96) and fire_image.get_size() == Vector2i(672, 96) and smoke_image.get_size() == Vector2i(672, 96), "the campfire loads separate base, flame-strip, and smoke-strip frame buckets")
	check(fire_frame_0.get_data() != fire_frame_1.get_data() and fire_frame_1.get_data() != fire_frame_2.get_data(), "the separated campfire flame changes between animation frames")
	check(smoke_frame_0.get_data() != smoke_frame_1.get_data() and smoke_frame_1.get_data() != smoke_frame_2.get_data(), "the subtle campfire smoke changes between animation frames")
	check(fire_frame_0.get_used_rect().end.y == fire_frame_1.get_used_rect().end.y and fire_frame_1.get_used_rect().end.y == fire_frame_2.get_used_rect().end.y and smoke_frame_0.get_used_rect().end.y <= 70 and smoke_frame_1.get_used_rect().end.y <= 70 and smoke_frame_2.get_used_rect().end.y <= 70, "the flame and smoke strips keep independent fixed frame buckets above the static base")
	var fire_ground_alpha_is_stable: bool = true
	for ground_pair: Array in [[fire_ground_0, fire_ground_1], [fire_ground_1, fire_ground_2]]:
		var ground_a: Image = ground_pair[0]
		var ground_b: Image = ground_pair[1]
		for pixel_y: int in ground_a.get_height():
			for pixel_x: int in ground_a.get_width():
				if absf(ground_a.get_pixel(pixel_x, pixel_y).a - ground_b.get_pixel(pixel_x, pixel_y).a) > 0.02:
					fire_ground_alpha_is_stable = false
	check(fire_ground_alpha_is_stable, "flame animation keeps the benches and lower stone ring perfectly still")
	var first_camp_props_are_unique: bool = true
	var seen_prop_names: Dictionary = {}
	for prop: Node in game.active_camp_scene.get_node("Props").get_children():
		if seen_prop_names.has(prop.name):
			first_camp_props_are_unique = false
		seen_prop_names[prop.name] = true
	check(first_camp_props_are_unique, "the first Refuge draws each approved prop exactly once")
	var spawn_samples_avoid_obstacles: bool = true
	for _spawn_sample: int in 80:
		var spawn_position: Vector2 = game._random_edge_position(16.0)
		if game._enemy_position_blocked(spawn_position, 16.0) or game._point_hits_refuge_forest(spawn_position, 16.0):
			spawn_samples_avoid_obstacles = false
			break
	check(spawn_samples_avoid_obstacles, "enemy spawn selection rejects forest canopies and every physical obstacle")
	check(game.terrain_layer != null and game.active_camp_scene != null and game.terrain_layer.chunks.size() > 0 and game.terrain_layer.get_node("BaseTiles") is TileMapLayer, "the visual foundation uses an authored TileSet and camp scene")
	var terrain_rebuilds_before_camera: int = game.terrain_layer.rebuild_count
	var camp_instance_before_camera: Node = game.active_camp_scene
	game.camera_offset += Vector2(0.37, 0.63)
	game._sync_visual_layers()
	game.world_root.position = -game.camera_offset.round()
	check(game.terrain_layer.rebuild_count == terrain_rebuilds_before_camera and game.active_camp_scene == camp_instance_before_camera and game.world_root.position == -game.camera_offset.round(), "camera movement pixel-snaps the retained world without rebuilding terrain or the authored camp")
	var town_bounds: Rect2 = game._town_bounds_world()
	check(game._town_tile_kind(town_bounds.position) == "cobble" and game._town_tile_kind(town_bounds.get_center() - Vector2(16.0, 16.0)) == "cobble" and game._town_tile_kind(town_bounds.end - Vector2(32.0, 32.0)) == "cobble", "the entire safe-town interior is paved with cobblestone")
	var refuge_decor: Array[Dictionary] = game._visible_camp_decor()
	var decor_has_art: bool = true
	var decor_has_footprints: bool = true
	for prop: Node in game.active_camp_scene.get_node("Props").get_children():
		var prop_visual := prop.get_node_or_null("MainVisual") as Sprite2D
		decor_has_art = decor_has_art and prop_visual != null and prop_visual.texture != null and prop_visual.texture.resource_path.begins_with("res://assets/runtime/")
	for decor_entry: Dictionary in refuge_decor:
		decor_has_footprints = decor_has_footprints and game._camp_decor_footprint(decor_entry).has_area()
	check(not refuge_decor.is_empty() and decor_has_art and decor_has_footprints and not game.has_method("_draw_camp_villager"), "authored physical dressing uses real art and collision without a raider placeholder masquerading as a camp resident")
	var gate_left_post := game.active_camp_scene.get_node("Gate/StaticBody2D/LeftPost") as CollisionPolygon2D
	var gate_right_post := game.active_camp_scene.get_node("Gate/StaticBody2D/RightPost") as CollisionPolygon2D
	check(game.active_camp_scene.get_node("BackWall").get_child_count() > 0 and game.active_camp_scene.get_node("FrontWall").get_child_count() > 0, "authored palisade scenes provide complete back and front wall runs")
	check(gate_left_post.polygon.size() >= 4 and gate_right_post.polygon.size() >= 4 and gate_left_post.polygon[1].x < gate_right_post.polygon[0].x, "the authored gate owns two blocking posts and a passable painted opening")
	var hall_anchor: Vector2 = (game.camp_structure_definitions["veterans_hall"] as StructureDefinition).anchor
	var fire_anchor: Vector2 = (game.camp_structure_definitions["campfire"] as StructureDefinition).anchor
	check(town_bounds.has_point(hall_anchor) and town_bounds.has_point(fire_anchor) and hall_anchor.y < fire_anchor.y, "the first-tier Hall and campfire use valid authored anchors inside the live refuge bounds")
	game._show_hall_detail()
	await process_frame
	check(game.find_child("HallOverlay", true, false) != null and game.find_child("HallUpgradeButton", true, false) != null and game.find_child("HallChooseBuildingButton", true, false) == null, "the initial full refuge asks for a Hall expansion before construction")
	var old_bounds: Rect2 = game._town_bounds_world()
	game._buy_hall_upgrade()
	await process_frame
	var authored_outpost: bool = game.active_camp_scene != null and int(game.active_camp_scene.camp_tier) == 1 and not game.active_camp_scene.structure_info("veterans_hall").is_empty() and not game.active_camp_scene.plot_info("plot_1").is_empty() and game.active_camp_scene.get_node("BackWall").get_child_count() > 0
	check(game._town_level() == 1 and game._town_capacity() == 3 and game._town_definition().name == "OUTPOST" and game._town_definition().bounds.size == Vector2(380.0, 530.0) and game._town_bounds_world().size.x > old_bounds.size.x and game._town_definition().bounds.size.x < 400.0 and game.active_camp_scene.revealed_plot_ids() == ["plot_1"] and authored_outpost, "the first Hall upgrade instantiates the complete authored Outpost scene")
	check(game._visible_camp_decor().size() == 6, "the growing hamlet gains military dressing without moving decoration into its building plot")
	game.camp_player_position = game._plot_anchor("plot_1") + Vector2(0.0, 38.0)
	check(game._nearest_camp_interaction() == "plot_1" and game._camp_interaction_text("plot_1") == "PLAN NEW BUILDING", "walking to the revealed foundation enables its construction choice")
	game._construct_building("armory", "plot_1")
	await process_frame
	check(game._is_constructed("armory") and game._constructed_count() == 3 and String(game.save.profile.building_plots.plot_1) == "armory" and game.active_camp_scene.get_node_or_null("BuildingSlots/Slot01/Content/TouchArea") != null, "choosing a service permanently assigns it to the approached authored slot")
	game.save.profile.hall_level = 4
	game.save.profile.constructed_buildings = ["veterans_hall", "campfire", "armory", "blacksmith", "quartermaster", "training"]
	game.save.profile.building_plots = {"plot_1": "armory", "plot_2": "quartermaster", "plot_3": "blacksmith", "plot_4": "training"}
	game._show_camp()
	await process_frame
	check(game._visible_camp_decor().size() >= refuge_decor.size(), "a restored town retains the complete authored decoration set")
	var armory_zero := (load("res://scenes/world/structures/armory_tier_0.tscn") as PackedScene).instantiate()
	var armory_one := (load("res://scenes/world/structures/armory_tier_1.tscn") as PackedScene).instantiate()
	check((armory_zero.get_node("MainVisual") as Sprite2D).texture != (armory_one.get_node("MainVisual") as Sprite2D).texture, "camp restoration uses distinct art for consecutive building tiers")
	armory_zero.free()
	armory_one.free()
	var armory_touch: Rect2 = game._camp_hit_rect_world("armory")
	var blacksmith_touch: Rect2 = game._camp_hit_rect_world("blacksmith")
	var quartermaster_touch: Rect2 = game._camp_hit_rect_world("quartermaster")
	var training_touch: Rect2 = game._camp_hit_rect_world("training")
	check(armory_touch.has_area() and blacksmith_touch.has_area() and quartermaster_touch.has_area() and training_touch.has_area() and not blacksmith_touch.intersects(training_touch) and not armory_touch.intersects(quartermaster_touch) and not armory_touch.intersects(blacksmith_touch) and not quartermaster_touch.intersects(training_touch), "all four restoration buildings have separate non-overlapping authored touch plots")
	var campfire_touch: Rect2 = game._camp_hit_rect_world("campfire")
	check(campfire_touch.has_area() and not training_touch.intersects(campfire_touch), "training and campfire keep separate authored touch regions")
	var authored_hall_anchor := game.active_camp_scene.get_node("Structures/VeteransHallAnchor") as Node2D
	var authored_fire_anchor := game.active_camp_scene.get_node("Structures/CampfireAnchor") as Node2D
	check(game._town_bounds_world().has_point(game.world_content_origin + authored_hall_anchor.position) and game._town_bounds_world().has_point(game.world_content_origin + authored_fire_anchor.position) and authored_hall_anchor.position.y < authored_fire_anchor.position.y, "visible structure bases use valid authored camp anchors")
	var armory_content := game.active_camp_scene.get_node_or_null("BuildingSlots/Slot01/Content") as Node2D
	var armory_outline := armory_content.get_node_or_null("Outline") as Sprite2D if armory_content != null else null
	check(armory_outline != null and armory_outline.texture != null and armory_content.get_node_or_null("TouchArea/CollisionPolygon2D") != null, "building interaction uses the authored sprite outline and touch polygon without a rectangular pressed panel")
	var camp_header: Control = game.find_child("LiveHud", true, false) as Control
	var current_hall_touch := game.active_camp_scene.get_node_or_null("Structures/VeteransHallAnchor/Content/TouchArea") as Area2D
	check(camp_header != null and current_hall_touch != null and camp_header.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the live authored HUD cannot block world-space building interaction")
	check(game.active_camp_scene.get_node_or_null("BuildingSlots/Slot04/Content/TouchArea/CollisionPolygon2D") != null, "camp building interaction remains inside its reusable authored structure scene")
	game.save.profile.armory_level = 0
	game.save.profile.silver = 100
	game.save.profile.provisions = 100
	game._show_building_detail("armory")
	await process_frame
	check(game.find_child("CampBuildingOverlay", true, false) != null and game.find_child("BuildingUpgradeButton", true, false) != null, "tapping a camp building opens its restoration and related menu")
	var building_effect: Label = game.find_child("BuildingEffectLabel", true, false) as Label
	check(building_effect != null and building_effect.text.contains("AXE ACCESS"), "camp restoration detail shows the exact next-tier benefit")
	game._show_camp()
	# The smoke run may be launched against a developer's existing local save;
	# make the roster assertion independent of whichever hero was last selected.
	Roster.set_active_hero(game.save.profile, "warrior")
	game._sync_active_hero_fields()
	game._show_camp_expeditions()
	await process_frame
	check(game.find_child("CampExpeditionOverlay", true, false) != null and game.find_child("RosterHero_warrior", true, false) != null and game.find_child("RosterHero_rogue", true, false) != null, "the veterans' hall opens the four-recruit roster and idle assignments")
	game._set_hero_assignment("hunter", "patrol")
	check(String(Roster.hero_by_id(game.save.profile.heroes, "hunter").assignment) == "patrol", "an unselected recruit can be assigned to an offline job")
	game._make_roster_hero_active("rogue")
	check(String(game.save.profile.active_hero_id) == "rogue" and String(game.save.profile.starting_class) == "rogue", "selecting a roster hero updates the persistent field character")
	var active_hero: Dictionary = game._active_hero()
	active_hero.level = 2
	game._show_class_tree()
	await process_frame
	check(game.find_child("ClassNode_light_foot", true, false) != null, "each hero exposes a compact permanent class tree")
	game._show_camp()
	game.save.profile.armory_level = 3
	game.save.profile.blacksmith_level = 3
	game.save.profile.training_level = 5
	game.save.profile.quartermaster_level = 3
	for progression_id: String in Content.PROGRESSION_NODES:
		game.save.profile.skill_tree[progression_id] = int(Content.PROGRESSION_NODES[progression_id].max_rank)
	game._show_camp()
	await process_frame
	var final_building_touch: Rect2 = game._camp_hit_rect_world("quartermaster")
	check(final_building_touch.has_area() and game.find_child("StartingWeaponStats", true, false) == null, "fully restored camp keeps an authored quartermaster touch shape without a redundant weapon selector")
	game._show_skill_tree()
	await process_frame
	var training_screen: Control = game.find_child("TrainingGroundsScreen", true, false)
	var training_canvas: Control = game.find_child("TrainingTreeCanvas", true, false)
	var crest_node: Button = game.find_child("TrainingNode_company_crest", true, false) as Button
	var vanguard_branch: Button = game.find_child("BranchVanguard", true, false) as Button
	check(training_screen != null and training_canvas != null and crest_node != null, "Training Grounds opens the real continuous authored tree")
	check(training_screen != null and training_screen.get_global_rect().end.x <= game.size.x + 1.0, "Training Grounds stays inside the phone viewport")
	check(crest_node != null and crest_node.size.x >= 120.0, "Training Grounds nodes keep a readable phone width")
	check(vanguard_branch != null and vanguard_branch.get_global_rect().end.x <= game.size.x + 1.0, "school shortcut buttons remain visible")
	var state_marker: Label = crest_node.get_node_or_null("StateMarker") as Label if crest_node != null else null
	check(state_marker != null and not crest_node.text.contains("UNLOCKED") and not crest_node.text.contains("LEARNED"), "purchased Training nodes communicate state without redundant labels")
	var locked_training_node: Button = game.find_child("TrainingNode_dual_doctrine", true, false) as Button
	check(locked_training_node != null and locked_training_node.self_modulate != crest_node.self_modulate, "Training node visuals distinguish purchased and tier-locked states")
	game.save.profile.inventory = [Rules.generate_equipment(7351, true, 0.0, 999)]
	game._show_inventory("", "999")
	await process_frame
	var inventory_panel: Control = game.find_child("InventoryPanel", true, false)
	var inventory_item: Control = game.find_child("InventoryItem_999", true, false)
	check(inventory_panel != null and inventory_panel.get_global_rect().end.y <= game.size.y + 1.0, "inventory fits inside the phone viewport without scrolling")
	check(inventory_item != null and game.find_child("EquipmentDetail", true, false) != null, "inventory shows recovered equipment and its modifiers")
	game._equip_item("999")
	var test_item: Dictionary = game._find_inventory_item("999")
	check(not test_item.is_empty() and String(game.save.profile.equipped[String(test_item.slot)]) == "999", "equipment can be assigned to its persistent slot")
	var tested_stat: String = String(test_item.modifiers[0].stat)
	var raw_positive_stat: float = 0.0
	for modifier_value: Variant in test_item.modifiers:
		var modifier: Dictionary = modifier_value
		if String(modifier.stat) == tested_stat and float(modifier.amount) > 0.0:
			raw_positive_stat += float(modifier.amount)
	check(raw_positive_stat <= 0.0 or is_equal_approx(game._equipment_total(tested_stat), raw_positive_stat * 1.15), "tier-three blacksmith strengthens positive equipment statistics by 15 percent")
	var display_font := load("res://assets/runtime/fonts/PixelifySans.ttf") as Font
	var body_font := load("res://assets/runtime/fonts/AtkinsonHyperlegible-Regular.otf") as Font
	check(display_font != null and body_font != null and display_font != body_font, "ornamental headings and readable body copy use separate canonical fonts")
	var settings_scene := load("res://scenes/ui/screens/settings_screen.tscn") as PackedScene
	check(settings_scene != null, "the custom company-ledger interface is an authored runtime scene")
	game._show_camp()
	game._show_weapon_picker()
	await process_frame
	var arsenal_screen: Control = game.find_child("ArsenalScreen", true, false)
	var sword_choice: Button = game.find_child("WeaponOption_sword", true, false) as Button
	var sword_stats: Label = sword_choice.get_node_or_null("Stats") as Label if sword_choice != null else null
	var arsenal_back: Button = game.find_child("BackButton", true, false) as Button
	check(arsenal_screen != null and sword_choice != null, "Expedition Arsenal opens from the camp flow")
	check(sword_stats != null and sword_stats.text.contains("POWER") and sword_stats.text.contains("INTERVAL"), "Arsenal choices show exact power and attack interval")
	check(sword_stats != null and sword_stats.get_theme_font_size("font_size") < (sword_choice.get_node("Title") as Label).get_theme_font_size("font_size"), "Arsenal statistics use smaller contrasting typography")
	check(arsenal_back != null and arsenal_back.get_global_rect().end.y <= game.size.y + 1.0, "the complete Expedition Arsenal fits inside the phone viewport")
	game.save.settings.gate_confirmations = true
	game._show_settings()
	await process_frame
	var settings_screen: AshenSettingsScreen = game.find_child("SettingsScreen", true, false) as AshenSettingsScreen
	var settings_panel: PanelContainer = settings_screen.get_node_or_null("AshenModal/SafeMargin/Frame") as PanelContainer if settings_screen != null else null
	var settings_content: Control = settings_screen.get_node_or_null("AshenModal/SafeMargin/Frame/ContentMargin/Content") as Control if settings_screen != null else null
	var settings_scroll: ScrollContainer = settings_screen.get_node_or_null("AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll") as ScrollContainer if settings_screen != null else null
	check(settings_screen != null and settings_panel != null and settings_panel.visible and settings_panel.size.x > 0.0 and settings_panel.size.y > 0.0 and settings_content != null and settings_content.size.x > 0.0 and settings_content.size.y > 0.0 and settings_scroll != null, "settings menu renders the authored safe modal and scrollable maintenance content")
	check(game.find_child("ReloadAppButton", true, false) != null, "settings exposes a PWA reload control")
	var reset_save_button: Button = game.find_child("ResetSaveButton", true, false) as Button
	check(reset_save_button != null, "settings exposes a guarded game-progress reset")
	reset_save_button.emit_signal("pressed")
	await process_frame
	var reset_overlay: Control = game.find_child("ResetSaveOverlay", true, false) as Control
	var cancel_reset: Button = reset_overlay.find_child("CancelButton", true, false) as Button if reset_overlay != null else null
	check(reset_overlay != null and reset_overlay.find_child("ConfirmButton", true, false) != null and cancel_reset != null, "reset requires an explicit destructive confirmation")
	cancel_reset.emit_signal("pressed")
	await process_frame
	check(game.find_child("ResetSaveOverlay", true, false) == null and int(game.save.profile.hall_level) == 4, "cancelling reset leaves progression untouched")
	var gate_confirmation_row: Control = game.find_child("GateConfirmationsRow", true, false) as Control
	var gate_confirmation_toggle: TextureButton = gate_confirmation_row.get_node_or_null("Toggle") as TextureButton if gate_confirmation_row != null else null
	check(gate_confirmation_row != null and gate_confirmation_toggle != null and gate_confirmation_toggle.button_pressed, "settings exposes an enabled-by-default toggle for both gate questions")
	game._show_camp()
	game.save.active_run = {}
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	var departure_overlay: Control = game.find_child("GateConfirmationOverlay", true, false) as Control
	var departure_panel: Control = departure_overlay.find_child("Panel", true, false) as Control if departure_overlay != null else null
	var departure_no: Button = departure_overlay.find_child("CancelButton", true, false) as Button if departure_overlay != null else null
	var departure_dim: ColorRect = departure_overlay.find_child("WorldDim", true, false) as ColorRect if departure_overlay != null else null
	check(game.screen == game.Screen.CAMP and departure_overlay != null and departure_panel != null and departure_panel.size.x < game.size.x and departure_dim != null and departure_dim.color.a > 0.6, "crossing the town gate dims the world behind a compact ready-for-battle confirmation")
	departure_no.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.CAMP and game.find_child("GateConfirmationOverlay", true, false) == null and game.camp_player_position.y < game._camp_gate_position().y, "declining battle returns the hero safely inside camp")
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	var departure_yes: Button = game.find_child("ConfirmButton", true, false) as Button
	departure_yes.emit_signal("pressed")
	await process_frame
	var departure_arsenal: Control = game.find_child("ArsenalScreen", true, false)
	var departure_start: Button = game.find_child("StartButton", true, false) as Button
	check(departure_arsenal != null and departure_start != null, "confirming departure opens the prepared Expedition Arsenal")
	departure_start.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.RUN and game.player_position.y <= game._camp_gate_position().y + 1.1 and game.run_camera_transition < 0.1 and game.ui_root.modulate.a < 1.0, "confirming battle starts exactly beyond the painted gate with a softly introduced HUD")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var immediate_return_no: Button = game.find_child("CancelButton", true, false) as Button
	check(immediate_return_no != null, "turning around at the gate immediately offers the opposite transition without a clearance radius")
	immediate_return_no.emit_signal("pressed")
	await process_frame
	game.player_position = Vector2(game._camp_gate_position().x, game._camp_gate_position().y - 120.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	check(game.screen == game.Screen.RUN and game.find_child("GateConfirmationOverlay", true, false) == null, "walking north through the camp cannot trigger extraction away from the southern gate")
	game._process_run(0.5)
	check(game.run_camera_transition > 0.0 and game.run_camera_transition < 1.0, "the camera blends from town framing into expedition framing over time")
	game._spawn_enemy("raider", false)
	var preserved_enemy = game.enemies.back()
	var preserved_enemy_count: int = game.enemies.size()
	var preserved_elapsed: float = game.run_elapsed
	game.run_exploration_silver = 7
	var silver_before_return: int = int(game.save.profile.silver)
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var return_overlay: Control = game.find_child("GateConfirmationOverlay", true, false) as Control
	var return_no: Button = return_overlay.find_child("CancelButton", true, false) as Button if return_overlay != null else null
	check(game.screen == game.Screen.RUN and game.run_paused and return_overlay != null and int(game.save.profile.silver) == silver_before_return, "approaching camp pauses combat behind a compact finish-run confirmation without banking early")
	return_no.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.RUN and not game.run_paused and game.enemies.size() == preserved_enemy_count and game.enemies.has(preserved_enemy) and absf(game.run_elapsed - preserved_elapsed) < 0.2, "declining extraction preserves every live enemy and resumes the same run")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var return_yes: Button = game.find_child("ConfirmButton", true, false) as Button
	var return_camera: Vector2 = game.camera_offset
	return_yes.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.CAMP and bool(game.result_data.get("extracted", false)) and bool(game.result_data.get("banked", false)) and int(game.save.profile.silver) >= silver_before_return + 7, "confirming extraction banks the run and swaps directly to the camp HUD")
	check(game.camera_offset.distance_to(return_camera) < 6.0 and game.camp_uses_field_camera, "entering camp preserves the continuous world camera instead of recentering it")
	# Returning to an installed PWA can preserve this continuous arrival frame in
	# memory.  Reopening must normalize it back to the full interactive camp.
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	check(game.screen == game.Screen.CAMP and not game.camp_uses_field_camera and game.find_child("CampInteractButton", true, false) != null and not game._camp_position_blocked(game.camp_player_position), "focus-in recenters a continuous camp arrival and restores camp interaction")
	check(game.camp_wanderers.has(preserved_enemy) and game.enemies.is_empty(), "nearby enemies de-aggro into persistent camp wanderers instead of disappearing")
	# The gate itself is a hostile-free refuge while the camp is active.  A
	# retained pursuer is pushed beyond its boundary but remains an ambient
	# wanderer, so starting another expedition cannot inherit a point-blank hit.
	preserved_enemy.position = game._camp_gate_safe_center()
	preserved_enemy.dispersing = false
	game._process_camp(0.0)
	check(game.camp_wanderers.has(preserved_enemy) and not game._camp_gate_safe_zone_contains(preserved_enemy.position, preserved_enemy.radius) and preserved_enemy.dispersing, "camp gate safe zone disperses retained enemies without despawning them")
	# Exercise dispersal in the unobstructed gate lane. The live extraction path
	# may leave this enemy beside either gate post depending on the generated run,
	# which made a one-frame movement assertion platform-dependent.
	preserved_enemy.position = game._camp_gate_position() + Vector2(0.0, 64.0)
	preserved_enemy.wander_direction = Vector2.DOWN
	preserved_enemy.wander_timer = 2.0
	preserved_enemy.dispersing = true
	var dispersal_origin: Vector2 = preserved_enemy.position
	game._process_camp(0.5)
	check(preserved_enemy.dispersing and preserved_enemy.position.y > dispersal_origin.y and game.camp_wanderers.size() >= game.MIN_CAMP_WANDERERS, "former pursuers disperse gradually while a small hostile presence keeps wandering outside camp")
	game.save.settings.gate_confirmations = false
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	check(game.screen == game.Screen.CAMP and game.find_child("GateConfirmationOverlay", true, false) == null and game.find_child("ArsenalScreen", true, false) != null, "disabled gate questions proceed directly to Arsenal preparation")
	var no_prompt_start: Button = game.find_child("StartButton", true, false) as Button
	no_prompt_start.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.RUN, "a valid prepared Arsenal begins battle without another gate question")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	check(game.screen == game.Screen.CAMP and game.find_child("GateConfirmationOverlay", true, false) == null, "disabled gate questions finish and bank the run immediately on return")
	game.save.settings.gate_confirmations = true
	game._start_new_run("spear")
	var silver_before_defeat: int = int(game.save.profile.silver)
	game.run_exploration_silver = 99
	game.run_loot.clear()
	game.run_loot.append({"uid": "unsecured_test", "base_id": "iron_kettle", "name": "Test Helm", "slot": "head", "rarity": "common", "modifiers": []})
	game._finish_run(false)
	check(int(game.save.profile.silver) == silver_before_defeat and int(game.result_data.get("lost_loot", 0)) == 1 and not bool(game.result_data.get("banked", true)), "defeat preserves progression but discards unsecured run currency and equipment")
	print("Ashen Company combat smoke: %d ms, %d failures" % [elapsed_ms, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func opaque_bounds(texture: Texture2D) -> Rect2i:
	var image: Image = texture.get_image()
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
