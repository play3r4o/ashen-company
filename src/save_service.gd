class_name SaveService
extends RefCounted

const GameRules = preload("res://src/rules.gd")
const GameContent = preload("res://src/content.gd")
const TrainingContent = preload("res://src/content/training_grounds_content.gd")
const Arsenal = preload("res://src/services/arsenal_service.gd")
const Roster = preload("res://src/services/roster_service.gd")

const SAVE_PATH: String = "user://ashen_company_v3_save.json"
const BACKUP_PATH: String = "user://ashen_company_v3_save.backup.json"
const V2_SAVE_PATH: String = "user://ashen_company_v2_save.json"
const V2_BACKUP_PATH: String = "user://ashen_company_v2_save.backup.json"
const LEGACY_SAVE_PATH: String = "user://ashen_company_save.json"
const V2_MIGRATION_BACKUP_PATH: String = "user://ashen_company_v2_pre_training.backup.json"
const LEGACY_SKILL_MAP: Dictionary = {
	"braced_stance": "vanguard_drill", "cleaving_footwork": "vanguard_axe", "iron_grip": "vanguard_grip", "shield_wall": "vanguard_shield",
	"weighted_heads": "huntsman_sling", "bodkin_craft": "huntsman_bow", "deep_quiver": "huntsman_quiver", "keen_eye": "company_eye",
	"ember_lore": "hedge_embers", "lantern_hook": "hedge_lantern", "field_dressing": "hedge_dressing", "quick_hands": "company_hands",
	"hard_march": "company_march", "mail_lining": "company_mail", "scavengers_reach": "huntsman_caltrops", "fletched_shafts": "huntsman_mark"
}

static func default_data() -> Dictionary:
	var now: float = Time.get_unix_time_from_system()
	return {
		"schema_version": 3,
		"profile": {
			"silver": 0,
			"provisions": 0,
			"armory_level": 0,
			"blacksmith_level": 0,
			"training_level": 0,
			"quartermaster_level": 0,
			"hall_level": 0,
			"constructed_buildings": ["veterans_hall", "campfire"],
			"building_plots": {},
			"starting_weapon": "sword",
			"starting_class": "warrior",
			"starting_doctrine": "",
			"starting_curse": "none",
			"campaign_flags": {},
			"skill_tree": {},
			"company_tree": {},
			"training_nodes": {"company_crest": 1, "sword": 1, "bow": 1, "daggers": 1, "staff": 1},
			"training_points": 0,
			"training_xp": 0,
			"claimed_training_rewards": {},
			"training_migration_complete": true,
			"expedition_arsenals": [{"id": "arsenal_company_standard", "name": "Company Standard", "starting_weapon": "sword", "weapon_ids": ["sword"], "technique_ids": [], "doctrine_ids": [], "class_id": "warrior", "valid": true}],
			"selected_arsenal_id": "arsenal_company_standard",
			"inventory": [],
			"equipped": {"head": "", "body": "", "hands": "", "boots": "", "trinket": ""},
			"heroes": Roster.default_roster(now),
			"active_hero_id": "warrior",
			"unlocked_biomes": ["blackthorn_moor"],
			"biome_keys": {},
			"frontier_upgrades": {},
			"region_seed": 41041,
			"next_item_uid": 1,
			"veteran": {},
			"expedition": {"operation": "forage", "last_seen": now, "started_at": now, "pending_silver": 0, "pending_provisions": 0}
		},
		"settings": {"music": 0.72, "sfx": 0.82, "effect_density": 1.0, "screen_shake": true, "left_handed": false, "collision_debug": false, "gate_confirmations": true},
		"active_run": {}
	}

