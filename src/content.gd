class_name GameContent
extends RefCounted

const CLASSES: Dictionary = {
	"warrior": {"name": "Warrior", "description": "A hard-bitten shield hand. More health and a stronger Guard Step.", "starting_weapon": "spear", "health": 18.0, "guard": 0.05, "damage": 0.0},
	"mage": {"name": "Moor Mage", "description": "A hedge scholar carrying pale fire from the old barrow.", "starting_weapon": "witchfire", "health": 0.0, "guard": 0.0, "damage": 0.12}
}

const DOCTRINES: Dictionary = {
	"shield_line": {"name": "Shield Line", "description": "Guard Step lasts longer and melee attacks stagger harder.", "guard": 0.04, "melee_damage": 0.06},
	"pursuer": {"name": "Pursuer", "description": "Moving toward a foe makes the next weapon attack hit harder.", "damage": 0.08, "speed": 0.04},
	"barrow_scholar": {"name": "Barrow Scholar", "description": "Arcane attacks burn brighter and supernatural foes are exposed.", "arcane_damage": 0.14, "damage": 0.02},
	"hedge_alchemist": {"name": "Hedge Alchemist", "description": "Witchfire impacts leave a lingering ember zone.", "arcane_damage": 0.08, "area": 0.10},
	"grave_listener": {"name": "Grave Listener", "description": "Supernatural enemies take more damage, but ordinary foes resist your first hit.", "arcane_damage": 0.10, "damage": -0.03}
}

const RELICS: Dictionary = {
	"wolf_tooth": {"name": "Wolf Tooth", "description": "Move faster and strike harder while wounded.", "stat": "wounded_damage", "amount": 0.22},
	"barrow_candle": {"name": "Barrow Candle", "description": "Arcane damage rises, but more supernatural foes answer the call.", "stat": "arcane_damage", "amount": 0.18},
	"broken_buckler": {"name": "Broken Buckler", "description": "Guard Step recovers sooner, but ranged damage is reduced.", "stat": "guard_cooldown", "amount": 1.0},
	"fletched_pennant": {"name": "Fletched Pennant", "description": "Carry one extra projectile; each projectile deals slightly less harm.", "stat": "projectiles", "amount": 1.0},
	"field_surgeons_kit": {"name": "Field Surgeon's Kit", "description": "Maximum health and field recovery rise together.", "stat": "health", "amount": 16.0}
}

const CONTRACTS: Dictionary = {
	"hound_hunt": {"name": "Hunt the Houndmaster", "description": "Kill the next elite before it escapes.", "kind": "elite_kill", "reward": 35},
	"hold_the_moor": {"name": "Hold the Moor", "description": "Stay alive for 25 seconds after accepting.", "kind": "survive", "duration": 25.0, "reward": 28},
	"break_the_shields": {"name": "Break the Shield Wall", "description": "Kill 8 shielded reavers before the next elite falls.", "kind": "reaver_kills", "target": 8, "reward": 40}
}

const OBJECTIVES: Dictionary = {
	"night_watch": {"name": "Night Watch", "description": "Survive until the first elite arrives.", "kind": "survive", "target": 120.0, "reward": 20},
	"moor_cull": {"name": "Moor Cull", "description": "Kill 35 ordinary enemies.", "kind": "kills", "target": 35, "reward": 24},
	"company_standard": {"name": "Recover the Company Standard", "description": "Defeat an elite and claim its banner.", "kind": "elite", "target": 1, "reward": 36}
}

const CURSES: Dictionary = {
	"none": {"name": "Clear Moor", "description": "A standard expedition.", "health": 1.0, "damage": 1.0, "reward": 1.0},
	"long_night": {"name": "The Long Night", "description": "Enemies are tougher; rewards increase.", "health": 1.16, "damage": 1.08, "reward": 1.28},
	"black_moon": {"name": "Black Moon", "description": "Supernatural enemies appear more often.", "health": 1.05, "damage": 1.04, "reward": 1.22},
	"thin_rations": {"name": "Thin Rations", "description": "Experience drops are scarcer; provisions increase.", "health": 1.0, "damage": 1.06, "reward": 1.18}
}

