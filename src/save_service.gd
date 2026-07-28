class_name SaveService
extends RefCounted

const GameRules = preload("res://src/rules.gd")

const SAVE_PATH: String = "user://ashen_company_save.json"
const BACKUP_PATH: String = "user://ashen_company_save.backup.json"

static func default_data() -> Dictionary:
	return {
		"schema_version": 1,
		"profile": {
			"silver": 0,
			"provisions": 0,
			"armory_level": 0,
			"training_level": 0,
			"quartermaster_level": 0,
			"starting_weapon": "spear",
			"starting_class": "warrior",
			"starting_doctrine": "shield_line",
			"starting_curse": "none",
			"campaign_flags": {},
			"skill_tree": {},
			"veteran": {},
			"expedition": {"operation": "forage", "last_seen": Time.get_unix_time_from_system(), "started_at": Time.get_unix_time_from_system(), "pending_silver": 0, "pending_provisions": 0}
		},
		"settings": {"music": 0.72, "sfx": 0.82, "effect_density": 1.0, "screen_shake": true, "left_handed": false},
		"active_run": {}
	}

static func load_data() -> Dictionary:
	var primary: Dictionary = _read_path(SAVE_PATH)
	if GameRules.validate_save(primary):
		return _merge_defaults(primary)
	var backup: Dictionary = _read_path(BACKUP_PATH)
	if GameRules.validate_save(backup):
		return _merge_defaults(backup)
	return default_data()

static func save_data(data: Dictionary) -> bool:
	if not GameRules.validate_save(data):
		return false
	if FileAccess.file_exists(SAVE_PATH):
		var current: Dictionary = _read_path(SAVE_PATH)
		if GameRules.validate_save(current):
			_write_path(BACKUP_PATH, current)
	return _write_path(SAVE_PATH, data)

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
	for section: String in ["profile", "settings"]:
		var target: Dictionary = data.get(section, {})
		for key: String in defaults[section]:
			if not target.has(key):
				target[key] = defaults[section][key]
		data[section] = target
	if not data.has("active_run"):
		data.active_run = {}
	return data
