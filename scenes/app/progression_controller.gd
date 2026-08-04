extends "res://scenes/combat/combat_runtime_controller.gd"
func _build_structure_definitions() -> void:
	camp_structure_definitions.clear()
	if not is_instance_valid(active_camp_scene):
		push_error("Cannot build camp interaction definitions without an authored camp scene")
		return
	for structure_value: Variant in _constructed_buildings():
		var structure_id: String = String(structure_value)
		var info: Dictionary = active_camp_scene.structure_info(structure_id)
		if info.is_empty():
			push_error("Constructed structure '%s' has no authored scene in camp tier %d" % [structure_id, _town_level()])
			continue
		var definition: StructureDefinition = StructureDefinitionResource.new()
		definition.id = structure_id
		definition.display_name = structure_id.replace("_", " ").capitalize()
		definition.menu_id = structure_id
		definition.anchor = Vector2(info.get("anchor", Vector2.ZERO))
		definition.footprint = info.get("footprint", PackedVector2Array())
		definition.interaction_polygon = info.get("interaction", PackedVector2Array())
		if definition.footprint.size() < 3:
			push_error("Authored structure '%s' is missing its CollisionPolygon2D footprint" % structure_id)
			continue
		if definition.interaction_polygon.size() < 3:
			push_error("Authored structure '%s' is missing its InteractionArea polygon" % structure_id)
			continue
		camp_structure_definitions[structure_id] = definition

func _active_hero() -> Dictionary:
	return Roster.active_hero(save.profile)

func _sync_active_hero_fields() -> void:
	var hero: Dictionary = _active_hero()
	if hero.is_empty():
		return
	save.profile.starting_class = String(hero.get("class_id", "warrior"))
	save.profile.equipped = hero.get("equipped", {}).duplicate(true)

func _sync_active_hero_equipment() -> void:
	var hero: Dictionary = _active_hero()
	if not hero.is_empty():
		hero.equipped = save.profile.get("equipped", {}).duplicate(true)

func _technique_total(stat: String) -> float:
	var total: float = 0.0
	for technique_id: String in techniques:
		if not runtime_techniques.has(technique_id):
			continue
		var definition: Dictionary = runtime_techniques[technique_id]
		var rank: int = clampi(int(techniques[technique_id]), 1, 5)
		var rank_stats: Array = definition.get("rank_stats", [])
		if not rank_stats.is_empty():
			# Canonical technique rank data belongs to that technique's cast. It is
			# consumed by _training_technique_progress() and must never leak into
			# every weapon or into the player's global projectile count.
			continue
		var stats: Dictionary = definition.get("stats", {})
		total += float(stats.get(stat, 0.0)) * rank
	return total

func _equipment_total(stat: String) -> float:
	var total: float = 0.0
	var smithing_bonus: float = 1.0 + float(save.profile.get("blacksmith_level", 0)) * 0.05
	var equipped: Dictionary = save.profile.get("equipped", {})
	var inventory: Array = save.profile.get("inventory", [])
	for slot: String in equipped:
		var uid: String = String(equipped[slot])
		if uid.is_empty():
			continue
		for item_value: Variant in inventory:
			var item: Dictionary = item_value
			if String(item.get("uid", "")) != uid:
				continue
			for modifier_value: Variant in item.get("modifiers", []):
				var modifier: Dictionary = modifier_value
				if String(modifier.get("stat", "")) == stat:
					var amount: float = float(modifier.get("amount", 0.0))
					total += amount * smithing_bonus if amount > 0.0 else amount
			break
	return total

func _doctrine_total(stat: String) -> float:
	var doctrine_ids: Array[String] = active_doctrines.duplicate()
	if doctrine_ids.is_empty() and not active_doctrine.is_empty():
		doctrine_ids.append(active_doctrine)
	var total: float = 0.0
	for doctrine_id: String in doctrine_ids:
		if TrainingContent.doctrines().has(doctrine_id):
			total += float(TrainingContent.doctrines()[doctrine_id].get("modifiers", {}).get(stat, 0.0))
		else:
			var doctrine: Dictionary = GameContent.DOCTRINES.get(doctrine_id, {})
			total += float(doctrine.get("stats", {}).get(stat, 0.0))
	return total

