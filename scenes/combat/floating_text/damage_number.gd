class_name AshenDamageNumberVisual
extends Node2D

@onready var value_label: Label = $Value


func sync_state(world_position: Vector2, value_text: String, tint: Color, opacity: float) -> void:
	position = world_position.round()
	value_label.text = value_text
	value_label.modulate = Color(tint, clampf(opacity, 0.0, 1.0))
	visible = true


func reset_visual() -> void:
	visible = true
	value_label.text = "0"
