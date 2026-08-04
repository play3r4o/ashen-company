extends SceneTree

const Content = preload("res://src/content.gd")
const Rules = preload("res://src/rules.gd")
const Saves = preload("res://src/save_service.gd")
const Roster = preload("res://src/services/roster_service.gd")
const Region = preload("res://src/services/region_generator.gd")
const Expedition = preload("res://src/services/expedition_service.gd")
const TrainingContent = preload("res://src/content/training_grounds_content.gd")
const TrainingGrounds = preload("res://src/services/training_grounds_service.gd")
const Arsenal = preload("res://src/services/arsenal_service.gd")
const Offers = preload("res://src/services/upgrade_offer_service.gd")
const CombatStats = preload("res://src/services/combat_stat_service.gd")
const Statuses = preload("res://src/services/status_service.gd")
const EnvironmentService = preload("res://src/services/environment_interaction_service.gd")
const Structure = preload("res://src/foundation/structure_definition.gd")
const HudLayout = preload("res://scenes/ui/hud/hud.tscn")
const CampTier0 = preload("res://scenes/world/camp/camp_tier_0.tscn")
const CampTier1 = preload("res://scenes/world/camp/camp_tier_1.tscn")
const TrainingTreeScreen = preload("res://scenes/ui/screens/training_tree_screen.tscn")
const ArsenalScreen = preload("res://scenes/ui/screens/arsenal_screen.tscn")

var passed: int = 0
var failed: int = 0

