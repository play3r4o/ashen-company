extends "res://scenes/app/progression_controller.gd"
func _start_new_run(starting_weapon: String = "", from_gate: bool = false) -> void:
	var departure_position: Vector2 = camp_player_position
	var continuous_departure: bool = camp_uses_field_camera
	_clear_run_state()
	run_camera_transition = 1.0 if continuous_departure else (0.0 if from_gate else 1.0)
	run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	rng.seed = run_seed
	save.profile.region_seed = run_seed
	generated_region = RegionGeneratorService.generate_blackthorn(run_seed)
	_cache_region_blockers()
	var hero: Dictionary = _active_hero()
	active_class = String(hero.get("class_id", save.profile.get("starting_class", "warrior")))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrines.clear()
	active_doctrine = ""
	active_curse = String(save.profile.get("starting_curse", "none"))
	if not GameContent.CURSES.has(active_curse):
		active_curse = "none"
	relics.clear()
	contract_id = ""
	contract_progress = 0.0
	contract_target = 0.0
	contract_complete = false
	objective_id = _choose_objective()
	objective_progress = 0.0
	objective_complete = false
	boss_phase = 0
	var class_weapon: String = TrainingContent.starter_weapon_for_class(active_class)
	var chosen_weapon: String = starting_weapon if not starting_weapon.is_empty() else class_weapon
	if not TrainingContent.abilities().has(chosen_weapon):
		chosen_weapon = TrainingContent.starter_weapon_for_class(active_class)
	prepared_arsenal = _selected_arsenal()
	if prepared_arsenal.is_empty():
		prepared_arsenal = ArsenalService.default_arsenal(save.profile)
	if String(prepared_arsenal.get("starting_weapon", "")) != chosen_weapon:
		prepared_arsenal.starting_weapon = chosen_weapon
		var prepared_weapons: Array = Array(prepared_arsenal.get("weapon_ids", []))
		if chosen_weapon not in prepared_weapons:
			prepared_weapons.push_front(chosen_weapon)
		prepared_arsenal.weapon_ids = prepared_weapons.slice(0, ArsenalService.MAX_WEAPONS)
	for doctrine_value: Variant in Array(prepared_arsenal.get("doctrine_ids", [])):
		var doctrine_id: String = String(doctrine_value)
		if (GameContent.DOCTRINES.has(doctrine_id) or TrainingContent.doctrines().has(doctrine_id)) and doctrine_id not in active_doctrines:
			active_doctrines.append(doctrine_id)
	active_doctrine = active_doctrines[0] if not active_doctrines.is_empty() else String(save.profile.get("starting_doctrine", ""))
	if not GameContent.DOCTRINES.has(active_doctrine) and not TrainingContent.doctrines().has(active_doctrine):
		active_doctrine = ""
	run_rerolls = 1 if int(Dictionary(save.profile.get("training_nodes", {})).get("tactical_rethink", 0)) > 0 else 0
	upgrade_offer_index = 0
	recently_rejected_choices.clear()
	rejected_choice_levels.clear()
	var runtime_weapon: String = _legacy_runtime_weapon_id(chosen_weapon)
	if not runtime_weapons.has(runtime_weapon):
		runtime_weapon = class_weapon
	weapons[runtime_weapon] = 1
	weapon_timers[runtime_weapon] = 0.2
	_generate_exploration_points()
	_recalculate_player_stats()
	player_hp = player_max_hp
	var gate: Vector2 = _camp_gate_position()
	player_position = departure_position if from_gate else gate + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
	player_position.y = maxf(player_position.y, gate.y + (1.0 if from_gate else 14.0))
	# A run that starts at the painted gate may be reversed immediately. The
	# narrow crossing band below still prevents any position elsewhere in camp
	# from being mistaken for extraction.
	run_gate_entry_armed = from_gate or player_position.y > gate.y + 26.0
	_activate_camp_wanderers_for_run()
	camp_uses_field_camera = false
	save.active_run = {}
	SaveService.save_data(save)
	screen = Screen.RUN
	_play_music("moor")
	_build_run_ui()

func _show_weapon_picker(category_index: int = -1) -> void:
	_show_arsenal_screen(false)
	return

