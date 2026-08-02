class_name TrainingGroundsContent
extends RefCounted

const TrainingNodeResource = preload("res://src/foundation/training_node_definition.gd")
const CombatAbilityResource = preload("res://src/foundation/combat_ability_definition.gd")
const AbilityRankResource = preload("res://src/foundation/ability_rank_definition.gd")
const DoctrineResource = preload("res://src/foundation/doctrine_definition.gd")
const StatusResource = preload("res://src/foundation/status_definition.gd")
const RunBoonResource = preload("res://src/foundation/run_boon_definition.gd")
const EnvironmentResource = preload("res://src/foundation/environment_interaction_definition.gd")

## Canonical content registry for the Training Grounds rework.  The registry
## deliberately lives outside the legacy content table so v2 saves can be
## migrated safely before the old offer pools are retired.

const SCHOOLS: Array[String] = ["vanguard", "ranger", "shadow", "arcanist"]
const SCHOOL_LABELS: Dictionary = {
	"vanguard": "VANGUARD",
	"ranger": "RANGER",
	"shadow": "SHADOW",
	"arcanist": "ARCANIST"
}
const SCHOOL_COLORS: Dictionary = {
	"vanguard": Color("a65b49"),
	"ranger": Color("78945e"),
	"shadow": Color("795d85"),
	"arcanist": Color("61a5a6")
}

const SCHOOL_WEAPONS: Dictionary = {
	"vanguard": ["sword", "spear", "greatsword"],
	"ranger": ["bow", "sling", "crossbow"],
	"shadow": ["daggers", "throwing_knives", "chakrams"],
	"arcanist": ["staff", "wand", "runic_orb"]
}
const SCHOOL_TECHNIQUES: Dictionary = {
	"vanguard": ["ground_slam", "shield_wall", "war_cry"],
	"ranger": ["rain_of_arrows", "hunters_mark", "windstep"],
	"shadow": ["smoke_veil", "poison_flask", "shadowstep"],
	"arcanist": ["fire_nova", "frost_ring", "chain_lightning"]
}
const SCHOOL_DOCTRINES: Dictionary = {
	"vanguard": ["iron_vanguard", "bloodbound"],
	"ranger": ["windrunner", "deadeye"],
	"shadow": ["nightblade", "venom_pact"],
	"arcanist": ["elemental_conduit", "runebinder"]
}
const SCHOOL_MAJORS: Dictionary = {
	"vanguard": ["tempered_formation", "hold_the_line", "deep_wounds", "unbroken", "execution_stroke"],
	"ranger": ["steady_aim", "running_shot", "predators_focus", "clean_kill", "high_ground"],
	"shadow": ["opportunist", "serrated_rhythm", "toxic_momentum", "vanishing_step", "finisher"],
	"arcanist": ["elemental_echo", "arcane_reservoir", "lingering_runes", "shatter", "static_field"]
}
const SCHOOL_KEYSTONES: Dictionary = {
	"vanguard": ["immovable", "reckless_cleaver"],
	"ranger": ["perfect_trajectory", "relentless_motion"],
	"shadow": ["one_cut_ahead", "toxic_blood"],
	"arcanist": ["unstable_elements", "glass_channel"]
}
const SCHOOL_MASTERY: Dictionary = {
	"vanguard": "vanguard_mastery",
	"ranger": "ranger_mastery",
	"shadow": "shadow_mastery",
	"arcanist": "arcanist_mastery"
}
const SCHOOL_MINORS: Dictionary = {
	"vanguard": [
		"fortified_body", "hardened_mail", "field_medicine", "rooted_stance", "drilled_swings",
		"measured_breath", "guarded_advance", "bleeding_edge", "enduring_wound", "blood_scent",
		"open_vein", "sweeping_form", "long_reach", "driving_force", "tempered_point",
		"impact_training", "close_order"
	],
	"ranger": [
		"fleetfoot", "sure_foot", "slip_mud", "moving_rhythm", "keen_eye", "lethal_draw",
		"straight_flight", "distant_focus", "bodkin_fletch", "bank_shot", "long_flight",
		"lasting_mark", "quarry_focus", "trophy_hunter", "echoing_mark", "light_step", "quick_release"
	],
	"shadow": [
		"fresh_blood", "first_cut", "afterimage", "backstab", "venom_tip", "concentrated_venom",
		"slow_toxin", "sickened_prey", "quick_blades", "close_quarters", "flowing_steps",
		"relentless_flurry", "evasive_instinct", "pain_response", "lingering_smoke", "prepared_escape", "execution_eye"
	],
	"arcanist": [
		"embercraft", "hotter_flame", "widened_nova", "cinder_sense", "deep_winter", "lower_threshold",
		"lasting_frost", "shatter_focus", "charged_air", "far_arc", "forked_current", "storm_sense",
		"runic_timing", "lasting_sigils", "focused_orbit", "warding_script", "arcane_velocity"
	]
}

const _CENTRAL_IDS: Array[String] = ["company_crest", "expedition_arsenal", "tactical_rethink", "dual_doctrine"]

static var _nodes_cache: Dictionary = {}
static var _abilities_cache: Dictionary = {}
static var _doctrines_cache: Dictionary = {}
static var _node_resources_cache: Dictionary = {}
static var _ability_resources_cache: Dictionary = {}
static var _doctrine_resources_cache: Dictionary = {}
static var _status_resources_cache: Dictionary = {}
static var _boon_resources_cache: Dictionary = {}
static var _environment_resources_cache: Dictionary = {}

static func statuses() -> Dictionary:
	return {
		"bleed": {"max_stacks": 5, "duration": 5.0, "tick_interval": 1.0, "boss_behavior": "stagger"},
		"poison": {"max_stacks": 8, "duration": 8.0, "tick_interval": 1.0, "boss_behavior": "normal"},
		"burn": {"max_stacks": 3, "duration": 4.0, "tick_interval": 0.75, "boss_behavior": "regen_reduction"},
		"chill": {"max_stacks": 100, "duration": 5.0, "freeze_threshold": 100, "freeze_duration": 1.25, "boss_behavior": "slow"},
		"shock": {"max_stacks": 1, "duration": 5.0, "boss_behavior": "chain"},
		"mark": {"max_stacks": 1, "duration": 8.0, "projectile_damage": 0.15, "boss_behavior": "normal"}
	}

static func run_boons() -> Dictionary:
	var result: Dictionary = {}
	var entries: Array[Dictionary] = [
		{"id": "damage", "name": "Damage", "description": "Increase all damage.", "stat": "damage", "values": [0.06, 0.12, 0.18, 0.24, 0.30]},
		{"id": "attack_speed", "name": "Attack Speed", "description": "Shorten automatic attack intervals.", "stat": "attack_speed", "values": [0.06, 0.12, 0.18, 0.24, 0.30]},
		{"id": "health", "name": "Maximum Health", "description": "Increase maximum health.", "stat": "health", "values": [12.0, 24.0, 36.0, 48.0, 60.0]},
		{"id": "armor", "name": "Armor", "description": "Reduce incoming damage.", "stat": "armor", "values": [5.0, 10.0, 15.0, 20.0, 25.0]},
		{"id": "speed", "name": "Movement", "description": "Move faster through the moor.", "stat": "speed", "values": [0.05, 0.10, 0.15, 0.20, 0.25]},
		{"id": "area", "name": "Area", "description": "Expand attacks and techniques.", "stat": "area", "values": [0.06, 0.12, 0.18, 0.24, 0.30]},
		{"id": "duration", "name": "Duration", "description": "Extend temporary effects.", "stat": "duration", "values": [0.06, 0.12, 0.18, 0.24, 0.30]},
		{"id": "critical", "name": "Critical Chance", "description": "Strike critically more often.", "stat": "critical", "values": [0.03, 0.06, 0.09, 0.12, 0.15]},
		{"id": "critical_damage", "name": "Critical Damage", "description": "Make critical strikes hit harder.", "stat": "critical_damage", "values": [0.08, 0.16, 0.24, 0.32, 0.40]},
		{"id": "projectile_speed", "name": "Projectile Speed", "description": "Faster projectiles travel farther.", "stat": "projectile_speed", "values": [0.08, 0.16, 0.24, 0.32, 0.40]},
		{"id": "pickup", "name": "Pickup Reach", "description": "Collect drops from farther away.", "stat": "pickup", "values": [12.0, 24.0, 36.0, 48.0, 60.0]},
		{"id": "healing", "name": "Healing", "description": "Improve all healing received.", "stat": "healing", "values": [0.06, 0.12, 0.18, 0.24, 0.30]}
	]
	for entry: Dictionary in entries:
		result[String(entry.id)] = entry
	return result

