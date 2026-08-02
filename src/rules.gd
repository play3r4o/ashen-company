class_name GameRules
extends RefCounted

const GameContent = preload("res://src/content.gd")
const TrainingContent = preload("res://src/content/training_grounds_content.gd")

const RUN_SECONDS: float = 480.0

static func damage_after_armor(raw_damage: float, armor_fraction: float) -> float:
	return maxf(1.0, raw_damage * (1.0 - clampf(armor_fraction, 0.0, 0.75)))

## v3 combat uses armor rating with diminishing returns. The legacy helper
## above remains available for old equipment and old run snapshots.
static func damage_after_armor_rating(raw_damage: float, armor_rating: float, scaling_constant: float = 100.0) -> float:
	var reduction: float = 0.0
	if armor_rating > 0.0:
		reduction = clampf(armor_rating / (armor_rating + maxf(1.0, scaling_constant)), 0.0, 0.80)
	return maxf(1.0, raw_damage * (1.0 - reduction))

static func attack_speed_multiplier(bonus: float) -> float:
	return 1.0 + clampf(bonus, -0.75, 1.20)

static func attack_interval(base_interval: float, attack_speed_bonus: float) -> float:
	return maxf(0.05, base_interval / attack_speed_multiplier(attack_speed_bonus))

static func technique_cooldown(base_cooldown: float, cooldown_reduction: float, runebinder: bool = false) -> float:
	var cap: float = 0.50 if runebinder else 0.45
	return maxf(0.05, base_cooldown * (1.0 - clampf(cooldown_reduction, 0.0, cap)))

static func training_xp_for_expedition(dread: float, elite_kills: int, boss_cycles: int, objectives: int, survival_seconds: float, extracted: bool) -> int:
	var amount: int = 20
	amount += floori(clampf(minf(dread, 300.0) * 0.20, 0.0, 60.0))
	amount += mini(25, maxi(0, elite_kills) * 5)
	amount += maxi(0, boss_cycles) * 50
	amount += maxi(0, objectives) * 30
	amount += mini(25, floori(maxf(0.0, survival_seconds) / 120.0) * 5)
	return amount if extracted else floori(float(amount) * 0.35)

static func veteran_rating(survival_seconds: float, kills: int, elites: int, boss_defeated: bool) -> float:
	var survival_score: float = clampf(survival_seconds / RUN_SECONDS, 0.0, 1.0) * 0.45
	var kill_score: float = clampf(float(kills) / 450.0, 0.0, 1.0) * 0.25
	var elite_score: float = clampf(float(elites) / 2.0, 0.0, 1.0) * 0.10
	var boss_score: float = 0.20 if boss_defeated else 0.0
	return clampf(survival_score + kill_score + elite_score + boss_score, 0.25, 1.0)

static func offline_cap_hours(quartermaster_level: int) -> float:
	return 8.0 + (4.0 * clampf(float(quartermaster_level) / 3.0, 0.0, 1.0))

static func offline_reward(operation: String, elapsed_seconds: float, rating: float, quartermaster_level: int) -> Dictionary:
	var safe_elapsed: float = clampf(elapsed_seconds, 0.0, offline_cap_hours(quartermaster_level) * 3600.0)
	var hours: float = safe_elapsed / 3600.0
	var efficiency: float = lerpf(0.55, 1.0, clampf(rating, 0.25, 1.0))
	var quartermaster_bonus: float = 1.0 + float(quartermaster_level) * 0.08
	var result: Dictionary = {"silver": 0, "provisions": 0, "elapsed": safe_elapsed}
	if operation == "patrol":
		result.silver = floori(hours * 11.0 * efficiency * quartermaster_bonus)
	elif operation == "forage":
		result.provisions = floori(hours * 3.0 * efficiency * quartermaster_bonus)
	return result

static func mastery_available(weapon_id: String, weapon_rank: int, techniques: Dictionary, skill_tree: Dictionary = {}) -> bool:
	if not GameContent.WEAPONS.has(weapon_id) or weapon_rank < 5:
		return false
	var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
	var tree_allows: bool = skill_tree.is_empty() or GameContent.mastery_unlocked(weapon_id, skill_tree)
	return tree_allows and not String(weapon.mastery).is_empty() and int(techniques.get(String(weapon.technique), 0)) > 0

static func equipment_rarity(seed_value: int, boss_drop: bool, loot_bonus: float) -> String:
	var roll_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	roll_rng.seed = seed_value
	var roll: float = clampf(roll_rng.randf() + loot_bonus, 0.0, 1.25)
	if boss_drop and roll >= 0.88:
		return "unique"
	if boss_drop or roll >= 1.02:
		return "barrow"
	if roll >= 0.72:
		return "masterwork"
	if roll >= 0.32:
		return "proven"
	return "common"

