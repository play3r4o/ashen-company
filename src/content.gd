class_name GameContent
extends RefCounted

const CLASSES: Dictionary = {
	"warrior": {"name": "Warrior", "description": "A durable melee fighter built around Guard Step.", "starting_weapon": "spear", "stats": {"health": 20.0, "melee_damage": 0.10, "guard_strength": 0.05, "guard_duration": 0.08}},
	"mage": {"name": "Moor Mage", "description": "A fast arcane attacker with an extra Witchfire ember.", "starting_weapon": "witchfire", "stats": {"arcane_damage": 0.15, "arcane_attack_speed": 0.12, "arcane_projectiles": 1.0}}
}

const DOCTRINES: Dictionary = {
	"shield_line": {"name": "Shield Line", "description": "A disciplined close-range formation built around Guard Step.", "stats": {"melee_damage": 0.10, "guard_duration": 0.10, "guard_strength": 0.05}},
	"pursuer": {"name": "Pursuer", "description": "Keep advancing toward your target to strike harder.", "stats": {"speed": 0.06, "pursuit_damage": 0.18}},
	"barrow_scholar": {"name": "Barrow Scholar", "description": "Study the old barrow and exploit its unnatural inhabitants.", "stats": {"arcane_damage": 0.18, "supernatural_damage": 0.15}},
	"hedge_alchemist": {"name": "Hedge Alchemist", "description": "Witchfire impacts leave a burning zone for 2.4 seconds.", "stats": {"arcane_attack_speed": 0.10}},
	"grave_listener": {"name": "Grave Listener", "description": "Specialize against the dead at the cost of ordinary combat.", "stats": {"supernatural_damage": 0.20, "ordinary_damage": -0.08}}
}

const RELICS: Dictionary = {
	"wolf_tooth": {"name": "Wolf Tooth", "description": "Desperation sharpens every attack while badly wounded.", "stats": {"wounded_damage": 0.22}},
	"barrow_candle": {"name": "Barrow Candle", "description": "Empowers sorcery, but draws more Blighted Corpses after minute 3.", "stats": {"arcane_damage": 0.20}},
	"broken_buckler": {"name": "Broken Buckler", "description": "Guard more often, but sacrifice ranged force.", "stats": {"guard_cooldown": 1.0, "ranged_damage": -0.05}},
	"fletched_pennant": {"name": "Fletched Pennant", "description": "Fill the air with more, lighter projectiles.", "stats": {"ranged_projectiles": 1.0, "ranged_damage": -0.08}},
	"field_surgeons_kit": {"name": "Field Surgeon's Kit", "description": "Survive longer through bandages and field medicine.", "stats": {"health": 16.0, "health_regen": 0.8}}
}

const CONTRACTS: Dictionary = {
	"hound_hunt": {"name": "Hunt the Houndmaster", "description": "Kill the next elite before the trail goes cold.", "kind": "elite_kill", "reward": 35, "silver": 25, "provisions": 0},
	"hold_the_moor": {"name": "Hold the Moor", "description": "Remain alive for 25 seconds after accepting.", "kind": "survive", "duration": 25.0, "reward": 28, "silver": 0, "provisions": 8},
	"break_the_shields": {"name": "Break the Shield Wall", "description": "Kill 8 Shielded Reavers.", "kind": "reaver_kills", "target": 8, "reward": 40, "silver": 30, "provisions": 4}
}

const OBJECTIVES: Dictionary = {
	"night_watch": {"name": "Night Watch", "description": "Survive until the first elite arrives at 2 minutes.", "kind": "survive", "target": 120.0, "reward": 20, "silver": 15, "provisions": 3},
	"moor_cull": {"name": "Moor Cull", "description": "Kill 35 ordinary enemies.", "kind": "kills", "target": 35, "reward": 24, "silver": 20, "provisions": 0},
	"company_standard": {"name": "Recover the Company Standard", "description": "Defeat an elite and recover its banner.", "kind": "elite", "target": 1, "reward": 36, "silver": 25, "provisions": 5}
}

