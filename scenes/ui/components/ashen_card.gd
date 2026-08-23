class_name AshenCard
extends PanelContainer

@export var normal_style: StyleBox
@export var selected_style: StyleBox
@export var selected: bool = false:
	set(value):
		selected = value
		if is_inside_tree():
			_apply_card_style()

@onready var icon: TextureRect = AshenSceneBindings.optional(self, &"Icon") as TextureRect
@onready var title: Label = AshenSceneBindings.optional(self, &"Title") as Label
@onready var description: Label = AshenSceneBindings.optional(self, &"Description") as Label
@onready var stats: Label = AshenSceneBindings.optional(self, &"Stats") as Label

func _ready() -> void:
	_apply_card_style()

func set_card_title(value: String) -> void:
	if title != null:
		title.text = value

func set_card_description(value: String) -> void:
	if description != null:
		description.text = value

func set_card_stats(value: String) -> void:
	if stats != null:
		stats.text = value

func _apply_card_style() -> void:
	add_theme_stylebox_override("panel", selected_style if selected else normal_style)