static func load_data() -> Dictionary:
	var primary: Dictionary = _read_path(SAVE_PATH)
	if GameRules.validate_save(primary):
		return _merge_defaults(primary)
	var backup: Dictionary = _read_path(BACKUP_PATH)
	if GameRules.validate_save(backup):
		return _merge_defaults(backup)
	var v2: Dictionary = _read_path(V2_SAVE_PATH)
	if int(v2.get("schema_version", 0)) == 2 and GameRules.validate_save(v2):
		var migrated_v2: Dictionary = _migrate_v2_to_v3(v2)
		_write_path(SAVE_PATH, migrated_v2)
		return migrated_v2
	var v2_backup: Dictionary = _read_path(V2_BACKUP_PATH)
	if int(v2_backup.get("schema_version", 0)) == 2 and GameRules.validate_save(v2_backup):
		var migrated_backup: Dictionary = _migrate_v2_to_v3(v2_backup)
		_write_path(SAVE_PATH, migrated_backup)
		return migrated_backup
	# The original prototype save carried only accessibility and audio settings.
	var fresh: Dictionary = default_data()
	var legacy: Dictionary = _read_path(LEGACY_SAVE_PATH)
	if legacy.get("settings", null) is Dictionary:
		for setting: String in fresh.settings:
			if legacy.settings.has(setting):
				fresh.settings[setting] = legacy.settings[setting]
	return fresh

static func save_data(data: Dictionary) -> bool:
	if not GameRules.validate_save(data):
		return false
	if FileAccess.file_exists(SAVE_PATH):
		var current: Dictionary = _read_path(SAVE_PATH)
		if GameRules.validate_save(current):
			_write_path(BACKUP_PATH, current)
	return _write_path(SAVE_PATH, data)

static func reset_data(preserved_settings: Dictionary = {}) -> Dictionary:
	# Remove both generations of the save before writing the fresh profile. A
	# normal save would preserve the old progression as its automatic backup,
	# allowing an apparent reset to silently restore itself on the next load.
	for path: String in [SAVE_PATH, BACKUP_PATH, V2_SAVE_PATH, V2_BACKUP_PATH, V2_MIGRATION_BACKUP_PATH, LEGACY_SAVE_PATH]:
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK and FileAccess.file_exists(path):
				return {}
	var fresh: Dictionary = default_data()
	for setting: String in fresh.settings:
		if preserved_settings.has(setting):
			fresh.settings[setting] = preserved_settings[setting]
	return fresh if _write_path(SAVE_PATH, fresh) else {}

static func export_code(data: Dictionary) -> String:
	return Marshalls.utf8_to_base64(JSON.stringify(data))

static func import_code(code: String) -> Dictionary:
	var clean_code: String = code.strip_edges()
	if clean_code.is_empty() or clean_code.length() % 4 != 0:
		return {}
	var pattern: RegEx = RegEx.new()
	pattern.compile("^[A-Za-z0-9+/]*={0,2}$")
	if pattern.search(clean_code) == null:
		return {}
	var decoded: String = Marshalls.base64_to_utf8(clean_code)
	if decoded.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(decoded)
	if parsed is Dictionary and int(parsed.get("schema_version", 0)) == 2:
		return _migrate_v2_to_v3(parsed)
	if not GameRules.validate_save(parsed):
		return {}
	return _merge_defaults(parsed)

