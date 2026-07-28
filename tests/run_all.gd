extends SceneTree

const Content = preload("res://src/content.gd")
const Rules = preload("res://src/rules.gd")
const Saves = preload("res://src/save_service.gd")

var passed: int = 0
var failed: int = 0

func _init() -> void:
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
	check(Content.CLASSES.has("warrior") and Content.CLASSES.has("mage"), "warrior and mage classes are registered")
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
	check(Rules.validate_save(fresh), "default save validates")
	var pre_blacksmith_save: Dictionary = fresh.duplicate(true)
	pre_blacksmith_save.profile.erase("blacksmith_level")
	check(Rules.validate_save(pre_blacksmith_save) and int(Saves.import_code(Saves.export_code(pre_blacksmith_save)).profile.blacksmith_level) == 0, "older saves migrate safely to a tier-zero blacksmith")
	var code: String = Saves.export_code(fresh)
	var imported: Dictionary = Saves.import_code(code)
	check(not imported.is_empty() and int(imported.schema_version) == 1, "save backup round trip")
	var legacy: Dictionary = Saves.default_data()
	legacy.profile.skill_tree = {"iron_grip": 2}
	var migrated: Dictionary = Saves.import_code(Saves.export_code(legacy))
	check(int(migrated.profile.skill_tree.get("vanguard_grip", 0)) == 1 and int(migrated.profile.skill_tree.get("vanguard_drill", 0)) == 1, "legacy skill purchases migrate into the new progression tree")
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
