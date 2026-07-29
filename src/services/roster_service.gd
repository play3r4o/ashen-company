class_name RosterService
extends RefCounted

const HERO_NAMES: Dictionary = {
	"warrior": "Rowan",
	"hunter": "Elowen",
	"mage": "Maren",
	"rogue": "Silas"
}

static func default_roster(now: float = -1.0) -> Array[Dictionary]:
	var timestamp: float = Time.get_unix_time_from_system() if now < 0.0 else now
	var roster: Array[Dictionary] = []
	for class_id: String in ["warrior", "hunter", "mage", "rogue"]:
		roster.append({
			"id": class_id,
			"name": HERO_NAMES[class_id],
			"class_id": class_id,
			"level": 1,
			"xp": 0,
			"class_tree": {},
			"equipped": {"head": "", "body": "", "hands": "", "boots": "", "trinket": ""},
			"assignment": "active" if class_id == "warrior" else "idle",
			"assignment_started": timestamp,
			"last_seen": timestamp,
			"pending_silver": 0,
			"pending_provisions": 0,
			"pending_xp": 0
		})
	return roster

static func hero_by_id(roster: Array, hero_id: String) -> Dictionary:
	for hero_value: Variant in roster:
		if hero_value is Dictionary and String(hero_value.get("id", "")) == hero_id:
			return hero_value
	return {}

static func active_hero(profile: Dictionary) -> Dictionary:
	return hero_by_id(profile.get("heroes", []), String(profile.get("active_hero_id", "warrior")))

static func set_active_hero(profile: Dictionary, hero_id: String) -> bool:
	var roster: Array = profile.get("heroes", [])
	if hero_by_id(roster, hero_id).is_empty():
		return false
	for hero_value: Variant in roster:
		if hero_value is Dictionary:
			if String(hero_value.get("id", "")) == hero_id:
				hero_value.assignment = "active"
			elif String(hero_value.get("assignment", "idle")) == "active":
				hero_value.assignment = "idle"
	profile.active_hero_id = hero_id
	return true

static func offline_cap_seconds(quartermaster_level: int) -> float:
	return (8.0 + 4.0 * clampf(float(quartermaster_level) / 3.0, 0.0, 1.0)) * 3600.0

static func apply_offline(profile: Dictionary, now: float) -> Dictionary:
	var totals: Dictionary = {"silver": 0, "provisions": 0, "xp": 0}
	var cap_seconds: float = offline_cap_seconds(int(profile.get("quartermaster_level", 0)))
	var roster: Array = profile.get("heroes", [])
	for hero_value: Variant in roster:
		if not hero_value is Dictionary:
			continue
		var hero: Dictionary = hero_value
		var elapsed: float = clampf(now - float(hero.get("last_seen", now)), 0.0, cap_seconds)
		var hours: float = elapsed / 3600.0
		var level_factor: float = 1.0 + float(int(hero.get("level", 1)) - 1) * 0.04
		match String(hero.get("assignment", "idle")):
			"patrol":
				var silver: int = floori(hours * 9.0 * level_factor)
				hero.pending_silver = int(hero.get("pending_silver", 0)) + silver
				totals.silver += silver
			"forage":
				var provisions: int = floori(hours * 2.5 * level_factor)
				hero.pending_provisions = int(hero.get("pending_provisions", 0)) + provisions
				totals.provisions += provisions
			"training":
				var xp: int = floori(hours * 6.0 * level_factor)
				hero.pending_xp = int(hero.get("pending_xp", 0)) + xp
				totals.xp += xp
		hero.last_seen = now
	profile.heroes = roster
	return totals

static func xp_for_next_level(level: int) -> int:
	return 80 + maxi(0, level - 1) * 45

static func grant_xp(hero: Dictionary, amount: int) -> int:
	var levels_gained: int = 0
	hero.xp = int(hero.get("xp", 0)) + maxi(0, amount)
	while int(hero.xp) >= xp_for_next_level(int(hero.get("level", 1))):
		hero.xp = int(hero.xp) - xp_for_next_level(int(hero.get("level", 1)))
		hero.level = int(hero.get("level", 1)) + 1
		levels_gained += 1
	return levels_gained

static func claim_hero(hero: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"silver": int(hero.get("pending_silver", 0)),
		"provisions": int(hero.get("pending_provisions", 0)),
		"xp": int(hero.get("pending_xp", 0)),
		"levels": 0
	}
	result.levels = grant_xp(hero, int(result.xp))
	hero.pending_silver = 0
	hero.pending_provisions = 0
	hero.pending_xp = 0
	return result
