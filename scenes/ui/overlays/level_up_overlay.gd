class_name AshenLevelUpOverlay
extends Control

signal choice_selected(choice: Dictionary)
signal reroll_requested

@onready var title_label: Label = %TitleLabel
@onready var level_label: Label = %LevelLabel
@onready var reroll_button: Button = %RerollButton

var _choices: Array[Dictionary] = []


func _ready() -> void:
	for index: int in range(4):
		var button := get_node("SafeArea/Panel/Margin/Content/Choices/Choice%d" % (index + 1)) as Button
		button.pressed.connect(_on_choice_pressed.bind(index))
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())


func bind_choices(level: int, choices: Array[Dictionary], rerolls: int) -> void:
	_choices = choices.duplicate(true)
	level_label.text = "LEVEL %d" % level
	reroll_button.text = "REROLL - %d REMAINING" % rerolls
	reroll_button.disabled = rerolls <= 0
	for index: int in range(4):
		var button := get_node("SafeArea/Panel/Margin/Content/Choices/Choice%d" % (index + 1)) as Button
		button.visible = index < _choices.size()
		if not button.visible:
			continue
		var choice: Dictionary = _choices[index]
		(button.get_node("Content/CardDescription") as Label).text = "%s\n%s" % [String(choice.get("name", "UNKNOWN")), String(choice.get("description", ""))]
		(button.get_node("Content/CardStats") as Label).text = String(choice.get("display_stats", ""))


func _on_choice_pressed(index: int) -> void:
	if index >= 0 and index < _choices.size():
		choice_selected.emit(_choices[index])
