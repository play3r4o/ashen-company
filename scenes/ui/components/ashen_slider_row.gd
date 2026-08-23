class_name AshenSliderRow
extends HBoxContainer

signal value_changed(value: float)

@onready var label: Label = AshenSceneBindings.optional(self, &"Label") as Label
@onready var slider: HSlider = AshenSceneBindings.required(self, &"Slider", "SliderRow") as HSlider

func _ready() -> void:
	if slider != null:
		slider.value_changed.connect(func(value: float) -> void: value_changed.emit(value))

func set_label(value: String) -> void:
	if label != null:
		label.text = value

func set_value(value: float) -> void:
	if slider != null:
		slider.set_value_no_signal(value)

func get_value() -> float:
	return slider.value if slider != null else 0.0
