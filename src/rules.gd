class_name GameRules
extends RefCounted

const GameContent = preload("res://src/content.gd")

const RUN_SECONDS: float = 480.0

static func damage_after_armor(raw_damage: float, armor_fraction: float) -> float:
	return maxf(1.0, raw_damage * (1.0 - clampf(armor_fraction, 0.0, 0.75)))

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
	if int(save.get("schema_version", 0)) != 2:
		return false
	if not save.get("profile", null) is Dictionary or not save.get("settings", null) is Dictionary:
		return false
	var profile: Dictionary = save.profile
	for key: String in ["silver", "provisions", "armory_level", "training_level", "quartermaster_level"]:
		if not profile.has(key) or not profile[key] is float and not profile[key] is int:
			return false
	if profile.has("blacksmith_level") and not profile.blacksmith_level is float and not profile.blacksmith_level is int:
		return false
	if profile.has("starting_class") and not GameContent.CLASSES.has(String(profile.starting_class)):
		return false
	if profile.has("starting_doctrine") and not GameContent.DOCTRINES.has(String(profile.starting_doctrine)):
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
	return true
