class_name AshenToggleRow
extends HBoxContainer

signal value_changed(value: bool)

@onready var label: Label = AshenSceneBindings.optional(self, &"Label") as Label
@onready var toggle: TextureButton = AshenSceneBindings.required(self, &"Toggle", "ToggleRow") as TextureButton

func _ready() -> void:
	if toggle != null:
		toggle.toggled.connect(_on_toggled)

func _on_toggled(value: bool) -> void:
	value_changed.emit(value)

func set_label(value: String) -> void:
	if label != null:
		label.text = value

func set_value(value: bool) -> void:
	if toggle != null:
		toggle.set_pressed_no_signal(value)

func get_value() -> bool:
	return toggle.button_pressed if toggle != null else false