const WEAPONS: Dictionary = {
	"spear": {"name": "Boar Spear", "category": "MELEE", "description": "A committed thrust that stops at the nearest rank.", "cooldown": 0.82, "damage": 21.0, "speed": 0.0, "radius": 48.0, "pierce": 2, "behavior": "thrust", "color": Color("d8c69c"), "technique": "braced_stance", "mastery": "Ashwood Pike"},
	"axe": {"name": "Woodsman's Axe", "category": "MELEE", "description": "A close, punishing sweep.", "cooldown": 1.18, "damage": 27.0, "speed": 0.0, "radius": 66.0, "pierce": 99, "behavior": "sweep", "color": Color("b7aaa0"), "technique": "cleaving_footwork", "mastery": "Bearded Axe"},
	"bow": {"name": "Longbow", "category": "RANGED", "description": "A heavy shaft aimed through the crowd.", "cooldown": 1.35, "damage": 31.0, "speed": 520.0, "radius": 4.0, "pierce": 1, "behavior": "line", "color": Color("d8b36a"), "technique": "bodkin_craft", "mastery": "War Bow"},
	"sling": {"name": "Sling", "category": "RANGED", "description": "Stones burst against packed foes.", "cooldown": 1.55, "damage": 23.0, "speed": 330.0, "radius": 7.0, "pierce": 1, "behavior": "splash", "color": Color("b9a58d"), "technique": "weighted_heads", "mastery": ""},
	"knives": {"name": "Throwing Knives", "category": "RANGED", "description": "A quick fan of balanced blades.", "cooldown": 0.92, "damage": 12.0, "speed": 480.0, "radius": 4.0, "pierce": 1, "behavior": "fan", "color": Color("c6cbd0"), "technique": "quick_hands", "mastery": ""},
	"caltrops": {"name": "Caltrops", "category": "RANGED", "description": "Iron thorns hold the ground behind you.", "cooldown": 2.8, "damage": 8.0, "speed": 0.0, "radius": 34.0, "pierce": 99, "behavior": "trap", "color": Color("8f969b"), "technique": "scavengers_reach", "mastery": ""},
	"witchfire": {"name": "Witchfire", "category": "ARCANE", "description": "A pale ember seeks the nearest living thing.", "cooldown": 1.20, "damage": 26.0, "speed": 245.0, "radius": 7.0, "pierce": 2, "behavior": "hex", "color": Color("78aaa2"), "technique": "ember_lore", "mastery": "Greenfire Brand"}
}

const TECHNIQUES: Dictionary = {
	"braced_stance": {"name": "Braced Stance", "description": "Set the haft and reach one body farther with each thrust.", "stat": "reach", "amount": 12.0},
	"cleaving_footwork": {"name": "Cleaving Footwork", "description": "Sweeps cover more ground.", "stat": "area", "amount": 0.12},
	"bodkin_craft": {"name": "Bodkin Craft", "description": "Arrows bite through armor.", "stat": "pierce", "amount": 1.0},
	"strong_arm": {"name": "Strong Arm", "description": "All weapon damage rises by 10%.", "stat": "damage", "amount": 0.10},
	"quick_hands": {"name": "Quick Hands", "description": "Recover weapons 8% faster.", "stat": "cooldown", "amount": 0.08},
	"hard_march": {"name": "Hard March", "description": "Maximum health rises by 12.", "stat": "health", "amount": 12.0},
	"mail_lining": {"name": "Mail Lining", "description": "Incoming harm is reduced.", "stat": "armor", "amount": 0.06},
	"field_dressing": {"name": "Field Dressing", "description": "Recover one health every six seconds.", "stat": "recovery", "amount": 1.0},
	"keen_eye": {"name": "Keen Eye", "description": "Critical chance rises by 6%.", "stat": "critical", "amount": 0.06},
	"scavengers_reach": {"name": "Scavenger's Reach", "description": "Gather experience from farther away.", "stat": "pickup", "amount": 18.0},
	"weighted_heads": {"name": "Weighted Heads", "description": "Hits stagger foes more strongly.", "stat": "stagger", "amount": 0.14},
	"deep_quiver": {"name": "Deep Quiver", "description": "Ranged attacks gain an extra projectile.", "stat": "projectiles", "amount": 1.0},
	"iron_grip": {"name": "Iron Grip", "description": "Melee weapons land 10% harder.", "stat": "melee_damage", "amount": 0.10},
	"measured_breath": {"name": "Measured Breath", "description": "Ranged weapons recover 8% faster after a calm release.", "stat": "ranged_cooldown", "amount": 0.08},
	"patched_padding": {"name": "Patched Padding", "description": "Layered cloth adds 8 maximum health.", "stat": "health", "amount": 8.0},
	"shield_wall": {"name": "Shield Wall", "description": "Guard Step turns aside another 6% of incoming harm.", "stat": "guard", "amount": 0.06},
	"long_stride": {"name": "Long Stride", "description": "Sure footing raises movement speed by 5%.", "stat": "speed", "amount": 0.05},
	"lantern_hook": {"name": "Lantern Hook", "description": "A hooked lantern draws experience from 12 paces farther.", "stat": "pickup", "amount": 12.0},
	"barbed_heads": {"name": "Barbed Heads", "description": "Notched iron makes every hit stagger harder.", "stat": "stagger", "amount": 0.10},
	"fletched_shafts": {"name": "Fletched Shafts", "description": "Ranged weapons deal 8% more damage with true-flying shafts.", "stat": "ranged_damage", "amount": 0.08},
	"ember_lore": {"name": "Ember Lore", "description": "Witchfire burns 12% hotter and its sparks pierce one more foe.", "stat": "arcane_damage", "amount": 0.12},
	"riposte_drill": {"name": "Shield Riposte", "description": "Guard Step answers nearby foes with a punishing shield blow.", "stat": "guard_blast", "amount": 24.0},
	"marked_prey": {"name": "Marked Prey", "description": "Elites and bosses suffer 15% more damage.", "stat": "elite_damage", "amount": 0.15},
	"twin_cast": {"name": "Twin Cast", "description": "Arcane weapons release one additional ember.", "stat": "arcane_projectiles", "amount": 1.0},
	"second_wind": {"name": "Second Wind", "description": "Once per expedition, recover 28 health when badly wounded.", "stat": "second_wind", "amount": 28.0},
	"salvagers_eye": {"name": "Salvager's Eye", "description": "Elite equipment is more likely to be well made.", "stat": "loot_luck", "amount": 0.12}
}