func _show_arsenal_screen(from_gate: bool = false) -> void:
	if not is_instance_valid(ui_root):
		_show_camp()
		return
	_reset_movement_input()
	run_paused = true
	var arsenal_screen := ArsenalScreenScene.instantiate() as AshenArsenalScreen
	arsenal_screen.name = "ArsenalScreen"
	arsenal_screen.z_index = 600
	arsenal_screen.closed.connect(_show_camp)
	arsenal_screen.expedition_requested.connect(_on_arsenal_expedition_requested.bind(from_gate))
	ui_controller.mount_screen(arsenal_screen)
	arsenal_screen.apply_safe_area(safe_area_top)
	arsenal_screen.bind_profile(save.profile)

func _on_arsenal_expedition_requested(arsenal: Dictionary, from_gate: bool = false) -> void:
	var validation: Dictionary = ArsenalService.validate(save.profile, arsenal)
	if not bool(validation.get("valid", false)):
		return
	save.profile.starting_class = String(arsenal.get("class_id", save.profile.get("starting_class", "warrior")))
	Roster.set_active_hero(save.profile, String(save.profile.starting_class))
	_sync_active_hero_fields()
	save.profile.starting_weapon = String(arsenal.get("starting_weapon", "sword"))
	var doctrine_ids: Array = arsenal.get("doctrine_ids", [])
	save.profile.starting_doctrine = String(doctrine_ids[0]) if not doctrine_ids.is_empty() else ""
	save.profile.expedition_arsenals = [arsenal.duplicate(true)]
	save.profile.selected_arsenal_id = String(arsenal.get("id", "arsenal_company_standard"))
	SaveService.save_data(save)
	_start_new_run(String(save.profile.starting_weapon), from_gate)

func _selected_arsenal() -> Dictionary:
	var selected_id: String = String(save.profile.get("selected_arsenal_id", ""))
	for arsenal_value: Variant in save.profile.get("expedition_arsenals", []):
		if arsenal_value is Dictionary and (selected_id.is_empty() or String(arsenal_value.get("id", "")) == selected_id):
			var candidate: Dictionary = arsenal_value.duplicate(true)
			var validation: Dictionary = ArsenalService.validate(save.profile, candidate)
			if bool(validation.get("valid", false)):
				return candidate
	return {}

func _legacy_runtime_weapon_id(canonical_id: String) -> String:
	match canonical_id:
		"axe": return "greatsword"
		"knives": return "daggers"
		"witchfire": return "staff"
		_: return canonical_id

func _register_training_runtime_content() -> void:
	# The combat runtime still owns pooled gameplay state and collision. These
	# definitions adapt the data-driven registry to that stable simulation
	# contract while preserving one distinct ID per weapon and technique. Visual
	# presentation is owned exclusively by authored projectile/effect scenes.
	for ability_id: String in TrainingContent.abilities():
		var data: Dictionary = TrainingContent.abilities()[ability_id]
		if String(data.get("category", "")) == "technique":
			# Replace legacy collisions (for example shield_wall) with the
			# canonical five-rank Training Grounds definition.
			runtime_techniques[ability_id] = _training_runtime_technique(data)
		else:
			# The old table contains spear, bow, and sling under the same IDs;
			# canonical data must win so their Bible stats are used at runtime.
			runtime_weapons[ability_id] = _training_runtime_weapon(data)

