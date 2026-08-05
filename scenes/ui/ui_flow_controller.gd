extends "res://scenes/world/expedition/run_lifecycle_controller.gd"
func _buy_building(building: String) -> void:
	var key: String = building + "_level"
	var level: int = int(save.profile[key])
	var costs: Array[Dictionary]
	match building:
		"armory": costs = GameContent.ARMORY_COSTS
		"blacksmith": costs = GameContent.BLACKSMITH_COSTS
		"training": costs = GameContent.TRAINING_COSTS
		_: costs = GameContent.QUARTERMASTER_COSTS
	if level >= costs.size():
		_show_camp("That part of camp is fully restored.")
		return
	var cost: Dictionary = costs[level]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		_show_camp("The company lacks the materials for that work.")
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	save.profile[key] = level + 1
	var training_service := TrainingGroundsService.new(save.profile)
	training_service.training_points_from_building_upgrade(building, level + 1)
	SaveService.save_data(save)
	_show_camp("The %s reaches tier %d." % [building.capitalize(), level + 1])

func _building_effect_text(building: String, level: int, maximum: int) -> String:
	if building == "armory":
		var access: Array[String] = ["AXE ACCESS", "BOW + KNIVES ACCESS", "CALTROPS + START PICK"]
		return "ALL WEAPON ACCESS" if level >= maximum else access[level]
	if building == "blacksmith":
		var shown_level: int = level if level >= maximum else level + 1
		return "+%d%% POSITIVE EQUIPMENT STATS" % (shown_level * 5)
	if building == "training":
		var shown_level: int = level if level >= maximum else level + 1
		return "+%d%% HP & DAMAGE  |  +%.1f%% MOVEMENT" % [roundi(float(shown_level) / 5.0 * 15.0), float(shown_level) / 5.0 * 8.0]
	var shown_level: int = level if level >= maximum else level + 1
	return "+%d%% IDLE YIELD  |  %.1fH CAP" % [shown_level * 8, GameRules.offline_cap_hours(shown_level)]

