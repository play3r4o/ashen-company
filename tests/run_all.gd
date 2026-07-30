extends SceneTree

const Content = preload("res://src/content.gd")
const Rules = preload("res://src/rules.gd")
const Saves = preload("res://src/save_service.gd")
const Roster = preload("res://src/services/roster_service.gd")
const Region = preload("res://src/services/region_generator.gd")
const Expedition = preload("res://src/services/expedition_service.gd")
const Structure = preload("res://src/foundation/structure_definition.gd")
const HudLayout = preload("res://src/ui/hud_layout.tscn")

var passed: int = 0
var failed: int = 0

func _init() -> void:
	var hud_layout := HudLayout.instantiate()
	check(hud_layout.rect_for("ResourceRail").size == Vector2(390.0, 52.0) and hud_layout.rect_for("Run/GuardStepButton").size == Vector2(82.0, 74.0), "HUD layout scene exposes editable rail and action rectangles")
	hud_layout.free()
	check(is_equal_approx(Rules.damage_after_armor(100.0, 0.25), 75.0), "armor reduces damage")
	check(Rules.damage_after_armor(1.0, 0.75) == 1.0, "damage always has a floor")
	check(is_equal_approx(Rules.veteran_rating(0.0, 0, 0, false), 0.25), "veteran rating has a useful floor")
	check(is_equal_approx(Rules.veteran_rating(480.0, 450, 2, true), 1.0), "perfect run reaches full rating")
	check(is_equal_approx(Rules.offline_cap_hours(0), 8.0), "base offline cap is eight hours")
	check(is_equal_approx(Rules.offline_cap_hours(3), 12.0), "quartermaster raises cap to twelve hours")
	var capped: Dictionary = Rules.offline_reward("patrol", 24.0 * 3600.0, 1.0, 0)
	check(is_equal_approx(float(capped.elapsed), 8.0 * 3600.0), "forward clock jumps are capped")
	var backwards: Dictionary = Rules.offline_reward("forage", -500.0, 1.0, 0)
	check(int(backwards.provisions) == 0 and float(backwards.elapsed) == 0.0, "backward clock changes award nothing")
	check(Rules.mastery_available("spear", 5, {"braced_stance": 1}), "spear mastery unlocks with its technique")
	check(not Rules.mastery_available("spear", 4, {"braced_stance": 1}), "mastery requires rank five")
	check(Content.unlocked_weapons(0) == ["spear", "sling", "witchfire"], "new profiles begin with melee, ranged and arcane weapons")
	check(String(Content.WEAPONS["spear"].category) == "MELEE" and String(Content.WEAPONS["sling"].category) == "RANGED", "starting arsenal covers both weapon ranges")
	check(Content.CLASSES.has("warrior") and Content.CLASSES.has("hunter") and Content.CLASSES.has("mage") and Content.CLASSES.has("rogue"), "all four persistent hero classes are registered")
	check(String(Content.CLASSES["mage"].starting_weapon) == "witchfire", "mage begins with witchfire")
	check(Content.DOCTRINES.size() >= 5 and Content.RELICS.size() >= 5, "doctrines and field relics are registered")
	check(Content.CONTRACTS.size() >= 3 and Content.OBJECTIVES.size() >= 3, "contracts and optional objectives are registered")
	check(Content.CURSES.has("long_night") and float(Content.CURSES["long_night"].reward) > 1.0, "cursed expeditions increase rewards")
	check(Content.TECHNIQUES.size() >= 20, "technique pool includes expanded abilities")
	check(Content.unlocked_weapons(3).size() == 3, "advanced weapons remain gated by the field skill tree")
	var arsenal_tree: Dictionary = {"vanguard_axe": 1, "huntsman_bow": 1, "huntsman_knives": 1, "huntsman_caltrops": 1}
	check(Content.unlocked_weapons(3, arsenal_tree).size() == 7, "armory and field training together unlock the complete arsenal")
	check(Content.unlocked_techniques({"vanguard_drill": 1}).has("braced_stance"), "skill nodes add techniques to the level-up pool")
	var complete_tree: Dictionary = {}
	for progression_id: String in Content.PROGRESSION_NODES:
		complete_tree[progression_id] = int(Content.PROGRESSION_NODES[progression_id].max_rank)
	check(Content.unlocked_techniques(complete_tree).size() == Content.TECHNIQUES.size(), "every registered technique is reachable through progression")
	check(not Content.progression_requirements_met("vanguard_axe", {}) and Content.progression_requirements_met("vanguard_axe", {"vanguard_drill": 1}), "skill tree prerequisites are enforced")
	check(Content.level_choice_count({"company_training": 1}) == 4, "broad training adds a fourth level-up choice")
	check(String(Content.WEAPONS["spear"].behavior) == "thrust" and float(Content.WEAPONS["spear"].speed) == 0.0, "spear is a contact thrust rather than a projectile")
	check(float(Content.TECHNIQUES["iron_grip"].stats.melee_damage) > 0.0 and float(Content.TECHNIQUES["measured_breath"].stats.ranged_attack_speed) > 0.0, "techniques use familiar and distinct combat statistics")
	check(not Content.stats_text(Content.TECHNIQUES["quick_hands"].stats).contains("RECOVERY"), "player-facing statistics use attack speed instead of recovery jargon")
	check(Content.stats_text({"stagger": 0.18}).contains("0.18s STAGGER DURATION"), "stagger is displayed as an exact duration instead of a vague percentage")
	check(not String(Content.WEAPONS["sling"].mastery).is_empty() and not String(Content.WEAPONS["caltrops"].mastery).is_empty(), "every weapon has a named mastery")
	var mastery_techniques: Dictionary = {}
	for weapon_id: String in Content.WEAPONS:
		mastery_techniques[String(Content.WEAPONS[weapon_id].technique)] = 1
	check(Content.WEAPONS.keys().all(func(weapon_id: String) -> bool: return Rules.mastery_available(weapon_id, 5, mastery_techniques, complete_tree)), "every weapon mastery can actually be reached")
	check(int(Content.OBJECTIVES.night_watch.silver) > 0 and int(Content.CONTRACTS.hound_hunt.silver) > 0, "objectives and contracts grant real currency rewards")
	var equipment: Dictionary = Rules.generate_equipment(1234, false, 0.0, 1)
	check(Content.EQUIPMENT.has(String(equipment.base_id)) and Array(equipment.modifiers).size() >= 2, "equipment generation produces multiple meaningful base statistics")
	check(Rules.equipment_rarity(1234, true, 0.0) in ["barrow", "unique"], "boss equipment is always a high rarity")
	var fresh: Dictionary = Saves.default_data()
	check(fresh.profile.inventory is Array and fresh.profile.equipped is Dictionary and int(fresh.profile.blacksmith_level) == 0, "new profiles include inventory, equipment slots and the blacksmith")
	check(int(fresh.profile.hall_level) == 0 and fresh.profile.constructed_buildings == ["veterans_hall", "campfire"] and Dictionary(fresh.profile.building_plots).is_empty(), "a fresh refuge begins with only the Hall and campfire")
	check(Content.HALL_COSTS.size() == 4 and Content.BUILDING_CONSTRUCTION_COSTS.size() == 4, "Hall growth and all four town services have explicit construction costs")
	check(Array(fresh.profile.heroes).size() == 4 and String(fresh.profile.active_hero_id) == "warrior", "new schema creates a four-recruit roster")
	check(Rules.validate_save(fresh) and bool(fresh.settings.gate_confirmations), "default save validates with gate confirmations enabled")
	var pre_blacksmith_save: Dictionary = fresh.duplicate(true)
	pre_blacksmith_save.profile.erase("blacksmith_level")
	check(Rules.validate_save(pre_blacksmith_save) and int(Saves.import_code(Saves.export_code(pre_blacksmith_save)).profile.blacksmith_level) == 0, "older saves migrate safely to a tier-zero blacksmith")
	var pre_city_save: Dictionary = fresh.duplicate(true)
	pre_city_save.profile.erase("hall_level")
	pre_city_save.profile.erase("constructed_buildings")
	pre_city_save.profile.erase("building_plots")
	pre_city_save.profile.armory_level = 1
	pre_city_save.profile.training_level = 2
	var migrated_city: Dictionary = Saves.import_code(Saves.export_code(pre_city_save))
	check(int(migrated_city.profile.hall_level) == 2 and migrated_city.profile.constructed_buildings.has("armory") and migrated_city.profile.constructed_buildings.has("training") and not migrated_city.profile.constructed_buildings.has("blacksmith") and String(migrated_city.profile.building_plots.plot_1) == "armory" and String(migrated_city.profile.building_plots.plot_2) == "training", "existing restoration tiers migrate into occupied city-builder slots")
	var code: String = Saves.export_code(fresh)
	var imported: Dictionary = Saves.import_code(code)
	check(not imported.is_empty() and int(imported.schema_version) == 2, "schema-v2 save backup round trip")
	var roster_profile: Dictionary = fresh.profile.duplicate(true)
	var now: float = 100000.0
	var hunter: Dictionary = Roster.hero_by_id(roster_profile.heroes, "hunter")
	hunter.assignment = "patrol"
	hunter.last_seen = now - 24.0 * 3600.0
	Roster.apply_offline(roster_profile, now)
	check(int(hunter.pending_silver) == 72, "hero Patrol uses the eight-hour base offline cap")
	hunter.last_seen = now + 50.0
	var before_backward: int = int(hunter.pending_silver)
	Roster.apply_offline(roster_profile, now)
	check(int(hunter.pending_silver) == before_backward, "backward clocks add no hero-assignment rewards")
	check(Roster.set_active_hero(roster_profile, "rogue") and String(Roster.active_hero(roster_profile).id) == "rogue", "roster active hero can be switched")
	var region_a: Dictionary = Region.generate_blackthorn(4141)
	var region_b: Dictionary = Region.generate_blackthorn(4141)
	var region_c: Dictionary = Region.generate_blackthorn(4142)
	check(Region.signature(region_a) == Region.signature(region_b) and Region.signature(region_a) != Region.signature(region_c), "Blackthorn Moor generation is deterministic by seed")
	check(Array(region_a.landmarks).size() == 10 and Array(region_a.blockers).size() > 100, "generated Moor contains reachable objectives and physical biome boundaries")
	check(is_equal_approx(Expedition.dread(600.0, 0.0), 100.0) and Expedition.boss_cycle_for_dread(100.0) == 1 and Expedition.boss_cycle_for_dread(175.0) == 2, "Dread summons the first boss near ten minutes and repeats every 75")
	var structure: StructureDefinition = Structure.new()
	structure.anchor = Vector2(100, 100)
	structure.footprint = PackedVector2Array([Vector2(-20, -10), Vector2(20, -10), Vector2(20, 10), Vector2(-20, 10)])
	structure.tier_footprints = [structure.footprint, PackedVector2Array([Vector2(-30, -15), Vector2(30, -15), Vector2(30, 15), Vector2(-30, 15)])]
	structure.interaction_polygon = PackedVector2Array([Vector2(-35, -25), Vector2(35, -25), Vector2(35, 25), Vector2(-35, 25)])
	check(structure.contains_ground_point(Vector2(100, 100)) and not structure.contains_ground_point(Vector2(100, 55)), "structure collision follows its ground footprint")
	check(structure.contains_ground_point_for_tier(Vector2(128, 100), 0.0, 1) and not structure.contains_ground_point_for_tier(Vector2(128, 100), 0.0, 0), "upgrade tiers can grow a structure's physical ground footprint")
	check(structure.can_interact(Vector2(130, 100)) and not structure.can_interact(Vector2(180, 100)), "structure interaction is local rather than screen-wide")
	var legacy_equipment: Dictionary = Saves.default_data()
	legacy_equipment.profile.inventory = [{"uid": "old", "modifiers": [{"stat": "ranged_cooldown", "amount": 0.08}, {"stat": "guard_blast", "amount": 18.0}]}]
	var migrated_equipment: Dictionary = Saves.import_code(Saves.export_code(legacy_equipment))
	var migrated_modifiers: Array = migrated_equipment.profile.inventory[0].modifiers
	check(String(migrated_modifiers[0].stat) == "ranged_attack_speed" and String(migrated_modifiers[1].stat) == "guard_damage", "old equipment statistics migrate to familiar names")
	var invalid: Dictionary = Saves.import_code("not-a-save")
	check(invalid.is_empty(), "invalid backup is rejected")
	print("Ashen Company tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", message)
	else:
		failed += 1
		push_error("FAIL: " + message)
