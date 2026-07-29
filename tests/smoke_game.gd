extends SceneTree

const Saves = preload("res://src/save_service.gd")
const Rules = preload("res://src/rules.gd")
const Content = preload("res://src/content.gd")
const Roster = preload("res://src/services/roster_service.gd")

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
	var region_rect := Rect2(game.region_origin, Vector2(region_size) * 32.0)
	var cardinal_openings_clear: bool = not game._run_position_blocked(Vector2(region_rect.get_center().x, region_rect.position.y + 16.0))
	cardinal_openings_clear = cardinal_openings_clear and not game._run_position_blocked(Vector2(region_rect.end.x - 16.0, region_rect.get_center().y))
	cardinal_openings_clear = cardinal_openings_clear and not game._run_position_blocked(Vector2(region_rect.position.x + 16.0, region_rect.get_center().y))
	cardinal_openings_clear = cardinal_openings_clear and not game._run_position_blocked(Vector2(region_rect.get_center().x, region_rect.end.y - 16.0))
	check(cardinal_openings_clear, "Blackthorn Moor keeps passable north, east, west and south frontier openings")
	game.run_discoveries = 1
	check(game.actor_textures.size() == 18 and game.foundation_hero_textures.size() == 16, "the unified enemy set and all four-direction hero sprites load")
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
	var hero_canvas_consistent: bool = true
	for hero_texture: Texture2D in game.foundation_hero_textures.values():
		hero_canvas_consistent = hero_canvas_consistent and hero_texture.get_size() == Vector2(56.0, 64.0)
	var warrior_down_bounds: Rect2i = opaque_bounds(game.foundation_hero_textures["warrior_down"])
	var warrior_left_bounds: Rect2i = opaque_bounds(game.foundation_hero_textures["warrior_left"])
	var warrior_right_bounds: Rect2i = opaque_bounds(game.foundation_hero_textures["warrior_right"])
	var warrior_up_bounds: Rect2i = opaque_bounds(game.foundation_hero_textures["warrior_up"])
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
	game._update_world_camera(game.player_position, false, true)
	var visible_map: Rect2 = game._visible_world_rect()
	game.player_position = visible_map.get_center()
	archer.position = Vector2(visible_map.end.x + 28.0, visible_map.get_center().y)
	archer.attack_cooldown = 0.0
	var off_map_x: float = archer.position.x
	var arrows_before: int = game.projectiles.size()
	game._update_enemies(0.1)
	check(game.projectiles.size() == arrows_before and archer.position.x < off_map_x, "archers enter the map before they can fire")
	archer.position = game.player_position + Vector2(100.0, 0.0)
	archer.attack_cooldown = 0.0
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
	var contract_overlay: Control = game.ui_root.get_node_or_null("ContractOverlay")
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
	var upgrade_overlay: Control = game.ui_root.get_node_or_null("UpgradeOverlay")
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
	check(game.ui_root.get_node_or_null("CampPanel") != null and game.ui_root.find_child("CampScroll", true, false) == null, "camp menu uses a fixed responsive panel")
	check(game._town_capacity() == 2 and game._constructed_count() == 2 and game._town_definition().bounds.size == Vector2(280.0, 285.0) and game.ui_root.find_child("CampBuilding_armory", true, false) == null and game.ui_root.find_child("CampPlot_plot_1", true, false) == null, "a fresh compact refuge uses the deliberately cramped Hall-and-fire footprint")
	check(not game._camp_position_blocked(game.camp_player_position) and game.camp_player_position.distance_to(game._camp_interaction_position("campfire")) > 28.0, "the hero spawns clear of the campfire footprint")
	var camp_interact: Button = game.ui_root.find_child("CampInteractButton", true, false) as Button
	var camp_start: Vector2 = game._safe_camp_spawn_position()
	game.camp_player_position = camp_start
	var camp_camera_start: Vector2 = game.camera_offset
	game.joystick_vector = Vector2.RIGHT
	game._process_camp(0.1)
	check(camp_interact != null and game.camp_player_position.x > camp_start.x and game.camera_offset.x > camp_camera_start.x, "the expanded town camera follows direct character movement between building plots")
	var refuge_bounds: Rect2 = game._town_bounds_world()
	var fence_samples: Array[Vector2] = [Vector2(refuge_bounds.position.x, refuge_bounds.get_center().y), Vector2(refuge_bounds.get_center().x, refuge_bounds.position.y), Vector2(refuge_bounds.end.x, refuge_bounds.get_center().y), Vector2(refuge_bounds.position.x + 40.0, refuge_bounds.end.y)]
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
	check(game.camp_interaction_target == "gate" and camp_interact.text.contains("CROSS"), "approaching the physical gate explains that crossing begins the expedition")
	game.screen = game.Screen.RESULTS
	game._show_camp()
	await process_frame
	var camp_crest: TextureRect = game.ui_root.find_child("CampTitleCrest", true, false) as TextureRect
	var silver_icon: TextureRect = game.ui_root.find_child("SilverIcon", true, false) as TextureRect
	var provisions_icon: TextureRect = game.ui_root.find_child("ProvisionsIcon", true, false) as TextureRect
	var silver_value: Label = game.ui_root.find_child("SilverValueLabel", true, false) as Label
	var provisions_value: Label = game.ui_root.find_child("ProvisionsValueLabel", true, false) as Label
	var currency_bar: TextureRect = game.ui_root.find_child("CurrencyBarBackground", true, false) as TextureRect
	var settings_cog: Button = game.ui_root.find_child("SettingsCogButton", true, false) as Button
	var expected_crest_width: float = minf(380.0, game.size.x - 10.0)
	var expected_crest_height: float = expected_crest_width * float(camp_crest.texture.get_height()) / float(camp_crest.texture.get_width()) if camp_crest != null and camp_crest.texture != null else 0.0
	check(camp_crest != null and camp_crest.texture != null and camp_crest.visible and is_equal_approx(camp_crest.modulate.a, 1.0) and is_equal_approx(camp_crest.position.x, (game.size.x - expected_crest_width) * 0.5) and is_equal_approx(camp_crest.position.y, 48.0) and is_equal_approx(camp_crest.size.x, expected_crest_width) and is_equal_approx(camp_crest.size.y, expected_crest_height), "entering town presents its 380px location crest below the permanent resource rail")
	check(silver_icon != null and silver_icon.texture != null and provisions_icon != null and provisions_icon.texture != null and silver_value != null and provisions_value != null and silver_value.text == str(int(game.save.profile.silver)) and provisions_value.text == str(int(game.save.profile.provisions)), "camp resources use illustrated icons with live numeric values")
	check(currency_bar != null and currency_bar.texture != null and currency_bar.position == Vector2.ZERO and is_equal_approx(currency_bar.size.y, 48.0) and currency_bar.size.x == game.size.x, "resources sit above everything in a taller custom company treasury rail")
	var measured_safe_top: float = game.safe_area_top
	game.safe_area_top = 34.0
	game._show_camp()
	await process_frame
	var simulated_safe_bar: TextureRect = game.ui_root.find_child("CurrencyBarBackground", true, false) as TextureRect
	var simulated_safe_band: ColorRect = game.ui_root.find_child("SafeAreaTopBand", true, false) as ColorRect
	check(simulated_safe_bar != null and is_equal_approx(simulated_safe_bar.global_position.y, 34.0) and simulated_safe_band != null and is_equal_approx(simulated_safe_band.size.y, 34.0) and simulated_safe_band.color == Color.BLACK, "a notch-safe device gets a black top band and moves the resource rail below it")
	game.safe_area_top = measured_safe_top
	game._show_camp()
	await process_frame
	settings_cog = game.ui_root.find_child("SettingsCogButton", true, false) as Button
	check(settings_cog != null and settings_cog.icon != null and is_equal_approx(settings_cog.position.x, game.size.x - 58.0) and is_equal_approx(settings_cog.position.y, game.size.y - 58.0) and settings_cog.get_theme_stylebox("normal") is StyleBoxEmpty, "settings uses a standalone bottom-right cog without a button rectangle")
	var veteran_tent: Button = game.ui_root.find_child("VeteranTentButton", true, false) as Button
	var veteran_caption: Label = veteran_tent.find_child("CampLocationCaption", true, false) as Label if veteran_tent != null else null
	check(veteran_caption != null and (veteran_caption.text.contains("READY") or veteran_caption.text.contains("BUILT")), "the Hall reports pending work or current building capacity")
	check(game.foundation_terrain_atlas != null and game.foundation_wall_textures.size() == 2 and game.foundation_wall_textures.has("wall_pole") and (game.foundation_wall_textures["wall_pole"] as Texture2D).get_size() == Vector2(16.0, 64.0) and game._camp_boundary_world().size() == 6 and game.camp_structure_definitions.size() == 6 and game.camp_building_textures.get("veterans_hall", []).size() == 5 and game.camp_building_textures.get("armory", []).size() == 4 and game.camp_building_textures.get("blacksmith", []).size() == 4 and game.camp_building_textures.get("training", []).size() == 6 and game.ui_root.find_child("CampfireButton", true, false) != null, "camp builds every wall direction from one native pole sprite and the physical gate")
	var town_bounds: Rect2 = game._town_bounds_world()
	check(game._town_tile_kind(town_bounds.position) == "cobble" and game._town_tile_kind(town_bounds.get_center() - Vector2(16.0, 16.0)) == "cobble" and game._town_tile_kind(town_bounds.end - Vector2(32.0, 32.0)) == "cobble", "the entire safe-town interior is paved with cobblestone")
	var refuge_decor: Array[Dictionary] = game._visible_camp_decor()
	var decor_inside_refuge: bool = true
	for decor_entry: Dictionary in refuge_decor:
		decor_inside_refuge = decor_inside_refuge and town_bounds.has_point(Vector2(decor_entry.anchor))
	var decor_is_physical: bool = not refuge_decor.is_empty() and game._camp_position_blocked(Vector2(refuge_decor[0].anchor))
	var center_lane_clear: bool = not game._point_hits_camp_decor(Vector2(town_bounds.get_center().x, town_bounds.get_center().y))
	check(game.camp_decor_textures.size() == 8 and refuge_decor.size() == 2 and decor_inside_refuge and decor_is_physical and center_lane_clear and not game.has_method("_draw_camp_villager"), "essential physical dressing stays at the perimeter and no raider placeholder masquerades as a camp resident")
	var right_side_poles: Array[Vector2] = game._vertical_wall_pole_anchors(town_bounds.end.x, town_bounds.position.y + 32.0, town_bounds.end.y + 32.0)
	var front_right_poles: Array[Vector2] = game._horizontal_wall_pole_anchors(game._camp_gate_position().x + 44.0, town_bounds.end.x, town_bounds.end.y + 32.0)
	var gate_draw_rect: Rect2 = game._town_gate_draw_rect(game._camp_gate_position())
	check(not right_side_poles.is_empty() and not front_right_poles.is_empty() and right_side_poles[-1].is_equal_approx(front_right_poles[-1]), "side and front palisades share one complete corner pole")
	check(is_equal_approx(gate_draw_rect.end.y, front_right_poles[0].y), "single-pole front wall and gate share their outer edge")
	var hall_anchor: Vector2 = (game.camp_structure_definitions["veterans_hall"] as StructureDefinition).anchor
	var fire_anchor: Vector2 = (game.camp_structure_definitions["campfire"] as StructureDefinition).anchor
	check(is_equal_approx(hall_anchor.x, town_bounds.get_center().x) and is_equal_approx(fire_anchor.x, town_bounds.get_center().x) and is_equal_approx(hall_anchor.y, town_bounds.position.y + 100.0) and is_equal_approx(fire_anchor.y, town_bounds.end.y - 85.0), "the first-tier Hall and campfire derive compact anchors from the live refuge bounds")
	game._show_hall_detail()
	await process_frame
	check(game.ui_root.get_node_or_null("HallOverlay") != null and game.ui_root.find_child("HallUpgradeButton", true, false) != null and game.ui_root.find_child("HallChooseBuildingButton", true, false) == null, "the initial full refuge asks for a Hall expansion before construction")
	var old_bounds: Rect2 = game._town_bounds_world()
	game._buy_hall_upgrade()
	await process_frame
	check(game._town_level() == 1 and game._town_capacity() == 3 and game._town_definition().name == "OUTPOST" and game._town_definition().bounds.size == Vector2(350.0, 355.0) and game._town_bounds_world().size.x > old_bounds.size.x and game._town_definition().bounds.size.x < 400.0 and game.ui_root.find_child("CampPlot_plot_1", true, false) != null and game.ui_root.find_child("CampPlot_plot_2", true, false) == null, "the first Hall upgrade uses a gradual outpost footprint and reveals exactly one neutral building plot")
	check(game._visible_camp_decor().size() == 6, "the growing hamlet gains military dressing without moving decoration into its building plot")
	game.camp_player_position = game._plot_anchor("plot_1") + Vector2(0.0, 38.0)
	check(game._nearest_camp_interaction() == "plot_1" and game._camp_interaction_text("plot_1") == "PLAN NEW BUILDING", "walking to the revealed foundation enables its construction choice")
	game._construct_building("armory", "plot_1")
	await process_frame
	check(game._is_constructed("armory") and game._constructed_count() == 3 and String(game.save.profile.building_plots.plot_1) == "armory" and game.ui_root.find_child("CampPlot_plot_1", true, false) == null, "choosing a service permanently assigns it to the approached plot")
	game.save.profile.hall_level = 4
	game.save.profile.constructed_buildings = ["veterans_hall", "campfire", "armory", "blacksmith", "quartermaster", "training"]
	game.save.profile.building_plots = {"plot_1": "armory", "plot_2": "quartermaster", "plot_3": "blacksmith", "plot_4": "training"}
	game._show_camp()
	await process_frame
	check(game._visible_camp_decor().size() == 9, "a restored town displays the full decoration set including two animated braziers")
	check(game._camp_tier_texture("armory", 0) != game._camp_tier_texture("armory", 1), "camp restoration uses distinct art for consecutive building tiers")
	var armory_hotspot: Button = game.ui_root.find_child("CampBuilding_armory", true, false) as Button
	var blacksmith_hotspot: Button = game.ui_root.find_child("CampBuilding_blacksmith", true, false) as Button
	var quartermaster_hotspot: Button = game.ui_root.find_child("CampBuilding_quartermaster", true, false) as Button
	var training_hotspot: Button = game.ui_root.find_child("CampBuilding_training", true, false) as Button
	check(blacksmith_hotspot != null and armory_hotspot != null and quartermaster_hotspot != null and training_hotspot != null and not blacksmith_hotspot.get_global_rect().intersects(training_hotspot.get_global_rect()) and not armory_hotspot.get_global_rect().intersects(quartermaster_hotspot.get_global_rect()) and not armory_hotspot.get_global_rect().intersects(blacksmith_hotspot.get_global_rect()) and not quartermaster_hotspot.get_global_rect().intersects(training_hotspot.get_global_rect()), "all four restoration buildings have separate non-overlapping touch plots")
	var campfire_hotspot: Button = game.ui_root.find_child("CampfireButton", true, false) as Button
	check(campfire_hotspot != null and not training_hotspot.get_global_rect().intersects(campfire_hotspot.get_global_rect()), "training and campfire keep separate mobile touch regions")
	check(armory_hotspot.position.is_equal_approx(game._camp_hit_rect_world("armory").position - game.camera_offset) and blacksmith_hotspot.position.is_equal_approx(game._camp_hit_rect_world("blacksmith").position - game.camera_offset) and campfire_hotspot.position.is_equal_approx(game._camp_hit_rect_world("campfire").position - game.camera_offset), "building touch regions follow the scrolling world artwork")
	check(float(game.CAMP_STRUCTURE_LAYOUT.veterans_hall.anchor.x) == 585.0 and float(game.CAMP_STRUCTURE_LAYOUT.veterans_hall.anchor.y) == 210.0 and float(game.CAMP_STRUCTURE_LAYOUT.campfire.anchor.y) == 390.0, "visible structure bases remain centered on the compact rebuilt town plots")
	check(game.camp_building_outline_textures.get("armory", []).size() == 4 and armory_hotspot.get_theme_stylebox("pressed") is StyleBoxEmpty, "building interaction uses a sprite outline without a rectangular pressed panel")
	var camp_header: Control = game.ui_root.get_node_or_null("CampPanel") as Control
	var veteran_hotspot: Button = game.ui_root.find_child("VeteranTentButton", true, false) as Button
	check(camp_header != null and veteran_hotspot != null and camp_header.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the fixed camp header cannot block world-space building interaction")
	var camp_building: Button = game.ui_root.find_child("CampBuilding_training", true, false) as Button
	var camp_caption: Label = camp_building.find_child("CampLocationCaption", true, false) as Label if camp_building != null else null
	check(camp_caption != null and (camp_caption.text.contains("TIER") or camp_caption.text.contains("RESTORED")), "camp building artwork retains a compact tier marker")
	game.save.profile.armory_level = 0
	game.save.profile.silver = 100
	game.save.profile.provisions = 100
	game._show_building_detail("armory")
	await process_frame
	check(game.ui_root.get_node_or_null("CampBuildingOverlay") != null and game.ui_root.find_child("BuildingUpgradeButton", true, false) != null, "tapping a camp building opens its restoration and related menu")
	var building_effect: Label = game.ui_root.find_child("BuildingEffectLabel", true, false) as Label
	check(building_effect != null and building_effect.text.contains("AXE ACCESS"), "camp restoration detail shows the exact next-tier benefit")
	game._show_camp()
	game._show_camp_expeditions()
	await process_frame
	check(game.ui_root.get_node_or_null("CampExpeditionOverlay") != null and game.ui_root.find_child("RosterHero_warrior", true, false) != null and game.ui_root.find_child("RosterHero_rogue", true, false) != null, "the veterans' hall opens the four-recruit roster and idle assignments")
	game._set_hero_assignment("hunter", "patrol")
	check(String(Roster.hero_by_id(game.save.profile.heroes, "hunter").assignment) == "patrol", "an unselected recruit can be assigned to an offline job")
	game._make_roster_hero_active("rogue")
	check(String(game.save.profile.active_hero_id) == "rogue" and String(game.save.profile.starting_class) == "rogue", "selecting a roster hero updates the persistent field character")
	var active_hero: Dictionary = game._active_hero()
	active_hero.level = 2
	game._show_class_tree()
	await process_frame
	check(game.ui_root.find_child("ClassNode_light_foot", true, false) != null, "each hero exposes a compact permanent class tree")
	game._show_camp()
	game.save.profile.armory_level = 3
	game.save.profile.blacksmith_level = 3
	game.save.profile.training_level = 5
	game.save.profile.quartermaster_level = 3
	for progression_id: String in Content.PROGRESSION_NODES:
		game.save.profile.skill_tree[progression_id] = int(Content.PROGRESSION_NODES[progression_id].max_rank)
	game._show_camp()
	await process_frame
	var final_building: Button = game.ui_root.find_child("CampBuilding_quartermaster", true, false) as Button
	check(final_building != null and final_building.get_global_rect().end.y <= game.size.y + 1.0 and game.ui_root.find_child("StartingWeaponStats", true, false) == null, "fully restored camp fits the phone height without a redundant weapon selector")
	game._show_skill_tree()
	await process_frame
	var skill_panel: Control = game.ui_root.find_child("SkillTreePanel", true, false)
	var skill_node: Control = game.ui_root.find_child("SkillNode_vanguard_drill", true, false)
	var last_branch: Control = game.ui_root.find_child("SkillBranch3", true, false)
	var skill_description: Control = game.ui_root.find_child("SkillTreeDescription", true, false)
	check(game.ui_root.find_child("SkillNodes", true, false) != null and skill_node != null, "field skill tree opens with expandable nodes")
	check(skill_panel != null and skill_panel.get_global_rect().end.x <= game.size.x + 1.0, "skill tree panel stays inside the phone viewport")
	check(skill_node != null and skill_node.size.x >= 120.0, "skill cards keep a readable phone width")
	check(last_branch != null and last_branch.get_global_rect().end.x <= game.size.x + 1.0, "all skill branch tabs remain visible")
	check(skill_description != null and skill_description.size.y >= 16.0, "skill tree headings remain visible")
	game.save.profile.skill_tree.vanguard_drill = 1
	game.save.profile.skill_tree.vanguard_axe = 0
	game.save.profile.skill_tree.vanguard_grip = 0
	game._show_skill_tree()
	await process_frame
	var learned_node: Button = game.ui_root.find_child("SkillNode_vanguard_drill", true, false) as Button
	var available_node: Button = game.ui_root.find_child("SkillNode_vanguard_axe", true, false) as Button
	var locked_node: Button = game.ui_root.find_child("SkillNode_vanguard_grip", true, false) as Button
	var learned_text: Label = learned_node.find_child("CardDescription", true, false) as Label if learned_node != null else null
	var learned_style: StyleBoxFlat = learned_node.get_theme_stylebox("disabled") as StyleBoxFlat if learned_node != null else null
	var locked_style: StyleBoxFlat = locked_node.get_theme_stylebox("disabled") as StyleBoxFlat if locked_node != null else null
	var locked_stats: Label = locked_node.find_child("CardStats", true, false) as Label if locked_node != null else null
	var available_stats: Label = available_node.find_child("CardStats", true, false) as Label if available_node != null else null
	check(learned_text != null and not learned_text.text.contains("UNLOCKED") and not learned_text.text.contains("LEARNED"), "completed skill nodes communicate state without redundant labels")
	check(learned_node != null and learned_node.disabled and available_node != null and not available_node.disabled and locked_node != null and locked_node.disabled and learned_style != null and locked_style != null and learned_style.bg_color != locked_style.bg_color, "skill node backgrounds distinguish learned, available, and locked states")
	check(locked_stats != null and available_stats != null and locked_stats.get_theme_color("font_color") == Color("696e70") and locked_stats.get_theme_color("font_color") != available_stats.get_theme_color("font_color"), "locked skill descriptions are visibly desaturated")
	game.save.profile.inventory = [Rules.generate_equipment(7351, true, 0.0, 999)]
	game._show_inventory("", "999")
	await process_frame
	var inventory_panel: Control = game.ui_root.find_child("InventoryPanel", true, false)
	var inventory_item: Control = game.ui_root.find_child("InventoryItem_999", true, false)
	check(inventory_panel != null and inventory_panel.get_global_rect().end.y <= game.size.y + 1.0, "inventory fits inside the phone viewport without scrolling")
	check(inventory_item != null and game.ui_root.find_child("EquipmentDetail", true, false) != null, "inventory shows recovered equipment and its modifiers")
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
	check(game.display_font != null and game.body_font != null and game.display_font != game.body_font, "ornamental headings and readable body copy use separate fonts")
	check(game.ui_frame_texture != null, "custom company-ledger interface art loads")
	game._show_camp()
	game._show_weapon_picker()
	await process_frame
	check(game.get_node_or_null("WeaponPickerOverlay") != null, "weapon picker opens from the camp flow")
	var spear_choice: Button = game.get_node_or_null("WeaponPickerOverlay").find_child("WeaponChoice_spear", true, false) as Button
	var doctrine_detail: Label = game.get_node_or_null("WeaponPickerOverlay").find_child("DoctrineDetail", true, false) as Label
	var spear_stats: Label = spear_choice.find_child("CardStats", true, false) as Label if spear_choice != null else null
	var spear_description: Label = spear_choice.find_child("CardDescription", true, false) as Label if spear_choice != null else null
	var doctrine_stats: Label = game.get_node_or_null("WeaponPickerOverlay").find_child("DoctrineStats", true, false) as Label
	var class_detail: Label = game.get_node_or_null("WeaponPickerOverlay").find_child("ClassDetail", true, false) as Label
	var class_stats: Label = game.get_node_or_null("WeaponPickerOverlay").find_child("ClassStats", true, false) as Label
	check(spear_stats != null and spear_stats.text.contains("DAMAGE 21") and spear_stats.text.contains("ATTACK EVERY"), "weapon choices show exact damage and attack interval")
	check(doctrine_detail != null and not doctrine_detail.text.contains("%") and doctrine_stats != null and doctrine_stats.text.contains("%"), "descriptions and numerical doctrine statistics use separate visual layers")
	check(class_detail != null and not class_detail.text.contains("%") and class_stats != null and class_stats.text.contains("%"), "class selector separates role description from exact statistics")
	check(spear_stats.get_theme_font_size("font_size") < spear_choice.get_theme_font_size("font_size") and spear_stats.get_theme_color("font_color") != spear_choice.get_theme_color("font_color"), "card statistics use smaller contrasting typography")
	check(spear_description != null and not spear_description.get_global_rect().intersects(spear_stats.get_global_rect()), "card descriptions and stat footers never overlap")
	game._show_weapon_picker(1)
	await process_frame
	var last_ranged_choice: Button = game.get_node_or_null("WeaponPickerOverlay").find_child("WeaponChoice_caltrops", true, false) as Button
	var picker_back: Button = game.get_node_or_null("WeaponPickerOverlay").find_child("WeaponPickerBack", true, false) as Button
	check(last_ranged_choice != null and picker_back != null and picker_back.get_global_rect().end.y <= game.size.y + 1.0, "fully unlocked ranged weapon picker fits without scrolling")
	game._show_settings()
	await process_frame
	var settings_panel: PanelContainer = game.ui_root.find_child("SettingsPanel", true, false) as PanelContainer
	var settings_box: VBoxContainer = settings_panel.get_child(0) as VBoxContainer if settings_panel != null and settings_panel.get_child_count() > 0 else null
	check(settings_panel != null and settings_panel.visible and settings_panel.size.x > 0.0 and settings_panel.size.y > 0.0 and settings_box != null and settings_box.size.x > 0.0 and settings_box.size.y > 0.0 and game.ui_root.find_child("SettingsScroll", true, false) == null, "settings menu renders a visible fixed panel without scrolling")
	check(game.ui_root.find_child("ReloadAppButton", true, false) != null, "settings exposes a PWA reload control")
	var reset_save_button: Button = game.ui_root.find_child("ResetSaveButton", true, false) as Button
	check(reset_save_button != null, "settings exposes a guarded game-progress reset")
	reset_save_button.emit_signal("pressed")
	await process_frame
	var reset_overlay: ColorRect = game.ui_root.get_node_or_null("ResetSaveOverlay") as ColorRect
	var cancel_reset: Button = game.ui_root.find_child("CancelResetSaveButton", true, false) as Button
	check(reset_overlay != null and game.ui_root.find_child("ConfirmResetSaveButton", true, false) != null and cancel_reset != null, "reset requires an explicit destructive confirmation")
	cancel_reset.emit_signal("pressed")
	await process_frame
	check(game.ui_root.get_node_or_null("ResetSaveOverlay") == null and int(game.save.profile.hall_level) == 4, "cancelling reset leaves progression untouched")
	var gate_confirmation_toggle: CheckButton = game.ui_root.find_child("GateConfirmationsToggle", true, false) as CheckButton
	check(gate_confirmation_toggle != null and gate_confirmation_toggle.button_pressed, "settings exposes an enabled-by-default toggle for both gate questions")
	game._show_camp()
	game._show_weapon_picker(1)
	var preparation_overlay: Control = game.get_node_or_null("WeaponPickerOverlay") as Control
	game._choose_starting_weapon("sling", preparation_overlay)
	check(game.screen == game.Screen.CAMP and String(game.save.profile.starting_weapon) == "sling", "choosing a loadout prepares the company inside town without starting a separate map")
	game._show_camp()
	game.save.active_run = {}
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	var departure_overlay: ColorRect = game.ui_root.get_node_or_null("GateConfirmationOverlay") as ColorRect
	var departure_panel: Control = departure_overlay.get_node_or_null("GateConfirmationPanel") as Control if departure_overlay != null else null
	var departure_no: Button = departure_overlay.find_child("GateNoButton", true, false) as Button if departure_overlay != null else null
	check(game.screen == game.Screen.CAMP and departure_overlay != null and departure_panel != null and departure_panel.size.x < game.size.x and departure_overlay.color.a > 0.6, "crossing the town gate dims the world behind a compact ready-for-battle confirmation")
	departure_no.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.CAMP and game.ui_root.get_node_or_null("GateConfirmationOverlay") == null and game.camp_player_position.y < game._camp_gate_position().y, "declining battle returns the hero safely inside camp")
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	var departure_yes: Button = game.ui_root.find_child("GateYesButton", true, false) as Button
	departure_yes.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.RUN and game.player_position.y <= game._camp_gate_position().y + 1.1 and game.run_camera_transition < 0.1 and game.ui_root.modulate.a < 1.0, "confirming battle starts exactly beyond the painted gate with a softly introduced HUD")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var immediate_return_no: Button = game.ui_root.find_child("GateNoButton", true, false) as Button
	check(immediate_return_no != null, "turning around at the gate immediately offers the opposite transition without a clearance radius")
	immediate_return_no.emit_signal("pressed")
	await process_frame
	game.player_position = Vector2(game._camp_gate_position().x, game._camp_gate_position().y - 120.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	check(game.screen == game.Screen.RUN and game.ui_root.get_node_or_null("GateConfirmationOverlay") == null, "walking north through the camp cannot trigger extraction away from the southern gate")
	game._process_run(0.5)
	check(game.run_camera_transition > 0.0 and game.run_camera_transition < 1.0, "the camera blends from town framing into expedition framing over time")
	game._spawn_enemy("raider", false)
	var preserved_enemy = game.enemies.back()
	var preserved_enemy_position: Vector2 = preserved_enemy.position
	var preserved_enemy_count: int = game.enemies.size()
	var preserved_elapsed: float = game.run_elapsed
	game.run_exploration_silver = 7
	var silver_before_return: int = int(game.save.profile.silver)
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var return_overlay: ColorRect = game.ui_root.get_node_or_null("GateConfirmationOverlay") as ColorRect
	var return_no: Button = return_overlay.find_child("GateNoButton", true, false) as Button if return_overlay != null else null
	check(game.screen == game.Screen.RUN and game.run_paused and return_overlay != null and int(game.save.profile.silver) == silver_before_return, "approaching camp pauses combat behind a compact finish-run confirmation without banking early")
	return_no.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.RUN and not game.run_paused and game.enemies.size() == preserved_enemy_count and game.enemies.has(preserved_enemy) and preserved_enemy.position.distance_to(preserved_enemy_position) < 5.0 and absf(game.run_elapsed - preserved_elapsed) < 0.1, "declining extraction preserves every live enemy and continues from the same position and time")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	var return_yes: Button = game.ui_root.find_child("GateYesButton", true, false) as Button
	var return_camera: Vector2 = game.camera_offset
	return_yes.emit_signal("pressed")
	await process_frame
	check(game.screen == game.Screen.CAMP and bool(game.result_data.get("extracted", false)) and bool(game.result_data.get("banked", false)) and int(game.save.profile.silver) >= silver_before_return + 7, "confirming extraction banks the run and swaps directly to the camp HUD")
	check(game.camera_offset.distance_to(return_camera) < 6.0 and game.camp_uses_field_camera, "entering camp preserves the continuous world camera instead of recentering it")
	check(game.camp_wanderers.has(preserved_enemy) and game.enemies.is_empty(), "nearby enemies de-aggro into persistent camp wanderers instead of disappearing")
	var dispersal_origin: Vector2 = preserved_enemy.position
	var dispersal_vector: Vector2 = preserved_enemy.wander_direction
	game._process_camp(1.0)
	check((preserved_enemy.position - dispersal_origin).dot(dispersal_vector) > 0.0 and game.camp_wanderers.size() >= game.MIN_CAMP_WANDERERS, "former pursuers disperse gradually while a small hostile presence keeps wandering outside camp")
	game.save.settings.gate_confirmations = false
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	check(game.screen == game.Screen.RUN and game.ui_root.get_node_or_null("GateConfirmationOverlay") == null, "disabled gate questions begin battle immediately on departure")
	game.player_position = game._camp_gate_position() + Vector2(0.0, 2.0)
	game.run_gate_entry_armed = true
	game.joystick_vector = Vector2.UP
	game._update_player(0.0)
	check(game.screen == game.Screen.CAMP and game.ui_root.get_node_or_null("GateConfirmationOverlay") == null, "disabled gate questions finish and bank the run immediately on return")
	game.save.settings.gate_confirmations = true
	game._start_new_run("spear")
	var silver_before_defeat: int = int(game.save.profile.silver)
	game.run_exploration_silver = 99
	game.run_loot.clear()
	game.run_loot.append({"uid": "unsecured_test", "base_id": "iron_kettle", "name": "Test Helm", "slot": "head", "rarity": "common", "modifiers": []})
	game._finish_run(false)
	check(int(game.save.profile.silver) == silver_before_defeat and int(game.result_data.get("lost_loot", 0)) == 1 and not bool(game.result_data.get("banked", true)), "defeat preserves progression but discards unsecured run currency and equipment")
	print("Ashen Company combat smoke: %d ms, %d failures" % [elapsed_ms, failures])
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