const BASE_TECHNIQUES: Array[String] = ["strong_arm", "long_stride", "patched_padding"]

const PROGRESSION_BRANCHES: Dictionary = {
	"VANGUARD": ["vanguard_drill", "vanguard_axe", "vanguard_grip", "vanguard_shield", "vanguard_riposte", "vanguard_mastery"],
	"HUNTSMAN": ["huntsman_sling", "huntsman_bow", "huntsman_knives", "huntsman_caltrops", "huntsman_quiver", "huntsman_mark"],
	"HEDGECRAFT": ["hedge_embers", "hedge_lantern", "hedge_twin_cast", "hedge_dressing", "hedge_second_wind", "hedge_mastery"],
	"COMPANYCRAFT": ["company_hands", "company_march", "company_eye", "company_mail", "company_stores", "company_training"]
}

const PROGRESSION_NODES: Dictionary = {
	"vanguard_drill": {"name": "Ashwood Drill", "description": "Adds Braced Stance to level-up choices.", "kind": "technique", "unlock": "braced_stance", "max_rank": 1, "cost": [18, 6], "requires": []},
	"vanguard_axe": {"name": "Woodsman's Muster", "description": "Unlocks the Woodsman's Axe in expeditions.", "kind": "weapon", "unlock": "axe", "max_rank": 1, "cost": [32, 10], "requires": ["vanguard_drill"]},
	"vanguard_grip": {"name": "Iron Grip", "description": "Adds the Iron Grip melee passive.", "kind": "technique", "unlock": "iron_grip", "max_rank": 1, "cost": [42, 14], "requires": ["vanguard_axe"]},
	"vanguard_shield": {"name": "Shield Wall", "description": "Adds the Shield Wall guard passive.", "kind": "technique", "unlock": "shield_wall", "max_rank": 1, "cost": [55, 18], "requires": ["vanguard_grip"]},
	"vanguard_riposte": {"name": "Shield Riposte", "description": "Unlocks a Guard Step counterattack.", "kind": "technique", "unlock": "riposte_drill", "max_rank": 1, "cost": [72, 24], "requires": ["vanguard_shield"]},
	"vanguard_mastery": {"name": "Master-at-Arms", "description": "Allows spear and axe mastery upgrades.", "kind": "mastery", "unlock": "vanguard", "max_rank": 1, "cost": [95, 32], "requires": ["vanguard_riposte"]},

	"huntsman_sling": {"name": "Stone Drill", "description": "Adds Weighted Heads to level-up choices.", "kind": "technique", "unlock": "weighted_heads", "max_rank": 1, "cost": [18, 6], "requires": []},
	"huntsman_bow": {"name": "Bowyer's Bench", "description": "Unlocks the Longbow and Bodkin Craft.", "kind": "weapon_technique", "unlock": "bow", "technique": "bodkin_craft", "max_rank": 1, "cost": [35, 12], "requires": ["huntsman_sling"]},
	"huntsman_knives": {"name": "Balanced Blades", "description": "Unlocks Throwing Knives.", "kind": "weapon_technique", "unlock": "knives", "technique": "quick_hands", "max_rank": 1, "cost": [48, 15], "requires": ["huntsman_bow"]},
	"huntsman_caltrops": {"name": "Iron Thorns", "description": "Unlocks Caltrops and Scavenger's Reach.", "kind": "weapon_technique", "unlock": "caltrops", "technique": "scavengers_reach", "max_rank": 1, "cost": [62, 20], "requires": ["huntsman_knives"]},
	"huntsman_quiver": {"name": "Deep Quiver", "description": "Adds Deep Quiver to level-up choices.", "kind": "technique", "unlock": "deep_quiver", "max_rank": 1, "cost": [78, 26], "requires": ["huntsman_caltrops"]},
	"huntsman_mark": {"name": "Marked Prey", "description": "Unlocks bonus damage against elites and bosses.", "kind": "technique", "unlock": "marked_prey", "max_rank": 1, "cost": [98, 32], "requires": ["huntsman_quiver"]},

	"hedge_embers": {"name": "Ember Lessons", "description": "Adds Ember Lore to level-up choices.", "kind": "technique", "unlock": "ember_lore", "max_rank": 1, "cost": [18, 6], "requires": []},
	"hedge_lantern": {"name": "Lantern Hook", "description": "Adds the Lantern Hook passive.", "kind": "technique", "unlock": "lantern_hook", "max_rank": 1, "cost": [30, 11], "requires": ["hedge_embers"]},
	"hedge_twin_cast": {"name": "Twin Cast", "description": "Unlocks an additional arcane projectile.", "kind": "technique", "unlock": "twin_cast", "max_rank": 1, "cost": [46, 16], "requires": ["hedge_lantern"]},
	"hedge_dressing": {"name": "Hedge Remedies", "description": "Adds Field Dressing to level-up choices.", "kind": "technique", "unlock": "field_dressing", "max_rank": 1, "cost": [60, 21], "requires": ["hedge_twin_cast"]},
	"hedge_second_wind": {"name": "Second Wind", "description": "Unlocks one emergency recovery each run.", "kind": "technique", "unlock": "second_wind", "max_rank": 1, "cost": [78, 27], "requires": ["hedge_dressing"]},
	"hedge_mastery": {"name": "Barrow Cant", "description": "Allows Witchfire mastery upgrades.", "kind": "mastery", "unlock": "hedge", "max_rank": 1, "cost": [100, 34], "requires": ["hedge_second_wind"]},

	"company_hands": {"name": "Practical Lessons", "description": "Adds Quick Hands to level-up choices.", "kind": "technique", "unlock": "quick_hands", "max_rank": 1, "cost": [18, 6], "requires": []},
	"company_march": {"name": "Hard March", "description": "Adds the Hard March health passive.", "kind": "technique", "unlock": "hard_march", "max_rank": 1, "cost": [30, 10], "requires": ["company_hands"]},
	"company_eye": {"name": "Keen Eye", "description": "Adds Keen Eye and Salvager's Eye to level ups.", "kind": "double_technique", "unlock": "keen_eye", "technique": "salvagers_eye", "max_rank": 1, "cost": [44, 15], "requires": ["company_march"]},
	"company_mail": {"name": "Mail Lining", "description": "Adds Mail Lining to level-up choices.", "kind": "technique", "unlock": "mail_lining", "max_rank": 1, "cost": [58, 20], "requires": ["company_eye"]},
	"company_stores": {"name": "Company Stores", "description": "Raises inventory capacity by ten per rank and improves loot quality.", "kind": "inventory", "unlock": "inventory", "max_rank": 3, "cost": [70, 24], "requires": ["company_mail"]},
	"company_training": {"name": "Broad Training", "description": "Adds a fourth choice to every level-up.", "kind": "choice", "unlock": "choice", "max_rank": 1, "cost": [140, 48], "requires": ["company_stores"]}
}