static func all_nodes() -> Dictionary:
	if not _nodes_cache.is_empty():
		return _nodes_cache
	var nodes: Dictionary = {}
	_add_node(nodes, "company_crest", "Company Crest", "Four schools share one company standard.", "root", "company", 0, 1, [], ["root"], Vector2(0, 0), true)
	_add_node(nodes, "expedition_arsenal", "Expedition Arsenal", "Prepare the weapons, techniques, and doctrine that may appear in a run.", "utility", "company", 0, 1, ["company_crest"], ["arsenal"], Vector2(0, 180), true)
	_add_node(nodes, "tactical_rethink", "Tactical Rethink", "One free reroll is restored at the start of every expedition.", "utility", "company", 2, 1, ["expedition_arsenal"], ["reroll"], Vector2(0, 340))
	_add_node(nodes, "dual_doctrine", "Dual Doctrine", "Prepare a second compatible doctrine for each expedition.", "utility", "company", 5, 5, ["tactical_rethink"], ["two_school_outer"], Vector2(0, 500))

	for school_index: int in SCHOOLS.size():
		var school: String = SCHOOLS[school_index]
		_add_school_nodes(nodes, school, school_index)
	_add_hybrid_nodes(nodes)
	# Keep doctrine conflicts visible in both the tree and Arsenal. The same
	# stable IDs are used by TrainingGroundsService and ArsenalService, so a
	# refund or load cannot accidentally make an incompatible pair purchasable.
	var exclusive_pairs: Array[Array] = [["iron_vanguard", "windrunner"], ["deadeye", "nightblade"]]
	for pair: Array in exclusive_pairs:
		var first: String = String(pair[0])
		var second: String = String(pair[1])
		if nodes.has(first) and nodes.has(second):
			nodes[first].exclusive_with = [second]
			nodes[second].exclusive_with = [first]
	_nodes_cache = nodes
	return _nodes_cache

static func node_count() -> int:
	return all_nodes().size()

## Typed authoring views. The compact dictionaries above are used by the hot
## runtime paths, while these cached Resources are the editable/data-driven
## contract for tools, inspectors, and future content packs.
static func node_resources() -> Dictionary:
	if not _node_resources_cache.is_empty():
		return _node_resources_cache
	for node_id: String in all_nodes():
		var data: Dictionary = all_nodes()[node_id]
		var resource: TrainingNodeDefinition = TrainingNodeResource.new()
		resource.id = node_id
		resource.display_name = String(data.get("name", node_id))
		resource.description = String(data.get("description", ""))
		resource.node_type = String(data.get("node_type", "minor"))
		resource.school = String(data.get("school", "company"))
		resource.icon = String(data.get("icon", node_id))
		resource.cost = int(data.get("cost", 0))
		resource.position = Vector2(data.get("position", Vector2.ZERO))
		resource.prerequisite_ids = _string_array(data.get("prerequisite_ids", []))
		resource.exclusive_with = _string_array(data.get("exclusive_with", []))
		resource.unlock_id = String(data.get("unlock_id", node_id))
		resource.stat_modifiers = Dictionary(data.get("stat_modifiers", {})).duplicate(true)
		resource.tags = _string_array(data.get("tags", []))
		resource.training_ground_tier = int(data.get("training_ground_tier", 1))
		resource.free_node = bool(data.get("free_node", false))
		_node_resources_cache[node_id] = resource
	return _node_resources_cache

static func nodes_by_type(node_type: String) -> Array[String]:
	var result: Array[String] = []
	for node_id: String in all_nodes():
		if String(all_nodes()[node_id].node_type) == node_type:
			result.append(node_id)
	return result

static func abilities() -> Dictionary:
	if not _abilities_cache.is_empty():
		return _abilities_cache
	var result: Dictionary = {}
	_add_weapon(result, "sword", "Sword", "vanguard", "melee", 1.00, 0.90, 100.0, ["physical", "melee", "slash", "bleed"], ["Wide forward slash", "+20% damage and +15% area", "Every third attack performs a second slash", "Attacks gain bleed chance", "Wider crescent, projectile deflection, Double Cut every second attack"])
	_add_weapon(result, "spear", "Spear", "vanguard", "melee", 1.25, 1.15, 120.0, ["physical", "melee", "thrust", "pierce"], ["Thrust through three targets", "+25% reach and +1 pierce", "Every fourth thrust is wider and stronger against elites", "Pin normal enemies near solid objects", "Two spectral side-thrusts converge on the target area"])
	_add_weapon(result, "greatsword", "Greatsword", "vanguard", "melee", 1.80, 1.60, 140.0, ["physical", "heavy", "slash", "impact"], ["Slow wide cleave", "+25% damage and knockback", "Impact sends a ground shockwave", "Blade and shockwave together deal bonus damage", "Every third attack creates a damaging fissure"])
	_add_weapon(result, "bow", "Bow", "ranger", "projectile", 0.90, 0.85, 520.0, ["physical", "ranged", "projectile", "precision"], ["Hunter's Arrow", "+20% damage and +20% projectile speed", "Every third shot splits into two arrows", "Critical hits mark targets and arrows home slightly", "Every fifth attack releases a heavy piercing volley"])
	_add_weapon(result, "sling", "Sling", "ranger", "projectile", 0.70, 0.70, 330.0, ["physical", "projectile", "blunt", "ricochet"], ["Stone bounces once", "+20% damage and speed", "Two additional ricochets with growing damage", "Repeated hits build stagger", "Every sixth shot fractures into ricocheting stones"])
	_add_weapon(result, "crossbow", "Crossbow", "ranger", "projectile", 1.65, 1.55, 520.0, ["physical", "ranged", "projectile", "pierce"], ["Powerful piercing bolt", "+25% damage and +1 pierce", "Every third firing releases two bolts", "Hits reduce enemy armor temporarily", "Oversized ballista bolt crosses the combat area"])
	_add_weapon(result, "daggers", "Daggers", "shadow", "melee", 0.96, 0.62, 90.0, ["physical", "melee", "rapid", "critical"], ["Two rapid strikes", "+18% attack speed and range", "Every fourth attack strikes in a circle", "Critical hits bleed and punish poisoned targets", "Blade Dance every third attack plus outward blade waves"])
	_add_weapon(result, "throwing_knives", "Throwing Knives", "shadow", "projectile", 1.26, 0.88, 480.0, ["physical", "ranged", "projectile", "critical"], ["Three-knife fan", "+1 knife and tighter spread", "Missed knives return through enemies", "Bonus critical damage below 30% health", "Two sequential fans with orbiting returns"])
	_add_weapon(result, "chakrams", "Chakrams", "shadow", "returning", 0.78, 1.10, 270.0, ["physical", "projectile", "returning", "multi_hit"], ["Outbound and return damage", "+20% damage and hit radius", "Two opposing chakrams", "Returned discs orbit briefly", "Returning discs split into a defensive constellation"])
	_add_weapon(result, "staff", "Staff", "arcanist", "projectile", 1.10, 1.10, 245.0, ["arcane", "projectile", "area"], ["Arcane bolt explodes", "+20% damage and explosion radius", "Cycles fire, frost, and lightning", "Repeating an element triggers a resonance effect", "Three elemental bolts target separate enemies or one boss"])
	_add_weapon(result, "wand", "Wand", "arcanist", "projectile", 0.55, 0.50, 430.0, ["arcane", "projectile", "rapid", "elemental"], ["Rapid spark bolts", "+15% attack speed and projectile speed", "Every fourth bolt forks", "Adopts the dominant element", "Charge releases seeking bolts"])
	_add_weapon(result, "runic_orb", "Runic Orb", "arcanist", "orbit", 0.50, 0.20, 86.0, ["arcane", "orbit", "persistent"], ["One orbiting damaging rune", "Larger orbit and damage", "Adds a second rune", "Runes leave damaging trails", "Four alternating runes align for an arcane pulse"])

	_add_technique(result, "ground_slam", "Ground Slam", "vanguard", 8.0, ["Area impact and stagger", "Larger radius and damage", "Three fissures outward", "Elite stagger and brittle breaking", "Repeated damaging fractured zone"])
	_add_technique(result, "shield_wall", "Shield Wall", "vanguard", 12.0, ["Directional damage barrier", "Stronger and longer barrier", "Reflects minor projectiles", "Touching enemies are pushed and weakened", "Three-shield formation with movement openings"])
	_add_technique(result, "war_cry", "War Cry", "vanguard", 14.0, ["Pushes enemies and grants damage", "Longer buff", "Attack speed and knockback resistance", "Bleeding enemies are forced outward", "Kills extend duration up to a cap"])
	_add_technique(result, "rain_of_arrows", "Rain of Arrows", "ranger", 9.0, ["Delayed cluster bombardment", "Larger area and more waves", "First wave marks", "Critical hits call extra arrows", "Final wave fires heavy piercing arrows"])
	_add_technique(result, "hunters_mark", "Hunter's Mark", "ranger", 10.0, ["Marks strongest nearby enemy", "Longer mark and damage bonus", "Kill transfers mark", "Projectiles home slightly", "Marked target pulses based on damage taken"])
	_add_technique(result, "windstep", "Windstep", "ranger", 11.0, ["Safe automatic reposition and speed", "Reduced cooldown and longer buff", "Gust pushes normal enemies", "Next ranged attack gains projectiles", "Two charges with predictable delay"])
	_add_technique(result, "smoke_veil", "Smoke Veil", "shadow", 12.0, ["Smoke reduces targeting and grants damage reduction", "Larger and longer smoke", "Entering grants movement", "Enemies inside are vulnerable to criticals", "Leaving creates one-strike shadow copies"])
	_add_technique(result, "poison_flask", "Poison Flask", "shadow", 8.0, ["Toxic ground pool", "Larger and longer pool", "Impact applies multiple poison stacks", "Deaths expand the pool", "Pool releases toxic projectiles"])
	_add_technique(result, "shadowstep", "Shadowstep", "shadow", 9.0, ["Safe dash behind a priority target", "More damage and range", "Leaves a damaging trail", "Kills partially reset cooldown", "Short sequence across three targets"])
	_add_technique(result, "fire_nova", "Fire Nova", "arcanist", 8.0, ["Fire ring applies burn", "Larger and stronger burn", "Leaves a burning ring", "Burning enemies release flame bursts", "Expands then collapses for two hits"])
	_add_technique(result, "frost_ring", "Frost Ring", "arcanist", 10.0, ["Frost wave chills", "More chill and radius", "Nearby enemies can freeze", "Frozen enemies take more impact damage", "Ice-crystal boundary damages crossings"])
	_add_technique(result, "chain_lightning", "Chain Lightning", "arcanist", 7.0, ["One strike chains to three", "More damage and range", "Two more chains", "Wet or shocked targets do not consume chain count", "Final target bursts and sends chains backward"])
	var environment_map: Dictionary = {
		"sword": ["cuttable"], "spear": ["cuttable"], "greatsword": ["cuttable", "brittle", "breakable_heavy"],
		"bow": ["breakable_light"], "sling": ["solid_ricochet", "breakable_light"], "crossbow": ["breakable_light"],
		"daggers": ["cuttable"], "throwing_knives": ["cuttable"], "chakrams": ["cuttable"],
		"staff": ["arcane_device"], "wand": ["arcane_device"], "runic_orb": ["arcane_device"],
		"ground_slam": ["brittle", "breakable_heavy"], "shield_wall": ["solid_ricochet"], "war_cry": ["hazard_ground"],
		"rain_of_arrows": ["flammable"], "hunters_mark": ["arcane_device"], "windstep": ["hazard_ground"],
		"smoke_veil": ["hazard_ground"], "poison_flask": ["wet", "hazard_ground"], "shadowstep": ["cuttable"],
		"fire_nova": ["flammable"], "frost_ring": ["freezable"], "chain_lightning": ["wet", "conductive"]
	}
	for ability_id: String in environment_map:
		if result.has(ability_id):
			result[ability_id]["environment_interactions"] = Array(environment_map[ability_id]).duplicate()
			result[ability_id]["visual_effect_ids"] = ["ability_%s" % ability_id]
			result[ability_id]["audio_effect_ids"] = ["sfx_%s" % ability_id]
	for ability_id: String in result:
		var ability_school: String = String(result[ability_id].get("school", ""))
		var eligible: Array[String] = _string_array(SCHOOL_DOCTRINES.get(ability_school, []))
		for hybrid_doctrine: String in ["skirmisher", "duelist", "hexblade", "arcane_archer"]:
			if hybrid_doctrine not in eligible:
				eligible.append(hybrid_doctrine)
		result[ability_id]["eligible_doctrines"] = eligible
	_abilities_cache = result
	return _abilities_cache