func _training_runtime_weapon(data: Dictionary) -> Dictionary:
	var ability_id: String = String(data.get("id", ""))
	var tags: Array = Array(data.get("tags", []))
	var base: Dictionary = Dictionary(data.get("base_stats", {}))
	var category: String = "ARCANE" if "arcane" in tags else ("MELEE" if "melee" in tags else "RANGED")
	var behavior: String = "line"
	if ability_id == "spear":
		behavior = "thrust"
	elif ability_id in ["sword", "greatsword", "daggers"]:
		behavior = "sweep"
	elif ability_id == "sling":
		behavior = "splash"
	elif ability_id == "throwing_knives":
		behavior = "fan"
	elif ability_id == "staff":
		behavior = "hex"
	elif ability_id in ["throwing_knives", "chakrams"]:
		behavior = "returning" if ability_id == "chakrams" else "fan"
	elif ability_id == "runic_orb":
		behavior = "orbit"
	var radius: float = 58.0 if category == "MELEE" else 5.0
	if ability_id == "spear":
		radius = 120.0
	elif ability_id == "greatsword":
		radius = 92.0
	elif ability_id == "daggers":
		radius = 54.0
	var rank_bonuses: Array[Dictionary] = []
	var ranks: Array = data.get("ranks", [])
	for rank_index: int in range(1, 5):
		var rank: Dictionary = Dictionary(ranks[rank_index]) if rank_index < ranks.size() else {}
		var changes: Dictionary = Dictionary(rank.get("stat_changes", {}))
		var bonus: Dictionary = {}
		var damage_multiplier: float = float(rank.get("damage_multiplier", 1.0))
		if not is_equal_approx(damage_multiplier, 1.0):
			bonus.damage = damage_multiplier - 1.0
		if int(rank.get("pierce", 0)) > 0:
			bonus.pierce = int(rank.get("pierce", 0))
		if float(rank.get("area_multiplier", 1.0)) != 1.0:
			bonus.melee_area = float(rank.get("area_multiplier", 1.0)) - 1.0 if category == "MELEE" else float(rank.get("area_multiplier", 1.0)) - 1.0
		for stat: String in ["attack_speed", "projectile_speed", "melee_range", "knockback", "bleed_damage"]:
			if changes.has(stat):
				bonus[stat] = float(changes[stat])
		if category == "MELEE" and changes.has("reach"):
			bonus.melee_range = float(changes.reach) * radius
		# Pattern projectile counts are cadence rules (every third/fifth attack),
		# not permanent global projectile bonuses. _fire_weapon consumes them with
		# the behavior flags and the per-weapon attack counter.
		rank_bonuses.append(bonus)
	var rank_five: Dictionary = Dictionary(ranks[4]) if ranks.size() > 4 else {}
	var mastery_stats: Dictionary = {}
	var mastery_changes: Dictionary = Dictionary(rank_five.get("stat_changes", {}))
	if float(rank_five.get("damage_multiplier", 1.0)) != 1.0:
		mastery_stats.damage = float(rank_five.get("damage_multiplier", 1.0)) - 1.0
	if category == "MELEE" and float(rank_five.get("area_multiplier", 1.0)) != 1.0:
		mastery_stats.melee_area = float(rank_five.get("area_multiplier", 1.0)) - 1.0
	return {
		"name": String(data.get("name", ability_id)), "category": category,
		"description": String(Dictionary(ranks[0]).get("description", "")) if not ranks.is_empty() else "",
		"cooldown": float(base.get("interval", 1.0)), "damage": float(base.get("normalized_power", 1.0)) * 20.0,
		"speed": 0.0 if category == "MELEE" else float(base.get("range", 300.0)), "radius": radius,
		"pierce": 2 if ability_id == "spear" else 0, "behavior": behavior,
		"color": TrainingContent.SCHOOL_COLORS.get(String(data.get("school", "vanguard")), Color.WHITE),
		"technique": "", "mastery": "%s Mastery" % String(data.get("name", ability_id)),
		"mastery_description": "Rank-five transformation unlocked by school mastery.", "mastery_stats": mastery_stats,
		"rank_bonuses": rank_bonuses, "homing": behavior == "hex"
	}

func _training_runtime_technique(data: Dictionary) -> Dictionary:
	var ranks: Array = data.get("ranks", [])
	var base: Dictionary = Dictionary(data.get("base_stats", {}))
	return {
		"name": String(data.get("name", data.get("id", "Technique"))),
		"description": String(Dictionary(ranks[0]).get("description", "")) if not ranks.is_empty() else "",
		# Canonical techniques are cast-scoped. Their rank data is consumed when
		# that specific technique fires and must never become a global player stat.
		"stats": {}, "cooldown": float(base.get("cooldown", 8.0)),
		"school": String(data.get("school", "")), "automatic": true,
		"rank_stats": ranks.duplicate(true)
	}