const SKILL_BRANCHES: Dictionary = PROGRESSION_BRANCHES

const RARITIES: Dictionary = {
	"common": {"name": "Common", "color": Color("a89e8b"), "affixes": 0, "power": 1.0, "salvage": 6},
	"proven": {"name": "Proven", "color": Color("769487"), "affixes": 1, "power": 1.15, "salvage": 12},
	"masterwork": {"name": "Masterwork", "color": Color("c6a15d"), "affixes": 2, "power": 1.35, "salvage": 24},
	"barrow": {"name": "Barrow-touched", "color": Color("73aaa1"), "affixes": 2, "power": 1.55, "salvage": 38},
	"unique": {"name": "Unique", "color": Color("b77b86"), "affixes": 2, "power": 1.75, "salvage": 55}
}

const EQUIPMENT: Dictionary = {
	"iron_kettle": {"name": "Iron Kettle", "slot": "head", "description": "A plain helm that has survived several owners.", "stat": "armor", "amount": 0.04},
	"poachers_cap": {"name": "Poacher's Cap", "slot": "head", "description": "Wool and waxed leather shaped for a careful eye.", "stat": "critical", "amount": 0.035},
	"riveted_mail": {"name": "Riveted Mail", "slot": "body", "description": "Closely set rings turn the worst of a blow.", "stat": "armor", "amount": 0.075},
	"padded_jack": {"name": "Padded Jack", "slot": "body", "description": "Layered linen keeps a mercenary standing.", "stat": "health", "amount": 14.0},
	"ashwood_bracer": {"name": "Ashwood Bracer", "slot": "hands", "description": "A stiff guard that keeps the haft true.", "stat": "reach", "amount": 10.0},
	"poachers_gloves": {"name": "Poacher's Gloves", "slot": "hands", "description": "Supple fingers make for a quick release.", "stat": "ranged_cooldown", "amount": 0.055},
	"marching_boots": {"name": "Marching Boots", "slot": "boots", "description": "Hobnailed soles made for the long road.", "stat": "speed", "amount": 0.045},
	"mud_spats": {"name": "Moorland Spats", "slot": "boots", "description": "Waxed wraps keep the mire from taking hold.", "stat": "guard", "amount": 0.04},
	"wolf_tooth_charm": {"name": "Wolf-Tooth Charm", "slot": "trinket", "description": "A hunter's promise tied in red thread.", "stat": "damage", "amount": 0.055},
	"barrow_lantern": {"name": "Barrow Lantern", "slot": "trinket", "description": "Its pale flame draws secrets from the dark.", "stat": "pickup", "amount": 18.0},
	"knights_broken_seal": {"name": "Knight's Broken Seal", "slot": "trinket", "description": "The cracked badge still remembers command.", "stat": "guard_blast", "amount": 18.0}
}