func _class_total(stat: String) -> float:
	var class_definition: Dictionary = GameContent.CLASSES.get(active_class, GameContent.CLASSES.warrior)
	var total: float = float(class_definition.get("stats", {}).get(stat, 0.0))
	var hero: Dictionary = _active_hero()
	var learned: Dictionary = hero.get("class_tree", {})
	for node_value: Variant in GameContent.CLASS_TREES.get(active_class, []):
		var node: Dictionary = node_value
		if bool(learned.get(String(node.id), false)):
			total += float(node.get("stats", {}).get(stat, 0.0))
	return total

func _relic_total(stat: String) -> float:
	var total: float = 0.0
	for relic_id: String in relics:
		var relic: Dictionary = GameContent.RELICS.get(relic_id, {})
		var stats: Dictionary = relic.get("stats", {})
		total += float(stats.get(stat, 0.0)) * int(relics[relic_id])
	return total

func _run_boon_total(stat: String) -> float:
	var total: float = 0.0
	for boon_id: String in run_boons:
		var rank: int = int(run_boons[boon_id])
		var per_rank: Dictionary = {"damage": 0.06, "attack_speed": 0.06, "health": 12.0, "armor": 5.0, "speed": 0.05, "area": 0.06, "duration": 0.06, "critical": 0.03, "critical_damage": 0.08, "projectile_speed": 0.08, "pickup": 12.0, "healing": 0.06}
		if boon_id == stat:
			total += float(per_rank.get(boon_id, 0.0)) * float(rank)
	return total

func _training_total(stat: String) -> float:
	return float(cached_training_modifiers.get(stat, 0.0))

func _refresh_training_modifier_cache() -> void:
	var training_service := TrainingGroundsService.new(save.profile)
	cached_training_modifiers = training_service.permanent_modifiers()

func _heal_player(amount: float, apply_modifiers: bool = true) -> void:
	if amount <= 0.0:
		return
	var multiplier: float = 1.0
	if apply_modifiers:
		multiplier += _training_total("healing") + _equipment_total("healing") + _run_boon_total("healing") + _doctrine_total("healing")
	player_hp = minf(player_max_hp, player_hp + amount * maxf(0.0, multiplier))

func _training_node_modifier(node_id: String, stat: String) -> float:
	if int(Dictionary(save.profile.get("training_nodes", {})).get(node_id, 0)) <= 0:
		return 0.0
	return float(Dictionary(TrainingContent.all_nodes().get(node_id, {}).get("stat_modifiers", {})).get(stat, 0.0))

func _curse_definition() -> Dictionary:
	return GameContent.CURSES.get(active_curse, GameContent.CURSES.none)

func _recalculate_player_stats() -> void:
	_refresh_training_modifier_cache()
	var training: int = int(save.profile.training_level)
	var training_fraction: float = float(training) / 5.0
	var doctrine_health: float = _doctrine_total("health")
	player_max_hp = 100.0 * (1.0 + training_fraction * 0.15 + doctrine_health + _training_total("health_multiplier")) + _technique_total("health") + _equipment_total("health") + _class_total("health") + _relic_total("health") + _run_boon_total("health") + _training_total("health")
	player_hp = minf(player_hp, player_max_hp)
	player_speed = 122.0 * (1.0 + training_fraction * 0.08 + _technique_total("speed") + _equipment_total("speed") + _class_total("speed") + _doctrine_total("speed") + _run_boon_total("speed") + _training_total("speed"))
	damage_multiplier = (1.0 + training_fraction * 0.15) * (1.0 + _technique_total("damage") + _equipment_total("damage") + _class_total("damage") + _run_boon_total("damage") + _training_total("damage"))
	cooldown_reduction = _technique_total("attack_speed") + _equipment_total("attack_speed") + _relic_total("attack_speed") + _run_boon_total("attack_speed") + _training_total("attack_speed")
	player_armor = _technique_total("armor") + _equipment_total("armor") + _run_boon_total("armor") + _doctrine_total("armor") + _training_total("armor")
	critical_chance = CombatStats.critical_chance(_technique_total("critical") + _equipment_total("critical") + _run_boon_total("critical") + _training_total("critical"))
	pickup_radius = 54.0 + _technique_total("pickup") + _equipment_total("pickup") + _run_boon_total("pickup")
	stagger_power = _technique_total("stagger") + _equipment_total("stagger")
	projectile_bonus = clampi(int(_technique_total("ranged_projectiles") + _relic_total("ranged_projectiles")), 0, 4)

