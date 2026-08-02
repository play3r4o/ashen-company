class_name AshenArsenalScreen
extends Control

signal closed
signal expedition_requested(arsenal: Dictionary)

const Content = preload("res://src/content/training_grounds_content.gd")
const TrainingGrounds = preload("res://src/services/training_grounds_service.gd")
const Arsenal = preload("res://src/services/arsenal_service.gd")
const OptionCardScene = preload("res://src/ui/arsenal_option_card.tscn")

var profile: Dictionary = {}
var pending_profile: Dictionary = {}
var training: TrainingGroundsService
var selected_class: String = "warrior"
var selected_weapon: String = "sword"
var selected_weapons: Array[String] = ["sword"]
var selected_techniques: Array[String] = []
var selected_doctrines: Array[String] = []
var weapon_buttons: Dictionary = {}
var technique_buttons: Dictionary = {}
var doctrine_buttons: Dictionary = {}

@onready var class_label: Label = $Panel/Root/ClassLabel
@onready var loadout_label: Label = $Panel/Root/LoadoutLabel
@onready var weapon_list: GridContainer = $Panel/Root/WeaponList
@onready var technique_list: GridContainer = $Panel/Root/TechniqueList
@onready var doctrine_list: HBoxContainer = $Panel/Root/DoctrineList
@onready var start_button: Button = $Panel/Root/StartButton
@onready var message_label: Label = $Panel/Root/MessageLabel
@onready var validation_label: Label = $Panel/Root/ValidationLabel

func apply_safe_area(top_inset: float) -> void:
	# Keep the authored panel geometry intact on devices without a notch. On a
	# notched iPhone, move the single authored panel below the black safe band
	# and give it back the same usable bottom edge.
	var inset: float = clampf(top_inset, 0.0, 59.0)
	$Panel.position.y = 28.0 + inset
	$Panel.size.y = maxf(620.0, 788.0 - inset)

func _ready() -> void:
	for class_button: Button in [$Panel/Root/ClassRow/ClassWarrior, $Panel/Root/ClassRow/ClassHunter, $Panel/Root/ClassRow/ClassMage, $Panel/Root/ClassRow/ClassRogue]:
		class_button.toggle_mode = true
	$Panel/Root/ClassRow/ClassWarrior.pressed.connect(_select_class.bind("warrior"))
	$Panel/Root/ClassRow/ClassHunter.pressed.connect(_select_class.bind("hunter"))
	$Panel/Root/ClassRow/ClassMage.pressed.connect(_select_class.bind("mage"))
	$Panel/Root/ClassRow/ClassRogue.pressed.connect(_select_class.bind("rogue"))
	$Panel/Root/BackButton.pressed.connect(func() -> void: closed.emit())
	start_button.pressed.connect(_start_expedition)
	if not pending_profile.is_empty():
		var deferred_profile: Dictionary = pending_profile
		pending_profile.clear()
		_bind_profile_now(deferred_profile)

func bind_profile(target_profile: Dictionary) -> void:
	if not is_node_ready():
		pending_profile = target_profile
		return
	_bind_profile_now(target_profile)

func _bind_profile_now(target_profile: Dictionary) -> void:
	profile = target_profile
	training = TrainingGrounds.new(profile)
	selected_class = String(profile.get("starting_class", "warrior"))
	var active_hero_id: String = String(profile.get("active_hero_id", ""))
	for hero_value: Variant in profile.get("heroes", []):
		var hero: Dictionary = hero_value
		if String(hero.get("id", "")) == active_hero_id:
			selected_class = String(hero.get("class_id", selected_class))
			break
	if selected_class not in ["warrior", "hunter", "mage", "rogue"]:
		selected_class = "warrior"
	selected_weapon = String(profile.get("starting_weapon", Content.starter_weapon_for_class(selected_class)))
	selected_weapons = [selected_weapon]
	selected_techniques = []
	selected_doctrines = []
	var arsenals: Array = profile.get("expedition_arsenals", [])
	if not arsenals.is_empty() and arsenals[0] is Dictionary:
		var saved: Dictionary = arsenals[0]
		selected_weapon = String(saved.get("starting_weapon", selected_weapon))
		selected_weapons = _clean_ids(Array(saved.get("weapon_ids", [selected_weapon])))
		selected_techniques = _clean_ids(Array(saved.get("technique_ids", [])))
		selected_doctrines = _clean_ids(Array(saved.get("doctrine_ids", [])))
	_build_content()