const EQUIPMENT_AFFIXES: Array[Dictionary] = [
	{"name": "Stout", "stat": "health", "amount": 8.0},
	{"name": "Honed", "stat": "damage", "amount": 0.04},
	{"name": "Warded", "stat": "armor", "amount": 0.025},
	{"name": "Fleet", "stat": "speed", "amount": 0.025},
	{"name": "Keen", "stat": "critical", "amount": 0.025},
	{"name": "Balanced", "stat": "stagger", "amount": 0.08},
	{"name": "Gatherer's", "stat": "pickup", "amount": 10.0},
	{"name": "Quick-set", "stat": "cooldown", "amount": 0.035}
]

const ENEMIES: Dictionary = {
	"wolf": {"name": "Gaunt Wolf", "health": 20.0, "speed": 58.0, "damage": 7.0, "xp": 3, "radius": 10.0, "color": Color("6e6559"), "kind": "wolf"},
	"raider": {"name": "Desperate Raider", "health": 34.0, "speed": 38.0, "damage": 9.0, "xp": 4, "radius": 12.0, "color": Color("72504a"), "kind": "raider"},
	"archer": {"name": "Moor Archer", "health": 26.0, "speed": 28.0, "damage": 8.0, "xp": 5, "radius": 11.0, "color": Color("7b6948"), "kind": "archer"},
	"reaver": {"name": "Shielded Reaver", "health": 72.0, "speed": 26.0, "damage": 12.0, "xp": 8, "radius": 14.0, "color": Color("596268"), "kind": "shield"},
	"blighted": {"name": "Blighted Corpse", "health": 92.0, "speed": 19.0, "damage": 14.0, "xp": 9, "radius": 14.0, "color": Color("6b8985"), "kind": "blighted"},
	"crow": {"name": "Carrion Crow", "health": 15.0, "speed": 82.0, "damage": 6.0, "xp": 3, "radius": 8.0, "color": Color("2c3034"), "kind": "crow"},
	"houndmaster": {"name": "Houndmaster", "health": 380.0, "speed": 34.0, "damage": 16.0, "xp": 45, "radius": 20.0, "color": Color("8f5c49"), "kind": "elite"},
	"grave_guard": {"name": "Grave Guard", "health": 620.0, "speed": 24.0, "damage": 19.0, "xp": 65, "radius": 23.0, "color": Color("658f88"), "kind": "elite"},
	"barrow_knight": {"name": "The Barrow Knight", "health": 2600.0, "speed": 21.0, "damage": 24.0, "xp": 0, "radius": 31.0, "color": Color("78aaa2"), "kind": "boss"}
}

