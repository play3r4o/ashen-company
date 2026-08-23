class_name AshenProjectileVisual
extends Area2D

@export var projectile_id: String = ""
@export var rotates_with_velocity: bool = true
@export var hit_effect_scene: PackedScene

var _last_rotation: float = INF
var _last_tint: Color = Color(-1.0, -1.0, -1.0, -1.0)
@onready var artwork: CanvasItem = AshenSceneBindings.optional(self, &"Artwork") as CanvasItem


func sync_state(world_position: Vector2, velocity: Vector2, tint: Color) -> void:
	# Preserve the precise simulation position. Rounding before applying a 0.6
	# world camera makes fast arrows alternate between pauses and large jumps.
	position = world_position
	if rotates_with_velocity and velocity.length_squared() > 0.01:
		var desired_rotation: float = velocity.angle()
		if not is_equal_approx(desired_rotation, _last_rotation):
			rotation = desired_rotation
			_last_rotation = desired_rotation
	if tint != _last_tint:
		if artwork != null:
			artwork.modulate = tint
		_last_tint = tint


func reset_visual() -> void:
	visible = true
	rotation = 0.0
	_last_rotation = INF
	_last_tint = Color(-1.0, -1.0, -1.0, -1.0)
