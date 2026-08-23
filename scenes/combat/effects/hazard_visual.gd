class_name AshenHazardVisual
extends Area2D

@onready var artwork: Sprite2D = AshenSceneBindings.optional(self, &"Artwork") as Sprite2D
var _authored_scale: Vector2 = Vector2.ONE
var _authored_modulate: Color = Color.WHITE


func _ready() -> void:
	_authored_scale = scale
	if artwork != null:
		_authored_modulate = artwork.modulate


func sync_state(world_position: Vector2, radius: float, triggered: bool) -> void:
	position = world_position.round()
	var authored_radius: float = 40.0
	scale = _authored_scale * maxf(radius / authored_radius, 0.05)
	if artwork != null:
		var state_tint := Color(1.0, 0.82, 0.42, 0.92 if triggered else 0.56)
		artwork.modulate = _authored_modulate * state_tint
	visible = true


func reset_visual() -> void:
	visible = true
	scale = _authored_scale
