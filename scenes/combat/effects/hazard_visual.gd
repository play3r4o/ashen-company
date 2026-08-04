class_name AshenHazardVisual
extends Area2D

@onready var artwork: Sprite2D = $Artwork


func sync_state(world_position: Vector2, radius: float, triggered: bool) -> void:
	position = world_position.round()
	var authored_radius: float = 40.0
	scale = Vector2.ONE * maxf(radius / authored_radius, 0.05)
	artwork.modulate = Color(1.0, 0.82, 0.42, 0.92 if triggered else 0.56)
	visible = true


func reset_visual() -> void:
	visible = true
	scale = Vector2.ONE
