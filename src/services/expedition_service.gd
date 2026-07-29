class_name ExpeditionService
extends RefCounted

const DREAD_SECONDS_PER_POINT: float = 6.0
const FIRST_BOSS_DREAD: float = 100.0
const REPEAT_BOSS_DREAD: float = 75.0

static func dread(elapsed_seconds: float, event_bonus: float) -> float:
	return maxf(0.0, elapsed_seconds / DREAD_SECONDS_PER_POINT + event_bonus)

static func threat_tier(dread_value: float) -> int:
	return maxi(0, floori(dread_value / 25.0))

static func boss_cycle_for_dread(dread_value: float) -> int:
	if dread_value < FIRST_BOSS_DREAD:
		return 0
	return 1 + floori((dread_value - FIRST_BOSS_DREAD) / REPEAT_BOSS_DREAD)

static func boss_threshold(cycle: int) -> float:
	if cycle <= 0:
		return FIRST_BOSS_DREAD
	return FIRST_BOSS_DREAD + float(cycle - 1) * REPEAT_BOSS_DREAD

static func loot_multiplier(dread_value: float) -> float:
	return 1.0 + minf(2.5, dread_value / 160.0)

static func enemy_health_multiplier(dread_value: float) -> float:
	return 1.0 + dread_value * 0.012

static func enemy_damage_multiplier(dread_value: float) -> float:
	return 1.0 + dread_value * 0.006
