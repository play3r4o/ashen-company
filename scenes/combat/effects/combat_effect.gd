class_name AshenCombatEffect
extends Node2D

@export var effect_id: String = ""
@export var reference_radius: float = 128.0
@export var rotates_with_direction: bool = false

@onready var artwork: Sprite2D = $Artwork


func sync_state(world_position: Vector2, radius: float, opacity: float, direction: Vector2) -> void:
	position = world_position.round()
	visible = true
	var authored_scale := maxf(radius / maxf(reference_radius, 1.0), 0.05)
	artwork.scale = Vector2.ONE * authored_scale
	artwork.modulate = Color(1.0, 1.0, 1.0, clampf(opacity, 0.0, 1.0))
	rotation = direction.angle() if rotates_with_direction and direction.length_squared() > 0.01 else 0.0


func reset_visual() -> void:
	visible = true
	rotation = 0.0
	artwork.scale = Vector2.ONE
	artwork.modulate = Color.WHITE