func _show_upgrade_choices() -> void:
	_reset_movement_input()
	choosing_upgrade = true
	run_paused = true
	var overlay := LevelUpOverlayScene.instantiate() as Control
	ui_controller.mount_modal(overlay)
	var choices: Array[Dictionary] = _build_upgrade_choices()
	var display_choices: Array[Dictionary] = []
	for choice: Dictionary in choices:
		var display_choice: Dictionary = choice.duplicate(true)
		display_choice["display_stats"] = _upgrade_summary(choice)
		display_choices.append(display_choice)
	overlay.call("bind_choices", run_level, display_choices, run_rerolls)
	overlay.connect("choice_selected", _apply_upgrade.bind(overlay))
	overlay.connect("reroll_requested", _reroll_upgrade_choices.bind(overlay))

func _reroll_upgrade_choices(overlay: Control) -> void:
	if run_rerolls <= 0 or not choosing_upgrade:
		return
	# Reject the complete visible set so the next deterministic offer applies
	# the reduced-weight memory rule to every card, not just the card under the
	# cursor. The service also advances the deterministic offer index.
	var current_choices: Array[Dictionary] = _build_upgrade_choices()
	for choice: Dictionary in current_choices:
		var choice_id: String = String(choice.get("canonical_id", choice.get("id", "")))
		if not choice_id.is_empty() and choice_id not in recently_rejected_choices:
			recently_rejected_choices.append(choice_id)
		if not choice_id.is_empty():
			rejected_choice_levels[choice_id] = run_level
	run_rerolls -= 1
	var run_state: Dictionary = _training_offer_run_state()
	var reroll_result: Dictionary = UpgradeOfferService.reroll(run_state, save.profile, prepared_arsenal, current_choices, upgrade_offer_index)
	upgrade_offer_index = int(reroll_result.get("offer_index", upgrade_offer_index + 1))
	if is_instance_valid(overlay):
		overlay.queue_free()
	# Recreate the same authored panel with the new offer. This keeps the
	# scene-owned layout authoritative and avoids stale card signal bindings.
	call_deferred("_show_upgrade_choices")

func _upgrade_summary(choice: Dictionary) -> String:
	if choice.has("summary"):
		return String(choice.summary)
	if String(choice.type) != "technique":
		return "WEAPON FORM · AUTOMATIC ATTACK"
	var stat: String = String(choice.get("stat", ""))
	var amount: float = float(choice.get("amount", 0.0))
	match stat:
		"reach": return "MELEE REACH  +%d" % roundi(amount)
		"area": return "ARC WIDTH  +%d%%" % roundi(amount * 100.0)
		"pierce": return "PIERCING  +%d" % roundi(amount)
		"damage": return "ALL DAMAGE  +%d%%" % roundi(amount * 100.0)
		"melee_damage": return "MELEE DAMAGE  +%d%%" % roundi(amount * 100.0)
		"ranged_damage": return "RANGED DAMAGE  +%d%%" % roundi(amount * 100.0)
		"cooldown": return "ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"melee_cooldown": return "MELEE ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"ranged_cooldown": return "RANGED ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"health": return "MAX HEALTH  +%d" % roundi(amount)
		"armor": return "ARMOR  +%d%%" % roundi(amount * 100.0)
		"guard": return "GUARD STEP  +%d%% REDUCTION" % roundi(amount * 100.0)
		"recovery": return "HEALTH REGEN  +%d / 5s" % roundi(amount)
		"critical": return "CRITICAL CHANCE  +%d%%" % roundi(amount * 100.0)
		"speed": return "MOVEMENT  +%d%%" % roundi(amount * 100.0)
		"pickup": return "PICKUP REACH  +%d" % roundi(amount)
		"stagger": return "STAGGER DURATION  +%.2fs" % amount
		"projectiles": return "PROJECTILE COUNT  +%d" % roundi(amount)
		"arcane_projectiles": return "ARCANE PROJECTILES  +%d" % roundi(amount)
		"guard_blast": return "GUARD RIPOSTE  %d DAMAGE" % roundi(amount)
		"elite_damage": return "ELITE DAMAGE  +%d%%" % roundi(amount * 100.0)
		"second_wind": return "SECOND WIND  +%d HEALTH" % roundi(amount)
		"loot_luck": return "LOOT QUALITY  +%d%%" % roundi(amount * 100.0)
	return "FIELD TECHNIQUE"

