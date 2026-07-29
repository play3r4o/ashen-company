extends SceneTree

const Saves = preload("res://src/save_service.gd")
const Rules = preload("res://src/rules.gd")
const Content = preload("res://src/content.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("run_smoke")

func run_smoke() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Control = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_new_run("spear")
	check(game.exploration_points.size() == 4 and game.expedition_interact_button != null, "expedition begins with searchable moor landmarks and a contextual action")
	var first_discovery = game.exploration_points[0]
	game.player_position = first_discovery.position
	game._update_exploration()
	var dread_before_discovery: float = game._current_dread()
	game._interact_with_expedition()
	check(first_discovery.discovered and game.run_discoveries == 1 and game.run_exploration_silver > 0 and game._current_dread() > dread_before_discovery, "searching a landmark grants field rewards and advances Dread")
	game.run_discoveries = 2
	game._update_exploration()
	check(game.world_size.x == game.size.x * 3.0 and game.world_size.y == game.size.y * 4.0 and first_discovery.position.y > game.size.y, "town and searchable moor occupy one continuous multi-screen world")
	game.run_discoveries = 1
	check(game.actor_textures.size() == 20, "all player and enemy facing sprites load")
	check(game.actor_frames.size() == 2 and game.health_bar != null, "class sprite frames and in-run health bar load")
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
	game._show_camp()
	check(game.ui_root.get_node_or_null("CampPanel") != null and game.ui_root.find_child("CampScroll", true, false) == null, "camp menu uses a fixed responsive panel")
	var camp_interact: Button = game.ui_root.find_child("CampInteractButton", true, false) as Button
	var camp_start: Vector2 = game._world_map_point(Vector2(585.0, 560.0))
	game.camp_player_position = camp_start
	var camp_camera_start: Vector2 = game.camera_offset
	game.joystick_vector = Vector2.RIGHT
	game._process_camp(0.1)
	check(camp_interact != null and game.camp_player_position.x > camp_start.x and game.camera_offset.x > camp_camera_start.x, "the expanded town camera follows direct character movement between building plots")
	var fence_samples: Array[Vector2] = [Vector2(80.0, 350.0), Vector2(585.0, 74.0), Vector2(1090.0, 350.0), Vector2(300.0, 700.0)]
	var fence_samples_blocked: bool = true
	for fence_sample: Vector2 in fence_samples:
		fence_samples_blocked = fence_samples_blocked and game._point_hits_camp_fence(game._world_map_point(fence_sample))
	var gate_opening: Vector2 = game._camp_gate_position() + Vector2(0.0, 8.0)
	check(game._camp_position_blocked(game._world_map_point(Vector2(12.0, 150.0))) and fence_samples_blocked and not game._camp_position_blocked(gate_opening), "the separate physical palisade blocks its visible timber perimeter on every side while leaving only the southern gate open")
	game.joystick_vector = Vector2.ZERO
	game.camp_player_position = game._camp_interaction_position("gate")
	game._process_camp(0.0)
	check(game.camp_interaction_target == "gate" and camp_interact.text.contains("CROSS"), "approaching the physical gate explains that crossing begins the expedition")
	var camp_crest: TextureRect = game.ui_root.find_child("CampTitleCrest", true, false) as TextureRect
	var silver_icon: TextureRect = game.ui_root.find_child("SilverIcon", true, false) as TextureRect
	var provisions_icon: TextureRect = game.ui_root.find_child("ProvisionsIcon", true, false) as TextureRect
	var silver_value: Label = game.ui_root.find_child("SilverValueLabel", true, false) as Label
	var provisions_value: Label = game.ui_root.find_child("ProvisionsValueLabel", true, false) as Label
	var currency_bar: ColorRect = game.ui_root.find_child("CurrencyBarBackground", true, false) as ColorRect
	var settings_cog: Button = game.ui_root.find_child("SettingsCogButton", true, false) as Button
	var expected_crest_width: float = minf(380.0, game.size.x - 10.0)
	var expected_crest_height: float = expected_crest_width * float(camp_crest.texture.get_height()) / float(camp_crest.texture.get_width()) if camp_crest != null and camp_crest.texture != null else 0.0
	check(camp_crest != null and camp_crest.texture != null and is_equal_approx(camp_crest.position.x, (game.size.x - expected_crest_width) * 0.5) and is_equal_approx(camp_crest.position.y, 6.0) and is_equal_approx(camp_crest.size.x, expected_crest_width) and is_equal_approx(camp_crest.size.y, expected_crest_height), "camp title crest uses a 380px aspect-preserving width")
	check(silver_icon != null and silver_icon.texture != null and provisions_icon != null and provisions_icon.texture != null and silver_value != null and provisions_value != null and silver_value.text == str(int(game.save.profile.silver)) and provisions_value.text == str(int(game.save.profile.provisions)), "camp resources use illustrated icons with live numeric values")
	check(currency_bar != null and is_equal_approx(currency_bar.color.a, 0.70) and is_equal_approx(currency_bar.position.y, 124.0) and is_equal_approx(currency_bar.size.y, 28.0) and currency_bar.position.x == 0.0 and currency_bar.size.x == game.size.x, "currency strip sits below the crest in a short seventy-percent backdrop")
	check(settings_cog != null and settings_cog.icon != null and is_equal_approx(settings_cog.position.x, game.size.x - 58.0) and is_equal_approx(settings_cog.position.y, game.size.y - 58.0) and settings_cog.get_theme_stylebox("normal") is StyleBoxEmpty, "settings uses a standalone bottom-right cog without a button rectangle")
	var veteran_tent: Button = game.ui_root.find_child("VeteranTentButton", true, false) as Button
	var veteran_caption: Label = veteran_tent.find_child("CampLocationCaption", true, false) as Label if veteran_tent != null else null
	check(veteran_caption != null and (veteran_caption.text.contains("READY") or veteran_caption.text.contains("EXPEDITIONS")), "camp explains the active idle expedition")
	check(game.world_map_texture != null and game.world_map_texture.get_height() > 2000 and game.camp_palisade_texture != null and game.CAMP_BOUNDARY_POLYGON.size() >= 20 and game.camp_building_textures.get("armory", []).size() == 4 and game.camp_building_textures.get("blacksmith", []).size() == 4 and game.camp_building_textures.get("training", []).size() == 6 and game.ui_root.find_child("CampfireButton", true, false) != null, "camp loads crisp terrain, a separate physical palisade, and every separate building tier")
	check(game._camp_tier_texture("armory", 0) != game._camp_tier_texture("armory", 1), "camp restoration uses distinct art for consecutive building tiers")
	var armory_hotspot: Button = game.ui_root.find_child("CampBuilding_armory", true, false) as Button
	var blacksmith_hotspot: Button = game.ui_root.find_child("CampBuilding_blacksmith", true, false) as Button
	var quartermaster_hotspot: Button = game.ui_root.find_child("CampBuilding_quartermaster", true, false) as Button
	var training_hotspot: Button = game.ui_root.find_child("CampBuilding_training", true, false) as Button
	check(blacksmith_hotspot != null and armory_hotspot != null and quartermaster_hotspot != null and training_hotspot != null and not blacksmith_hotspot.get_global_rect().intersects(training_hotspot.get_global_rect()) and not armory_hotspot.get_global_rect().intersects(quartermaster_hotspot.get_global_rect()) and not armory_hotspot.get_global_rect().intersects(blacksmith_hotspot.get_global_rect()) and not quartermaster_hotspot.get_global_rect().intersects(training_hotspot.get_global_rect()), "all four restoration buildings have separate non-overlapping touch plots")
	var campfire_hotspot: Button = game.ui_root.find_child("CampfireButton", true, false) as Button
	check(campfire_hotspot != null and not training_hotspot.get_global_rect().intersects(campfire_hotspot.get_global_rect()), "training and campfire keep separate mobile touch regions")
	check(armory_hotspot.position.is_equal_approx(game._camp_hit_rect_world("armory").position - game.camera_offset) and blacksmith_hotspot.position.is_equal_approx(game._camp_hit_rect_world("blacksmith").position - game.camera_offset) and campfire_hotspot.position.is_equal_approx(game._camp_hit_rect_world("campfire").position - game.camera_offset), "building touch regions follow the scrolling world artwork")
	check(float(game.CAMP_STRUCTURE_LAYOUT.veterans_hall.anchor.x) == 585.0 and float(game.CAMP_STRUCTURE_LAYOUT.campfire.anchor.y) == 716.0, "visible structure bases remain centered on the new irregular town plots")
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
	check(game.ui_root.get_node_or_null("CampExpeditionOverlay") != null and game.ui_root.find_child("ExpeditionStatusDetail", true, false) != null, "the veterans' tent opens detailed idle expedition controls")
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
	check(game.ui_root.find_child("SettingsPanel", true, false) != null and game.ui_root.find_child("SettingsScroll", true, false) == null, "settings menu fits without scrolling")
	check(game.ui_root.find_child("ReloadAppButton", true, false) != null, "settings exposes a PWA reload control")
	game._show_camp()
	game._show_weapon_picker(1)
	var preparation_overlay: Control = game.get_node_or_null("WeaponPickerOverlay") as Control
	game._choose_starting_weapon("sling", preparation_overlay)
	check(game.screen == game.Screen.CAMP and String(game.save.profile.starting_weapon) == "sling", "choosing a loadout prepares the company inside town without starting a separate map")
	game._show_camp()
	game.save.active_run = {}
	game.camp_player_position = game._camp_gate_position() + Vector2(0.0, 1.0)
	game._process_camp(0.0)
	check(game.screen == game.Screen.RUN and game.player_position.y >= game._camp_gate_position().y, "crossing the town gate starts combat in place without loading another map")
	game.run_gate_cleared = true
	game.player_position = game._camp_gate_position() - Vector2(0.0, 1.0)
	game._update_player(0.0)
	check(game.screen == game.Screen.RESULTS and bool(game.result_data.get("extracted", false)), "walking back through the same gate extracts into the safe town")
	print("Ashen Company combat smoke: %d ms, %d failures" % [elapsed_ms, failures])
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