func _init() -> void:
	var catalog_report: Dictionary = TrainingContent.validate_catalog()
	check(bool(catalog_report.valid) and int(catalog_report.node_count) == 156, "Training Grounds registers exactly 156 valid nodes")
	check(TrainingContent.SCHOOL_WEAPONS.vanguard == ["sword", "spear", "greatsword"] and TrainingContent.SCHOOL_WEAPONS.arcanist == ["staff", "wand", "runic_orb"], "four schools expose the planned weapon identity")
	check(TrainingContent.abilities().size() == 24 and TrainingContent.doctrines().size() == 12, "all weapons, techniques, and doctrines are registered")
	check(TrainingContent.node_resources().size() == 156 and TrainingContent.ability_resources().size() == 24 and TrainingContent.doctrine_resources().size() == 12 and TrainingContent.status_resources().size() == 6 and TrainingContent.boon_resources().size() == 12, "typed Resources mirror the canonical Training Grounds registry")
	var sword_rank_two: Dictionary = TrainingContent.compile_ability("sword", 2)
	var fire_nova_rank_five: Dictionary = TrainingContent.compile_ability("fire_nova", 5)
	check(is_equal_approx(float(sword_rank_two.get("base_stats", {}).get("normalized_power", 0.0)), 1.0) and is_equal_approx(float(sword_rank_two.get("rank_stats", {}).get("damage_multiplier", 0.0)), 1.20) and fire_nova_rank_five.get("rank_stats", {}).get("behavior_flags", []).has("expand_collapse_double_hit"), "ability ranks expose the Bible's numeric changes and signature behaviors")
	var build_state_script = load("res://src/foundation/run_build_state.gd")
	var build_state = build_state_script.from_dictionary({"seed": 44, "level": 3, "weapon_ranks": {"sword": 2}, "rerolls_remaining": 1})
	check(int(build_state.level) == 3 and int(build_state.weapon_ranks.sword) == 2 and int(build_state.rerolls_remaining) == 1, "run build state compiles and restores typed rank data")
	var screen_profile: Dictionary = Saves.default_data().profile
	screen_profile.training_level = 5
	screen_profile.training_points = 1000
	var tree_screen := TrainingTreeScreen.instantiate()
	tree_screen.apply_safe_area(47.0)
	tree_screen.bind_profile(screen_profile)
	check(tree_screen.get_node("TreeViewport").position.y == 179.0 and tree_screen.get_node("TreeViewport").clip_contents, "Training Grounds screen keeps the authored canvas pannable under a notch safe area")
	tree_screen.free()
	var arsenal_screen := ArsenalScreen.instantiate()
	arsenal_screen.apply_safe_area(47.0)
	arsenal_screen.bind_profile(screen_profile)
	check(arsenal_screen.get_node("Panel").position.y == 75.0 and arsenal_screen.get_node("Panel/Root/StartButton") is Button, "Expedition Arsenal instantiates its authored controls under a notch safe area")
	arsenal_screen.free()
	var training_profile: Dictionary = Saves.default_data().profile
	training_profile.training_level = 5
	training_profile.training_points = 1000
	var training := TrainingGrounds.new(training_profile)
	check(bool(training.validate_tree().get("valid", false)) and training.node_state("company_crest") == "purchased", "Training Grounds graph is connected and exposes authored node states")
	check(bool(training.can_purchase("tactical_rethink").get("ok", false)) and bool(training.purchase("tactical_rethink").get("ok", false)), "Training Points purchase central utility nodes")
	check(bool(training.can_purchase("ground_slam").get("ok", false)) and bool(training.purchase("ground_slam").get("ok", false)), "Training Grounds prerequisites unlock techniques")
	var refund_preview: Dictionary = training.refund_preview("tactical_rethink")
	check(bool(refund_preview.get("ok", false)) and int(refund_preview.get("refund_points", 0)) == 2, "Training Grounds refunds return exact node costs")
	check(bool(training.refund("tactical_rethink").get("ok", false)) and int(training_profile.training_points) == 998, "individual refunds are free and restore points")
	var arsenal: Dictionary = Arsenal.default_arsenal(training_profile)
	check(bool(Arsenal.validate(training_profile, arsenal).get("valid", false)), "default Expedition Arsenal is valid")
	arsenal.technique_ids = ["ground_slam"]
	var offer_run: Dictionary = {"seed": 1212, "level": 1, "weapon_ranks": {"sword": 1}, "technique_ranks": {}, "boon_ranks": {}, "recent_rejected_choices": []}
	var offers_a: Array[Dictionary] = Offers.generate(offer_run, training_profile, arsenal)
	var offers_b: Array[Dictionary] = Offers.generate(offer_run, training_profile, arsenal)
	check(offers_a == offers_b and offers_a.size() == 3, "level offers are deterministic and contain three choices")
	check(offers_a.any(func(choice: Dictionary) -> bool: return not bool(choice.get("owned", false)) and String(choice.get("type", "")) in ["weapon", "technique"]), "the early acquisition guarantee cannot be satisfied by a generic Boon")
	var rerolled: Dictionary = Offers.reroll(offer_run, training_profile, arsenal, offers_a, 0)
	check(int(rerolled.get("offer_index", 0)) > 0 and Offers.choice_signature(Array(rerolled.get("choices", []))) != Offers.choice_signature(offers_a), "rerolls advance deterministically and cannot repeat the visible set")
	var construction_profile: Dictionary = Saves.default_data().profile
	var construction_service := TrainingGrounds.new(construction_profile)
	var construction_reward: Dictionary = construction_service.grant_one_time_points("training_grounds_constructed", 4, "training_grounds")
	var construction_repeat: Dictionary = construction_service.grant_one_time_points("training_grounds_constructed", 4, "training_grounds")
	check(bool(construction_reward.get("claimed", false)) and not bool(construction_repeat.get("claimed", false)) and int(construction_profile.training_points) == 4, "Training Grounds construction reward is one-time and idempotent")
	check(is_equal_approx(GameRules.damage_after_armor_rating(100.0, 100.0), 50.0) and is_equal_approx(GameRules.attack_interval(1.0, 1.0), 0.5), "v3 armor and attack-speed formulas use shared stat rules")
	check(is_equal_approx(CombatStats.armor_reduction(100.0), 0.5) and is_equal_approx(CombatStats.attack_interval(1.0, 0.6), 0.625) and CombatStats.critical_chance(0.60) == 0.60, "shared combat stat service applies caps and formulas")
	var status_service := Statuses.new()
	var bleed_apply: Dictionary = status_service.apply(7, "bleed", "hero", "sword", 1.0, 1.0, -1.0, 2)
	check(bool(bleed_apply.get("applied", false)) and status_service.has(7, "bleed") and int(bleed_apply.get("stacks", 0)) == 2, "status service tracks source, stacks, and duration")
	check(status_service.consume_stacks(7, "bleed", 1) == 1 and status_service.stacks_for(7, "bleed") == 1, "status reactions consume only the requested stacks")
	check(EnvironmentService.resolve(["lightning"], ["wet"]).size() == 1 and EnvironmentService.resolve(["impact"], ["brittle"]).front().id == "impact_brittle_break", "environment interactions use shared tags")
	var hud_layout := HudLayout.instantiate()
	check(hud_layout.rect_for("SafeAreaTop/ResourceRail").size == Vector2(390.0, 52.0) and hud_layout.rect_for("RunActions/GuardStepButton").size == Vector2(82.0, 74.0), "HUD scene exposes the actual editable rail and action controls")
	check(hud_layout.get_node_or_null("PreviewResourceRail") == null and hud_layout.get_node_or_null("SafeAreaTop/ResourceRail/HealthBar") is ProgressBar and hud_layout.get_node_or_null("SafeAreaTop/SettingsCogButton") is Button, "HUD scene contains live runtime visuals with no preview duplicates")
	var authored_health_icon := hud_layout.get_node("SafeAreaTop/ResourceRail/HealthIcon") as Control
	authored_health_icon.position += Vector2(7.0, 2.0)
	check(hud_layout.rect_for("SafeAreaTop/ResourceRail/HealthIcon").position == authored_health_icon.global_position, "moving a visible HUD node changes the same node used at runtime")
	hud_layout.free()
	var campfire_scene: Node = (load("res://scenes/world/structures/campfire.tscn") as PackedScene).instantiate()
	var campfire_base_sprite := campfire_scene.get_node("Base") as Sprite2D
	var campfire_flame_sprite := campfire_scene.get_node("Flame") as AnimatedSprite2D
	var campfire_smoke_sprite := campfire_scene.get_node("Smoke") as AnimatedSprite2D
	check(campfire_base_sprite.texture != null and campfire_base_sprite.texture.resource_path.ends_with("campfire_base.png") and campfire_flame_sprite.sprite_frames.get_frame_count("burn") == 6 and campfire_smoke_sprite.sprite_frames.get_frame_count("drift") == 6 and campfire_scene.get_node_or_null("StaticBody2D/CollisionPolygon2D") != null and campfire_scene.get_node_or_null("InteractionArea/CollisionPolygon2D") != null, "the editable Campfire scene owns its art, animation, collision and interaction")
	campfire_scene.free()
	var camp_tier_zero := CampTier0.instantiate() as AshenCampRuntime
	camp_tier_zero.bind_state(0, {}, {})
	check(camp_tier_zero.camp_tier == 0 and camp_tier_zero.camp_bounds_world().has_area() and not camp_tier_zero.structure_info("veterans_hall").is_empty() and not camp_tier_zero.structure_info("campfire").is_empty(), "camp tier zero directly exposes its authored bounds and structures")
	camp_tier_zero.free()
	var camp_tier_one := CampTier1.instantiate() as AshenCampRuntime
	camp_tier_one.bind_state(1, {}, {})
	var plot_info: Dictionary = camp_tier_one.plot_info("plot_1")
	check(camp_tier_one.camp_tier == 1 and camp_tier_one.camp_bounds_world().has_area() and not plot_info.is_empty() and PackedVector2Array(plot_info.get("interaction", PackedVector2Array())).size() >= 3, "each Hall level is a complete selectable runtime camp scene with authored plots")
	camp_tier_one.free()
	var node_card_scene := load("res://scenes/ui/components/training_node_card.tscn") as PackedScene
	var connector_scene := load("res://scenes/ui/components/training_connector.tscn") as PackedScene
	var option_card_scene := load("res://scenes/ui/components/arsenal_option_card.tscn") as PackedScene
	var node_card := node_card_scene.instantiate()
	var connector := connector_scene.instantiate()
	var option_card := option_card_scene.instantiate()
	check(node_card is AshenTrainingNodeCard and connector is Line2D and option_card is AshenArsenalOptionCard, "Training tree and Arsenal entries use editable authored runtime components")
	node_card.free()
	connector.free()
	option_card.free()
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
	check(not imported.is_empty() and int(imported.schema_version) == 3, "schema-v3 save backup round trip")
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