func _weapon_stats_text(weapon_id: String) -> String:
	var weapon: Dictionary = runtime_weapons[weapon_id]
	var behavior: String = String(weapon.behavior)
	var shape_text: String
	match behavior:
		"thrust": shape_text = "RANGE %d  |  BLEED 3 x 18%%" % roundi(float(weapon.radius))
		"sweep": shape_text = "AREA %d  |  BLEED 3 x 18%%" % roundi(float(weapon.radius))
		"splash": shape_text = "3 STONES  |  48 DEG SPREAD  |  BLAST 42"
		"trap": shape_text = "AREA %d  |  DURATION 6.0s" % roundi(float(weapon.radius))
		"fan": shape_text = "3 KNIVES  |  BLEED 3 x 18%"
		"hex": shape_text = "BLAST 18  |  SCORCH 3 x 24%"
		_: shape_text = "PIERCING %d  |  PIN 1.25s" % int(weapon.pierce)
	return "DAMAGE %d  |  ATTACK EVERY %.2fs\n%s" % [roundi(float(weapon.damage)), float(weapon.cooldown), shape_text]

func _build_prepared_upgrade_choices() -> Array[Dictionary]:
	_prune_rejected_choice_memory()
	var run_state: Dictionary = _training_offer_run_state()
	var generated: Array[Dictionary] = UpgradeOfferService.generate(run_state, save.profile, prepared_arsenal, upgrade_offer_index)
	var result: Array[Dictionary] = []
	var seen_runtime_ids: Dictionary = {}
	var training_service := TrainingGroundsService.new(save.profile)
	for offer: Dictionary in generated:
		var offer_type: String = String(offer.get("type", "boon"))
		var canonical_id: String = String(offer.get("id", ""))
		var choice: Dictionary = offer.duplicate(true)
		if offer_type == "weapon":
			var runtime_id: String = _legacy_runtime_weapon_id(canonical_id)
			if seen_runtime_ids.has(runtime_id) or not runtime_weapons.has(runtime_id):
				continue
			seen_runtime_ids[runtime_id] = true
			var runtime_rank: int = int(weapons.get(runtime_id, 0))
			var weapon: Dictionary = runtime_weapons[runtime_id]
			if int(offer.get("rank", runtime_rank + 1)) >= 5:
				var school: String = TrainingContent.school_for_ability(canonical_id)
				if not training_service.mastery_unlocked(school):
					continue
				choice.type = "mastery"
				choice.name = String(weapon.get("mastery", "%s mastery" % weapon.name)).to_upper()
				choice.description = "School mastery transforms this weapon at rank five."
				choice.summary = _ability_rank_delta_text(canonical_id, 5)
			else:
				choice.id = runtime_id
				choice.canonical_id = canonical_id
				choice.name = "%s  %d > %d" % [String(weapon.name), runtime_rank, runtime_rank + 1]
				choice.description = String(TrainingContent.abilities().get(canonical_id, {}).get("ranks", [{}])[mini(runtime_rank, 4)].get("description", weapon.description))
				choice.summary = _ability_rank_delta_text(canonical_id, runtime_rank + 1)
		elif offer_type == "technique":
			var runtime_technique: String = _legacy_runtime_technique_id(canonical_id)
			if seen_runtime_ids.has(runtime_technique) or not runtime_techniques.has(runtime_technique):
				continue
			seen_runtime_ids[runtime_technique] = true
			var current_rank: int = int(techniques.get(runtime_technique, 0))
			choice.id = runtime_technique
			choice.canonical_id = canonical_id
			var canonical_definition: Dictionary = TrainingContent.abilities().get(canonical_id, {})
			if int(offer.get("rank", current_rank + 1)) >= 5:
				choice.type = "mastery"
				choice.mastery_kind = "technique"
				choice.name = "%s MASTERY" % String(canonical_definition.get("name", runtime_technique)).to_upper()
				choice.description = "School mastery transforms this technique at rank five."
				choice.summary = _ability_rank_delta_text(canonical_id, 5)
			else:
				choice.name = "%s  %d > %d" % [String(canonical_definition.get("name", runtime_technique)).to_upper(), current_rank, current_rank + 1]
				choice.description = String(canonical_definition.get("ranks", [{}])[mini(current_rank, 4)].get("description", runtime_techniques[runtime_technique].description))
				choice.summary = _ability_rank_delta_text(canonical_id, current_rank + 1)
		elif offer_type == "boon":
			choice.id = canonical_id
			choice.name = "BOON · %s  %d > %d" % [canonical_id.replace("_", " ").to_upper(), int(run_boons.get(canonical_id, 0)), int(offer.get("rank", 1))]
			choice.description = "A temporary expedition bonus. Does not consume an Arsenal slot."
			choice.summary = _run_boon_summary(canonical_id)
		if not result.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(choice.get("id", "")) and String(existing.get("type", "")) == String(choice.get("type", ""))):
			result.append(choice)
	if result.size() < 3:
		for boon_id: String in ["damage", "attack_speed", "health", "armor", "speed", "area", "duration", "critical", "critical_damage", "projectile_speed", "pickup", "healing"]:
			if int(run_boons.get(boon_id, 0)) >= 5:
				continue
			var boon_choice: Dictionary = {"type": "boon", "id": boon_id, "rank": int(run_boons.get(boon_id, 0)) + 1, "name": "BOON · %s" % boon_id.replace("_", " ").to_upper(), "description": "A temporary expedition bonus. Does not consume an Arsenal slot.", "summary": _run_boon_summary(boon_id)}
			if not result.any(func(existing: Dictionary) -> bool: return String(existing.id) == boon_id):
				result.append(boon_choice)
			if result.size() >= 3:
				break
	return result.slice(0, 3)

