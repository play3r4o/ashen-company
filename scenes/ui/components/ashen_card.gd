class_name AshenCard
extends PanelContainer

@export var normal_style: StyleBox
@export var selected_style: StyleBox
@export var selected: bool = false:
	set(value):
		selected = value
		if is_inside_tree():
			_apply_card_style()

@onready var icon: TextureRect = $Margin/Body/Icon
@onready var title: Label = $Margin/Body/Text/Title
@onready var description: Label = $Margin/Body/Text/Description
@onready var stats: Label = $Margin/Body/Text/Stats

func _ready() -> void:
	_apply_card_style()

func set_card_title(value: String) -> void:
	title.text = value

func set_card_description(value: String) -> void:
	description.text = value

func set_card_stats(value: String) -> void:
	stats.text = value

func _apply_card_style() -> void:
	add_theme_stylebox_override("panel", selected_style if selected else normal_style)