const WEAPON_UNLOCK_LEVEL: Dictionary = {"spear": 0, "sling": 0, "witchfire": 0, "axe": 1, "bow": 2, "knives": 2, "caltrops": 3}
const ARMORY_COSTS: Array[Dictionary] = [{"silver": 45, "provisions": 15}, {"silver": 110, "provisions": 35}, {"silver": 230, "provisions": 75}]
const TRAINING_COSTS: Array[Dictionary] = [{"silver": 30, "provisions": 12}, {"silver": 55, "provisions": 20}, {"silver": 90, "provisions": 30}, {"silver": 140, "provisions": 45}, {"silver": 210, "provisions": 65}]
const QUARTERMASTER_COSTS: Array[Dictionary] = [{"silver": 35, "provisions": 20}, {"silver": 90, "provisions": 48}, {"silver": 180, "provisions": 90}]

static func unlocked_weapons(armory_level: int, skill_tree: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	for weapon_id: String in WEAPON_UNLOCK_LEVEL:
		if int(WEAPON_UNLOCK_LEVEL[weapon_id]) > armory_level:
			continue
		if weapon_id in ["spear", "sling", "witchfire"] or _tree_unlocks(skill_tree, "weapon", weapon_id):
			result.append(weapon_id)
	return result

static func unlocked_techniques(skill_tree: Dictionary) -> Array[String]:
	var result: Array[String] = BASE_TECHNIQUES.duplicate()
	for node_id: String in PROGRESSION_NODES:
		if int(skill_tree.get(node_id, 0)) <= 0:
			continue
		var node: Dictionary = PROGRESSION_NODES[node_id]
		var kind: String = String(node.kind)
		if kind in ["technique", "weapon_technique", "double_technique"]:
			var primary: String = String(node.unlock)
			if TECHNIQUES.has(primary) and not result.has(primary):
				result.append(primary)
			var secondary: String = String(node.get("technique", ""))
			if TECHNIQUES.has(secondary) and not result.has(secondary):
				result.append(secondary)
	return result

static func progression_cost(node_id: String, current_rank: int) -> Dictionary:
	if not PROGRESSION_NODES.has(node_id):
		return {"silver": 9999, "provisions": 9999}
	var base: Array = PROGRESSION_NODES[node_id].cost
	var multiplier: float = 1.0 + float(current_rank) * 0.85
	return {"silver": roundi(float(base[0]) * multiplier), "provisions": roundi(float(base[1]) * multiplier)}

static func progression_requirements_met(node_id: String, skill_tree: Dictionary) -> bool:
	if not PROGRESSION_NODES.has(node_id):
		return false
	for required_id: Variant in PROGRESSION_NODES[node_id].requires:
		if int(skill_tree.get(String(required_id), 0)) <= 0:
			return false
	return true

static func mastery_unlocked(weapon_id: String, skill_tree: Dictionary) -> bool:
	if weapon_id in ["spear", "axe"]:
		return int(skill_tree.get("vanguard_mastery", 0)) > 0
	if weapon_id == "witchfire":
		return int(skill_tree.get("hedge_mastery", 0)) > 0
	return weapon_id == "bow" and int(skill_tree.get("huntsman_mark", 0)) > 0

static func inventory_capacity(skill_tree: Dictionary) -> int:
	return 30 + int(skill_tree.get("company_stores", 0)) * 10

static func level_choice_count(skill_tree: Dictionary) -> int:
	return 3 + mini(1, int(skill_tree.get("company_training", 0)))

static func permanent_loot_bonus(skill_tree: Dictionary) -> float:
	return float(skill_tree.get("company_stores", 0)) * 0.08

static func _tree_unlocks(skill_tree: Dictionary, kind: String, unlock_id: String) -> bool:
	for node_id: String in PROGRESSION_NODES:
		if int(skill_tree.get(node_id, 0)) <= 0:
			continue
		var node: Dictionary = PROGRESSION_NODES[node_id]
		if String(node.kind).contains(kind) and String(node.unlock) == unlock_id:
			return true
	return false