func _training_offer_run_state() -> Dictionary:
	var canonical_weapon_ranks: Dictionary = {}
	for canonical_id_value: Variant in prepared_arsenal.get("weapon_ids", []):
		var canonical_id: String = String(canonical_id_value)
		canonical_weapon_ranks[canonical_id] = int(weapons.get(_legacy_runtime_weapon_id(canonical_id), 0))
	var canonical_technique_ranks: Dictionary = {}
	for canonical_id_value: Variant in prepared_arsenal.get("technique_ids", []):
		var canonical_id: String = String(canonical_id_value)
		canonical_technique_ranks[canonical_id] = int(techniques.get(_legacy_runtime_technique_id(canonical_id), 0))
	return {
		"seed": run_seed,
		"level": run_level,
		"weapon_ranks": canonical_weapon_ranks,
		"technique_ranks": canonical_technique_ranks,
		"boon_ranks": run_boons,
		"recent_rejected_choices": recently_rejected_choices
	}

func _prune_rejected_choice_memory() -> void:
	for choice_id_value: Variant in rejected_choice_levels.keys().duplicate():
		var choice_id: String = String(choice_id_value)
		if run_level - int(rejected_choice_levels.get(choice_id, run_level)) > 2:
			rejected_choice_levels.erase(choice_id)
	recently_rejected_choices.assign(rejected_choice_levels.keys())