const CURSES: Dictionary = {
	"none": {"name": "Clear Moor", "description": "A standard expedition through familiar ground.", "health": 1.0, "damage": 1.0, "reward": 1.0},
	"long_night": {"name": "The Long Night", "description": "Face a tougher, more dangerous expedition for greater spoils.", "health": 1.16, "damage": 1.08, "reward": 1.28},
	"black_moon": {"name": "Black Moon", "description": "More supernatural enemies emerge beneath the black moon.", "health": 1.05, "damage": 1.04, "reward": 1.22},
	"thin_rations": {"name": "Thin Rations", "description": "Experience is scarcer, but a victory brings extra provisions.", "health": 1.0, "damage": 1.06, "reward": 1.18}
}

const WEAPONS: Dictionary = {
	"spear": {"name": "Boar Spear", "category": "MELEE", "description": "Forward melee thrust that causes a 3-hit bleed.", "cooldown": 0.82, "damage": 21.0, "speed": 0.0, "radius": 50.0, "pierce": 99, "behavior": "thrust", "color": Color("d8c69c"), "technique": "braced_stance", "mastery": "Ashwood Pike", "mastery_description": "+35% damage, +28 range and +50% bleed damage.", "mastery_stats": {"damage": 0.35, "melee_range": 28.0, "bleed_damage": 0.50}, "rank_bonuses": [{"damage": 0.20}, {"melee_range": 16.0}, {"attack_speed": 0.20}, {"melee_area": 0.20, "bleed_damage": 0.40}]},
	"axe": {"name": "Woodsman's Axe", "category": "MELEE", "description": "Wide forward cleave that causes a 3-hit bleed.", "cooldown": 1.18, "damage": 27.0, "speed": 0.0, "radius": 66.0, "pierce": 99, "behavior": "sweep", "color": Color("b7aaa0"), "technique": "cleaving_footwork", "mastery": "Bearded Axe", "mastery_description": "+30% damage, +25% area and a second strike for 40% damage.", "mastery_stats": {"damage": 0.30, "melee_area": 0.25, "follow_up": 0.40}, "rank_bonuses": [{"melee_area": 0.15}, {"attack_speed": 0.15}, {"damage": 0.30}, {"follow_up": 0.25}]},
	"bow": {"name": "Longbow", "category": "RANGED", "description": "Fast line shot that pins enemies for 1.25 seconds.", "cooldown": 1.35, "damage": 31.0, "speed": 520.0, "radius": 4.0, "pierce": 1, "behavior": "line", "color": Color("d8b36a"), "technique": "bodkin_craft", "mastery": "War Bow", "mastery_description": "+35% damage, +2 piercing and +1 arrow.", "mastery_stats": {"damage": 0.35, "pierce": 2.0, "ranged_projectiles": 1.0}, "rank_bonuses": [{"pierce": 1.0}, {"projectile_speed": 0.20}, {"damage": 0.30}, {"attack_speed": 0.25}]},
	"sling": {"name": "Sling", "category": "RANGED", "description": "42-pixel blast that staggers enemies for 0.30 seconds.", "cooldown": 1.55, "damage": 23.0, "speed": 330.0, "radius": 7.0, "pierce": 1, "behavior": "splash", "color": Color("b9a58d"), "technique": "weighted_heads", "mastery": "Staff Sling", "mastery_description": "+30% damage, +40% blast area and +0.30s stagger duration.", "mastery_stats": {"damage": 0.30, "splash_area": 0.40, "stagger": 0.30}, "rank_bonuses": [{"splash_area": 0.20}, {"stagger": 0.25}, {"attack_speed": 0.18}, {"ranged_projectiles": 1.0}]},
	"knives": {"name": "Throwing Knives", "category": "RANGED", "description": "Short fan of three knives; each causes a 3-hit bleed.", "cooldown": 0.92, "damage": 12.0, "speed": 480.0, "radius": 4.0, "pierce": 1, "behavior": "fan", "color": Color("c6cbd0"), "technique": "barbed_heads", "mastery": "Bandolier Volley", "mastery_description": "+25% damage, +2 knives and +50% bleed damage.", "mastery_stats": {"damage": 0.25, "ranged_projectiles": 2.0, "bleed_damage": 0.50}, "rank_bonuses": [{"ranged_projectiles": 1.0}, {"bleed_damage": 0.35}, {"attack_speed": 0.20}, {"ranged_projectiles": 2.0}]},
	"caltrops": {"name": "Caltrops", "category": "RANGED", "description": "Drops a 6-second trap that damages every 0.55 seconds.", "cooldown": 2.8, "damage": 8.0, "speed": 0.0, "radius": 34.0, "pierce": 99, "behavior": "trap", "color": Color("8f969b"), "technique": "scavengers_reach", "mastery": "Hardened Caltrops", "mastery_description": "+35% damage, +30% area and +50% duration.", "mastery_stats": {"damage": 0.35, "trap_area": 0.30, "trap_duration": 0.50}, "rank_bonuses": [{"trap_duration": 0.25}, {"trap_area": 0.20}, {"attack_speed": 0.20}, {"damage": 0.40, "stagger": 0.20}]},
	"witchfire": {"name": "Witchfire", "category": "ARCANE", "description": "Homing embers divide between nearby targets, then blast and scorch.", "cooldown": 1.20, "damage": 26.0, "speed": 245.0, "radius": 7.0, "pierce": 1, "behavior": "hex", "color": Color("78aaa2"), "technique": "ember_lore", "mastery": "Greenfire Brand", "mastery_description": "+30% damage, +50% blast area, +60% scorch damage and +1 ember.", "mastery_stats": {"damage": 0.30, "splash_area": 0.50, "scorch_damage": 0.60, "arcane_projectiles": 1.0}, "rank_bonuses": [{"splash_area": 0.20}, {"scorch_damage": 0.35}, {"attack_speed": 0.20}, {"arcane_projectiles": 1.0}]}
}