static func _read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _write_path(path: String, data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	return true

static func _merge_defaults(data: Dictionary) -> Dictionary:
	var defaults: Dictionary = default_data()
	var source_profile: Dictionary = data.get("profile", {}) if data.get("profile", {}) is Dictionary else {}
	# An explicitly stored Hall tier is authoritative.  Older saves may omit the
	# city fields entirely, in which case we still infer them below, but never
	# promote a valid save merely because it contains advanced service buildings.
	var had_hall_level: bool = source_profile.has("hall_level") and (source_profile.hall_level is int or source_profile.hall_level is float)
	var had_city_fields: bool = source_profile.has("constructed_buildings")
	var had_plot_fields: bool = source_profile.has("building_plots")
	for section: String in ["profile", "settings"]:
		var target: Dictionary = data.get(section, {})
		for key: String in defaults[section]:
			if not target.has(key):
				target[key] = defaults[section][key]
		data[section] = target
	if not had_city_fields:
		var migrated_buildings: Array[String] = ["veterans_hall", "campfire"]
		for building_id: String in ["armory", "blacksmith", "quartermaster", "training"]:
			if int(data.profile.get("%s_level" % building_id, 0)) > 0:
				migrated_buildings.append(building_id)
		data.profile.constructed_buildings = migrated_buildings
		if not had_hall_level:
			data.profile.hall_level = clampi(migrated_buildings.size() - 2, 0, 4)
	if not had_plot_fields or not data.profile.get("building_plots", {}) is Dictionary:
		var migrated_plots: Dictionary = {}
		var plot_index: int = 0
		for building_id: String in ["armory", "blacksmith", "quartermaster", "training"]:
			if building_id in data.profile.constructed_buildings and plot_index < 4:
				migrated_plots["plot_%d" % (plot_index + 1)] = building_id
				plot_index += 1
		data.profile.building_plots = migrated_plots
		if not had_hall_level:
			data.profile.hall_level = maxi(int(data.profile.hall_level), plot_index)
	# Keep the persisted value in the same bounded form used by the world
	# controller.  This prevents malformed data from selecting a later scene,
	# while preserving a legitimate, explicitly saved tier exactly.
	data.profile.hall_level = clampi(int(data.profile.get("hall_level", 0)), 0, 4)
	var equipped_defaults: Dictionary = defaults.profile.equipped
	var equipped: Dictionary = data.profile.get("equipped", {})
	for slot: String in equipped_defaults:
		if not equipped.has(slot):
			equipped[slot] = ""
	data.profile.equipped = equipped
	if not data.profile.get("heroes", []) is Array or Array(data.profile.get("heroes", [])).is_empty():
		data.profile.heroes = Roster.default_roster()
	if not data.profile.get("unlocked_biomes", []) is Array:
		data.profile.unlocked_biomes = ["blackthorn_moor"]
	if not data.profile.get("company_tree", {}) is Dictionary:
		data.profile.company_tree = {}
	# A valid v3 profile always retains the permanent Company Crest and the four
	# class starter weapons, even when an older v3 writer stored an empty tree.
	var training_nodes: Dictionary = data.profile.get("training_nodes", {})
	training_nodes["company_crest"] = 1
	for starter_id: String in ["sword", "bow", "daggers", "staff"]:
		training_nodes[starter_id] = 1
	data.profile.training_nodes = training_nodes
	# `skill_tree` is kept as a compatibility alias while UI and combat migrate
	# to the clearer company-tree contract.
	if Dictionary(data.profile.get("skill_tree", {})).is_empty() and not Dictionary(data.profile.company_tree).is_empty():
		data.profile.skill_tree = Dictionary(data.profile.company_tree).duplicate(true)
	elif Dictionary(data.profile.company_tree).is_empty() and not Dictionary(data.profile.get("skill_tree", {})).is_empty():
		data.profile.company_tree = Dictionary(data.profile.skill_tree).duplicate(true)
	_migrate_equipment_stats(data.profile)
	if not data.has("active_run"):
		data.active_run = {}
	data.schema_version = 3
	return data

static func _migrate_v2_to_v3(v2_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = v2_data.duplicate(true)
	if not FileAccess.file_exists(V2_MIGRATION_BACKUP_PATH):
		_write_path(V2_MIGRATION_BACKUP_PATH, v2_data)
	var fresh: Dictionary = default_data()
	var old_profile: Dictionary = Dictionary(v2_data.get("profile", {}))
	var profile: Dictionary = fresh.profile
	for key: String in profile:
		if old_profile.has(key) and key not in ["training_nodes", "training_points", "training_xp", "claimed_training_rewards", "training_migration_complete", "expedition_arsenals", "selected_arsenal_id"]:
			profile[key] = old_profile[key]
	for key: String in ["silver", "provisions", "armory_level", "blacksmith_level", "training_level", "quartermaster_level", "hall_level", "constructed_buildings", "building_plots", "inventory", "equipped", "heroes", "active_hero_id", "unlocked_biomes", "biome_keys", "frontier_upgrades", "region_seed", "next_item_uid", "veteran", "expedition"]:
		if old_profile.has(key):
			profile[key] = old_profile[key]
	var old_class: String = String(old_profile.get("starting_class", "warrior")).to_lower()
	profile.starting_class = _map_legacy_class(old_class)
	profile.starting_weapon = _map_legacy_weapon(String(old_profile.get("starting_weapon", "")), old_class)
	profile.starting_doctrine = ""
	profile.skill_tree = {}
	profile.company_tree = {}
	profile.training_nodes = {"company_crest": 1, "sword": 1, "bow": 1, "daggers": 1, "staff": 1}
	var old_tree: Dictionary = Dictionary(old_profile.get("skill_tree", old_profile.get("company_tree", {})))
	var refund: int = 0
	var branch_ids: Array = ["VANGUARD", "HUNTSMAN", "HEDGECRAFT", "COMPANYCRAFT"]
	for branch_name_value: Variant in branch_ids:
		var branch_name: String = String(branch_name_value)
		var branch: Array = GameContent.PROGRESSION_BRANCHES.get(branch_name, [])
		for index: int in branch.size():
			if int(old_tree.get(String(branch[index]), 0)) <= 0:
				continue
			if index < 2:
				refund += 1
			elif index < 4:
				refund += 2
			elif index == 4:
				refund += 3
			else:
				refund += 4
	profile.training_points = refund
	profile.training_migration_complete = true
	profile.expedition_arsenals = fresh.profile.expedition_arsenals
	profile.selected_arsenal_id = "arsenal_company_standard"
	migrated.schema_version = 3
	migrated.profile = profile
	migrated.settings = Dictionary(v2_data.get("settings", fresh.settings)).duplicate(true)
	migrated.active_run = {}
	return _merge_defaults(migrated)

static func _map_legacy_weapon(old_weapon: String, old_class: String) -> String:
	old_weapon = old_weapon.to_lower()
	old_class = old_class.to_lower()
	if old_class == "hunter" or old_weapon in ["bow", "sling", "caltrops"]:
		return "bow"
	if old_class == "rogue" or old_weapon == "knives":
		return "daggers"
	if old_class == "mage" or old_weapon == "witchfire":
		return "staff"
	return "sword"

static func _map_legacy_class(old_class: String) -> String:
	match old_class.to_lower():
		"vanguard", "warrior": return "warrior"
		"ranger", "hunter", "huntsman": return "hunter"
		"shadow", "rogue": return "rogue"
		"arcanist", "mage", "hedge": return "mage"
	return "warrior"

static func _migrate_legacy_skill_tree(profile: Dictionary) -> void:
	var tree: Dictionary = profile.get("skill_tree", {})
	for legacy_id: String in LEGACY_SKILL_MAP:
		if int(tree.get(legacy_id, 0)) <= 0:
			continue
		_grant_progression_node(String(LEGACY_SKILL_MAP[legacy_id]), tree)
		tree.erase(legacy_id)
	profile.skill_tree = tree

static func _migrate_equipment_stats(profile: Dictionary) -> void:
	var stat_names: Dictionary = {
		"reach": "melee_range", "guard_blast": "guard_damage", "guard": "guard_strength",
		"cooldown": "attack_speed", "melee_cooldown": "melee_attack_speed",
		"ranged_cooldown": "ranged_attack_speed", "arcane_cooldown": "arcane_attack_speed",
		"recovery": "health_regen", "loot_luck": "loot_quality", "projectiles": "ranged_projectiles"
	}
	var inventory: Array = profile.get("inventory", [])
	for item_value: Variant in inventory:
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		var old_modifiers: Array = item.get("modifiers", [])
		var migrated: Array[Dictionary] = []
		for modifier_value: Variant in old_modifiers:
			if not modifier_value is Dictionary:
				continue
			var modifier: Dictionary = modifier_value
			var old_stat: String = String(modifier.get("stat", ""))
			if old_stat.is_empty():
				continue
			migrated.append({"stat": String(stat_names.get(old_stat, old_stat)), "amount": float(modifier.get("amount", 0.0))})
		item.modifiers = migrated
	profile.inventory = inventory

static func _grant_progression_node(node_id: String, tree: Dictionary) -> void:
	if not GameContent.PROGRESSION_NODES.has(node_id):
		return
	for required_value: Variant in GameContent.PROGRESSION_NODES[node_id].requires:
		_grant_progression_node(String(required_value), tree)
	tree[node_id] = maxi(1, int(tree.get(node_id, 0)))
