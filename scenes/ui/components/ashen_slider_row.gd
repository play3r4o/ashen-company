class_name AshenSliderRow
extends HBoxContainer

signal value_changed(value: float)

@onready var label: Label = $Label
@onready var slider: HSlider = $Slider

func _ready() -> void:
	slider.value_changed.connect(func(value: float) -> void: value_changed.emit(value))

func set_label(value: String) -> void:
	label.text = value

func set_value(value: float) -> void:
	slider.set_value_no_signal(value)

func get_value() -> float:
	return slider.value