static func ability_resources() -> Dictionary:
	if not _ability_resources_cache.is_empty():
		return _ability_resources_cache
	for ability_id: String in abilities():
		var data: Dictionary = abilities()[ability_id]
		var resource: CombatAbilityDefinition = CombatAbilityResource.new()
		resource.id = ability_id
		resource.display_name = String(data.get("name", ability_id))
		resource.school = String(data.get("school", ""))
		resource.category = String(data.get("category", "weapon"))
		resource.tags = _string_array(data.get("tags", []))
		resource.base_stats = Dictionary(data.get("base_stats", {})).duplicate(true)
		resource.environment_interactions = _string_array(data.get("environment_interactions", []))
		resource.visual_effect_ids = _string_array(data.get("visual_effect_ids", []))
		resource.audio_effect_ids = _string_array(data.get("audio_effect_ids", []))
		resource.eligible_doctrines = _string_array(data.get("eligible_doctrines", []))
		var rank_resources: Array[Resource] = []
		for rank_value: Variant in data.get("ranks", []):
			var rank_data: Dictionary = Dictionary(rank_value)
			var rank_resource: AbilityRankDefinition = AbilityRankResource.new()
			rank_resource.rank = int(rank_data.get("rank", rank_resources.size() + 1))
			rank_resource.damage_multiplier = float(rank_data.get("damage_multiplier", 1.0))
			rank_resource.cooldown_or_interval = float(rank_data.get("cooldown_or_interval", 0.0))
			rank_resource.area_multiplier = float(rank_data.get("area_multiplier", 1.0))
			rank_resource.duration_multiplier = float(rank_data.get("duration_multiplier", 1.0))
			rank_resource.projectile_count = int(rank_data.get("projectile_count", 0))
			rank_resource.pierce = int(rank_data.get("pierce", 0))
			rank_resource.stat_changes = Dictionary(rank_data.get("stat_changes", {})).duplicate(true)
			rank_resource.status_application = Dictionary(rank_data.get("status_application", {})).duplicate(true)
			rank_resource.behavior_flags = _string_array(rank_data.get("behavior_flags", []))
			rank_resource.visual_upgrade = String(rank_data.get("visual_upgrade", ""))
			rank_resource.description = String(rank_data.get("description", ""))
			rank_resources.append(rank_resource)
		resource.ranks = rank_resources
		_ability_resources_cache[ability_id] = resource
	return _ability_resources_cache

static func compile_ability(ability_id: String, rank: int) -> Dictionary:
	var resource: CombatAbilityDefinition = ability_resources().get(ability_id) as CombatAbilityDefinition
	if resource == null:
		return {}
	return resource.compile_rank(rank)

static func doctrines() -> Dictionary:
	if not _doctrines_cache.is_empty():
		return _doctrines_cache
	var result: Dictionary = {
		"iron_vanguard": _doctrine("Iron Vanguard", "vanguard", "+20 armor and +15% health; −8% movement. Vanguard techniques grant 15% damage reduction for 2 seconds.", {"armor": 20.0, "health": 0.15, "speed": -0.08, "vanguard_technique_damage_reduction": 0.15}),
		"bloodbound": _doctrine("Bloodbound", "vanguard", "+25% bleed potency. Melee hits against bleeding enemies heal 0.35% maximum health, capped at 2% per second. Other healing is 30% weaker.", {"bleed_potency": 0.25, "bleed_heal": 0.0035, "healing": -0.30}),
		"windrunner": _doctrine("Windrunner", "ranger", "Movement converts to attack speed up to +25%. Standing still removes the bonus. −10 armor.", {"moving_attack_speed": 0.5, "moving_attack_speed_cap": 0.25, "armor": -10.0}),
		"deadeye": _doctrine("Deadeye", "ranger", "+35% critical damage and +20% distant damage. −15% area and −20% adjacent damage.", {"critical_damage": 0.35, "distant_damage": 0.20, "area": -0.15, "adjacent_damage": -0.20}),
		"nightblade": _doctrine("Nightblade", "shadow", "+25% damage after movement techniques. Critical kills reduce Shadow cooldowns by 10%. −12% health.", {"post_mobility_damage": 0.25, "shadow_cooldown_on_crit_kill": 0.10, "health": -0.12}),
		"venom_pact": _doctrine("Venom Pact", "shadow", "+4 poison stacks and +50% duration. −15% poison tick potency and −10% direct damage.", {"poison_stack_limit": 4, "poison_duration": 0.50, "poison_tick": -0.15, "direct_damage": -0.10}),
		"elemental_conduit": _doctrine("Elemental Conduit", "arcanist", "Fire, frost, and shock on one target trigger a 1.2-power detonation. Individual status potency is 15% weaker.", {"elemental_reaction": 1.20, "elemental_status": -0.15}),
		"runebinder": _doctrine("Runebinder", "arcanist", "+30% persistent-effect duration and a 50% Technique Cooldown cap. −12% projectile damage.", {"persistent_duration": 0.30, "cooldown_cap": 0.50, "projectile_damage": -0.12}),
		"skirmisher": _doctrine("Skirmisher", "hybrid", "Moving empowers spear, bow, and crossbow. Melee improves projectile speed and projectiles improve melee reach.", {"movement_synergy": 0.15}, []),
		"duelist": _doctrine("Duelist", "hybrid", "Alternating heavy and rapid attacks builds Momentum. Maximum Momentum grants critical chance and damage reduction.", {"momentum_max": 6, "momentum_crit": 0.12, "momentum_reduction": 0.10}, []),
		"hexblade": _doctrine("Hexblade", "hybrid", "Weapon criticals increase elemental status chance. Elemental status increases poison and bleed potency. Raw damage is 8% weaker.", {"crit_elemental_chance": 0.15, "elemental_status_dot": 0.15, "raw_damage": -0.08}, []),
		"arcane_archer": _doctrine("Arcane Archer", "hybrid", "Projectiles inherit part of the strongest elemental status. Elemental techniques mark enemies. −15% melee damage.", {"projectile_element": 0.20, "elemental_technique_mark": true, "melee_damage": -0.15}, [])
	}
	result["iron_vanguard"].exclusive_with = ["windrunner"]
	result["windrunner"].exclusive_with = ["iron_vanguard"]
	result["deadeye"].exclusive_with = ["nightblade"]
	result["nightblade"].exclusive_with = ["deadeye"]
	_doctrines_cache = result
	return _doctrines_cache

static func doctrine_resources() -> Dictionary:
	if not _doctrine_resources_cache.is_empty():
		return _doctrine_resources_cache
	for doctrine_id: String in doctrines():
		var data: Dictionary = doctrines()[doctrine_id]
		var resource: DoctrineDefinition = DoctrineResource.new()
		resource.id = doctrine_id
		resource.display_name = String(data.get("name", doctrine_id))
		resource.school = String(data.get("school", ""))
		resource.description = String(data.get("description", ""))
		resource.modifiers = Dictionary(data.get("modifiers", {})).duplicate(true)
		resource.exclusive_with = _string_array(data.get("exclusive_with", []))
		resource.tags = _string_array(data.get("tags", []))
		_doctrine_resources_cache[doctrine_id] = resource
	return _doctrine_resources_cache

