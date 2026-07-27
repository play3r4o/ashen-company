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
	check(Content.unlocked_weapons(0) == ["spear", "sling"], "new profiles begin with melee and ranged weapons")
	check(String(Content.WEAPONS["spear"].category) == "MELEE" and String(Content.WEAPONS["sling"].category) == "RANGED", "starting arsenal covers both weapon ranges")
	check(Content.TECHNIQUES.size() >= 20, "technique pool includes expanded abilities")
	check(Content.unlocked_weapons(3).size() == 6, "armory tier three unlocks the complete arsenal")
	check(String(Content.WEAPONS["spear"].behavior) == "thrust" and float(Content.WEAPONS["spear"].speed) == 0.0, "spear is a contact thrust rather than a projectile")
	check(String(Content.TECHNIQUES["iron_grip"].stat) == "melee_damage" and String(Content.TECHNIQUES["measured_breath"].stat) == "ranged_cooldown", "techniques have distinct weapon identities")
	var fresh: Dictionary = Saves.default_data()
	check(Rules.validate_save(fresh), "default save validates")
	var code: String = Saves.export_code(fresh)
	var imported: Dictionary = Saves.import_code(code)
	check(not imported.is_empty() and int(imported.schema_version) == 1, "save backup round trip")
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
