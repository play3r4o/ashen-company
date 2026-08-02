class_name ArsenalService
extends RefCounted

const Content = preload("res://src/content/training_grounds_content.gd")
const TrainingGrounds = preload("res://src/services/training_grounds_service.gd")

const MAX_WEAPONS: int = 4
const MAX_TECHNIQUES: int = 4

static func default_arsenal(profile: Dictionary, name: String = "Company Standard") -> Dictionary:
	var training := TrainingGrounds.new(profile)
	var class_id: String = String(profile.get("starting_class", "warrior"))
	var starter: String = Content.starter_weapon_for_class(class_id)
	var weapon_ids: Array[String] = [starter]
	var technique_ids: Array[String] = []
	return {"id": "arsenal_%s" % name.to_lower().replace(" ", "_"), "name": name, "starting_weapon": starter, "weapon_ids": weapon_ids, "technique_ids": technique_ids, "doctrine_ids": [], "class_id": class_id, "valid": training.unlocked_weapons().has(starter)}

static func validate(profile: Dictionary, arsenal: Dictionary) -> Dictionary:
	var training := TrainingGrounds.new(profile)
	var errors: Array[String] = []
	var weapon_ids: Array = arsenal.get("weapon_ids", [])
	var technique_ids: Array = arsenal.get("technique_ids", [])
	var doctrine_ids: Array = arsenal.get("doctrine_ids", [])
	var class_id: String = String(arsenal.get("class_id", profile.get("starting_class", "warrior")))
	if class_id not in ["warrior", "hunter", "mage", "rogue"]:
		errors.append("Choose a valid company role.")
	if _unique_strings(weapon_ids).size() != weapon_ids.size():
		errors.append("A weapon candidate cannot be selected twice.")
	if _unique_strings(technique_ids).size() != technique_ids.size():
		errors.append("A technique candidate cannot be selected twice.")
	if weapon_ids.size() < 1:
		errors.append("Choose a starting weapon.")
	if weapon_ids.size() > MAX_WEAPONS:
		errors.append("Prepare no more than four weapon candidates.")
	if technique_ids.size() > MAX_TECHNIQUES:
		errors.append("Prepare no more than four technique candidates.")
	var starting_weapon: String = String(arsenal.get("starting_weapon", ""))
	if starting_weapon.is_empty() or not weapon_ids.has(starting_weapon):
		errors.append("The starting weapon must be one of the prepared weapons.")
	var unlocked_weapons: Array[String] = training.unlocked_weapons()
	for weapon_id_value: Variant in weapon_ids:
		var weapon_id: String = String(weapon_id_value)
		if not unlocked_weapons.has(weapon_id):
			errors.append("Weapon is not unlocked: %s." % weapon_id)
	var unlocked_techniques: Array[String] = training.unlocked_techniques()
	for technique_id_value: Variant in technique_ids:
		var technique_id: String = String(technique_id_value)
		if not unlocked_techniques.has(technique_id):
			errors.append("Technique is not unlocked: %s." % technique_id)
	var unlocked_doctrines: Array[String] = training.unlocked_doctrines()
	var max_doctrines: int = 2 if training.node_rank("dual_doctrine") > 0 else 1
	if doctrine_ids.size() > max_doctrines:
		errors.append("Prepare no more than %d doctrine%s." % [max_doctrines, "s" if max_doctrines != 1 else ""])
	for doctrine_id_value: Variant in doctrine_ids:
		var doctrine_id: String = String(doctrine_id_value)
		if not unlocked_doctrines.has(doctrine_id):
			errors.append("Doctrine is not unlocked: %s." % doctrine_id)
		if doctrine_ids.count(doctrine_id) > 1:
			errors.append("A doctrine cannot be selected twice.")
	for doctrine_id_value: Variant in doctrine_ids:
		var doctrine_id: String = String(doctrine_id_value)
		var definition: Dictionary = Content.doctrines().get(doctrine_id, {})
		for conflict_value: Variant in definition.get("exclusive_with", []):
			if doctrine_ids.has(String(conflict_value)):
				errors.append("Doctrine conflict: %s cannot combine with %s." % [doctrine_id, String(conflict_value)])
	return {"valid": errors.is_empty(), "errors": errors, "weapon_count": weapon_ids.size(), "technique_count": technique_ids.size(), "doctrine_count": doctrine_ids.size()}

static func available_unprepared(profile: Dictionary, arsenal: Dictionary) -> Dictionary:
	var training := TrainingGrounds.new(profile)
	var prepared_weapons: Array = arsenal.get("weapon_ids", [])
	var prepared_techniques: Array = arsenal.get("technique_ids", [])
	var prepared_doctrines: Array = arsenal.get("doctrine_ids", [])
	var weapons: Array[String] = []
	for weapon_id: String in training.unlocked_weapons():
		if weapon_id not in prepared_weapons:
			weapons.append(weapon_id)
	var techniques: Array[String] = []
	for technique_id: String in training.unlocked_techniques():
		if technique_id not in prepared_techniques:
			techniques.append(technique_id)
	var doctrines: Array[String] = []
	for doctrine_id: String in training.unlocked_doctrines():
		if doctrine_id not in prepared_doctrines:
			doctrines.append(doctrine_id)
	return {"weapons": weapons, "techniques": techniques, "doctrines": doctrines}

static func normalize(profile: Dictionary, arsenal: Dictionary) -> Dictionary:
	var copy: Dictionary = arsenal.duplicate(true)
	copy.weapon_ids = _unique_strings(Array(copy.get("weapon_ids", []))).slice(0, MAX_WEAPONS)
	copy.technique_ids = _unique_strings(Array(copy.get("technique_ids", []))).slice(0, MAX_TECHNIQUES)
	var max_doctrines: int = 2 if int(Dictionary(profile.get("training_nodes", {})).get("dual_doctrine", 0)) > 0 else 1
	copy.doctrine_ids = _unique_strings(Array(copy.get("doctrine_ids", []))).slice(0, max_doctrines)
	if String(copy.get("starting_weapon", "")) not in copy.weapon_ids and not copy.weapon_ids.is_empty():
		copy.starting_weapon = copy.weapon_ids[0]
	copy.valid = bool(validate(profile, copy).valid)
	return copy

static func _unique_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		var clean: String = String(value)
		if not clean.is_empty() and not result.has(clean):
			result.append(clean)
	return result