static func status_resources() -> Dictionary:
	if not _status_resources_cache.is_empty():
		return _status_resources_cache
	for status_id: String in statuses():
		var data: Dictionary = statuses()[status_id]
		var resource: StatusDefinition = StatusResource.new()
		resource.id = status_id
		resource.display_name = status_id.replace("_", " ").capitalize()
		resource.school = String(data.get("school", ""))
		resource.max_stacks = int(data.get("max_stacks", 1))
		resource.duration = float(data.get("duration", 0.0))
		resource.tick_interval = float(data.get("tick_interval", 0.0))
		resource.default_potency = float(data.get("default_potency", 1.0))
		resource.refresh_rule = String(data.get("refresh_rule", "refresh_duration"))
		resource.boss_behavior = String(data.get("boss_behavior", "normal"))
		resource.tags = _string_array(data.get("tags", []))
		_status_resources_cache[status_id] = resource
	return _status_resources_cache

static func boon_resources() -> Dictionary:
	if not _boon_resources_cache.is_empty():
		return _boon_resources_cache
	for boon_id: String in run_boons():
		var data: Dictionary = run_boons()[boon_id]
		var resource: RunBoonDefinition = RunBoonResource.new()
		resource.id = boon_id
		resource.display_name = String(data.get("name", boon_id))
		resource.description = String(data.get("description", ""))
		resource.stat = String(data.get("stat", boon_id))
		var values: Array[float] = []
		for value: Variant in data.get("values", []):
			values.append(float(value))
		resource.rank_values = values
		_boon_resources_cache[boon_id] = resource
	return _boon_resources_cache

static func environment_resources() -> Dictionary:
	if not _environment_resources_cache.is_empty():
		return _environment_resources_cache
	var entries: Array[Dictionary] = [
		{"id": "fire_flammable", "source": ["fire", "flame"], "target": ["flammable"], "result": ["burning"], "power": 1.0, "duration": 4.0, "description": "Fire ignites flammable surfaces."},
		{"id": "frost_freeze", "source": ["frost"], "target": ["freezable"], "result": ["frozen_surface"], "power": 1.0, "duration": 2.0, "description": "Frost freezes water and mud temporarily."},
		{"id": "lightning_conduct", "source": ["lightning"], "target": ["wet", "conductive"], "result": ["shock_chain"], "power": 1.0, "duration": 0.0, "description": "Lightning chains farther through wet or conductive targets."},
		{"id": "impact_brittle_break", "source": ["impact"], "target": ["brittle", "breakable_heavy"], "result": ["broken"], "power": 1.0, "duration": 0.0, "description": "Heavy impacts break brittle objects."},
		{"id": "sling_solid_ricochet", "source": ["sling"], "target": ["solid_ricochet"], "result": ["ricochet"], "power": 1.0, "duration": 0.0, "description": "Sling stones ricochet from marked solid surfaces."},
		{"id": "poison_wet_spread", "source": ["poison"], "target": ["wet"], "result": ["poison_spread"], "power": 1.5, "duration": 8.0, "description": "Poison pools spread farther over wet ground."}
	]
	for entry: Dictionary in entries:
		var resource: EnvironmentInteractionDefinition = EnvironmentResource.new()
		resource.id = String(entry.id)
		resource.source_tags = PackedStringArray(_string_array(entry.source))
		resource.target_tags = PackedStringArray(_string_array(entry.target))
		resource.result_tags = PackedStringArray(_string_array(entry.result))
		resource.power_multiplier = float(entry.power)
		resource.duration = float(entry.duration)
		resource.description = String(entry.description)
		_environment_resources_cache[resource.id] = resource
	return _environment_resources_cache

static func _string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if values is Array or values is PackedStringArray:
		for value: Variant in values:
			result.append(String(value))
	return result

static func validate_catalog() -> Dictionary:
	var nodes: Dictionary = all_nodes()
	var errors: Array[String] = []
	if nodes.size() != 156:
		errors.append("expected 156 nodes, got %d" % nodes.size())
	for node_id: String in nodes:
		var node: Dictionary = nodes[node_id]
		for required_value: Variant in node.get("prerequisite_ids", []):
			if not nodes.has(String(required_value)):
				errors.append("%s requires missing %s" % [node_id, String(required_value)])
		for exclusive_value: Variant in node.get("exclusive_with", []):
			if not nodes.has(String(exclusive_value)):
				errors.append("%s excludes missing %s" % [node_id, String(exclusive_value)])
	var expected_counts: Dictionary = {"weapon": 12, "technique": 12, "doctrine": 12, "minor": 76, "major": 28, "keystone": 8, "mastery": 4, "utility": 3, "root": 1}
	var actual_counts: Dictionary = {}
	for node_id: String in nodes:
		var kind: String = String(nodes[node_id].get("node_type", ""))
		actual_counts[kind] = int(actual_counts.get(kind, 0)) + 1
	for kind: String in expected_counts:
		if int(actual_counts.get(kind, 0)) != int(expected_counts[kind]):
			errors.append("%s count expected %d, got %d" % [kind, int(expected_counts[kind]), int(actual_counts.get(kind, 0))])
	# Keep the school and hybrid partitions explicit.  This catches a content
	# author accidentally moving a node between branches while the global 156
	# count still happens to balance.
	for school: String in SCHOOLS:
		var school_count: int = 0
		for node_id: String in nodes:
			if String(nodes[node_id].get("school", "")) == school:
				school_count += 1
		if school_count != 33:
			errors.append("%s school expected 33 nodes, got %d" % [school, school_count])
	var hybrid_count: int = 0
	for node_id: String in nodes:
		if String(nodes[node_id].get("school", "")) == "hybrid":
			hybrid_count += 1
	if hybrid_count != 20:
		errors.append("hybrid corridors expected 20 nodes, got %d" % hybrid_count)
	var total_cost: int = 0
	for node_id: String in nodes:
		total_cost += int(nodes[node_id].get("cost", 0))
	# The locked per-type costs sum to 271 (the brief's 267 total is four
	# points short of the same category table). Keep the table authoritative so
	# every node retains its documented cost and validate the resulting total.
	if total_cost != 271:
		errors.append("complete tree expected 271 Training Points from the locked costs, got %d" % total_cost)
	var abilities_by_id: Dictionary = abilities()
	if abilities_by_id.size() != 24:
		errors.append("expected 24 combat abilities, got %d" % abilities_by_id.size())
	for ability_id: String in abilities_by_id:
		var ability: Dictionary = abilities_by_id[ability_id]
		var ranks: Array = ability.get("ranks", [])
		if ranks.size() != 5:
			errors.append("%s expected five ranks, got %d" % [ability_id, ranks.size()])
		for rank_index: int in ranks.size():
			if int(Dictionary(ranks[rank_index]).get("rank", -1)) != rank_index + 1:
				errors.append("%s has an invalid rank sequence" % ability_id)
	return {"valid": errors.is_empty(), "errors": errors, "counts": actual_counts, "node_count": nodes.size()}

static func starter_weapon_for_class(hero_class: String) -> String:
	return {"warrior": "sword", "hunter": "bow", "rogue": "daggers", "mage": "staff"}.get(hero_class, "sword")

static func school_for_ability(ability_id: String) -> String:
	var definition: Dictionary = abilities().get(ability_id, {})
	return String(definition.get("school", ""))