func _ability_rank_delta_text(ability_id: String, rank: int) -> String:
	var compiled: Dictionary = TrainingContent.compile_ability(ability_id, rank)
	var rank_stats: Dictionary = Dictionary(compiled.get("rank_stats", {}))
	if rank_stats.is_empty():
		return "RANK %d" % rank
	var cumulative_progress: Dictionary = _ability_progress(ability_id, rank)
	var cumulative_stats: Dictionary = Dictionary(cumulative_progress.get("stats", {}))
	var lines: Array[String] = ["RANK %d" % rank]
	var damage_multiplier: float = float(rank_stats.get("damage_multiplier", 1.0))
	if not is_equal_approx(damage_multiplier, 1.0):
		lines.append("DAMAGE  %+d%%" % roundi((damage_multiplier - 1.0) * 100.0))
	var interval: float = float(rank_stats.get("cooldown_or_interval", 0.0))
	if interval > 0.0:
		lines.append(("COOLDOWN  %.2fs" if String(compiled.get("category", "")) == "technique" else "ATTACK INTERVAL  %.2fs") % interval)
	var area_multiplier: float = float(rank_stats.get("area_multiplier", 1.0))
	if not is_equal_approx(area_multiplier, 1.0):
		lines.append("AREA  %+d%%" % roundi((area_multiplier - 1.0) * 100.0))
	var duration_multiplier: float = float(rank_stats.get("duration_multiplier", 1.0))
	if not is_equal_approx(duration_multiplier, 1.0):
		lines.append("DURATION  %+d%%" % roundi((duration_multiplier - 1.0) * 100.0))
	var projectile_count_value: int = int(cumulative_progress.get("projectile_count", rank_stats.get("projectile_count", 0)))
	var split_interval: int = int(cumulative_stats.get("split_interval", 0))
	var repeat_interval: int = int(cumulative_stats.get("repeat_interval", 0))
	var fork_interval: int = int(cumulative_stats.get("fork_interval", 0))
	var volley_interval: int = int(cumulative_stats.get("volley_interval", 0))
	var has_projectile_pattern: bool = split_interval > 0 or repeat_interval > 0 or fork_interval > 0 or volley_interval > 0
	if has_projectile_pattern:
		lines.append("NORMAL SHOT  1 PROJECTILE")
		if split_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [split_interval, projectile_count_value])
		if repeat_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [repeat_interval, projectile_count_value])
		if fork_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [fork_interval, projectile_count_value])
		if volley_interval > 0:
			var volley_count: int = int(cumulative_stats.get("volley_projectile_count", maxi(5, projectile_count_value)))
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [volley_interval, volley_count])
	elif projectile_count_value > 0:
		lines.append("PROJECTILES  %d" % projectile_count_value)
	var pierce_value: int = int(rank_stats.get("pierce", 0))
	if pierce_value > 0:
		lines.append("PIERCE  +%d" % pierce_value)
	for stat: String in Dictionary(rank_stats.get("stat_changes", {})):
		if stat in ["split_interval", "repeat_interval", "fork_interval", "volley_interval", "volley_projectile_count"]:
			continue
		var value: Variant = Dictionary(rank_stats.stat_changes)[stat]
		lines.append("%s  %s" % [stat.replace("_", " ").to_upper(), str(value)])
	return " · ".join(lines)

func _legacy_runtime_technique_id(canonical_id: String) -> String:
	# Canonical Training Grounds IDs are also the runtime IDs. Keeping this
	# function as a compatibility shim lets old snapshots still be read without
	# collapsing new weapons or techniques into the retired v2 definitions.
	return {
		"riposte_drill": "ground_slam", "deep_quiver": "rain_of_arrows", "marked_prey": "hunters_mark",
		"long_stride": "windstep", "second_wind": "smoke_veil", "scavengers_reach": "poison_flask",
		"ember_lore": "fire_nova", "field_dressing": "frost_ring", "twin_cast": "chain_lightning"
	}.get(canonical_id, canonical_id)

func _run_boon_summary(boon_id: String) -> String:
	match boon_id:
		"damage": return "ALL DAMAGE  +6%"
		"attack_speed": return "ATTACK SPEED  +6%"
		"health": return "MAX HEALTH  +12"
		"armor": return "ARMOR  +5"
		"speed": return "MOVEMENT  +5%"
		"area": return "ABILITY AREA  +6%"
		"duration": return "ABILITY DURATION  +6%"
		"critical": return "CRITICAL CHANCE  +3%"
		"critical_damage": return "CRITICAL DAMAGE  +8%"
		"projectile_speed": return "PROJECTILE SPEED  +8%"
		"pickup": return "PICKUP REACH  +12"
		"healing": return "HEALING  +6%"
	return "TEMPORARY FIELD BONUS"

