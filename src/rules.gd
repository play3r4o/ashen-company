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

static func mastery_available(weapon_id: String, weapon_rank: int, techniques: Dictionary) -> bool:
	if not GameContent.WEAPONS.has(weapon_id) or weapon_rank < 5:
		return false
	var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
	return not String(weapon.mastery).is_empty() and int(techniques.get(String(weapon.technique), 0)) > 0

static func validate_save(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var save: Dictionary = data
	if int(save.get("schema_version", 0)) != 1:
		return false
	if not save.get("profile", null) is Dictionary or not save.get("settings", null) is Dictionary:
		return false
	var profile: Dictionary = save.profile
	for key: String in ["silver", "provisions", "armory_level", "training_level", "quartermaster_level"]:
		if not profile.has(key) or not profile[key] is float and not profile[key] is int:
			return false
	if profile.has("starting_class") and not GameContent.CLASSES.has(String(profile.starting_class)):
		return false
	if profile.has("starting_doctrine") and not GameContent.DOCTRINES.has(String(profile.starting_doctrine)):
		return false
	if profile.has("starting_curse") and not GameContent.CURSES.has(String(profile.starting_curse)):
		return false
	return true
