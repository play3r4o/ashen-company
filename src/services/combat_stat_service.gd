class_name CombatStatService
extends RefCounted

const CRITICAL_CHANCE_BASE: float = 0.05
const CRITICAL_CHANCE_CAP: float = 0.60
const CRITICAL_MULTIPLIER_BASE: float = 1.50
const PERMANENT_ATTACK_SPEED_CAP: float = 0.60
const COMBINED_ATTACK_SPEED_CAP: float = 1.20
const TECHNIQUE_COOLDOWN_CAP: float = 0.45
const RUNEBINDER_COOLDOWN_CAP: float = 0.50
const EVASION_CAP: float = 0.15
const ARMOR_REDUCTION_CAP: float = 0.80

static func attack_interval(base_interval: float, attack_speed_bonus: float, temporary_bonus: float = 0.0) -> float:
	var permanent: float = clampf(attack_speed_bonus, -0.90, PERMANENT_ATTACK_SPEED_CAP)
	var combined: float = clampf(permanent + temporary_bonus, -0.90, COMBINED_ATTACK_SPEED_CAP)
	return maxf(0.01, base_interval / (1.0 + combined))

static func technique_cooldown(base_cooldown: float, cooldown_reduction: float, runebinder: bool = false) -> float:
	var cap: float = RUNEBINDER_COOLDOWN_CAP if runebinder else TECHNIQUE_COOLDOWN_CAP
	return maxf(0.05, base_cooldown * (1.0 - clampf(cooldown_reduction, -1.0, cap)))

static func armor_reduction(armor: float) -> float:
	return clampf(armor / (armor + 100.0), 0.0, ARMOR_REDUCTION_CAP) if armor > 0.0 else 0.0

static func damage_after_armor(raw_damage: float, armor: float) -> float:
	return maxf(1.0, raw_damage * (1.0 - armor_reduction(armor)))

static func critical_chance(permanent_bonus: float, temporary_bonus: float = 0.0) -> float:
	return clampf(CRITICAL_CHANCE_BASE + permanent_bonus + temporary_bonus, 0.0, CRITICAL_CHANCE_CAP)

static func critical_damage(multiplier_bonus: float = 0.0) -> float:
	return maxf(1.0, CRITICAL_MULTIPLIER_BASE + multiplier_bonus)

static func evasion(permanent_bonus: float, temporary_bonus: float = 0.0) -> float:
	return clampf(permanent_bonus, 0.0, EVASION_CAP) + maxf(0.0, temporary_bonus)

static func merge_modifiers(permanent: Dictionary, equipment: Dictionary = {}, run: Dictionary = {}, doctrine: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for source: Dictionary in [permanent, equipment, run, doctrine]:
		for stat: String in source:
			result[stat] = float(result.get(stat, 0.0)) + float(source[stat])
	return result

static func calculate(base: Dictionary, modifiers: Dictionary, runebinder: bool = false) -> Dictionary:
	var attack_speed: float = float(modifiers.get("attack_speed", 0.0))
	var cooldown_reduction: float = float(modifiers.get("technique_cooldown", modifiers.get("cooldown_reduction", 0.0)))
	var result: Dictionary = modifiers.duplicate(true)
	result["max_health"] = float(base.get("max_health", 100.0)) + float(modifiers.get("max_health", modifiers.get("health", 0.0)))
	result["armor"] = float(base.get("armor", 0.0)) + float(modifiers.get("armor", 0.0))
	result["critical_chance"] = critical_chance(float(modifiers.get("critical_chance", modifiers.get("critical", 0.0))))
	result["attack_speed"] = clampf(attack_speed, -0.90, COMBINED_ATTACK_SPEED_CAP)
	result["technique_cooldown"] = clampf(cooldown_reduction, -1.0, RUNEBINDER_COOLDOWN_CAP if runebinder else TECHNIQUE_COOLDOWN_CAP)
	result["evasion"] = evasion(float(modifiers.get("evasion", 0.0)))
	result["armor_reduction"] = armor_reduction(result["armor"])
	return result