static func _add_school_nodes(nodes: Dictionary, school: String, school_index: int) -> void:
	# The authored canvas is a compass: Arcanist north, Vanguard east,
	# Shadow south, and Ranger west. Keep the registry order stable for save
	# and deterministic-offer code while deriving layout from the design
	# direction rather than that order.
	var school_angles: Dictionary = {"arcanist": -PI * 0.5, "vanguard": 0.0, "shadow": PI * 0.5, "ranger": PI}
	var angle: float = float(school_angles.get(school, -PI * 0.5 + float(school_index) * PI * 0.5))
	var direction: Vector2 = Vector2(cos(angle), sin(angle))
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var previous: String = "company_crest"
	var school_color: Color = SCHOOL_COLORS[school]
	var weapons: Array = SCHOOL_WEAPONS[school]
	var techniques: Array = SCHOOL_TECHNIQUES[school]
	var doctrines_list: Array = SCHOOL_DOCTRINES[school]
	var majors: Array = SCHOOL_MAJORS[school]
	var keystones: Array = SCHOOL_KEYSTONES[school]
	var minors: Array = SCHOOL_MINORS[school]
	var mastery: String = SCHOOL_MASTERY[school]
	var order: Array[Dictionary] = []
	order.append({"id": weapons[0], "name": String(weapons[0]).capitalize(), "kind": "weapon", "cost": 0, "tier": 1, "free": true, "tags": ["starter_weapon"]})
	order.append({"id": techniques[0], "name": String(techniques[0]).replace("_", " ").capitalize(), "kind": "technique", "cost": 2, "tier": 1})
	order.append({"id": minors[0], "kind": "minor", "cost": 1, "tier": 1})
	order.append({"id": minors[1], "kind": "minor", "cost": 1, "tier": 1})
	order.append({"id": majors[0], "kind": "major", "cost": 2, "tier": 2})
	order.append({"id": minors[2], "kind": "minor", "cost": 1, "tier": 2})
	order.append({"id": minors[3], "kind": "minor", "cost": 1, "tier": 2})
	order.append({"id": weapons[1], "name": String(weapons[1]).replace("_", " ").capitalize(), "kind": "weapon", "cost": 2, "tier": 2})
	order.append({"id": techniques[1], "name": String(techniques[1]).replace("_", " ").capitalize(), "kind": "technique", "cost": 2, "tier": 2})
	order.append({"id": majors[1], "kind": "major", "cost": 2, "tier": 2})
	order.append({"id": minors[4], "kind": "minor", "cost": 1, "tier": 2})
	order.append({"id": minors[5], "kind": "minor", "cost": 1, "tier": 2})
	order.append({"id": minors[6], "kind": "minor", "cost": 1, "tier": 2})
	order.append({"id": majors[2], "kind": "major", "cost": 2, "tier": 3})
	order.append({"id": minors[7], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": minors[8], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": minors[9], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": weapons[2], "name": String(weapons[2]).replace("_", " ").capitalize(), "kind": "weapon", "cost": 2, "tier": 3})
	order.append({"id": techniques[2], "name": String(techniques[2]).replace("_", " ").capitalize(), "kind": "technique", "cost": 2, "tier": 3})
	order.append({"id": majors[3], "kind": "major", "cost": 2, "tier": 3})
	order.append({"id": minors[10], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": minors[11], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": majors[4], "kind": "major", "cost": 2, "tier": 3})
	order.append({"id": minors[12], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": minors[13], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": mastery, "name": "%s Mastery" % SCHOOL_LABELS[school].capitalize(), "kind": "mastery", "cost": 3, "tier": 3})
	order.append({"id": keystones[0], "kind": "keystone", "cost": 3, "tier": 3})
	order.append({"id": minors[14], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": minors[15], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": keystones[1], "kind": "keystone", "cost": 3, "tier": 3})
	order.append({"id": minors[16], "kind": "minor", "cost": 1, "tier": 3})
	order.append({"id": doctrines_list[0], "kind": "doctrine", "cost": 3, "tier": 3})
	order.append({"id": doctrines_list[1], "kind": "doctrine", "cost": 3, "tier": 3})
	for index: int in order.size():
		var entry: Dictionary = order[index]
		var id: String = String(entry.id)
		var name: String = String(entry.get("name", id.replace("_", " ").capitalize()))
		var prerequisite_ids: Array[String] = []
		prerequisite_ids.append(previous if previous != "" else "company_crest")
		var position: Vector2 = direction * (190.0 + float(index) * 35.0) + side * float((index % 3) - 1) * 46.0
		var free_node: bool = bool(entry.get("free", false))
		var description: String = _node_description(id, school, String(entry.kind))
		var node_modifiers: Dictionary = _node_stat_modifiers(id) if String(entry.kind) in ["minor", "major", "keystone", "mastery"] else {}
		_add_node(nodes, id, name, description, String(entry.kind), school, int(entry.cost), int(entry.tier), prerequisite_ids, [school_color.to_html(false)], position, free_node, node_modifiers)
		previous = id

static func _add_hybrid_nodes(nodes: Dictionary) -> void:
	var definitions: Array[Dictionary] = [
		{"id": "marching_reach", "name": "Marching Reach", "kind": "major", "schools": ["vanguard", "ranger"], "requires": ["vanguard_mastery", "ranger_mastery"], "cost": 3, "tier": 4},
		{"id": "drilled_ballistics", "name": "Drilled Ballistics", "kind": "minor", "schools": ["vanguard", "ranger"], "requires": ["marching_reach"], "cost": 2, "tier": 4},
		{"id": "skirmisher", "name": "Skirmisher Doctrine", "kind": "doctrine", "schools": ["vanguard", "ranger"], "requires": ["drilled_ballistics"], "cost": 4, "tier": 4},
		{"id": "close_quarters_ballistics", "name": "Close-Quarters Ballistics", "kind": "major", "schools": ["ranger", "shadow"], "requires": ["ranger_mastery", "shadow_mastery"], "cost": 3, "tier": 4},
		{"id": "ambush_volley", "name": "Ambush Volley", "kind": "minor", "schools": ["ranger", "shadow"], "requires": ["close_quarters_ballistics"], "cost": 2, "tier": 4},
		{"id": "tainted_quarry", "name": "Tainted Quarry", "kind": "minor", "schools": ["ranger", "shadow"], "requires": ["ambush_volley"], "cost": 2, "tier": 4},
		{"id": "mobile_execution", "name": "Mobile Execution", "kind": "minor", "schools": ["ranger", "shadow"], "requires": ["tainted_quarry"], "cost": 2, "tier": 4},
		{"id": "cursed_venom", "name": "Cursed Venom", "kind": "major", "schools": ["shadow", "arcanist"], "requires": ["shadow_mastery", "arcanist_mastery"], "cost": 3, "tier": 4},
		{"id": "volatile_mixture", "name": "Volatile Mixture", "kind": "major", "schools": ["shadow", "arcanist"], "requires": ["cursed_venom"], "cost": 3, "tier": 4},
		{"id": "hexblade", "name": "Hexblade Doctrine", "kind": "doctrine", "schools": ["shadow", "arcanist"], "requires": ["volatile_mixture"], "cost": 4, "tier": 4},
		{"id": "elemental_shadow", "name": "Elemental Shadow", "kind": "minor", "schools": ["shadow", "arcanist"], "requires": ["hexblade"], "cost": 2, "tier": 4},
		{"id": "warded_edge", "name": "Warded Edge", "kind": "major", "schools": ["arcanist", "vanguard"], "requires": ["arcanist_mastery", "vanguard_mastery"], "cost": 3, "tier": 4},
		{"id": "elemental_impact", "name": "Elemental Impact", "kind": "major", "schools": ["arcanist", "vanguard"], "requires": ["warded_edge"], "cost": 3, "tier": 4},
		{"id": "resonant_guard", "name": "Resonant Guard", "kind": "minor", "schools": ["arcanist", "vanguard"], "requires": ["elemental_impact"], "cost": 2, "tier": 4},
		{"id": "runic_bulwark", "name": "Runic Bulwark", "kind": "minor", "schools": ["arcanist", "vanguard"], "requires": ["resonant_guard"], "cost": 2, "tier": 4},
		{"id": "adaptive_tempo", "name": "Adaptive Tempo", "kind": "major", "schools": ["vanguard", "shadow"], "requires": ["vanguard_mastery", "shadow_mastery"], "cost": 3, "tier": 5},
		{"id": "crimson_feint", "name": "Crimson Feint", "kind": "minor", "schools": ["vanguard", "shadow"], "requires": ["adaptive_tempo"], "cost": 2, "tier": 5},
		{"id": "duelist", "name": "Duelist Doctrine", "kind": "doctrine", "schools": ["vanguard", "shadow"], "requires": ["crimson_feint"], "cost": 4, "tier": 5},
		{"id": "elemental_fletching", "name": "Elemental Fletching", "kind": "major", "schools": ["ranger", "arcanist"], "requires": ["ranger_mastery", "arcanist_mastery"], "cost": 3, "tier": 5},
		{"id": "arcane_archer", "name": "Arcane Archer Doctrine", "kind": "doctrine", "schools": ["ranger", "arcanist"], "requires": ["elemental_fletching"], "cost": 4, "tier": 5}
	]
	for index: int in definitions.size():
		var entry: Dictionary = definitions[index]
		var position: Vector2 = Vector2(cos(-PI * 0.25 + float(index % 6) * PI * 0.333), sin(-PI * 0.25 + float(index % 6) * PI * 0.333)) * (760.0 + float(index / 6) * 90.0)
		var hybrid_requires: Array[String] = []
		for required_value: Variant in entry.requires:
			hybrid_requires.append(String(required_value))
		var hybrid_modifiers: Dictionary = _node_stat_modifiers(String(entry.id)) if String(entry.kind) in ["minor", "major", "keystone", "mastery"] else {}
		_add_node(nodes, String(entry.id), String(entry.name), _node_description(String(entry.id), "hybrid", String(entry.kind)), String(entry.kind), "hybrid", int(entry.cost), int(entry.tier), hybrid_requires, ["hybrid"], position, false, hybrid_modifiers)

static func _add_node(nodes: Dictionary, id: String, display_name: String, description: String, node_type: String, school: String, cost: int, tier: int, requires: Array[String], tags: Array, position: Vector2, free_node: bool = false, stat_modifiers: Dictionary = {}) -> void:
	nodes[id] = {
		"id": id,
		"name": display_name,
		"description": description,
		"node_type": node_type,
		"kind": node_type,
		"school": school,
		"cost": cost,
		"max_rank": 1,
		"prerequisite_ids": requires.duplicate(),
		"requires": requires.duplicate(),
		"exclusive_with": [],
		"unlock_id": id,
		"stat_modifiers": stat_modifiers.duplicate(true),
		"tags": tags.duplicate(),
		"training_ground_tier": tier,
		"position": position,
		"free_node": free_node
	}

static func _node_description(id: String, school: String, kind: String) -> String:
	var descriptions: Dictionary = {
		"tempered_formation": "After avoiding damage for 3 seconds, gain a barrier equal to 8% maximum health.",
		"hold_the_line": "+15% frontal damage and −5% rear damage.",
		"deep_wounds": "Heavy attacks apply one additional bleed stack.",
		"unbroken": "Below 30% health, gain armor and knockback resistance.",
		"execution_stroke": "Heavy melee consumes bleed stacks for bonus damage.",
		"steady_aim": "Remaining within a small area increases projectile damage.",
		"running_shot": "Moving a set distance empowers the next ranged attack.",
		"predators_focus": "Critical hits mark targets or extend existing marks.",
		"clean_kill": "Killing marked enemies reduces Ranger technique cooldowns.",
		"high_ground": "Deal more damage at range and less damage up close.",
		"opportunist": "Deal increased damage to enemies affected by at least two statuses.",
		"serrated_rhythm": "Every fifth blade hit applies an additional bleed stack.",
		"toxic_momentum": "Poisoned kills spread weaker poison nearby.",
		"vanishing_step": "Taking significant damage grants a short movement burst.",
		"finisher": "Gain increased critical damage against enemies below 25% health.",
		"elemental_echo": "Applying a new element to a target causes a small arcane burst.",
		"arcane_reservoir": "Technique cooldown recovery improves while no technique effect is active.",
		"lingering_runes": "Persistent elemental areas last longer but deal slightly less per tick.",
		"shatter": "Frozen normal enemies explode when killed.",
		"static_field": "Shocked enemies occasionally arc damage to wet or shocked enemies.",
		"immovable": "Armor increases while moving slowly; movement partly becomes resistance.",
		"reckless_cleaver": "Heavy attacks deal more damage but take longer.",
		"perfect_trajectory": "Projectile damage grows with each pierced enemy, but first hits weaken.",
		"relentless_motion": "Movement increases attack speed; standing still removes it.",
		"one_cut_ahead": "First-hit and execution damage improve; repeated hits lose direct damage.",
		"toxic_blood": "Taking damage emits a poison burst, but healing is weaker.",
		"unstable_elements": "Elemental reactions are stronger, but single-element damage is weaker.",
		"glass_channel": "Area and cooldown improve at the cost of health and armor."
	}
	if descriptions.has(id):
		return String(descriptions[id])
	if kind == "weapon":
		return "Unlocks this weapon for the Expedition Arsenal."
	if kind == "technique":
		return "Unlocks this automatic technique for the Expedition Arsenal."
	if kind == "doctrine":
		return "Unlocks this expedition doctrine."
	if kind == "mastery":
		return "Enables rank-five transformations for this school."
	return "Permanent %s training for the %s school." % [kind, school]

static func _node_stat_modifiers(id: String) -> Dictionary:
	var values: Dictionary = {
		# Vanguard minor lanes: Fortitude, Discipline, Bloodletting, Reach and
		# Impact. Each node has a named stat instead of sharing one opaque bonus.
		"fortified_body": {"health": 6.0}, "hardened_mail": {"armor": 2.0}, "field_medicine": {"healing": 0.06}, "rooted_stance": {"knockback_resistance": 0.05},
		"drilled_swings": {"attack_speed": 0.02}, "measured_breath": {"technique_cooldown": 0.02}, "guarded_advance": {"guard_strength": 0.03},
		"bleeding_edge": {"bleed_chance": 0.05}, "enduring_wound": {"bleed_potency": 0.08}, "blood_scent": {"bleed_duration": 1.0}, "open_vein": {"bleed_stacks": 1.0},
		"sweeping_form": {"melee_area": 0.03}, "long_reach": {"melee_range": 8.0}, "driving_force": {"pierce": 1.0}, "tempered_point": {"damage": 0.02},
		"impact_training": {"stagger": 0.08}, "close_order": {"frontal_damage": 0.03},
		# Ranger minor lanes: Fleetfoot, Precision, Fletcher, and Hunter.
		"fleetfoot": {"speed": 0.02}, "sure_foot": {"acceleration": 0.04}, "slip_mud": {"slow_resistance": 0.05}, "moving_rhythm": {"moving_attack_speed": 0.03},
		"keen_eye": {"critical": 0.01}, "lethal_draw": {"critical_damage": 0.04}, "straight_flight": {"projectile_speed": 0.04}, "distant_focus": {"distant_damage": 0.03},
		"bodkin_fletch": {"pierce": 1.0}, "bank_shot": {"ricochet": 1.0}, "long_flight": {"projectile_lifetime": 0.20},
		"lasting_mark": {"mark_duration": 2.0}, "quarry_focus": {"marked_damage": 0.05}, "trophy_hunter": {"elite_damage": 0.04}, "echoing_mark": {"mark_transfer": 0.10},
		"light_step": {"speed": 0.02}, "quick_release": {"attack_speed": 0.02},
		# Shadow minor lanes: Ambush, Venom, Blade Dance, and Escape.
		"fresh_blood": {"full_health_critical": 0.02}, "first_cut": {"first_hit_damage": 0.10}, "afterimage": {"post_mobility_damage": 0.05}, "backstab": {"rear_damage": 0.15},
		"venom_tip": {"poison_chance": 0.06}, "concentrated_venom": {"poison_potency": 0.08}, "slow_toxin": {"poison_duration": 0.10}, "sickened_prey": {"poisoned_damage": 0.05},
		"quick_blades": {"attack_speed": 0.03}, "close_quarters": {"close_damage": 0.05}, "flowing_steps": {"repeated_hit_damage": 0.03}, "relentless_flurry": {"rapid_damage": 0.04},
		"evasive_instinct": {"speed": 0.02, "evasion": 0.02}, "pain_response": {"low_health_damage": 0.05}, "lingering_smoke": {"smoke_duration": 0.15}, "prepared_escape": {"technique_cooldown": 0.02}, "execution_eye": {"execution_damage": 0.08},
		# Arcanist minor lanes: Ember, Winter, Storm, and Runic.
		"embercraft": {"burn_chance": 0.05}, "hotter_flame": {"burn_potency": 0.08}, "widened_nova": {"fire_area": 0.05}, "cinder_sense": {"burning_damage": 0.05},
		"deep_winter": {"chill_potency": 0.08}, "lower_threshold": {"freeze_threshold": -10.0}, "lasting_frost": {"chill_duration": 0.15}, "shatter_focus": {"chilled_damage": 0.05},
		"charged_air": {"shock_chance": 0.05}, "far_arc": {"chain_range": 0.15}, "forked_current": {"chain_targets": 1.0}, "storm_sense": {"shocked_damage": 0.05},
		"runic_timing": {"technique_cooldown": 0.02}, "lasting_sigils": {"duration": 0.08}, "focused_orbit": {"orbit_area": 0.10}, "warding_script": {"barrier_strength": 0.05}, "arcane_velocity": {"projectile_speed": 0.04},
		"tempered_formation": {"barrier_max_health": 0.08, "barrier_avoid_seconds": 3.0},
		"hold_the_line": {"frontal_damage": 0.15, "rear_damage": -0.05},
		"deep_wounds": {"bleed_stacks": 1.0},
		"unbroken": {"low_health_armor": 20.0, "low_health_knockback_resistance": 0.35},
		"execution_stroke": {"bleed_consume_damage": 0.12, "bleed_consume_limit": 5.0},
		"immovable": {"slow_armor": 25.0, "slow_to_knockback": 0.50},
		"reckless_cleaver": {"heavy_damage": 0.35, "heavy_interval": 0.20},
		"steady_aim": {"projectile_damage": 0.15, "stationary_radius": 32.0, "stationary_seconds": 1.5},
		"running_shot": {"moving_distance": 160.0, "bonus_projectiles": 1.0, "internal_cooldown": 2.0},
		"predators_focus": {"mark_duration": 8.0, "mark_extend": 2.0},
		"clean_kill": {"marked_cooldown_reduction": 1.0},
		"high_ground": {"distant_damage": 0.15, "close_damage": -0.10},
		"perfect_trajectory": {"pierced_damage": 0.08, "first_hit_damage": -0.15},
		"relentless_motion": {"moving_attack_speed": 0.24, "standing_attack_speed": -0.10},
		"opportunist": {"multi_status_damage": 0.15, "required_statuses": 2.0},
		"serrated_rhythm": {"blade_hit_interval": 5.0, "extra_bleed": 1.0},
		"toxic_momentum": {"poison_spread_potency": 0.50},
		"vanishing_step": {"damage_threshold": 0.15, "movement_burst": 0.25, "burst_duration": 2.0, "cooldown": 10.0},
		"finisher": {"low_health_critical_damage": 0.30, "health_threshold": 0.25},
		"one_cut_ahead": {"first_hit_damage": 0.35, "execution_damage": 0.35, "repeat_loss": -0.03, "repeat_loss_cap": -0.15},
		"toxic_blood": {"poison_burst": 1.0, "cooldown": 3.0, "healing": -0.20},
		"elemental_echo": {"reaction_power": 0.35, "target_cooldown": 1.0},
		"arcane_reservoir": {"inactive_cooldown_speed": 0.20},
		"lingering_runes": {"persistent_duration": 0.35, "persistent_tick_damage": -0.10},
		"shatter": {"freeze_explosion_power": 0.75, "boss_pulse_power": 0.30},
		"static_field": {"shock_arc_chance": 0.15, "shock_arc_power": 0.30},
		"unstable_elements": {"reaction_power": 0.40, "single_element_damage": -0.15},
		"glass_channel": {"area": 0.25, "technique_cooldown": 0.15, "health_multiplier": -0.20, "armor": -20.0},
		"marching_reach": {"moving_distance": 120.0, "next_attack_damage": 0.12},
		"drilled_ballistics": {"reach_to_projectile": 0.50, "speed_to_reach": 0.50},
		"close_quarters_ballistics": {"close_critical": 0.08},
		"ambush_volley": {"mobility_projectile_damage": 0.15},
		"tainted_quarry": {"marked_poison_stack": 1.0, "ricochet_bleed_chance": 0.10},
		"mobile_execution": {"moving_execution_damage": 0.15},
		"cursed_venom": {"elemental_status_buildup": 0.10},
		"volatile_mixture": {"poison_consume_burst": 1.0, "cooldown": 3.0},
		"elemental_shadow": {"dominant_element_trail": 1.0},
		"warded_edge": {"barrier_melee_damage": 0.10},
		"elemental_impact": {"heavy_element_wave": 0.25},
		"resonant_guard": {"barrier_cooldown_reduction": 0.50, "cooldown": 1.0},
		"runic_bulwark": {"barrier_strength": 0.15},
		"adaptive_tempo": {"alternating_damage": 0.12},
		"crimson_feint": {"mobility_critical": 0.10},
		"elemental_fletching": {"projectile_elemental_status": 0.20},
	}
	if values.has(id):
		return Dictionary(values[id]).duplicate(true)
	var generic: Dictionary = {
		"health": 6.0, "armor": 2.0, "speed": 0.02, "damage": 0.02, "attack_speed": 0.02,
		"melee_damage": 0.02, "ranged_damage": 0.02, "arcane_damage": 0.02, "critical": 0.01,
		"critical_damage": 0.04, "melee_area": 0.03, "projectile_speed": 0.04, "pierce": 1.0,
		"pickup": 8.0, "technique_cooldown": 0.02
	}
	return generic

static func _add_weapon(result: Dictionary, id: String, display_name: String, school: String, category: String, power: float, interval: float, range_value: float, tags: Array, rank_descriptions: Array) -> void:
	var ranks: Array[Dictionary] = []
	for rank_index: int in 5:
		var rank: int = rank_index + 1
		var rank_data: Dictionary = {"rank": rank, "damage_multiplier": 1.0, "cooldown_or_interval": interval, "area_multiplier": 1.0, "duration_multiplier": 1.0, "projectile_count": 1, "pierce": 0, "stat_changes": {}, "status_application": {}, "behavior_flags": [], "visual_upgrade": "", "description": String(rank_descriptions[rank_index])}
		var changes: Dictionary = _weapon_rank_changes(id, rank)
		rank_data.merge(changes, true)
		ranks.append(rank_data)
	result[id] = {"id": id, "name": display_name, "school": school, "category": category, "tags": tags, "base_stats": {"normalized_power": power, "interval": interval, "range": range_value}, "ranks": ranks}

static func _add_technique(result: Dictionary, id: String, display_name: String, school: String, cooldown: float, rank_descriptions: Array) -> void:
	var ranks: Array[Dictionary] = []
	for rank_index: int in 5:
		var rank: int = rank_index + 1
		var rank_data: Dictionary = {"rank": rank, "damage_multiplier": 1.0, "cooldown_or_interval": cooldown, "area_multiplier": 1.0, "duration_multiplier": 1.0, "projectile_count": 0, "pierce": 0, "stat_changes": {}, "status_application": {}, "behavior_flags": [id], "visual_upgrade": "", "description": String(rank_descriptions[rank_index])}
		var changes: Dictionary = _technique_rank_changes(id, rank)
		rank_data.merge(changes, true)
		ranks.append(rank_data)
	result[id] = {"id": id, "name": display_name, "school": school, "category": "technique", "tags": [school, "automatic"], "base_stats": {"cooldown": cooldown}, "ranks": ranks}

## Rank values are deliberately data-only. The combat runtime can consume the
## same fields for every ability instead of branching on individual weapon
## names. Descriptions remain the player-facing authority; these values make
## the progression inspectable and testable by tools.
static func _weapon_rank_changes(id: String, rank: int) -> Dictionary:
	var changes: Dictionary = {}
	match id:
		"sword":
			if rank == 2: changes = {"damage_multiplier": 1.20, "area_multiplier": 1.15, "stat_changes": {"damage": 0.20, "area": 0.15}}
			elif rank == 3: changes = {"stat_changes": {"double_cut_interval": 3, "double_cut_damage": 0.70}, "behavior_flags": ["double_cut"]}
			elif rank == 4: changes = {"status_application": {"status": "bleed", "chance": 0.18, "potency": 1.0, "duration": 5.0}, "behavior_flags": ["double_cut_bleed"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "area_multiplier": 1.35, "stat_changes": {"double_cut_interval": 2, "projectile_deflect_cooldown": 1.25}, "behavior_flags": ["crescent_guard", "deflect_minor_projectiles"], "visual_upgrade": "crescent_guard_trail"}
		"spear":
			if rank == 2: changes = {"pierce": 1, "stat_changes": {"reach": 0.25}}
			elif rank == 3: changes = {"stat_changes": {"impaling_interval": 4, "elite_damage": 0.20}, "behavior_flags": ["wide_impaling_rhythm"]}
			elif rank == 4: changes = {"stat_changes": {"wall_pin_seconds": 1.25, "boss_stagger": 0.15}, "behavior_flags": ["pin_near_solid"]}
			elif rank == 5: changes = {"projectile_count": 3, "stat_changes": {"spectral_side_damage": 0.65}, "behavior_flags": ["phalanx_side_thrusts"], "visual_upgrade": "phalanx_trails"}
		"greatsword":
			if rank == 2: changes = {"damage_multiplier": 1.25, "stat_changes": {"knockback": 0.25}}
			elif rank == 3: changes = {"stat_changes": {"shockwave_damage": 0.35, "shockwave_range": 0.80}, "behavior_flags": ["ground_shockwave"]}
			elif rank == 4: changes = {"stat_changes": {"blade_shockwave_bonus": 0.20, "stagger": 0.25}, "behavior_flags": ["crushing_momentum"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "stat_changes": {"fissure_interval": 3, "fissure_duration": 2.5}, "behavior_flags": ["earthsplitter_fissure"], "visual_upgrade": "earthsplitter_crack"}
		"bow":
			if rank == 2: changes = {"damage_multiplier": 1.20, "stat_changes": {"projectile_speed": 0.20}}
			elif rank == 3: changes = {"projectile_count": 2, "stat_changes": {"split_interval": 3, "split_spread": 0.12}, "behavior_flags": ["split_fletching"]}
			elif rank == 4: changes = {"status_application": {"status": "mark", "chance": 1.0, "potency": 0.15, "duration": 8.0}, "behavior_flags": ["mark_on_critical", "home_on_marked"]}
			elif rank == 5: changes = {"projectile_count": 2, "pierce": 1, "damage_multiplier": 1.10, "stat_changes": {"volley_interval": 5, "volley_projectile_count": 5, "central_arrow_damage": 1.50}, "behavior_flags": ["storm_volley"], "visual_upgrade": "storm_volley_fan"}
		"sling":
			if rank == 2: changes = {"damage_multiplier": 1.20, "stat_changes": {"projectile_speed": 0.15}}
			elif rank == 3: changes = {"stat_changes": {"ricochet_count": 3, "ricochet_damage_per_bounce": 0.08}, "behavior_flags": ["double_ricochet"]}
			elif rank == 4: changes = {"stat_changes": {"stagger_per_repeat": 0.12}, "behavior_flags": ["stunning_impact"]}
			elif rank == 5: changes = {"projectile_count": 5, "damage_multiplier": 1.35, "stat_changes": {"meteor_interval": 6, "fracture_count": 4}, "behavior_flags": ["meteor_sling"], "visual_upgrade": "meteor_sling_impact"}
		"crossbow":
			if rank == 2: changes = {"damage_multiplier": 1.25, "pierce": 1}
			elif rank == 3: changes = {"projectile_count": 2, "stat_changes": {"repeat_interval": 3}, "behavior_flags": ["repeating_mechanism"]}
			elif rank == 4: changes = {"stat_changes": {"armor_break": 0.15, "armor_break_duration": 5.0}, "behavior_flags": ["armor_breaker"]}
			elif rank == 5: changes = {"damage_multiplier": 1.40, "pierce": 3, "stat_changes": {"ballista_interval": 6, "ballista_push": 0.60}, "behavior_flags": ["ballista_pattern"], "visual_upgrade": "ballista_bolt"}
		"daggers":
			if rank == 2: changes = {"stat_changes": {"attack_speed": 0.18, "target_range": 0.15}}
			elif rank == 3: changes = {"stat_changes": {"circle_interval": 4, "circle_area": 1.0}, "behavior_flags": ["blade_dance"]}
			elif rank == 4: changes = {"status_application": {"status": "bleed", "chance": 1.0, "potency": 1.0, "duration": 5.0}, "stat_changes": {"critical_vs_poison": 0.15}, "behavior_flags": ["serrated_tips"]}
			elif rank == 5: changes = {"damage_multiplier": 1.10, "stat_changes": {"circle_interval": 3, "blade_wave_range": 0.65}, "behavior_flags": ["thousand_cuts"], "visual_upgrade": "blade_waves"}
		"throwing_knives":
			if rank == 2: changes = {"projectile_count": 4, "stat_changes": {"spread": -0.15}}
			elif rank == 3: changes = {"stat_changes": {"return_damage": 0.80}, "behavior_flags": ["rebound"]}
			elif rank == 4: changes = {"stat_changes": {"execute_threshold": 0.30, "execute_critical_damage": 0.35}, "behavior_flags": ["executioners_edge"]}
			elif rank == 5: changes = {"projectile_count": 6, "damage_multiplier": 1.10, "stat_changes": {"fan_count": 2, "return_orbit_seconds": 1.0}, "behavior_flags": ["endless_blades"], "visual_upgrade": "returning_fan"}
		"chakrams":
			if rank == 2: changes = {"damage_multiplier": 1.20, "area_multiplier": 1.15}
			elif rank == 3: changes = {"projectile_count": 2, "behavior_flags": ["twin_orbit"]}
			elif rank == 4: changes = {"stat_changes": {"return_orbit_seconds": 1.25}, "behavior_flags": ["circling_blades"]}
			elif rank == 5: changes = {"projectile_count": 4, "damage_multiplier": 1.15, "stat_changes": {"fragment_count": 6, "array_duration": 3.0}, "behavior_flags": ["blade_constellation"], "visual_upgrade": "orbiting_fragments"}
		"staff":
			if rank == 2: changes = {"damage_multiplier": 1.20, "area_multiplier": 1.20}
			elif rank == 3: changes = {"stat_changes": {"element_cycle": 3}, "behavior_flags": ["elemental_cycle"]}
			elif rank == 4: changes = {"stat_changes": {"resonance_power": 0.25}, "behavior_flags": ["elemental_resonance"]}
			elif rank == 5: changes = {"projectile_count": 3, "damage_multiplier": 1.10, "stat_changes": {"convergence_interval": 6}, "behavior_flags": ["grand_convergence"], "visual_upgrade": "elemental_convergence"}
		"wand":
			if rank == 2: changes = {"stat_changes": {"attack_speed": 0.15, "projectile_speed": 0.20}}
			elif rank == 3: changes = {"projectile_count": 2, "stat_changes": {"fork_interval": 4}, "behavior_flags": ["forked_casting"]}
			elif rank == 4: changes = {"stat_changes": {"attunement_status": 1.0}, "behavior_flags": ["elemental_attunement"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "stat_changes": {"charge_threshold": 8, "seeking_bolts": 5}, "behavior_flags": ["arcane_torrent"], "visual_upgrade": "seeking_burst"}
		"runic_orb":
			if rank == 2: changes = {"damage_multiplier": 1.20, "area_multiplier": 1.25}
			elif rank == 3: changes = {"projectile_count": 2, "behavior_flags": ["second_rune"]}
			elif rank == 4: changes = {"stat_changes": {"trail_duration": 1.5}, "behavior_flags": ["runic_wake"]}
			elif rank == 5: changes = {"projectile_count": 4, "damage_multiplier": 1.15, "stat_changes": {"pulse_interval": 4, "outer_orbit_multiplier": 1.35}, "behavior_flags": ["celestial_array"], "visual_upgrade": "aligned_arcane_pulse"}
	return changes

static func _technique_rank_changes(id: String, rank: int) -> Dictionary:
	var changes: Dictionary = {}
	match id:
		"ground_slam":
			if rank == 2: changes = {"damage_multiplier": 1.25, "area_multiplier": 1.25}
			elif rank == 3: changes = {"projectile_count": 3, "stat_changes": {"fissure_length": 0.75}, "behavior_flags": ["three_fissures"]}
			elif rank == 4: changes = {"stat_changes": {"elite_stagger": 0.35}, "behavior_flags": ["break_brittle"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "duration_multiplier": 1.50, "stat_changes": {"zone_tick_interval": 0.75}, "behavior_flags": ["fractured_zone"], "visual_upgrade": "persistent_fissures"}
		"shield_wall":
			if rank == 2: changes = {"duration_multiplier": 1.25, "stat_changes": {"barrier_strength": 0.25}}
			elif rank == 3: changes = {"behavior_flags": ["reflect_minor_projectiles"]}
			elif rank == 4: changes = {"stat_changes": {"touch_push": 0.35, "touch_weakness": 0.15}, "behavior_flags": ["push_and_weaken"]}
			elif rank == 5: changes = {"projectile_count": 3, "duration_multiplier": 1.15, "behavior_flags": ["three_shield_formation"], "visual_upgrade": "shield_formation"}
		"war_cry":
			if rank == 2: changes = {"duration_multiplier": 1.25}
			elif rank == 3: changes = {"stat_changes": {"attack_speed": 0.15, "knockback_resistance": 0.35}, "behavior_flags": ["combat_cry"]}
			elif rank == 4: changes = {"behavior_flags": ["bleed_fear"]}
			elif rank == 5: changes = {"duration_multiplier": 1.20, "stat_changes": {"kill_extension": 0.75, "max_extension": 6.0}, "behavior_flags": ["kill_extension"], "visual_upgrade": "war_cry_banner"}
		"rain_of_arrows":
			if rank == 2: changes = {"area_multiplier": 1.25, "projectile_count": 2}
			elif rank == 3: changes = {"behavior_flags": ["mark_first_wave"], "status_application": {"status": "mark", "chance": 1.0, "potency": 0.15, "duration": 8.0}}
			elif rank == 4: changes = {"stat_changes": {"critical_extra_arrows": 1}, "behavior_flags": ["critical_call_arrows"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "pierce": 2, "stat_changes": {"heavy_final_wave": 1.5}, "behavior_flags": ["heavy_final_wave"], "visual_upgrade": "piercing_storm"}
		"hunters_mark":
			if rank == 2: changes = {"duration_multiplier": 1.25, "stat_changes": {"marked_damage": 0.15}}
			elif rank == 3: changes = {"behavior_flags": ["transfer_on_kill"]}
			elif rank == 4: changes = {"behavior_flags": ["home_on_marked"]}
			elif rank == 5: changes = {"damage_multiplier": 1.10, "stat_changes": {"pulse_damage_from_received": 0.25, "pulse_interval": 2.0}, "behavior_flags": ["marked_pulse"], "visual_upgrade": "mark_pulse"}
		"windstep":
			if rank == 2: changes = {"cooldown_or_interval": 9.35, "duration_multiplier": 1.25}
			elif rank == 3: changes = {"stat_changes": {"gust_push": 0.35}, "behavior_flags": ["gust"]}
			elif rank == 4: changes = {"projectile_count": 2, "behavior_flags": ["next_attack_projectiles"]}
			elif rank == 5: changes = {"stat_changes": {"charges": 2, "minimum_delay": 2.0}, "behavior_flags": ["two_charges"], "visual_upgrade": "double_windstep"}
		"smoke_veil":
			if rank == 2: changes = {"area_multiplier": 1.25, "duration_multiplier": 1.25}
			elif rank == 3: changes = {"stat_changes": {"movement_speed": 0.20}, "behavior_flags": ["speed_inside_smoke"]}
			elif rank == 4: changes = {"stat_changes": {"critical_vulnerability": 0.20}, "behavior_flags": ["critical_vulnerability"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "stat_changes": {"copies": 2}, "behavior_flags": ["shadow_copies"], "visual_upgrade": "departing_copies"}
		"poison_flask":
			if rank == 2: changes = {"area_multiplier": 1.25, "duration_multiplier": 1.25}
			elif rank == 3: changes = {"status_application": {"status": "poison", "chance": 1.0, "potency": 1.0, "stacks": 3}, "behavior_flags": ["impact_stacks"]}
			elif rank == 4: changes = {"stat_changes": {"death_pool_growth": 0.20}, "behavior_flags": ["death_expands_pool"]}
			elif rank == 5: changes = {"damage_multiplier": 1.10, "stat_changes": {"toxic_projectile_interval": 2.5}, "behavior_flags": ["toxic_projectiles"], "visual_upgrade": "toxic_pool_projectiles"}
		"shadowstep":
			if rank == 2: changes = {"damage_multiplier": 1.25, "stat_changes": {"target_range": 0.20}}
			elif rank == 3: changes = {"stat_changes": {"trail_duration": 1.5}, "behavior_flags": ["shadow_trail"]}
			elif rank == 4: changes = {"stat_changes": {"kill_cooldown_refund": 0.35}, "behavior_flags": ["kill_refund"]}
			elif rank == 5: changes = {"damage_multiplier": 1.20, "stat_changes": {"targets": 3}, "behavior_flags": ["three_target_sequence"], "visual_upgrade": "shadow_sequence"}
		"fire_nova":
			if rank == 2: changes = {"area_multiplier": 1.25, "damage_multiplier": 1.15}
			elif rank == 3: changes = {"duration_multiplier": 1.25, "behavior_flags": ["burning_ring"]}
			elif rank == 4: changes = {"stat_changes": {"flame_burst_power": 0.30}, "behavior_flags": ["burning_enemy_bursts"]}
			elif rank == 5: changes = {"damage_multiplier": 1.20, "area_multiplier": 1.30, "behavior_flags": ["expand_collapse_double_hit"], "visual_upgrade": "converging_fire_ring"}
		"frost_ring":
			if rank == 2: changes = {"area_multiplier": 1.20, "stat_changes": {"chill": 0.25}}
			elif rank == 3: changes = {"stat_changes": {"freeze_near_player": 1.0}, "behavior_flags": ["freeze_threshold"]}
			elif rank == 4: changes = {"stat_changes": {"impact_damage_bonus": 0.20}, "behavior_flags": ["shatter_vulnerability"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "duration_multiplier": 1.50, "behavior_flags": ["ice_crystal_boundary"], "visual_upgrade": "ice_crystal_ring"}
		"chain_lightning":
			if rank == 2: changes = {"damage_multiplier": 1.20, "stat_changes": {"chain_range": 0.20}}
			elif rank == 3: changes = {"stat_changes": {"additional_chains": 2}, "behavior_flags": ["extended_chain"]}
			elif rank == 4: changes = {"behavior_flags": ["wet_shocked_free_chain"]}
			elif rank == 5: changes = {"damage_multiplier": 1.15, "stat_changes": {"final_burst_power": 0.50, "return_chain_count": 2}, "behavior_flags": ["returning_chain_burst"], "visual_upgrade": "forked_storm"}
	return changes

static func _doctrine(display_name: String, school: String, description: String, modifiers: Dictionary, exclusive_with: Array = []) -> Dictionary:
	return {"name": display_name, "school": school, "description": description, "modifiers": modifiers, "exclusive_with": exclusive_with}
