class_name AshenSettingsToggleHQ
extends HBoxContainer

signal value_changed(value: bool)

@onready var label: Label = $Label
@onready var toggle: TextureButton = $Toggle

func _ready() -> void:
	toggle.toggled.connect(_on_toggled)

func _on_toggled(value: bool) -> void:
	value_changed.emit(value)

func set_label(value: String) -> void:
	label.text = value

func set_value(value: bool) -> void:
	toggle.set_pressed_no_signal(value)

func get_value() -> bool:
	return toggle.button_pressed
