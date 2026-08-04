class_name AshenProjectileVisual
extends Area2D

@export var projectile_id: String = ""
@export var rotates_with_velocity: bool = true


func sync_state(world_position: Vector2, velocity: Vector2, tint: Color) -> void:
	position = world_position.round()
	if rotates_with_velocity and velocity.length_squared() > 0.01:
		rotation = velocity.angle()
	$Artwork.modulate = tint


func reset_visual() -> void:
	visible = true
	rotation = 0.0