func _select_class(class_id: String, overlay: Control) -> void:
	if not GameContent.CLASSES.has(class_id):
		return
	Roster.set_active_hero(save.profile, class_id)
	_sync_active_hero_fields()
	save.profile.starting_weapon = String(GameContent.CLASSES[class_id].starting_weapon)
	weapon_picker_category = 2 if class_id == "mage" else (1 if class_id in ["hunter", "rogue"] else 0)
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_weapon_picker()

func _offer_contract() -> void:
	if choosing_upgrade or ui_root == null or (not contract_id.is_empty() and not contract_complete):
		return
	if contract_complete:
		contract_id = ""
	var ids: Array[String] = []
	for id: String in GameContent.CONTRACTS:
		ids.append(id)
	ids.shuffle()
	var authored_overlay := ContractChoiceOverlayScene.instantiate() as Control
	ui_controller.mount_modal(authored_overlay)
	var authored_entries: Array[Dictionary] = []
	for authored_index: int in mini(2, ids.size()):
		var authored_contract_id: String = ids[authored_index]
		var authored_contract: Dictionary = GameContent.CONTRACTS[authored_contract_id]
		authored_entries.append({"id": authored_contract_id, "node_name": "Contract_%s" % authored_contract_id, "title": String(authored_contract.name).to_upper(), "detail": "%s\n%s" % [String(authored_contract.description), GameContent.reward_text(authored_contract)]})
	authored_overlay.call("bind_screen", "A COMPANY CONTRACT", "Accept one task for an immediate expedition reward.", "", authored_entries, "DECLINE")
	authored_overlay.connect("action_requested", _accept_contract.bind(authored_overlay))
	authored_overlay.connect("back_requested", _decline_contract.bind(authored_overlay))
	choosing_upgrade = true
	run_paused = true
	_reset_movement_input()
	return
