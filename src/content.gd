class_name GameContent
extends RefCounted

const WEAPONS: Dictionary = {
	"spear": {"name": "Boar Spear", "category": "MELEE", "description": "A committed thrust that stops at the nearest rank.", "cooldown": 0.82, "damage": 21.0, "speed": 0.0, "radius": 48.0, "pierce": 2, "behavior": "thrust", "color": Color("d8c69c"), "technique": "braced_stance", "mastery": "Ashwood Pike"},
	"axe": {"name": "Woodsman's Axe", "category": "MELEE", "description": "A close, punishing sweep.", "cooldown": 1.18, "damage": 27.0, "speed": 0.0, "radius": 66.0, "pierce": 99, "behavior": "sweep", "color": Color("b7aaa0"), "technique": "cleaving_footwork", "mastery": "Bearded Axe"},
	"bow": {"name": "Longbow", "category": "RANGED", "description": "A heavy shaft aimed through the crowd.", "cooldown": 1.35, "damage": 31.0, "speed": 520.0, "radius": 4.0, "pierce": 1, "behavior": "line", "color": Color("d8b36a"), "technique": "bodkin_craft", "mastery": "War Bow"},
	"sling": {"name": "Sling", "category": "RANGED", "description": "Stones burst against packed foes.", "cooldown": 1.55, "damage": 23.0, "speed": 330.0, "radius": 7.0, "pierce": 1, "behavior": "splash", "color": Color("b9a58d"), "technique": "weighted_heads", "mastery": ""},
	"knives": {"name": "Throwing Knives", "category": "RANGED", "description": "A quick fan of balanced blades.", "cooldown": 0.92, "damage": 12.0, "speed": 480.0, "radius": 4.0, "pierce": 1, "behavior": "fan", "color": Color("c6cbd0"), "technique": "quick_hands", "mastery": ""},
	"caltrops": {"name": "Caltrops", "category": "RANGED", "description": "Iron thorns hold the ground behind you.", "cooldown": 2.8, "damage": 8.0, "speed": 0.0, "radius": 34.0, "pierce": 99, "behavior": "trap", "color": Color("8f969b"), "technique": "scavengers_reach", "mastery": ""}
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
	"fletched_shafts": {"name": "Fletched Shafts", "description": "Ranged weapons deal 8% more damage with true-flying shafts.", "stat": "ranged_damage", "amount": 0.08}
}

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

const WEAPON_UNLOCK_LEVEL: Dictionary = {"spear": 0, "sling": 0, "axe": 1, "bow": 2, "knives": 2, "caltrops": 3}
const ARMORY_COSTS: Array[Dictionary] = [{"silver": 45, "provisions": 15}, {"silver": 110, "provisions": 35}, {"silver": 230, "provisions": 75}]
const TRAINING_COSTS: Array[Dictionary] = [{"silver": 30, "provisions": 12}, {"silver": 55, "provisions": 20}, {"silver": 90, "provisions": 30}, {"silver": 140, "provisions": 45}, {"silver": 210, "provisions": 65}]
const QUARTERMASTER_COSTS: Array[Dictionary] = [{"silver": 35, "provisions": 20}, {"silver": 90, "provisions": 48}, {"silver": 180, "provisions": 90}]

static func unlocked_weapons(armory_level: int) -> Array[String]:
	var result: Array[String] = []
	for weapon_id: String in WEAPON_UNLOCK_LEVEL:
		if int(WEAPON_UNLOCK_LEVEL[weapon_id]) <= armory_level:
			result.append(weapon_id)
	return result