func _build_upgrade_choices() -> Array[Dictionary]:
	if not prepared_arsenal.is_empty():
		var prepared_choices: Array[Dictionary] = _build_prepared_upgrade_choices()
		if not prepared_choices.is_empty():
			return prepared_choices
		# A prepared Arsenal is authoritative. If every prepared ability and boon
		# is already at its cap, do not fall back to the retired v2 pools; offer a
		# harmless recovery choice instead of leaking Woodsman's Axe, Caltrops,
		# Witchfire, or legacy generic techniques into a v3 expedition.
		return [{"type": "heal", "id": "rations", "name": "FIELD RATIONS", "description": "Restore 30 health immediately.", "summary": "+30 CURRENT HEALTH"}]
	var candidates: Array[Dictionary] = []
	for weapon_id: String in weapons:
		var rank: int = int(weapons[weapon_id])
		if GameRules.mastery_available(weapon_id, rank, techniques, save.profile.get("skill_tree", {})) and not bool(mastered.get(weapon_id, false)):
			var weapon: Dictionary = runtime_weapons[weapon_id]
			candidates.append({"type": "mastery", "id": weapon_id, "name": String(weapon.mastery).to_upper(), "description": "Complete this weapon's proven final form.", "summary": GameContent.stats_text(weapon.mastery_stats)})
		elif rank < 5:
			var weapon: Dictionary = runtime_weapons[weapon_id]
			var rank_stats: Dictionary = weapon.rank_bonuses[rank - 1]
			candidates.append({"type": "weapon", "id": weapon_id, "name": "%s  %d > %d" % [weapon.name, rank, rank + 1], "description": weapon.description, "summary": GameContent.stats_text(rank_stats)})
	if weapons.size() < 4:
		for weapon_id: String in GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})):
			if not weapons.has(weapon_id):
				var weapon: Dictionary = runtime_weapons[weapon_id]
				candidates.append({"type": "weapon", "id": weapon_id, "name": "TAKE %s" % String(weapon.name).to_upper(), "description": weapon.description, "summary": _weapon_stats_text(weapon_id)})
	for technique_id: String in techniques:
		var rank: int = int(techniques[technique_id])
		if rank < 3:
			var technique: Dictionary = runtime_techniques[technique_id]
			candidates.append({"type": "technique", "id": technique_id, "name": "%s  %d > %d" % [technique.name, rank, rank + 1], "description": technique.description, "stats": technique.stats, "summary": GameContent.stats_text(technique.stats)})
	if techniques.size() < 4:
		for technique_id: String in GameContent.unlocked_techniques(save.profile.get("skill_tree", {})):
			if not techniques.has(technique_id):
				var technique: Dictionary = runtime_techniques[technique_id]
				candidates.append({"type": "technique", "id": technique_id, "name": "LEARN %s" % String(technique.name).to_upper(), "description": technique.description, "stats": technique.stats, "summary": GameContent.stats_text(technique.stats)})
	var choices: Array[Dictionary] = []
	var choice_count: int = GameContent.level_choice_count(save.profile.get("skill_tree", {}))
	while not candidates.is_empty() and choices.size() < choice_count:
		var index: int = rng.randi_range(0, candidates.size() - 1)
		choices.append(candidates.pop_at(index))
	if choices.is_empty():
		choices.append({"type": "heal", "id": "rations", "name": "FIELD RATIONS", "description": "Restore 30 health immediately.", "summary": "+30 CURRENT HEALTH"})
	return choices

func _apply_upgrade(choice: Dictionary, overlay: Control) -> void:
	match String(choice.type):
		"weapon":
			var id: String = String(choice.id)
			weapons[id] = int(weapons.get(id, 0)) + 1
			weapon_timers[id] = 0.15
		"technique":
			var id: String = String(choice.id)
			techniques[id] = int(techniques.get(id, 0)) + 1
		"mastery":
			var mastery_kind: String = String(choice.get("mastery_kind", "weapon"))
			var runtime_id: String = String(choice.id)
			var canonical_id: String = String(choice.get("canonical_id", runtime_id))
			# A mastery card is the rank-five acquisition, not only a cosmetic
			# flag. Persist the rank in the run build so the rank-five data and
			# transformation are immediately active and survive snapshots.
			if mastery_kind == "technique":
				techniques[runtime_id] = maxi(5, int(techniques.get(runtime_id, 0)))
				mastered[canonical_id] = true
			else:
				weapons[runtime_id] = maxi(5, int(weapons.get(runtime_id, 0)))
				mastered[canonical_id] = true
		"boon":
			var boon_id: String = String(choice.id)
			run_boons[boon_id] = int(run_boons.get(boon_id, 0)) + 1
		"heal":
			_heal_player(30.0)
	upgrade_offer_index += 1
	_prune_rejected_choice_memory()
	_recalculate_player_stats()
	overlay.queue_free()
	_reset_movement_input()
	choosing_upgrade = false
	run_paused = false

func _reset_movement_input() -> void:
	joystick_touch_id = -1
	joystick_origin = Vector2.ZERO
	joystick_position = Vector2.ZERO
	joystick_vector = Vector2.ZERO
	player_move_vector = Vector2.ZERO
