class_name AshenArsenalOptionCard
extends Button

@onready var title_label: Label = $Title
@onready var stats_label: Label = $Stats

var content_id: String = ""

func configure(id_value: String, title: String, stats: String, detail: String, selected: bool) -> void:
	content_id = id_value
	title_label.text = title.to_upper()
	stats_label.text = stats
	tooltip_text = detail
	button_pressed = selected

func set_conflict(reason: String) -> void:
	disabled = not reason.is_empty() and not button_pressed
	if not reason.is_empty():
		tooltip_text = reason
