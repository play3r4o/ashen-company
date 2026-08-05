class_name AshenTrapVisual
extends Area2D

@export var trap_kind: String = "caltrops"


func sync_state(world_position: Vector2, radius: float) -> void:
	position = world_position.round()
	scale = Vector2.ONE * maxf(radius / 30.0, 0.05)
	visible = true


func reset_visual() -> void:
	visible = true
	scale = Vector2.ONE