const TECHNIQUES: Dictionary = {
	"braced_stance": {"name": "Braced Stance", "description": "Set the spear firmly and control a wider lane.", "stats": {"melee_range": 16.0, "melee_damage": 0.04}},
	"cleaving_footwork": {"name": "Cleaving Footwork", "description": "Turn each axe swing into a broader cleave.", "stats": {"melee_area": 0.15}},
	"bodkin_craft": {"name": "Bodkin Craft", "description": "Hardened arrowheads pass through another foe.", "stats": {"pierce": 1.0, "ranged_damage": 0.04}},
	"strong_arm": {"name": "Strong Arm", "description": "Put more force behind every attack.", "stats": {"damage": 0.08}},
	"quick_hands": {"name": "Quick Hands", "description": "Ready every weapon sooner after attacking.", "stats": {"attack_speed": 0.10}},
	"hard_march": {"name": "Hard March", "description": "Build the endurance needed for a longer expedition.", "stats": {"health": 15.0}},
	"mail_lining": {"name": "Mail Lining", "description": "Reinforce vulnerable gaps beneath the company mail.", "stats": {"armor": 0.05}},
	"field_dressing": {"name": "Field Dressing", "description": "Treat wounds steadily while the fight continues.", "stats": {"health_regen": 1.0}},
	"keen_eye": {"name": "Keen Eye", "description": "Recognize openings for a decisive strike.", "stats": {"critical": 0.05}},
	"scavengers_reach": {"name": "Trap Setter", "description": "Spread caltrops across more ground for longer.", "stats": {"trap_duration": 0.20, "trap_area": 0.12}},
	"weighted_heads": {"name": "Weighted Stones", "description": "Heavier sling stones disrupt tightly packed enemies.", "stats": {"stagger": 0.18, "splash_area": 0.10}},
	"deep_quiver": {"name": "Deep Quiver", "description": "Loose another ranged projectile with each attack.", "stats": {"ranged_projectiles": 1.0}},
	"iron_grip": {"name": "Iron Grip", "description": "Keep close weapons steady through every impact.", "stats": {"melee_damage": 0.12}},
	"measured_breath": {"name": "Measured Breath", "description": "Maintain a faster rhythm with ranged weapons.", "stats": {"ranged_attack_speed": 0.12}},
	"patched_padding": {"name": "Patched Padding", "description": "Layered cloth adds both protection and endurance.", "stats": {"health": 8.0, "armor": 0.02}},
	"shield_wall": {"name": "Shield Wall", "description": "Turn aside more harm during Guard Step.", "stats": {"guard_strength": 0.05}},
	"long_stride": {"name": "Long Stride", "description": "Cross dangerous ground with practiced footwork.", "stats": {"speed": 0.06}},
	"lantern_hook": {"name": "Lantern Hook", "description": "Draw scattered experience toward the company.", "stats": {"pickup": 24.0}},
	"barbed_heads": {"name": "Barbed Blades", "description": "Barbs leave wounds that continue to bleed.", "stats": {"bleed_damage": 0.25}},
	"fletched_shafts": {"name": "Fletched Shafts", "description": "True-flying shafts arrive faster and strike harder.", "stats": {"projectile_speed": 0.15, "ranged_damage": 0.06}},
	"ember_lore": {"name": "Ember Lore", "description": "Feed Witchfire until its lingering scorch burns hotter.", "stats": {"arcane_damage": 0.12, "scorch_damage": 0.20}},
	"riposte_drill": {"name": "Shield Riposte", "description": "Guard Step answers nearby enemies with a shield blow.", "stats": {"guard_damage": 28.0}},
	"marked_prey": {"name": "Marked Prey", "description": "Identify the weak points of elites and bosses.", "stats": {"elite_damage": 0.18}},
	"twin_cast": {"name": "Twin Cast", "description": "Shape another arcane projectile with each casting.", "stats": {"arcane_projectiles": 1.0}},
	"second_wind": {"name": "Second Wind", "description": "Recover once per run when health falls below 30%.", "stats": {"second_wind": 30.0}},
	"salvagers_eye": {"name": "Salvager's Eye", "description": "Recognize better equipment among elite spoils.", "stats": {"loot_quality": 0.12}}
}

