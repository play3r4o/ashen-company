class_name AshenPickupVisual
extends Area2D


func sync_state(world_position: Vector2) -> void:
	position = world_position.round()
	visible = true


func reset_visual() -> void:
	visible = true
	rotation = 0.0
