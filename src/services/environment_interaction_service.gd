class_name EnvironmentInteractionService
extends RefCounted

static var TAGS: PackedStringArray = PackedStringArray(["flammable", "wet", "conductive", "freezable", "brittle", "breakable_light", "breakable_heavy", "cuttable", "corrupted_growth", "arcane_device", "solid_ricochet", "hazard_ground"])

const RULES: Array[Dictionary] = [
	{"id": "fire_ignite", "source": ["fire"], "target": ["flammable"], "result": ["burning"], "power": 1.0, "duration": 4.0},
	{"id": "flame_ignite", "source": ["flame"], "target": ["flammable"], "result": ["burning"], "power": 1.0, "duration": 4.0},
	{"id": "frost_freeze", "source": ["frost"], "target": ["freezable"], "result": ["frozen"], "power": 1.0, "duration": 2.5},
	{"id": "lightning_wet_chain", "source": ["lightning"], "target": ["wet"], "result": ["conductive"], "power": 1.35, "duration": 5.0},
	{"id": "lightning_conductive_chain", "source": ["lightning"], "target": ["conductive"], "result": ["conductive"], "power": 1.35, "duration": 5.0},
	{"id": "impact_brittle_break", "source": ["impact"], "target": ["brittle"], "result": ["broken"], "power": 1.25, "duration": 0.0},
	{"id": "impact_heavy_break", "source": ["impact"], "target": ["breakable_heavy"], "result": ["broken"], "power": 1.25, "duration": 0.0},
	{"id": "sling_ricochet", "source": ["blunt", "projectile"], "target": ["solid_ricochet"], "result": ["ricochet"], "power": 1.0, "duration": 0.0},
	{"id": "sling_tagged_ricochet", "source": ["sling"], "target": ["solid_ricochet"], "result": ["ricochet"], "power": 1.0, "duration": 0.0},
	{"id": "poison_wet_spread", "source": ["poison"], "target": ["wet"], "result": ["poison_pool"], "power": 1.5, "duration": 5.0}
]

static func resolve(source_tags: Array[String], target_tags: Array[String]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for rule: Dictionary in RULES:
		var matches: bool = true
		for source: String in rule.source:
			if source not in source_tags:
				matches = false
				break
		if not matches:
			continue
		for target: String in rule.target:
			if target not in target_tags:
				matches = false
				break
		if matches:
			results.append(rule.duplicate(true))
	return results

static func has_tag(tags: Array[String], tag: String) -> bool:
	return tag in tags
