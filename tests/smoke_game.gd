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
	check(absf(game.run_elapsed - saved_elapsed) < 0.01 and game.weapons.has("spear"), "serialized expedition restores its timer and build")
	game.run_elapsed = 479.0
	game.run_kills = 120
	game.run_elites = 2
	game.boss_defeated = true
	game._finish_run(true)
	check(game.screen == game.Screen.RESULTS and not game.save.profile.veteran.is_empty(), "victory creates results and a Veteran Record")
	game._show_camp()
	check(game.ui_root.get_node_or_null("CampPanel") != null and game.ui_root.find_child("CampScroll", true, false) == null, "camp menu uses a fixed responsive panel")
	check(game.ui_root.find_child("ExpeditionStatus", true, false) != null, "camp explains the active idle expedition")
	var camp_building: Button = game.ui_root.find_child("CampBuilding_training", true, false) as Button
	var camp_stats: Label = camp_building.find_child("CardStats", true, false) as Label if camp_building != null else null
	check(camp_stats != null and camp_stats.text.contains("HP & DAMAGE") and camp_stats.text.contains("MOVEMENT"), "camp upgrades show their exact next-tier benefit")
	game.save.profile.armory_level = 3
	game.save.profile.training_level = 5
	game.save.profile.quartermaster_level = 3
	for progression_id: String in Content.PROGRESSION_NODES:
		game.save.profile.skill_tree[progression_id] = int(Content.PROGRESSION_NODES[progression_id].max_rank)
	game._show_camp()
	await process_frame
	var starting_stats: Label = game.ui_root.find_child("StartingWeaponStats", true, false) as Label
	check(starting_stats != null and starting_stats.get_global_rect().end.y <= game.size.y + 1.0, "fully restored camp and starting weapon statistics fit the phone height")
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
	print("Ashen Company combat smoke: %d ms, %d failures" % [elapsed_ms, failures])
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
