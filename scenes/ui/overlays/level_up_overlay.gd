class_name AshenLevelUpOverlay
extends Control

signal choice_selected(choice: Dictionary)
signal reroll_requested

@onready var title_label: Label = AshenSceneBindings.optional(self, &"TitleLabel") as Label
@onready var level_label: Label = AshenSceneBindings.optional(self, &"LevelLabel") as Label
@onready var reroll_button: Button = AshenSceneBindings.optional(self, &"RerollButton") as Button

var _choices: Array[Dictionary] = []


func _ready() -> void:
	for index: int in range(4):
		var button := AshenSceneBindings.optional(self, StringName("Choice%d" % (index + 1))) as Button
		if button != null:
			button.pressed.connect(_on_choice_pressed.bind(index))
	if reroll_button != null:
		reroll_button.pressed.connect(func() -> void: reroll_requested.emit())


func bind_choices(level: int, choices: Array[Dictionary], rerolls: int) -> void:
	_choices = choices.duplicate(true)
	if level_label != null:
		level_label.text = "LEVEL %d" % level
	if reroll_button != null:
		reroll_button.text = "REROLL - %d REMAINING" % rerolls
		reroll_button.disabled = rerolls <= 0
	for index: int in range(4):
		var button := AshenSceneBindings.optional(self, StringName("Choice%d" % (index + 1))) as Button
		if button == null:
			continue
		button.visible = index < _choices.size()
		if not button.visible:
			continue
		var choice: Dictionary = _choices[index]
		var description := AshenSceneBindings.optional(button, &"CardDescription") as Label
		var stats := AshenSceneBindings.optional(button, &"CardStats") as Label
		if description != null:
			description.text = "%s\n%s" % [String(choice.get("name", "UNKNOWN")), String(choice.get("description", ""))]
		if stats != null:
			stats.text = String(choice.get("display_stats", ""))


func _on_choice_pressed(index: int) -> void:
	if index >= 0 and index < _choices.size():
		choice_selected.emit(_choices[index])