const BASE_TECHNIQUES: Array[String] = ["strong_arm", "long_stride", "patched_padding"]

const PROGRESSION_BRANCHES: Dictionary = {
	"VANGUARD": ["vanguard_drill", "vanguard_axe", "vanguard_grip", "vanguard_shield", "vanguard_riposte", "vanguard_mastery"],
	"HUNTSMAN": ["huntsman_sling", "huntsman_bow", "huntsman_knives", "huntsman_caltrops", "huntsman_quiver", "huntsman_mark"],
	"HEDGECRAFT": ["hedge_embers", "hedge_lantern", "hedge_twin_cast", "hedge_dressing", "hedge_second_wind", "hedge_mastery"],
	"COMPANYCRAFT": ["company_hands", "company_march", "company_eye", "company_mail", "company_stores", "company_training"]
}

const PROGRESSION_NODES: Dictionary = {
	"vanguard_drill": {"name": "Ashwood Drill", "description": "Level-up pool: Braced Stance (+16 melee range, +4% melee damage).", "kind": "technique", "unlock": "braced_stance", "max_rank": 1, "cost": [18, 6], "requires": []},
	"vanguard_axe": {"name": "Woodsman's Muster", "description": "Unlocks Woodsman's Axe and Cleaving Footwork (+15% melee area).", "kind": "weapon_technique", "unlock": "axe", "techniques": ["cleaving_footwork"], "max_rank": 1, "cost": [32, 10], "requires": ["vanguard_drill"]},
	"vanguard_grip": {"name": "Iron Grip", "description": "Level-up pool: Iron Grip (+12% melee damage).", "kind": "technique", "unlock": "iron_grip", "max_rank": 1, "cost": [42, 14], "requires": ["vanguard_axe"]},
	"vanguard_shield": {"name": "Shield Wall", "description": "Level-up pool: Shield Wall (+5% Guard Step protection).", "kind": "technique", "unlock": "shield_wall", "max_rank": 1, "cost": [55, 18], "requires": ["vanguard_grip"]},
	"vanguard_riposte": {"name": "Shield Riposte", "description": "Level-up pool: Shield Riposte (28 area damage per rank).", "kind": "technique", "unlock": "riposte_drill", "max_rank": 1, "cost": [72, 24], "requires": ["vanguard_shield"]},
	"vanguard_mastery": {"name": "Master-at-Arms", "description": "Enables Ashwood Pike and Bearded Axe at weapon rank 5.", "kind": "mastery", "unlock": "vanguard", "max_rank": 1, "cost": [95, 32], "requires": ["vanguard_riposte"]},

	"huntsman_sling": {"name": "Stone Drill", "description": "Level-up pool: Weighted Stones and Measured Breath.", "kind": "double_technique", "unlock": "weighted_heads", "techniques": ["measured_breath"], "max_rank": 1, "cost": [18, 6], "requires": []},
	"huntsman_bow": {"name": "Bowyer's Bench", "description": "Unlocks Longbow, Bodkin Craft and Fletched Shafts.", "kind": "weapon_technique", "unlock": "bow", "techniques": ["bodkin_craft", "fletched_shafts"], "max_rank": 1, "cost": [35, 12], "requires": ["huntsman_sling"]},
	"huntsman_knives": {"name": "Balanced Blades", "description": "Unlocks Throwing Knives and Barbed Blades (+25% bleed damage).", "kind": "weapon_technique", "unlock": "knives", "techniques": ["barbed_heads"], "max_rank": 1, "cost": [48, 15], "requires": ["huntsman_bow"]},
	"huntsman_caltrops": {"name": "Iron Thorns", "description": "Unlocks Caltrops and Trap Setter (+duration and area).", "kind": "weapon_technique", "unlock": "caltrops", "techniques": ["scavengers_reach"], "max_rank": 1, "cost": [62, 20], "requires": ["huntsman_knives"]},
	"huntsman_quiver": {"name": "Deep Quiver", "description": "Level-up pool: Deep Quiver (+1 ranged projectile).", "kind": "technique", "unlock": "deep_quiver", "max_rank": 1, "cost": [78, 26], "requires": ["huntsman_caltrops"]},
	"huntsman_mark": {"name": "Marked Prey", "description": "Level-up pool: +18% elite damage; enables all ranged masteries.", "kind": "technique", "unlock": "marked_prey", "max_rank": 1, "cost": [98, 32], "requires": ["huntsman_quiver"]},

	"hedge_embers": {"name": "Ember Lessons", "description": "Level-up pool: +12% arcane and +20% scorch damage.", "kind": "technique", "unlock": "ember_lore", "max_rank": 1, "cost": [18, 6], "requires": []},
	"hedge_lantern": {"name": "Lantern Hook", "description": "Level-up pool: Lantern Hook (+24 pickup range).", "kind": "technique", "unlock": "lantern_hook", "max_rank": 1, "cost": [30, 11], "requires": ["hedge_embers"]},
	"hedge_twin_cast": {"name": "Twin Cast", "description": "Level-up pool: Twin Cast (+1 arcane projectile).", "kind": "technique", "unlock": "twin_cast", "max_rank": 1, "cost": [46, 16], "requires": ["hedge_lantern"]},
	"hedge_dressing": {"name": "Hedge Remedies", "description": "Level-up pool: +1 health every 5 seconds.", "kind": "technique", "unlock": "field_dressing", "max_rank": 1, "cost": [60, 21], "requires": ["hedge_twin_cast"]},
	"hedge_second_wind": {"name": "Second Wind", "description": "Level-up pool: one 30-health emergency heal per rank.", "kind": "technique", "unlock": "second_wind", "max_rank": 1, "cost": [78, 27], "requires": ["hedge_dressing"]},
	"hedge_mastery": {"name": "Barrow Cant", "description": "Enables Greenfire Brand at Witchfire rank 5.", "kind": "mastery", "unlock": "hedge", "max_rank": 1, "cost": [100, 34], "requires": ["hedge_second_wind"]},

	"company_hands": {"name": "Practical Lessons", "description": "Level-up pool: Quick Hands (+10% attack speed).", "kind": "technique", "unlock": "quick_hands", "max_rank": 1, "cost": [18, 6], "requires": []},
	"company_march": {"name": "Hard March", "description": "Level-up pool: Hard March (+15 maximum health).", "kind": "technique", "unlock": "hard_march", "max_rank": 1, "cost": [30, 10], "requires": ["company_hands"]},
	"company_eye": {"name": "Keen Eye", "description": "Level-up pool: +5% critical chance and +12% equipment quality.", "kind": "double_technique", "unlock": "keen_eye", "technique": "salvagers_eye", "max_rank": 1, "cost": [44, 15], "requires": ["company_march"]},
	"company_mail": {"name": "Mail Lining", "description": "Level-up pool: Mail Lining (+5% armor).", "kind": "technique", "unlock": "mail_lining", "max_rank": 1, "cost": [58, 20], "requires": ["company_eye"]},
	"company_stores": {"name": "Company Stores", "description": "+10 inventory slots and +8% equipment quality per rank.", "kind": "inventory", "unlock": "inventory", "max_rank": 3, "cost": [70, 24], "requires": ["company_mail"]},
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
	"iron_kettle": {"name": "Iron Kettle", "slot": "head", "description": "Armor and Guard Step protection.", "stats": {"armor": 0.04, "guard_strength": 0.03}},
	"poachers_cap": {"name": "Poacher's Cap", "slot": "head", "description": "Critical chance and ranged damage.", "stats": {"critical": 0.04, "ranged_damage": 0.04}},
	"riveted_mail": {"name": "Riveted Mail", "slot": "body", "description": "Heavy armor that slightly slows movement.", "stats": {"armor": 0.08, "speed": -0.03}},
	"padded_jack": {"name": "Padded Jack", "slot": "body", "description": "Maximum health and steady healing.", "stats": {"health": 16.0, "health_regen": 0.5}},
	"ashwood_bracer": {"name": "Ashwood Bracer", "slot": "hands", "description": "Melee range and melee damage.", "stats": {"melee_range": 12.0, "melee_damage": 0.04}},
	"poachers_gloves": {"name": "Poacher's Gloves", "slot": "hands", "description": "Ranged attack speed and projectile speed.", "stats": {"ranged_attack_speed": 0.08, "projectile_speed": 0.10}},
	"marching_boots": {"name": "Marching Boots", "slot": "boots", "description": "Reliable movement speed.", "stats": {"speed": 0.05}},
	"mud_spats": {"name": "Moorland Spats", "slot": "boots", "description": "Stronger and more frequent Guard Steps.", "stats": {"guard_strength": 0.05, "guard_cooldown": 0.35}},
	"wolf_tooth_charm": {"name": "Wolf-Tooth Charm", "slot": "trinket", "description": "More damage while wounded.", "stats": {"wounded_damage": 0.15}},
	"barrow_lantern": {"name": "Barrow Lantern", "slot": "trinket", "description": "Pickup range and arcane damage.", "stats": {"pickup": 20.0, "arcane_damage": 0.08}},
	"knights_broken_seal": {"name": "Knight's Broken Seal", "slot": "trinket", "description": "Guard Step counterattack and elite damage.", "stats": {"guard_damage": 20.0, "elite_damage": 0.08}}
}