func _build_content() -> void:
	for child: Node in weapon_list.get_children():
		weapon_list.remove_child(child)
		child.queue_free()
	for child: Node in technique_list.get_children():
		technique_list.remove_child(child)
		child.queue_free()
	for child: Node in doctrine_list.get_children():
		doctrine_list.remove_child(child)
		child.queue_free()
	weapon_buttons.clear()
	technique_buttons.clear()
	doctrine_buttons.clear()
	var unlocked_weapons: Array[String] = training.unlocked_weapons()
	for weapon_id: String in unlocked_weapons:
		if not Content.abilities().has(weapon_id):
			continue
		var definition: Dictionary = Content.abilities()[weapon_id]
		var button := OptionCardScene.instantiate() as AshenArsenalOptionCard
		button.name = "WeaponOption_%s" % weapon_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weapon_list.add_child(button)
		button.configure(weapon_id, String(definition.name), _compact_stats(definition), _ability_detail(definition), selected_weapons.has(weapon_id))
		button.pressed.connect(_toggle_weapon.bind(weapon_id))
		weapon_buttons[weapon_id] = button
	var unlocked_techniques: Array[String] = training.unlocked_techniques()
	for technique_id: String in unlocked_techniques:
		if not Content.abilities().has(technique_id):
			continue
		var definition: Dictionary = Content.abilities()[technique_id]
		var button := OptionCardScene.instantiate() as AshenArsenalOptionCard
		button.name = "TechniqueOption_%s" % technique_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		technique_list.add_child(button)
		button.configure(technique_id, String(definition.name), _compact_stats(definition), _ability_detail(definition), selected_techniques.has(technique_id))
		button.pressed.connect(_toggle_technique.bind(technique_id))
		technique_buttons[technique_id] = button
	for doctrine_id: String in training.unlocked_doctrines():
		var definition: Dictionary = Content.doctrines().get(doctrine_id, {})
		var button := OptionCardScene.instantiate() as AshenArsenalOptionCard
		button.name = "DoctrineOption_%s" % doctrine_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		doctrine_list.add_child(button)
		button.configure(doctrine_id, String(definition.get("name", doctrine_id)), "DOCTRINE", String(definition.get("description", "")), selected_doctrines.has(doctrine_id))
		var conflict: String = _doctrine_conflict(doctrine_id)
		button.set_conflict("CONFLICTS WITH %s" % conflict.to_upper() if not conflict.is_empty() else "")
		button.pressed.connect(_toggle_doctrine.bind(doctrine_id))
		doctrine_buttons[doctrine_id] = button
	_update_labels()

func _select_class(class_id: String) -> void:
	selected_class = class_id
	var starter: String = Content.starter_weapon_for_class(class_id)
	if not selected_weapons.has(starter):
		selected_weapons.push_front(starter)
	selected_weapon = starter
	_update_labels()
	_build_content()

func _toggle_weapon(weapon_id: String) -> void:
	if selected_weapons.has(weapon_id):
		if weapon_id != selected_weapon:
			selected_weapon = weapon_id
			message_label.text = "%s IS NOW THE STARTING WEAPON" % weapon_id.replace("_", " ").to_upper()
		else:
			if selected_weapons.size() == 1:
				return
			selected_weapons.erase(weapon_id)
	else:
		if selected_weapons.size() >= 4:
			message_label.text = "FOUR WEAPON CANDIDATES MAXIMUM"
			return
		selected_weapons.append(weapon_id)
	if selected_weapon not in selected_weapons:
		selected_weapon = selected_weapons[0]
	_update_labels()
	_build_content()

func _toggle_technique(technique_id: String) -> void:
	if selected_techniques.has(technique_id):
		selected_techniques.erase(technique_id)
	elif selected_techniques.size() < 4:
		selected_techniques.append(technique_id)
	else:
		message_label.text = "FOUR TECHNIQUE CANDIDATES MAXIMUM"
	_update_labels()

func _toggle_doctrine(doctrine_id: String) -> void:
	if selected_doctrines.has(doctrine_id):
		selected_doctrines.erase(doctrine_id)
	elif not _doctrine_conflict(doctrine_id).is_empty():
		message_label.text = "%s CANNOT BE PAIRED WITH %s" % [doctrine_id.replace("_", " ").to_upper(), _doctrine_conflict(doctrine_id).to_upper()]
	elif selected_doctrines.size() < (2 if training.node_rank("dual_doctrine") > 0 else 1):
		selected_doctrines.append(doctrine_id)
	else:
		message_label.text = "UNLOCK DUAL DOCTRINE FOR A SECOND SLOT"
	_update_labels()

