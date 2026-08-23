class_name AshenCombatEffect
extends Node2D

@export var effect_id: String = ""
@export var reference_radius: float = 128.0
@export var rotates_with_direction: bool = false

@onready var artwork: Sprite2D = AshenSceneBindings.optional(self, &"Artwork") as Sprite2D
var _authored_artwork_scale: Vector2 = Vector2.ONE
var _authored_artwork_modulate: Color = Color.WHITE


func sync_state(world_position: Vector2, radius: float, opacity: float, direction: Vector2) -> void:
	position = world_position.round()
	visible = true
	var authored_scale := maxf(radius / maxf(reference_radius, 1.0), 0.05)
	if artwork != null:
		artwork.scale = _authored_artwork_scale * authored_scale
		artwork.modulate = Color(_authored_artwork_modulate, _authored_artwork_modulate.a * clampf(opacity, 0.0, 1.0))
	rotation = direction.angle() if rotates_with_direction and direction.length_squared() > 0.01 else 0.0


func reset_visual() -> void:
	visible = true
	rotation = 0.0
	if artwork != null:
		artwork.scale = _authored_artwork_scale
		artwork.modulate = _authored_artwork_modulate


func _ready() -> void:
	if artwork != null:
		_authored_artwork_scale = artwork.scale
		_authored_artwork_modulate = artwork.modulate