const EQUIPMENT_AFFIXES: Array[Dictionary] = [
	{"name": "Stout", "stat": "health", "amount": 8.0},
	{"name": "Honed", "stat": "damage", "amount": 0.04},
	{"name": "Warded", "stat": "armor", "amount": 0.025},
	{"name": "Fleet", "stat": "speed", "amount": 0.025},
	{"name": "Keen", "stat": "critical", "amount": 0.025},
	{"name": "Balanced", "stat": "stagger", "amount": 0.08},
	{"name": "Gatherer's", "stat": "pickup", "amount": 10.0},
	{"name": "Quick-set", "stat": "attack_speed", "amount": 0.05}
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
			var secondary_ids: Array = node.get("techniques", [])
			if node.has("technique"):
				secondary_ids.append(String(node.technique))
			for secondary_value: Variant in secondary_ids:
				var secondary: String = String(secondary_value)
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
	return weapon_id in ["bow", "sling", "knives", "caltrops"] and int(skill_tree.get("huntsman_mark", 0)) > 0

static func inventory_capacity(skill_tree: Dictionary) -> int:
	return 30 + int(skill_tree.get("company_stores", 0)) * 10

static func level_choice_count(skill_tree: Dictionary) -> int:
	return 3 + mini(1, int(skill_tree.get("company_training", 0)))

static func permanent_loot_bonus(skill_tree: Dictionary) -> float:
	return float(skill_tree.get("company_stores", 0)) * 0.08

static func stats_text(stats: Dictionary, separator: String = "  |  ") -> String:
	var parts: PackedStringArray = []
	for stat: String in stats:
		parts.append(stat_text(stat, float(stats[stat])))
	return separator.join(parts)

static func reward_text(entry: Dictionary) -> String:
	var rewards: PackedStringArray = []
	var silver: int = int(entry.get("silver", 0))
	var provisions: int = int(entry.get("provisions", 0))
	if silver > 0:
		rewards.append("+%d SILVER" % silver)
	if provisions > 0:
		rewards.append("+%d PROVISIONS" % provisions)
	return "  /  ".join(rewards) if not rewards.is_empty() else "NO CURRENCY REWARD"

static func stat_text(stat: String, amount: float) -> String:
	var sign: String = "+" if amount >= 0.0 else ""
	match stat:
		"health": return "%s%d MAX HEALTH" % [sign, roundi(amount)]
		"health_regen": return "%s%.1f HEALTH / 5s" % [sign, amount]
		"melee_range": return "%s%d MELEE RANGE" % [sign, roundi(amount)]
		"pickup": return "%s%d PICKUP RANGE" % [sign, roundi(amount)]
		"guard_damage": return "%s%d GUARD DAMAGE" % [sign, roundi(amount)]
		"second_wind": return "%s%d SECOND WIND HEALTH" % [sign, roundi(amount)]
		"pierce", "ranged_projectiles", "arcane_projectiles": return "%s%d %s" % [sign, roundi(amount), stat.replace("_", " ").to_upper()]
		"guard_cooldown": return "-%.2fs GUARD COOLDOWN" % absf(amount)
		"guard_duration": return "%s%.2fs GUARD DURATION" % [sign, amount]
		"follow_up": return "%s%d%% FOLLOW-UP DAMAGE" % [sign, roundi(amount * 100.0)]
		"stagger": return "%s%.2fs STAGGER DURATION" % [sign, amount]
		"loot_quality": return "%s%d%% EQUIPMENT QUALITY" % [sign, roundi(amount * 100.0)]
		"attack_speed", "melee_attack_speed", "ranged_attack_speed", "arcane_attack_speed": return "%s%d%% %s" % [sign, roundi(amount * 100.0), stat.replace("_", " ").to_upper()]
		"damage", "melee_damage", "ranged_damage", "arcane_damage", "elite_damage", "supernatural_damage", "ordinary_damage", "wounded_damage", "armor", "critical", "speed", "guard_strength", "melee_area", "splash_area", "trap_area", "trap_duration", "bleed_damage", "scorch_damage", "projectile_speed":
			return "%s%d%% %s" % [sign, roundi(amount * 100.0), stat.replace("_", " ").to_upper()]
		_: return "%s%.2f %s" % [sign, amount, stat.replace("_", " ").to_upper()]

static func _tree_unlocks(skill_tree: Dictionary, kind: String, unlock_id: String) -> bool:
	for node_id: String in PROGRESSION_NODES:
		if int(skill_tree.get(node_id, 0)) <= 0:
			continue
		var node: Dictionary = PROGRESSION_NODES[node_id]
		if String(node.kind).contains(kind) and String(node.unlock) == unlock_id:
			return true
	return false