func _start_expedition() -> void:
	var arsenal: Dictionary = {"id": "arsenal_company_standard", "name": "Company Standard", "starting_weapon": selected_weapon, "weapon_ids": selected_weapons.duplicate(), "technique_ids": selected_techniques.duplicate(), "doctrine_ids": selected_doctrines.duplicate(), "class_id": selected_class}
	var validation: Dictionary = Arsenal.validate(profile, arsenal)
	if not bool(validation.get("valid", false)):
		message_label.text = "\n".join(Array(validation.get("errors", [])))
		return
	profile.starting_class = selected_class
	profile.starting_weapon = selected_weapon
	profile.starting_doctrine = selected_doctrines[0] if not selected_doctrines.is_empty() else ""
	profile.expedition_arsenals = [arsenal]
	profile.selected_arsenal_id = String(arsenal.id)
	expedition_requested.emit(arsenal)

func _update_labels() -> void:
	class_label.text = "COMPANY ROLE  ·  %s" % selected_class.to_upper()
	loadout_label.text = "START: %s   |   WEAPONS %d/4   |   TECHNIQUES %d/4   |   DOCTRINES %d/%d" % [selected_weapon.to_upper(), selected_weapons.size(), selected_techniques.size(), selected_doctrines.size(), 2 if training != null and training.node_rank("dual_doctrine") > 0 else 1]
	var current_arsenal: Dictionary = {"starting_weapon": selected_weapon, "weapon_ids": selected_weapons, "technique_ids": selected_techniques, "doctrine_ids": selected_doctrines, "class_id": selected_class}
	var validation: Dictionary = Arsenal.validate(profile, current_arsenal)
	var errors: Array = validation.get("errors", [])
	if bool(validation.get("valid", false)):
		validation_label.text = "READY  ·  ONLY PREPARED CONTENT WILL APPEAR IN LEVEL-UPS"
		validation_label.add_theme_color_override("font_color", Color("91a985"))
		start_button.disabled = false
	else:
		validation_label.text = ("NOT READY  ·  " + String(errors[0])) if not errors.is_empty() else "NOT READY"
		validation_label.add_theme_color_override("font_color", Color("c47d69"))
		start_button.disabled = true
	for weapon_id: String in weapon_buttons:
		weapon_buttons[weapon_id].button_pressed = selected_weapons.has(weapon_id)
	for technique_id: String in technique_buttons:
		technique_buttons[technique_id].button_pressed = selected_techniques.has(technique_id)
	for doctrine_id: String in doctrine_buttons:
		doctrine_buttons[doctrine_id].button_pressed = selected_doctrines.has(doctrine_id)
		var conflict: String = _doctrine_conflict(doctrine_id)
		doctrine_buttons[doctrine_id].disabled = not conflict.is_empty() and not selected_doctrines.has(doctrine_id)
		doctrine_buttons[doctrine_id].set_conflict("CONFLICTS WITH %s" % conflict.to_upper() if not conflict.is_empty() else "")
	$Panel/Root/ClassRow/ClassWarrior.button_pressed = selected_class == "warrior"
	$Panel/Root/ClassRow/ClassHunter.button_pressed = selected_class == "hunter"
	$Panel/Root/ClassRow/ClassMage.button_pressed = selected_class == "mage"
	$Panel/Root/ClassRow/ClassRogue.button_pressed = selected_class == "rogue"

func _ability_detail(definition: Dictionary) -> String:
	var base: Dictionary = definition.get("base_stats", {})
	return "%s\nBASE %s\nRANK 1  %s" % [String(definition.name), _compact_stats(definition), String(definition.ranks[0].description)]

func _compact_stats(definition: Dictionary) -> String:
	var base: Dictionary = definition.get("base_stats", {})
	if base.has("normalized_power"):
		return "POWER %.2f  INTERVAL %.2fs" % [float(base.normalized_power), float(base.interval)]
	return "COOLDOWN %.1fs" % float(base.get("cooldown", 0.0))

func _clean_ids(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		var id: String = String(value)
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result

func _doctrine_conflict(doctrine_id: String) -> String:
	var definition: Dictionary = Content.doctrines().get(doctrine_id, {})
	for conflict_value: Variant in definition.get("exclusive_with", []):
		var conflict_id: String = String(conflict_value)
		if selected_doctrines.has(conflict_id):
			return conflict_id.replace("_", " ")
	return ""