static func generate_equipment(seed_value: int, boss_drop: bool, loot_bonus: float, uid: int) -> Dictionary:
	var roll_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	roll_rng.seed = seed_value
	var base_ids: Array = GameContent.EQUIPMENT.keys()
	var base_id: String = String(base_ids[roll_rng.randi_range(0, base_ids.size() - 1)])
	var base: Dictionary = GameContent.EQUIPMENT[base_id]
	var rarity_id: String = equipment_rarity(seed_value ^ 0x5f3759df, boss_drop, loot_bonus)
	var rarity: Dictionary = GameContent.RARITIES[rarity_id]
	var modifiers: Array[Dictionary] = []
	for base_stat: String in base.get("stats", {}):
		modifiers.append({"stat": base_stat, "amount": float(base.stats[base_stat]) * float(rarity.power)})
	var available_affixes: Array = GameContent.EQUIPMENT_AFFIXES.duplicate(true)
	var prefix: String = ""
	for affix_index: int in int(rarity.affixes):
		if available_affixes.is_empty():
			break
		var selected_index: int = roll_rng.randi_range(0, available_affixes.size() - 1)
		var affix: Dictionary = available_affixes.pop_at(selected_index)
		modifiers.append({"stat": String(affix.stat), "amount": float(affix.amount) * float(rarity.power)})
		if affix_index == 0:
			prefix = String(affix.name) + " "
	return {"uid": str(uid), "base_id": base_id, "name": prefix + String(base.name), "slot": String(base.slot), "rarity": rarity_id, "modifiers": modifiers}

static func validate_save(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var save: Dictionary = data
	var schema: int = int(save.get("schema_version", 0))
	if schema not in [2, 3]:
		return false
	if not save.get("profile", null) is Dictionary or not save.get("settings", null) is Dictionary:
		return false
	var profile: Dictionary = save.profile
	for key: String in ["silver", "provisions", "armory_level", "training_level", "quartermaster_level"]:
		if not profile.has(key) or not profile[key] is float and not profile[key] is int:
			return false
	if profile.has("blacksmith_level") and not profile.blacksmith_level is float and not profile.blacksmith_level is int:
		return false
	if profile.has("hall_level") and not profile.hall_level is float and not profile.hall_level is int:
		return false
	if profile.has("constructed_buildings"):
		if not profile.constructed_buildings is Array:
			return false
		for building: Variant in profile.constructed_buildings:
			if not building is String or not String(building) in ["veterans_hall", "campfire", "armory", "blacksmith", "quartermaster", "training"]:
				return false
	if profile.has("starting_class") and not GameContent.CLASSES.has(String(profile.starting_class)):
		return false
	if profile.has("starting_doctrine") and schema == 2 and not GameContent.DOCTRINES.has(String(profile.starting_doctrine)):
		return false
	if profile.has("starting_doctrine") and schema >= 3 and not String(profile.starting_doctrine).is_empty() and not TrainingContent.doctrines().has(String(profile.starting_doctrine)):
		return false
	if profile.has("starting_weapon"):
		if schema >= 3 and not TrainingContent.abilities().has(String(profile.starting_weapon)):
			return false
		if schema == 2 and not GameContent.WEAPONS.has(String(profile.starting_weapon)):
			return false
	if profile.has("starting_curse") and not GameContent.CURSES.has(String(profile.starting_curse)):
		return false
	if profile.has("inventory") and not profile.inventory is Array:
		return false
	if profile.has("equipped") and not profile.equipped is Dictionary:
		return false
	if not profile.get("heroes", null) is Array or Array(profile.heroes).size() < 4:
		return false
	if not profile.get("active_hero_id", null) is String:
		return false
	if not profile.get("unlocked_biomes", null) is Array:
		return false
	if schema >= 3:
		if not profile.get("training_nodes", null) is Dictionary:
			return false
		if not profile.get("training_points", 0) is int and not profile.get("training_points", 0) is float:
			return false
		if not profile.get("training_xp", 0) is int and not profile.get("training_xp", 0) is float:
			return false
		if int(profile.get("training_points", 0)) < 0 or int(profile.get("training_xp", 0)) < 0 or int(profile.get("training_xp", 0)) >= 100:
			return false
		if not profile.get("claimed_training_rewards", {}) is Dictionary or not profile.get("training_migration_complete", false) is bool:
			return false
		if not profile.get("expedition_arsenals", null) is Array:
			return false
		if not profile.get("selected_arsenal_id", "") is String:
			return false
		for arsenal_value: Variant in profile.expedition_arsenals:
			if not arsenal_value is Dictionary:
				return false
			var arsenal: Dictionary = arsenal_value
			for arsenal_key: String in ["id", "starting_weapon", "weapon_ids", "technique_ids", "doctrine_ids", "class_id"]:
				if not arsenal.has(arsenal_key):
					return false
			if not arsenal.id is String or not arsenal.starting_weapon is String or not arsenal.class_id is String:
				return false
			if not arsenal.weapon_ids is Array or not arsenal.technique_ids is Array or not arsenal.doctrine_ids is Array:
				return false
		for node_id: String in profile.training_nodes:
			if not TrainingContent.all_nodes().has(node_id):
				return false
	return true
