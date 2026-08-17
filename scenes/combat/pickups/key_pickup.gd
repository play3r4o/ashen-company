class_name AshenKeyPickupVisual
extends Area2D

@onready var artwork: Sprite2D = $Artwork

func sync_state(world_position: Vector2) -> void:
	position = world_position.round()
	visible = true

func reset_visual() -> void:
	visible = true
	rotation = 0.0
	if artwork != null:
		artwork.position = Vector2.ZERO