func _show_camp(message: String = "", preserve_world: bool = false) -> void:
	# Only play the location card on a genuine arrival. Rebuilding the camp UI
	# after closing a menu must not restart it.
	var show_location_title: bool = not is_instance_valid(ui_root) or screen == Screen.RUN or screen == Screen.RESULTS
	var keep_camera: bool = preserve_world or camp_uses_field_camera
	screen = Screen.CAMP
	run_paused = true
	camp_uses_field_camera = keep_camera
	_sync_authored_camp_scene()
	_build_structure_definitions()
	camp_highlighted_structure = ""
	_sync_structure_anchors()
	if not keep_camera:
		_update_world_camera(camp_player_position, true, true)
	_ensure_camp_wanderers()
	_apply_offline_progress()
	_play_music("camp")
	_clear_ui()
	ui_root = ScreenHostScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_hud(ui_root)
	ui_root.z_index = 100

	_add_safe_area_band(ui_root)

	var expedition: Dictionary = save.profile.expedition
	var current_operation: String = String(expedition.get("operation", "forage"))
	var pending_silver: int = int(expedition.get("pending_silver", 0))
	var pending_provisions: int = int(expedition.get("pending_provisions", 0))
	var operation_name: String = "PATROL" if current_operation == "patrol" else "FORAGING"
	var pending_text: String = "%dS / %dP READY · %d/%d BUILT" % [pending_silver, pending_provisions, _constructed_count(), _town_capacity()] if pending_silver + pending_provisions > 0 else "%s · %d/%d BUILT" % [operation_name, _constructed_count(), _town_capacity()]
	var live_hud := _add_live_hud("camp")
	var title_crest := live_hud.get_node("SafeAreaTop/CampTitleCrest") as TextureRect
	title_crest.visible = show_location_title
	camp_arrival_crest = title_crest
	camp_arrival_crest_elapsed = 0.0
	if show_location_title:
		title_crest.modulate.a = 1.0
	live_hud.bind_profile(save.profile, _active_hero(), _camp_display_max_health())
	silver_value_label = live_hud.get_node("SafeAreaTop/ResourceRail/SilverCell/SilverValueLabel") as Label
	provisions_value_label = live_hud.get_node("SafeAreaTop/ResourceRail/ProvisionsCell/ProvisionsValueLabel") as Label
	health_bar = live_hud.get_node("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	var settings_button_top := live_hud.get_node("SafeAreaTop/SettingsCogButton") as Button
	settings_button_top.tooltip_text = "Settings"
	settings_button_top.pressed.connect(_show_settings)
	camp_interact_button = live_hud.get_node("Camp/CampInteractButton") as Button
	camp_interact_button.disabled = true
	camp_interact_button.pressed.connect(_interact_with_camp_target)
	if not Geometry2D.is_point_in_polygon(camp_player_position, _camp_boundary_world()) or _camp_position_blocked(camp_player_position):
		camp_player_position = _safe_camp_spawn_position()
	camp_interaction_target = _nearest_camp_interaction()
	_update_camp_interact_button()
	status_label = live_hud.get_node("Camp/CampStatusLabel") as Label
	status_label.text = message
	status_label.visible = not message.is_empty()

func _show_hall_detail() -> void:
	_reset_movement_input()
	var overlay := HallScreenScene.instantiate() as Control
	ui_controller.mount_screen(overlay)
	var authored_hall_level: int = _town_level()
	var authored_town: Dictionary = _town_definition()
	var authored_entries: Array[Dictionary] = []
	if authored_hall_level < GameContent.HALL_COSTS.size():
		var authored_cost: Dictionary = GameContent.HALL_COSTS[authored_hall_level]
		var authored_can_afford: bool = int(save.profile.silver) >= int(authored_cost.silver) and int(save.profile.provisions) >= int(authored_cost.provisions)
		var authored_next_town: Dictionary = _camp_tier_metadata(authored_hall_level + 1)
		authored_entries.append({"id": "upgrade", "node_name": "HallUpgradeButton", "title": "EXPAND TO %s" % String(authored_next_town.name), "detail": "+1 BUILDING SLOT - %d SILVER / %d PROVISIONS" % [int(authored_cost.silver), int(authored_cost.provisions)], "disabled": not authored_can_afford})
	authored_entries.append({"id": "roster", "node_name": "HallRosterButton", "title": "MANAGE COMPANY & OFFLINE WORK", "detail": "Choose the field hero and assignments."})
	var authored_slot_status: String = "A MARKED FOUNDATION IS READY" if _has_open_building_slot() else "ALL CURRENT SLOTS ARE OCCUPIED"
	overlay.call("bind_screen", "VETERANS' HALL", "%s - HALL TIER %d" % [String(authored_town.name), authored_hall_level], "BUILDING CAPACITY %d / %d\n%s" % [_constructed_count(), _town_capacity(), authored_slot_status], authored_entries, "RETURN TO TOWN")
	overlay.connect("action_requested", _on_hall_screen_action.bind(overlay))
	overlay.connect("back_requested", overlay.queue_free)
	return

func _buy_hall_upgrade() -> void:
	var hall_level: int = _town_level()
	if hall_level >= GameContent.HALL_COSTS.size():
		return
	var cost: Dictionary = GameContent.HALL_COSTS[hall_level]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	save.profile.hall_level = hall_level + 1
	var training_service := TrainingGroundsService.new(save.profile)
	training_service.training_points_from_building_upgrade("veterans_hall", hall_level + 1)
	SaveService.save_data(save)
	_show_camp("The palisade expands. Find the new marked foundation in town.")

func _on_hall_screen_action(action_id: String, overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	match action_id:
		"upgrade": _buy_hall_upgrade()
		"roster": _show_camp_expeditions()

func _show_construction_menu(plot_id: String = "") -> void:
	if plot_id.is_empty():
		plot_id = _first_open_plot()
	if plot_id.is_empty() or not _is_plot_visible(plot_id):
		return
	_reset_movement_input()
	var authored_overlay := ConstructionScreenScene.instantiate() as Control
	ui_controller.mount_screen(authored_overlay)
	var authored_entries: Array[Dictionary] = []
	for authored_building: String in ["armory", "blacksmith", "quartermaster", "training"]:
		if _is_constructed(authored_building):
			continue
		var authored_cost: Dictionary = GameContent.BUILDING_CONSTRUCTION_COSTS[authored_building]
		var authored_label: String = "TRAINING YARD" if authored_building == "training" else authored_building.replace("_", " ").to_upper()
		var authored_can_build: bool = int(save.profile.silver) >= int(authored_cost.silver) and int(save.profile.provisions) >= int(authored_cost.provisions)
		authored_entries.append({"id": authored_building, "node_name": "Construct_%s" % authored_building, "title": "%s - %dS / %dP" % [authored_label, int(authored_cost.silver), int(authored_cost.provisions)], "detail": _building_construction_effect(authored_building), "disabled": not authored_can_build})
	authored_overlay.call("bind_screen", "CHOOSE A TOWN SERVICE", "FOUNDATION %d - THIS CHOICE IS PERMANENT" % (_revealed_plot_ids().find(plot_id) + 1), "", authored_entries, "LEAVE FOUNDATION")
	authored_overlay.connect("action_requested", _on_construction_action.bind(plot_id, authored_overlay))
	authored_overlay.connect("back_requested", authored_overlay.queue_free)
	return
func _on_construction_action(building: String, plot_id: String, overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_construct_building(building, plot_id)

func _building_construction_effect(building: String) -> String:
	match building:
		"armory": return "Unlocks weapon loadouts and martial weapon restoration."
		"blacksmith": return "Unlocks equipment inspection and improves positive item stats."
		"quartermaster": return "Unlocks expedition logistics, idle yield and frontier work."
		"training": return "Unlocks the company skill tree and permanent hero training."
	return "Adds a new service to the settlement."

func _construct_building(building: String, plot_id: String = "") -> void:
	if plot_id.is_empty():
		plot_id = _first_open_plot()
	if _is_constructed(building) or not _is_plot_visible(plot_id) or not GameContent.BUILDING_CONSTRUCTION_COSTS.has(building):
		return
	var cost: Dictionary = GameContent.BUILDING_CONSTRUCTION_COSTS[building]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	var buildings: Array = _constructed_buildings().duplicate()
	buildings.append(building)
	save.profile.constructed_buildings = buildings
	var plots: Dictionary = _building_plots().duplicate(true)
	plots[plot_id] = building
	save.profile.building_plots = plots
	# Constructing the Training Grounds is its own one-time reward. Later
	# Restorations (tiers 2–5) are handled by _buy_building below.
	if building == "training":
		var training_service := TrainingGroundsService.new(save.profile)
		training_service.grant_one_time_points("training_grounds_constructed", 4, "training_grounds")
	_sync_structure_anchors()
	SaveService.save_data(save)
	_show_camp("The %s is ready for service." % ("training yard" if building == "training" else building.replace("_", " ")))

func _show_building_detail(building: String) -> void:
	if not _is_constructed(building):
		_show_construction_menu(_first_open_plot())
		return
	var building_costs: Array[Dictionary]
	var building_name: String
	var linked_menu: String
	match building:
		"armory":
			building_costs = GameContent.ARMORY_COSTS
			building_name = "ARMORY"
			linked_menu = "CHOOSE LOADOUT"
		"blacksmith":
			building_costs = GameContent.BLACKSMITH_COSTS
			building_name = "BLACKSMITH"
			linked_menu = "OPEN EQUIPMENT"
		"training":
			building_costs = GameContent.TRAINING_COSTS
			building_name = "TRAINING YARD"
			linked_menu = "OPEN SKILL TREE"
		_:
			building_costs = GameContent.QUARTERMASTER_COSTS
			building_name = "QUARTERMASTER"
			linked_menu = "VETERANS' WORK"
	var level: int = int(save.profile[building + "_level"])
	var authored_overlay := BuildingDetailScreenScene.instantiate() as Control
	ui_controller.mount_screen(authored_overlay)
	var authored_entries: Array[Dictionary] = []
	if level < building_costs.size():
		var authored_cost: Dictionary = building_costs[level]
		var authored_can_afford: bool = int(save.profile.silver) >= int(authored_cost.silver) and int(save.profile.provisions) >= int(authored_cost.provisions)
		authored_entries.append({"id": "upgrade", "node_name": "BuildingUpgradeButton", "title": "RESTORE TIER %d" % (level + 1), "detail": "COST %d SILVER / %d PROVISIONS" % [int(authored_cost.silver), int(authored_cost.provisions)], "disabled": not authored_can_afford})
	authored_entries.append({"id": "linked_menu", "node_name": "BuildingLinkedMenuButton", "title": linked_menu, "detail": "Open this service."})
	if building == "training":
		authored_entries.append({"id": "class_tree", "node_name": "ClassTrainingButton", "title": "ACTIVE HERO TRAINING", "detail": "Spend this hero's class points."})
	if building == "quartermaster" and not save.profile.get("unlocked_biomes", []).has("gloamwood"):
		var authored_key_count: int = int(save.profile.get("biome_keys", {}).get("barrows_key", 0))
		var authored_frontier_ready: bool = level >= 1 and authored_key_count >= 1
		authored_entries.append({"id": "frontier", "node_name": "FrontierUpgradeButton", "title": "RESTORE GLOAMWOOD GATE", "detail": "NEEDS TIER 1 + 1 BARROW KEY - OWNED %d" % authored_key_count, "disabled": not authored_frontier_ready})
	var authored_effect_heading: String = "CURRENT RESTORATION" if level >= building_costs.size() else "NEXT RESTORATION"
	authored_overlay.call("bind_screen", building_name, "RESTORATION TIER %d / %d" % [level, building_costs.size()], "%s\n%s" % [authored_effect_heading, _building_effect_text(building, level, building_costs.size())], authored_entries, "RETURN TO CAMP")
	var authored_effect_label := authored_overlay.find_child("Status", true, false) as Label
	if authored_effect_label != null:
		authored_effect_label.name = "BuildingEffectLabel"
	authored_overlay.connect("action_requested", _on_building_detail_action.bind(building, authored_overlay))
	authored_overlay.connect("back_requested", authored_overlay.queue_free)
	return
func _on_building_detail_action(action_id: String, building: String, overlay: Control) -> void:
	match action_id:
		"upgrade":
			if is_instance_valid(overlay):
				overlay.queue_free()
			_buy_building(building)
		"linked_menu":
			if is_instance_valid(overlay):
				overlay.queue_free()
			match building:
				"armory": _show_weapon_picker()
				"blacksmith": _show_inventory()
				"training": _show_skill_tree()
				_: _show_camp_expeditions()
		"class_tree": _replace_overlay_with_class_tree(overlay)
		"frontier": _unlock_frontier(overlay)

func _replace_overlay_with_class_tree(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_class_tree()

func _show_class_tree(message: String = "") -> void:
	_reset_movement_input()
	var authored_overlay := ClassTrainingScreenScene.instantiate() as Control
	ui_controller.mount_screen(authored_overlay)
	var authored_hero: Dictionary = _active_hero()
	var authored_class_id: String = String(authored_hero.get("class_id", "warrior"))
	var authored_learned: Dictionary = authored_hero.get("class_tree", {})
	var authored_points: int = maxi(0, int(authored_hero.get("level", 1)) - 1 - authored_learned.size())
	var authored_entries: Array[Dictionary] = []
	var authored_nodes: Array = GameContent.CLASS_TREES.get(authored_class_id, [])
	for authored_index: int in authored_nodes.size():
		var authored_node: Dictionary = authored_nodes[authored_index]
		var authored_is_learned: bool = bool(authored_learned.get(String(authored_node.id), false))
		var authored_prior_met: bool = authored_index == 0 or bool(authored_learned.get(String(authored_nodes[authored_index - 1].id), false))
		authored_entries.append({"id": "learn:%s" % String(authored_node.id), "node_name": "ClassNode_%s" % String(authored_node.id), "title": String(authored_node.name).to_upper(), "detail": "%s\n%s" % [String(authored_node.description), GameContent.stats_text(authored_node.stats)], "disabled": authored_is_learned or not authored_prior_met or authored_points <= 0})
	authored_overlay.call("bind_screen", "%s - %s" % [String(authored_hero.get("name", "HERO")).to_upper(), String(GameContent.CLASSES[authored_class_id].name).to_upper()], "HERO LEVEL %d - %d TRAINING POINTS" % [int(authored_hero.get("level", 1)), authored_points], message, authored_entries, "RETURN TO TRAINING YARD")
	authored_overlay.connect("action_requested", _on_class_training_action.bind(authored_overlay))
	authored_overlay.connect("back_requested", authored_overlay.queue_free)
	return
func _buy_class_node(node_id: String) -> void:
	var hero: Dictionary = _active_hero()
	var class_id: String = String(hero.get("class_id", "warrior"))
	var nodes: Array = GameContent.CLASS_TREES.get(class_id, [])
	var learned: Dictionary = hero.get("class_tree", {})
	if maxi(0, int(hero.get("level", 1)) - 1 - learned.size()) <= 0:
		_show_class_tree("Gain a hero level to earn another training point.")
		return
	for node_index: int in nodes.size():
		var node: Dictionary = nodes[node_index]
		if String(node.id) != node_id:
			continue
		if node_index > 0 and not bool(learned.get(String(nodes[node_index - 1].id), false)):
			return
		learned[node_id] = true
		hero.class_tree = learned
		SaveService.save_data(save)
		_show_class_tree("%s learned." % String(node.name))
		return

func _on_class_training_action(action_id: String, overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	if action_id.begins_with("learn:"):
		_buy_class_node(action_id.trim_prefix("learn:"))

func _unlock_frontier(overlay: Control) -> void:
	if int(save.profile.get("quartermaster_level", 0)) < 1:
		return
	var keys: Dictionary = save.profile.get("biome_keys", {})
	if int(keys.get("barrows_key", 0)) < 1:
		return
	keys.barrows_key = int(keys.barrows_key) - 1
	save.profile.biome_keys = keys
	var unlocked: Array = save.profile.get("unlocked_biomes", ["blackthorn_moor"])
	if not unlocked.has("gloamwood"):
		unlocked.append("gloamwood")
	save.profile.unlocked_biomes = unlocked
	save.profile.frontier_upgrades.gloamwood_gate = true
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_camp("The Gloamwood frontier gate is restored. The road beyond is coming next.")

func _show_camp_expeditions() -> void:
	_apply_offline_progress()
	_reset_movement_input()
	var authored_overlay := ExpeditionAssignmentsScreenScene.instantiate() as Control
	ui_controller.mount_screen(authored_overlay)
	var authored_entries: Array[Dictionary] = []
	var authored_total_pending: int = 0
	for authored_hero_value: Variant in save.profile.get("heroes", []):
		var authored_hero: Dictionary = authored_hero_value
		var authored_hero_id: String = String(authored_hero.id)
		var authored_assignment: String = String(authored_hero.get("assignment", "idle")).replace("_", " ").to_upper()
		var authored_pending: int = int(authored_hero.get("pending_silver", 0)) + int(authored_hero.get("pending_provisions", 0)) + int(authored_hero.get("pending_xp", 0))
		authored_total_pending += authored_pending
		authored_entries.append({"id": "hero:%s" % authored_hero_id, "node_name": "RosterHero_%s" % authored_hero_id, "title": "%s - %s" % [String(authored_hero.name).to_upper(), String(GameContent.CLASSES[authored_hero.class_id].name).to_upper()], "detail": "LV %d - %s%s" % [int(authored_hero.level), authored_assignment, " - READY" if authored_pending > 0 else ""]})
	var authored_selected: Dictionary = Roster.hero_by_id(save.profile.get("heroes", []), selected_roster_hero_id)
	if authored_selected.is_empty():
		selected_roster_hero_id = "hunter"
		authored_selected = Roster.hero_by_id(save.profile.get("heroes", []), selected_roster_hero_id)
	for authored_assignment_data: Dictionary in [{"id": "patrol", "label": "PATROL", "rate": "9S/H"}, {"id": "forage", "label": "FORAGE", "rate": "2.5P/H"}, {"id": "training", "label": "TRAIN", "rate": "6XP/H"}]:
		authored_entries.append({"id": "assign:%s" % String(authored_assignment_data.id), "node_name": "Assignment_%s" % String(authored_assignment_data.id), "title": String(authored_assignment_data.label), "detail": String(authored_assignment_data.rate), "disabled": String(authored_selected.get("assignment", "idle")) == "active"})
	if String(authored_selected.get("assignment", "idle")) != "active":
		authored_entries.append({"id": "make_active", "node_name": "MakeHeroActiveButton", "title": "TAKE %s INTO THE MOOR" % String(authored_selected.get("name", "HERO")).to_upper(), "detail": "Make this recruit the active field hero."})
	if authored_total_pending > 0:
		authored_entries.append({"id": "claim", "node_name": "ClaimRosterRewardsButton", "title": "COLLECT ALL COMPLETED WORK", "detail": "Bank all pending company rewards."})
	var authored_selected_class: String = String(authored_selected.get("class_id", "hunter"))
	var authored_status: String = "%s - LV %d - XP %d/%d\n%s" % [String(authored_selected.get("name", "Recruit")).to_upper(), int(authored_selected.get("level", 1)), int(authored_selected.get("xp", 0)), Roster.xp_for_next_level(int(authored_selected.get("level", 1))), String(GameContent.CLASSES[authored_selected_class].description)]
	authored_overlay.call("bind_screen", "COMPANY ROSTER", "Choose one field hero. Send the others to work while you are away.", authored_status, authored_entries, "RETURN TO CAMP")
	authored_overlay.connect("action_requested", _on_roster_screen_action.bind(authored_overlay))
	authored_overlay.connect("back_requested", authored_overlay.queue_free)
	return
func _select_roster_hero(hero_id: String) -> void:
	selected_roster_hero_id = hero_id
	_show_camp_expeditions()

func _on_roster_screen_action(action_id: String, overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	if action_id.begins_with("hero:"):
		_select_roster_hero(action_id.trim_prefix("hero:"))
	elif action_id.begins_with("assign:"):
		_set_hero_assignment(selected_roster_hero_id, action_id.trim_prefix("assign:"))
	elif action_id == "make_active":
		_make_roster_hero_active(selected_roster_hero_id)
	elif action_id == "claim":
		_claim_roster_rewards()

func _set_hero_assignment(hero_id: String, assignment: String) -> void:
	_apply_offline_progress()
	var hero: Dictionary = Roster.hero_by_id(save.profile.get("heroes", []), hero_id)
	if hero.is_empty() or String(hero.get("assignment", "idle")) == "active":
		return
	hero.assignment = assignment
	hero.assignment_started = Time.get_unix_time_from_system()
	hero.last_seen = hero.assignment_started
	SaveService.save_data(save)
	_show_camp_expeditions()

func _make_roster_hero_active(hero_id: String) -> void:
	_apply_offline_progress()
	if Roster.set_active_hero(save.profile, hero_id):
		_sync_active_hero_fields()
		SaveService.save_data(save)
	_show_camp_expeditions()

func _claim_roster_rewards() -> void:
	_apply_offline_progress()
	var silver: int = 0
	var provisions: int = 0
	var xp: int = 0
	for hero_value: Variant in save.profile.get("heroes", []):
		var result: Dictionary = Roster.claim_hero(hero_value)
		silver += int(result.silver)
		provisions += int(result.provisions)
		xp += int(result.xp)
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	SaveService.save_data(save)
	_show_camp("Company work collected: %d silver, %d provisions, %d hero XP." % [silver, provisions, xp])

func _replace_camp_overlay_with_weapon_picker(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_weapon_picker()

func _show_inventory(message: String = "", requested_uid: String = "") -> void:
	screen = Screen.CAMP
	run_paused = true
	_play_music("camp")
	_clear_ui()
	ui_root = InventoryScreenScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_screen(ui_root)
	ui_root.z_index = 100
	_bind_inventory_screen(ui_root, message, requested_uid)
	return
func _find_inventory_item(uid: String) -> Dictionary:
	if uid.is_empty():
		return {}
	for item_value: Variant in save.profile.get("inventory", []):
		var item: Dictionary = item_value
		if String(item.get("uid", "")) == uid:
			return item
	return {}

func _equipment_modifier_text(item: Dictionary) -> String:
	var parts: PackedStringArray = []
	for modifier_value: Variant in item.get("modifiers", []):
		var modifier: Dictionary = modifier_value
		parts.append(_equipment_stat_text(String(modifier.stat), float(modifier.amount)))
	return "  |  ".join(parts)

func _equipment_stat_text(stat: String, amount: float) -> String:
	return GameContent.stat_text(stat, amount)

func _change_inventory_page(delta: int) -> void:
	inventory_page += delta
	selected_item_uid = ""
	_show_inventory()

func _equip_item(uid: String) -> void:
	var item: Dictionary = _find_inventory_item(uid)
	if item.is_empty():
		return
	var equipped: Dictionary = save.profile.get("equipped", {})
	equipped[String(item.slot)] = uid
	save.profile.equipped = equipped
	_sync_active_hero_equipment()
	SaveService.save_data(save)
	_recalculate_player_stats()
	_show_inventory("%s equipped." % String(item.name), uid)

func _show_dismantle_confirm(uid: String) -> void:
	var item: Dictionary = _find_inventory_item(uid)
	if item.is_empty() or ui_root == null:
		return
	var overlay := DismantleConfirmationScene.instantiate() as Control
	overlay.name = "DismantleConfirm"
	ui_controller.mount_modal(overlay)
	overlay.call("configure", "DISMANTLE %s?" % String(item.name).to_upper(), "This permanently turns the item into silver.", "KEEP ITEM", "DISMANTLE")
	overlay.connect("confirmed", _dismantle_item.bind(uid, overlay))
	overlay.connect("cancelled", overlay.queue_free)

func _dismantle_item(uid: String, overlay: Control) -> void:
	var inventory: Array = save.profile.get("inventory", [])
	var salvage_value: int = 0
	for item_index: int in inventory.size():
		var item: Dictionary = inventory[item_index]
		if String(item.get("uid", "")) != uid:
			continue
		salvage_value = int(GameContent.RARITIES[String(item.rarity)].salvage)
		inventory.remove_at(item_index)
		break
	var equipped: Dictionary = save.profile.get("equipped", {})
	for slot: String in equipped:
		if String(equipped[slot]) == uid:
			equipped[slot] = ""
	save.profile.inventory = inventory
	save.profile.equipped = equipped
	_sync_active_hero_equipment()
	save.profile.silver = int(save.profile.silver) + salvage_value
	selected_item_uid = ""
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_inventory("Equipment dismantled for %d silver." % salvage_value)

func _show_skill_tree(message: String = "", branch_index: int = -1) -> void:
	_show_training_tree_screen()
	return

func _show_training_tree_screen() -> void:
	var training_service := TrainingGroundsService.new(save.profile)
	if not training_service.tree_available():
		_show_camp("Construct the Training Grounds before opening the skill tree.")
		return
	screen = Screen.CAMP
	run_paused = true
	_reset_movement_input()
	_play_music("camp")
	_clear_ui()
	ui_root = ScreenHostScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_screen(ui_root)
	ui_root.z_index = 100
	_add_safe_area_band(ui_root)
	var tree_screen := TrainingTreeScreenScene.instantiate() as AshenTrainingTreeScreen
	tree_screen.name = "TrainingGroundsScreen"
	tree_screen.profile_changed.connect(func() -> void:
		SaveService.save_data(save)
		_sync_active_hero_fields()
	)
	tree_screen.closed.connect(_show_camp)
	ui_controller.mount_screen(tree_screen)
	tree_screen.apply_safe_area(safe_area_top)
	tree_screen.bind_profile(save.profile)

func _build_run_ui() -> void:
	_clear_ui()
	ui_root = ScreenHostScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_hud(ui_root)
	ui_root.z_index = 100
	_add_safe_area_band(ui_root)
	if run_camera_transition < 1.0:
		ui_root.modulate.a = 0.0
		var hud_fade: Tween = ui_root.create_tween()
		hud_fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hud_fade.tween_interval(0.12)
		hud_fade.tween_property(ui_root, "modulate:a", 1.0, 0.38)
	var live_hud := _add_live_hud("run")
	live_hud.bind_run(run_level, player_hp, player_max_hp, run_exploration_silver, run_exploration_provisions, floori(_current_dread()))
	health_bar = live_hud.get_node("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	hud_label = live_hud.get_node("SafeAreaTop/RunTop/HudLabel") as Label
	boss_label = live_hud.get_node("SafeAreaTop/RunTop/BossLabel") as Label
	objective_label = live_hud.get_node("SafeAreaTop/RunTop/ObjectiveLabel") as Label
	pause_button = live_hud.get_node("SafeAreaTop/RunTop/PauseButton") as Button
	pause_button.pressed.connect(_toggle_pause)
	skill_button = live_hud.get_node("RunActions/GuardStepButton") as Button
	skill_button.pressed.connect(_guard_step)
	expedition_interact_button = live_hud.get_node("RunActions/ExpeditionInteractButton") as Button
	expedition_interact_button.visible = false
	expedition_interact_button.disabled = true
	expedition_interact_button.pressed.connect(_interact_with_expedition)
	pause_label = live_hud.get_node("PauseLabel") as Label
	# Keep the authored panel and its message in the same state.  In
	# particular, a fresh run must start with the complete pause overlay hidden.
	live_hud.set_paused(run_paused)
	_update_hud()

func _toggle_pause() -> void:
	if choosing_upgrade:
		return
	run_paused = not run_paused
	pause_button.text = "GO" if run_paused else "II"
	pause_label.text = "EXPEDITION PAUSED\nProgress has been saved" if run_paused else ""
	if is_instance_valid(active_hud_layout):
		active_hud_layout.set_paused(run_paused)
	if run_paused:
		_snapshot_run()
		SaveService.save_data(save)

func _update_hud() -> void:
	if hud_label == null:
		return
	var field_phase: String = "BLACKTHORN MOOR  %s" % _format_time(run_elapsed)
	hud_label.text = "%s · SITES %d/%d · XP %d/%d · %d KILLS" % [field_phase, run_discoveries, exploration_points.size(), run_xp, next_xp, run_kills]
	if is_instance_valid(active_hud_layout):
		active_hud_layout.bind_run(run_level, player_hp, player_max_hp, run_exploration_silver, run_exploration_provisions, floori(_current_dread()))
	if health_bar != null:
		health_bar.max_value = player_max_hp
		health_bar.value = clampf(player_hp, 0.0, player_max_hp)
	if objective_label != null and GameContent.OBJECTIVES.has(objective_id):
		var objective: Dictionary = GameContent.OBJECTIVES[objective_id]
		var objective_state: String = "DONE" if objective_complete else "%d/%d" % [floori(objective_progress), ceili(float(objective.get("target", 1.0)))]
		var field_text: String = "OBJECTIVE: %s  %s\n%s" % [String(objective.name).to_upper(), objective_state, GameContent.reward_text(objective)]
		if not contract_id.is_empty() and GameContent.CONTRACTS.has(contract_id):
			var contract: Dictionary = GameContent.CONTRACTS[contract_id]
			var contract_state: String = "DONE" if contract_complete else "%d/%d" % [floori(contract_progress), ceili(contract_target)]
			field_text += "\nCONTRACT: %s  %s  %s" % [String(contract.name).to_upper(), contract_state, GameContent.reward_text(contract)]
		if run_discoveries >= 2:
			field_text += "\nRETURN ROUTE OPEN AT THE SOUTHERN MARKER"
		objective_label.text = field_text
	if skill_button != null:
		skill_button.text = "GUARD\nREADY" if guard_cooldown <= 0.0 else "GUARD\n%.1fs" % guard_cooldown
		skill_button.disabled = guard_cooldown > 0.0

func _build_results_ui() -> void:
	_clear_ui()
	ui_root = ResultsScreenScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_screen(ui_root)
	ui_root.z_index = 100
	var live_objective_result: Dictionary = GameContent.OBJECTIVES.get(String(result_data.get("objective", "")), {})
	var live_contract_result: Dictionary = GameContent.CONTRACTS.get(String(result_data.get("contract", "")), {})
	var live_objective_text: String = "OBJECTIVE: %s" % GameContent.reward_text(live_objective_result) if bool(result_data.get("objective_complete", false)) else "OBJECTIVE INCOMPLETE"
	var live_contract_text: String = "CONTRACT: %s" % GameContent.reward_text(live_contract_result) if bool(result_data.get("contract_complete", false)) else "NO CONTRACT REWARD"
	var live_doctrine_name: String = String(GameContent.DOCTRINES.get(String(result_data.get("doctrine", active_doctrine)), {}).get("name", active_doctrine))
	var live_curse_name: String = String(GameContent.CURSES.get(String(result_data.get("curse", active_curse)), {}).get("name", active_curse))
	var live_salvaged_count: int = int(result_data.get("salvaged_loot", 0))
	var live_banked: bool = bool(result_data.get("banked", false))
	var live_loot_text: String = "EQUIPMENT BANKED: %d%s" % [int(result_data.get("stored_loot", 0)), " - %d DISMANTLED" % live_salvaged_count if live_salvaged_count > 0 else ""] if live_banked else "UNSECURED EQUIPMENT LOST: %d" % int(result_data.get("lost_loot", 0))
	ui_root.call("bind_result", {
		"heading": "THE BARROW IS QUIET" if bool(result_data.victory) else ("THE COMPANY RETURNS" if bool(result_data.get("extracted", false)) else "THE COMPANY WITHDRAWS"),
		"stats": "Time %s\n%d enemies / %d elites / %d discoveries\nVeteran rating %d%%" % [_format_time(float(result_data.time)), int(result_data.kills), int(result_data.elites), int(result_data.get("discoveries", 0)), roundi(float(result_data.rating) * 100.0)],
		"objective": "%s\n%s" % [live_objective_text, live_contract_text],
		"doctrine": "%s / %s\nRelics carried: %d" % [live_doctrine_name.to_upper(), live_curse_name.to_upper(), relics.size()],
		"loot": live_loot_text,
		"rewards": "+%d SILVER     +%d PROVISIONS     +%d HERO XP\nBARROW KEYS BANKED: %d" % [int(result_data.silver), int(result_data.provisions), int(result_data.get("hero_xp", 0)), int(result_data.get("boss_keys", 0))],
	})
	ui_root.connect("march_again_requested", Callable(self, "_show_weapon_picker"))
	ui_root.connect("return_to_camp_requested", Callable(self, "_show_camp"))
	return

func _show_settings() -> void:
	screen = Screen.SETTINGS
	_clear_ui()
	ui_root = ScreenHostScene.instantiate() as Control
	ui_root.theme = theme_main
	ui_controller.mount_screen(ui_root)
	ui_root.z_index = 100
	var settings_screen := SettingsScreenScene.instantiate() as AshenSettingsScreen
	settings_screen.name = "SettingsScreen"
	ui_root.add_child(settings_screen)
	settings_screen.apply_safe_area(safe_area_top)
	settings_screen.set_values(save.settings, _gate_confirmations_enabled())
	settings_screen.close_requested.connect(_show_camp)
	settings_screen.music_slider.value_changed.connect(_setting_slider_changed.bind("music"))
	settings_screen.sfx_slider.value_changed.connect(_setting_slider_changed.bind("sfx"))
	settings_screen.effects_slider.value_changed.connect(_setting_slider_changed.bind("effect_density"))
	settings_screen.screen_shake_toggle.toggled.connect(_setting_toggle_changed.bind("screen_shake"))
	settings_screen.left_handed_toggle.toggled.connect(_setting_toggle_changed.bind("left_handed"))
	settings_screen.collision_debug_toggle.toggled.connect(_setting_toggle_changed.bind("collision_debug"))
	settings_screen.gate_confirmations_toggle.toggled.connect(_setting_toggle_changed.bind("gate_confirmations"))
	settings_screen.export_button.pressed.connect(_export_save.bind(settings_screen.save_text))
	settings_screen.import_button.pressed.connect(_import_save.bind(settings_screen.save_text))
	settings_screen.reload_button.pressed.connect(_reload_app)
	settings_screen.reset_button.pressed.connect(_show_reset_save_confirmation)
	status_label = settings_screen.status_label

func _bind_inventory_screen(inventory_screen: Control, message: String, requested_uid: String) -> void:
	var inventory: Array = save.profile.get("inventory", [])
	var capacity: int = GameContent.inventory_capacity(save.profile.get("skill_tree", {}))
	var equipped: Dictionary = save.profile.get("equipped", {})
	if not requested_uid.is_empty():
		selected_item_uid = requested_uid
	if _find_inventory_item(selected_item_uid).is_empty():
		selected_item_uid = String(inventory[0].uid) if not inventory.is_empty() else ""
	var per_page: int = 6
	var page_count: int = maxi(1, ceili(float(inventory.size()) / float(per_page)))
	inventory_page = clampi(inventory_page, 0, page_count - 1)
	var entries: Array[Dictionary] = []
	for slot: String in ["head", "body", "hands", "boots", "trinket"]:
		var equipped_item: Dictionary = _find_inventory_item(String(equipped.get(slot, "")))
		entries.append({"id": "select:%s" % String(equipped_item.get("uid", "")), "node_name": "EquipmentSlot_%s" % slot, "title": slot.to_upper(), "detail": "EMPTY" if equipped_item.is_empty() else String(equipped_item.name), "disabled": equipped_item.is_empty()})
	var start_index: int = inventory_page * per_page
	for item_index: int in range(start_index, mini(inventory.size(), start_index + per_page)):
		var item: Dictionary = inventory[item_index]
		var rarity: Dictionary = GameContent.RARITIES.get(String(item.get("rarity", "common")), GameContent.RARITIES.common)
		var equipped_mark: String = " [EQUIPPED]" if String(equipped.get(String(item.slot), "")) == String(item.uid) else ""
		entries.append({"id": "select:%s" % String(item.uid), "node_name": "InventoryItem_%s" % String(item.uid), "title": "%s%s" % [String(item.name).to_upper(), equipped_mark], "detail": "%s - %s" % [String(rarity.name).to_upper(), String(item.slot).to_upper()]})
	if inventory_page > 0:
		entries.append({"id": "page:-1", "node_name": "InventoryPreviousPage", "title": "PREVIOUS PAGE", "detail": "PAGE %d / %d" % [inventory_page + 1, page_count]})
	if inventory_page < page_count - 1:
		entries.append({"id": "page:1", "node_name": "InventoryNextPage", "title": "NEXT PAGE", "detail": "PAGE %d / %d" % [inventory_page + 1, page_count]})
	var selected: Dictionary = _find_inventory_item(selected_item_uid)
	var detail_text: String = "No equipment recovered yet. The first elite in every expedition carries a guaranteed item."
	if not selected.is_empty():
		var selected_rarity: Dictionary = GameContent.RARITIES[String(selected.rarity)]
		detail_text = "%s - %s\n%s\n%s" % [String(selected_rarity.name).to_upper(), String(selected.slot).to_upper(), String(GameContent.EQUIPMENT[String(selected.base_id)].description), _equipment_modifier_text(selected)]
		entries.append({"id": "equip:%s" % String(selected.uid), "node_name": "EquipItemButton", "title": "EQUIP", "detail": "Assign to the %s slot." % String(selected.slot).to_upper()})
		entries.append({"id": "dismantle:%s" % String(selected.uid), "node_name": "DismantleItemButton", "title": "DISMANTLE", "detail": "+%d SILVER" % int(selected_rarity.salvage)})
	if not message.is_empty():
		detail_text = "%s\n%s" % [message, detail_text]
	inventory_screen.call("bind_screen", "COMPANY EQUIPMENT", "%d / %d ITEMS - ELITE AND BOSS SPOILS" % [inventory.size(), capacity], detail_text, entries, "BACK TO CAMP")
	var panel := inventory_screen.find_child("Panel", true, false)
	if panel != null:
		panel.name = "InventoryPanel"
	var detail_label := inventory_screen.find_child("Status", true, false)
	if detail_label != null:
		detail_label.name = "EquipmentDetail"
	inventory_screen.connect("action_requested", _on_inventory_screen_action)
	inventory_screen.connect("back_requested", _show_camp)

func _on_inventory_screen_action(action_id: String) -> void:
	if action_id.begins_with("select:"):
		_show_inventory("", action_id.trim_prefix("select:"))
	elif action_id.begins_with("page:"):
		_change_inventory_page(int(action_id.trim_prefix("page:")))
	elif action_id.begins_with("equip:"):
		_equip_item(action_id.trim_prefix("equip:"))
	elif action_id.begins_with("dismantle:"):
		_show_dismantle_confirm(action_id.trim_prefix("dismantle:"))

func _setting_slider_changed(value: float, key: String) -> void:
	save.settings[key] = value
	_update_audio_volumes()
	SaveService.save_data(save)

func _setting_toggle_changed(value: bool, key: String) -> void:
	save.settings[key] = value
	SaveService.save_data(save)

func _reload_app() -> void:
	status_label.text = "Clearing the old build and downloading the latest one..."
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(async()=>{try{const registrations=await navigator.serviceWorker.getRegistrations();await Promise.all(registrations.map(r=>r.unregister()));const keys=await caches.keys();await Promise.all(keys.map(k=>caches.delete(k)));const base=new URL('.',location.href);const assets=['index.html','index.js','index.pck','index.wasm','index.service.worker.js'];await Promise.allSettled(assets.map(name=>fetch(new URL(name,base),{cache:'reload'})));}catch(e){}const u=new URL(location.href);u.searchParams.set('fresh',Date.now());location.replace(u.toString());})()")
	else:
		get_tree().reload_current_scene()

func _show_reset_save_confirmation() -> void:
	var overlay := ResetConfirmationScene.instantiate() as Control
	ui_controller.mount_modal(overlay)
	overlay.connect("cancelled", overlay.queue_free)
	overlay.connect("confirmed", _reset_game_progress.bind(overlay))

func _reset_game_progress(overlay: Control) -> void:
	var preserved_settings: Dictionary = save.get("settings", {}).duplicate(true)
	var fresh_save: Dictionary = SaveService.reset_data(preserved_settings)
	if fresh_save.is_empty():
		if is_instance_valid(overlay):
			overlay.queue_free()
		if is_instance_valid(status_label):
			status_label.text = "The save could not be reset."
		return
	for enemy: EnemyState in camp_wanderers:
		enemy_pool.append(enemy)
	camp_wanderers.clear()
	if is_instance_valid(overlay):
		overlay.queue_free()
	save = fresh_save
	_clear_run_state()
	result_data.clear()
	_sync_active_hero_fields()
	generated_region = RegionGeneratorService.generate_blackthorn(int(save.profile.get("region_seed", 41041)))
	_cache_region_blockers()
	_sync_structure_anchors()
	_configure_world()
	camp_uses_field_camera = false
	_update_audio_volumes()
	_show_camp("A new company begins.")

func _export_save(field: TextEdit) -> void:
	var code: String = SaveService.export_code(save)
	field.text = code
	field.select_all()
	DisplayServer.clipboard_set(code)
	status_label.text = "Backup shown above. Select and copy it."

func _import_save(field: TextEdit) -> void:
	var imported: Dictionary = SaveService.import_code(field.text)
	if imported.is_empty():
		status_label.text = "That backup code is not valid."
		return
	save = imported
	SaveService.save_data(save)
	status_label.text = "Backup restored. Return to camp to see it."

func _clear_ui() -> void:
	if is_instance_valid(ui_controller):
		ui_controller.clear_all()
	elif is_instance_valid(ui_root):
		ui_root.queue_free()
	ui_root = null
	hud_label = null
	objective_label = null
	boss_label = null
	pause_label = null
	skill_button = null
	pause_button = null
	status_label = null
	silver_value_label = null
	provisions_value_label = null
	health_bar = null
	active_hud_layout = null
	hud_layout_data = null
	camp_interact_button = null
	expedition_interact_button = null