func _accept_contract(selected_id: String, overlay: Control) -> void:
	contract_id = selected_id
	contract_progress = 0.0
	var contract: Dictionary = GameContent.CONTRACTS[selected_id]
	contract_target = float(contract.get("target", contract.get("duration", 1.0)))
	contract_complete = false
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _decline_contract(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _show_relic_choices() -> void:
	if choosing_upgrade or ui_root == null:
		return
	var available: Array[String] = []
	for relic_id: String in GameContent.RELICS:
		if not relics.has(relic_id):
			available.append(relic_id)
	available.shuffle()
	if available.is_empty():
		return
	var overlay := RelicChoiceOverlayScene.instantiate() as Control
	ui_controller.mount_modal(overlay)
	var entries: Array[Dictionary] = []
	for index: int in mini(3, available.size()):
		var relic_id: String = available[index]
		var relic: Dictionary = GameContent.RELICS[relic_id]
		entries.append({"id": relic_id, "name": relic.name, "description": relic.description, "stats": GameContent.stats_text(relic.stats)})
	overlay.call("bind_relics", entries)
	overlay.connect("relic_selected", _claim_relic.bind(overlay))
	choosing_upgrade = true
	run_paused = true
	_reset_movement_input()

func _claim_relic(relic_id: String, overlay: Control) -> void:
	relics[relic_id] = int(relics.get(relic_id, 0)) + 1
	_recalculate_player_stats()
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _clear_run_state() -> void:
	for enemy: EnemyState in enemies:
		enemy_pool.append(enemy)
	for projectile: ProjectileState in projectiles:
		projectile_pool.append(projectile)
	for pickup: PickupState in pickups:
		pickup_pool.append(pickup)
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	traps.clear()
	hazards.clear()
	float_texts.clear()
	effects.clear()
	weapons.clear()
	techniques.clear()
	mastered.clear()
	run_boons.clear()
	combat_statuses.clear()
	environment_states.clear()
	weapon_attack_counts.clear()
	elemental_echo_cooldowns.clear()
	elemental_conduit_cooldowns.clear()
	volatile_mixture_cooldowns.clear()
	repeated_hit_counts.clear()
	prepared_arsenal.clear()
	run_rerolls = 0
	upgrade_offer_index = 0
	recently_rejected_choices.clear()
	rejected_choice_levels.clear()
	technique_timers.clear()
	run_loot.clear()
	weapon_timers.clear()
	exploration_points.clear()
	player_position = _camp_gate_position() + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
	run_elapsed = 0.0
	run_level = 1
	run_xp = 0
	next_xp = 14
	run_kills = 0
	run_elites = 0
	run_score = 0
	boss_spawned = false
	boss_defeated = false
	elite_one_spawned = false
	elite_two_spawned = false
	active_doctrine = ""
	active_doctrines.clear()
	active_curse = "none"
	relics.clear()
	contract_id = ""
	contract_progress = 0.0
	contract_target = 0.0
	contract_complete = false
	objective_id = ""
	objective_progress = 0.0
	objective_complete = false
	boss_phase = 0
	boss_cycle_spawned = 0
	run_bosses_defeated = 0
	run_boss_keys = 0
	run_paused = false
	choosing_upgrade = false
	run_gate_entry_armed = false
	autosave_timer = 0.0
	spawn_accumulator = 0.0
	guard_cooldown = 0.0
	guard_timer = 0.0
	guard_empowered = false
	player_barrier = 0.0
	time_since_player_damage = 0.0
	stationary_time = 0.0
	stationary_anchor = Vector2.ZERO
	recent_movement_distance = 0.0
	post_mobility_timer = 0.0
	war_cry_timer = 0.0
	war_cry_attack_speed = 0.0
	movement_burst_timer = 0.0
	vanishing_step_cooldown = 0.0
	running_shot_cooldown = 0.0
	toxic_blood_cooldown = 0.0
	resonant_guard_cooldown = 0.0
	technique_damage_reduction_timer = 0.0
	static_field_timer = 1.0
	blade_hit_count = 0
	bloodbound_heal_window = 0.0
	bloodbound_healed = 0.0
	duelist_momentum = 0
	duelist_last_category = ""
	next_ranged_projectiles = 0
	second_wind_used = false
	joystick_touch_id = -1
	joystick_vector = Vector2.ZERO
	player_move_vector = Vector2.ZERO
	next_enemy_uid = 1
	run_dread_bonus = 0.0
	run_discoveries = 0
	run_exploration_silver = 0
	run_exploration_provisions = 0
	nearby_exploration_index = -1
	run_camera_transition = 1.0

func _finish_run(victory: bool, extracted: bool = false) -> void:
	if screen != Screen.RUN:
		return
	run_paused = true
	var curse_reward: float = float(_curse_definition().get("reward", 1.0))
	var silver: int = floori((float(run_kills) / 10.0 + run_elites * 10.0 + (60 if victory else 0)) * curse_reward)
	var provisions: int = floori((run_elapsed / 30.0 + (20 if victory else 0)) * curse_reward)
	silver += run_exploration_silver
	provisions += run_exploration_provisions
	if active_curse == "thin_rations":
		provisions += 8 if victory else 0
	if objective_complete and GameContent.OBJECTIVES.has(objective_id):
		var objective_reward: Dictionary = GameContent.OBJECTIVES[objective_id]
		silver += int(objective_reward.get("silver", 0))
		provisions += int(objective_reward.get("provisions", 0))
	if contract_complete and GameContent.CONTRACTS.has(contract_id):
		var contract_reward: Dictionary = GameContent.CONTRACTS[contract_id]
		silver += int(contract_reward.get("silver", 0))
		provisions += int(contract_reward.get("provisions", 0))
	var banked: bool = victory or extracted
	var loot_result: Dictionary = _store_run_loot() if banked else {"stored": 0, "salvaged": 0, "salvaged_silver": 0}
	silver = silver + int(loot_result.salvaged_silver) if banked else 0
	provisions = provisions if banked else 0
	var rating: float = GameRules.veteran_rating(run_elapsed, run_kills, run_elites, victory)
	var hero: Dictionary = _active_hero()
	var hero_xp: int = maxi(1, floori(float(run_kills) * 0.35 + float(run_elites) * 8.0 + float(run_bosses_defeated) * 35.0))
	var hero_levels: int = Roster.grant_xp(hero, hero_xp)
	var training_service := TrainingGroundsService.new(save.profile)
	var training_xp: int = training_service.expedition_training_xp(_current_dread(), run_elites, run_bosses_defeated, 1 if objective_complete else 0, run_elapsed, banked)
	var training_reward: Dictionary = training_service.grant_training_xp(training_xp, "victory" if victory else ("extraction" if extracted else "defeat"))
	var one_time_training_points: int = 0
	if victory:
		one_time_training_points += int(training_service.grant_one_time_points("blackthorn_moor_boss_first", 5, "boss").get("points", 0))
	if objective_complete:
		one_time_training_points += int(training_service.grant_one_time_points("blackthorn_moor_objective_%s" % objective_id, 3, "objective").get("points", 0))
	var keys_banked: int = run_boss_keys if banked else 0
	result_data = {"victory": victory, "extracted": extracted, "banked": banked, "silver": silver, "provisions": provisions, "rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "discoveries": run_discoveries, "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete, "class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true), "loot": run_loot.duplicate(true), "stored_loot": int(loot_result.stored), "salvaged_loot": int(loot_result.salvaged), "lost_loot": 0 if banked else run_loot.size(), "boss_keys": keys_banked, "hero_xp": hero_xp, "hero_levels": hero_levels, "training_xp": training_xp, "training_points_gained": int(training_reward.get("points", 0)) + one_time_training_points, "training_xp_remaining": int(training_reward.get("remaining_xp", 0))}
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	if keys_banked > 0:
		var biome_keys: Dictionary = save.profile.get("biome_keys", {})
		biome_keys.barrows_key = int(biome_keys.get("barrows_key", 0)) + keys_banked
		save.profile.biome_keys = biome_keys
	var current_veteran: Dictionary = save.profile.veteran
	if current_veteran.is_empty() or rating > float(current_veteran.get("rating", 0.0)):
		save.profile.veteran = {"rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "boss": victory, "weapons": weapons.duplicate(true), "techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true), "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete}
	var campaign_flags: Dictionary = save.profile.get("campaign_flags", {})
	if objective_complete:
		campaign_flags["objective_%s" % objective_id] = true
	if victory:
		campaign_flags["barrow_knight_defeated"] = true
	if active_curse != "none":
		campaign_flags["cursed_expeditions"] = true
	if run_discoveries > 0:
		campaign_flags["moor_discoveries"] = int(campaign_flags.get("moor_discoveries", 0)) + run_discoveries
	save.profile.campaign_flags = campaign_flags
	save.active_run = {}
	camp_player_position = _camp_gate_position() + Vector2(0.0, -2.0)
	_update_last_seen()
	SaveService.save_data(save)
	if extracted:
		_handoff_run_enemies_to_camp()
		# Preserve the exact field framing for the first camp frame. The anchor
		# is a camera continuity value, not a UI coordinate, so allowing it to be
		# slightly beyond the usual portrait comfort range prevents a visible
		# snap when the town HUD takes over.
		camp_camera_anchor_x = (camp_player_position.x - camera_offset.x) / maxf(1.0, size.x)
		camp_camera_anchor_y = (camp_player_position.y - camera_offset.y) / maxf(1.0, size.y)
		var return_message: String = "Banked %d silver, %d provisions and %d equipment." % [silver, provisions, int(loot_result.stored)]
		_show_camp(return_message, true)
		return
	camera_offset = camp_world_origin
	screen = Screen.RESULTS
	_build_results_ui()

func _store_run_loot() -> Dictionary:
	var inventory: Array = save.profile.get("inventory", [])
	var capacity: int = GameContent.inventory_capacity(save.profile.get("skill_tree", {}))
	var stored: int = 0
	var salvaged: int = 0
	var salvaged_silver: int = 0
	for item_value: Variant in run_loot:
		var item: Dictionary = item_value
		if inventory.size() < capacity:
			inventory.append(item.duplicate(true))
			stored += 1
		else:
			var rarity: Dictionary = GameContent.RARITIES.get(String(item.get("rarity", "common")), GameContent.RARITIES.common)
			salvaged += 1
			salvaged_silver += int(rarity.salvage)
	save.profile.inventory = inventory
	return {"stored": stored, "salvaged": salvaged, "salvaged_silver": salvaged_silver}

func _snapshot_run() -> void:
	if screen != Screen.RUN:
		return
	var discovered_points: Array[String] = []
	for point: ExplorationPoint in exploration_points:
		if point.discovered:
			discovered_points.append(point.id)
	save.active_run = {
		"world_map": true,
		"seed": run_seed, "rng_state": rng.state, "elapsed": run_elapsed, "hp": player_hp, "max_hp": player_max_hp,
		"class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true),
		"prepared_arsenal": prepared_arsenal.duplicate(true), "run_boons": run_boons.duplicate(true), "rerolls_remaining": run_rerolls,
		"upgrade_offer_index": upgrade_offer_index, "recently_rejected_choices": recently_rejected_choices.duplicate(), "rejected_choice_levels": rejected_choice_levels.duplicate(true),
		"position": [player_position.x, player_position.y], "level": run_level, "xp": run_xp, "next_xp": next_xp,
		"kills": run_kills, "elites": run_elites, "score": run_score, "weapons": weapons.duplicate(true),
		"techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated, "elite_one": elite_one_spawned, "elite_two": elite_two_spawned, "boss_phase": boss_phase,
		"boss_cycle_spawned": boss_cycle_spawned, "bosses_defeated": run_bosses_defeated, "boss_keys": run_boss_keys,
		"hero_id": String(save.profile.get("active_hero_id", "warrior")), "biome": "blackthorn_moor",
		"objective": objective_id, "objective_progress": objective_progress, "objective_complete": objective_complete,
		"contract": contract_id, "contract_progress": contract_progress, "contract_target": contract_target, "contract_complete": contract_complete,
		"run_loot": run_loot.duplicate(true), "second_wind_used": second_wind_used,
		"dread_bonus": run_dread_bonus, "discoveries": run_discoveries,
		"exploration_silver": run_exploration_silver, "exploration_provisions": run_exploration_provisions,
		"discovered_points": discovered_points
	}
	_update_last_seen()

func _resume_run() -> void:
	var snapshot: Dictionary = save.active_run
	if snapshot.is_empty():
		_start_new_run()
		return
	_clear_run_state()
	run_seed = int(snapshot.get("seed", 1))
	rng.seed = run_seed
	rng.state = int(snapshot.get("rng_state", rng.state))
	generated_region = RegionGeneratorService.generate_blackthorn(run_seed)
	_cache_region_blockers()
	Roster.set_active_hero(save.profile, String(snapshot.get("hero_id", save.profile.get("active_hero_id", "warrior"))))
	_sync_active_hero_fields()
	active_class = String(snapshot.get("class", save.profile.get("starting_class", "warrior")))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrines.clear()
	for doctrine_value: Variant in Array(snapshot.get("doctrines", [])):
		var doctrine_id: String = String(doctrine_value)
		if (GameContent.DOCTRINES.has(doctrine_id) or TrainingContent.doctrines().has(doctrine_id)) and doctrine_id not in active_doctrines:
			active_doctrines.append(doctrine_id)
	active_doctrine = String(snapshot.get("doctrine", active_doctrines[0] if not active_doctrines.is_empty() else save.profile.get("starting_doctrine", "")))
	if active_doctrines.is_empty() and not active_doctrine.is_empty():
		active_doctrines.append(active_doctrine)
	if not GameContent.DOCTRINES.has(active_doctrine) and not TrainingContent.doctrines().has(active_doctrine):
		active_doctrine = ""
	active_curse = String(snapshot.get("curse", save.profile.get("starting_curse", "none")))
	if not GameContent.CURSES.has(active_curse):
		active_curse = "none"
	relics = snapshot.get("relics", {}).duplicate(true)
	run_elapsed = maxf(0.0, float(snapshot.get("elapsed", 0.0)))
	player_hp = float(snapshot.get("hp", 100.0))
	var position_data: Array = snapshot.get("position", [_camp_gate_position().x, _camp_gate_position().y + FIELD_START_DISTANCE + 12.0])
	if bool(snapshot.get("world_map", false)):
		player_position = Vector2(float(position_data[0]), float(position_data[1]))
	else:
		# Old snapshots used screen coordinates. Resume them just beyond the same
		# physical gate instead of placing the player inside the rebuilt town.
		player_position = _camp_gate_position() + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
	run_level = int(snapshot.get("level", 1))
	run_xp = int(snapshot.get("xp", 0))
	next_xp = int(snapshot.get("next_xp", 14))
	run_kills = int(snapshot.get("kills", 0))
	run_elites = int(snapshot.get("elites", 0))
	run_score = int(snapshot.get("score", 0))
	weapons = snapshot.get("weapons", {"spear": 1}).duplicate(true)
	techniques = snapshot.get("techniques", {}).duplicate(true)
	mastered = snapshot.get("mastered", {}).duplicate(true)
	prepared_arsenal = snapshot.get("prepared_arsenal", _selected_arsenal()).duplicate(true)
	run_boons = snapshot.get("run_boons", {}).duplicate(true)
	run_rerolls = int(snapshot.get("rerolls_remaining", 0))
	upgrade_offer_index = int(snapshot.get("upgrade_offer_index", 0))
	recently_rejected_choices.assign(snapshot.get("recently_rejected_choices", []))
	rejected_choice_levels = Dictionary(snapshot.get("rejected_choice_levels", {})).duplicate(true)
	if rejected_choice_levels.is_empty():
		for rejected_id: String in recently_rejected_choices:
			rejected_choice_levels[rejected_id] = run_level
	boss_spawned = bool(snapshot.get("boss_spawned", false))
	boss_defeated = bool(snapshot.get("boss_defeated", false))
	elite_one_spawned = bool(snapshot.get("elite_one", run_elapsed >= 120.0))
	elite_two_spawned = bool(snapshot.get("elite_two", run_elapsed >= 300.0))
	boss_phase = int(snapshot.get("boss_phase", 0))
	boss_cycle_spawned = int(snapshot.get("boss_cycle_spawned", Expedition.boss_cycle_for_dread(_current_dread())))
	run_bosses_defeated = int(snapshot.get("bosses_defeated", 0))
	run_boss_keys = int(snapshot.get("boss_keys", 0))
	objective_id = String(snapshot.get("objective", _choose_objective()))
	objective_progress = float(snapshot.get("objective_progress", 0.0))
	objective_complete = bool(snapshot.get("objective_complete", false))
	contract_id = String(snapshot.get("contract", ""))
	contract_progress = float(snapshot.get("contract_progress", 0.0))
	contract_target = float(snapshot.get("contract_target", 0.0))
	contract_complete = bool(snapshot.get("contract_complete", false))
	run_loot.assign(snapshot.get("run_loot", []))
	second_wind_used = bool(snapshot.get("second_wind_used", false))
	run_dread_bonus = float(snapshot.get("dread_bonus", 0.0))
	run_discoveries = int(snapshot.get("discoveries", 0))
	run_exploration_silver = int(snapshot.get("exploration_silver", 0))
	run_exploration_provisions = int(snapshot.get("exploration_provisions", 0))
	_generate_exploration_points()
	var discovered_points: Array = snapshot.get("discovered_points", [])
	for point: ExplorationPoint in exploration_points:
		point.discovered = discovered_points.has(point.id)
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = rng.randf_range(0.1, 0.5)
	_recalculate_player_stats()
	player_hp = minf(player_hp, player_max_hp)
	player_position.x = clampf(player_position.x, 18.0, world_size.x - 18.0)
	player_position.y = clampf(player_position.y, _camp_gate_position().y + 14.0, world_size.y - 22.0)
	# Resumed runs also begin at a valid field position, so returning straight
	# to the gate remains an intentional, immediate crossing.
	run_gate_entry_armed = true
	run_camera_transition = 1.0
	_update_world_camera(player_position, false, true)
	for index: int in mini(24, 6 + floori(run_elapsed / 25.0)):
		_spawn_enemy(_choose_wave_enemy(), false)
	_activate_camp_wanderers_for_run()
	if boss_spawned and not boss_defeated:
		_spawn_enemy("barrow_knight", true)
	screen = Screen.RUN
	run_paused = false
	_build_run_ui()

func _apply_offline_progress() -> void:
	var now: float = Time.get_unix_time_from_system()
	Roster.apply_offline(save.profile, now)
	SaveService.save_data(save)

func _update_last_seen() -> void:
	var expedition: Dictionary = save.profile.expedition
	expedition.last_seen = Time.get_unix_time_from_system()
	save.profile.expedition = expedition
