class_name AshenExplorationMarker
extends Node2D

@onready var pulse: Node2D = AshenSceneBindings.optional(self, &"Pulse") as Node2D
@onready var marker: Sprite2D = AshenSceneBindings.optional(self, &"Marker") as Sprite2D
@onready var label: Label = AshenSceneBindings.optional(self, &"Label") as Label
var _authored_pulse_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if pulse != null:
		_authored_pulse_scale = pulse.scale


func sync_state(world_position: Vector2, display_name: String, kind: String, elapsed: float) -> void:
	position = world_position.round()
	z_as_relative = false
	z_index = AshenWorldDepthSortController.depth_for_world_y(position.y)
	if label != null:
		label.text = display_name
	var tint := Color("78aaa2") if kind in ["shrine", "barrow"] else Color("d38a36")
	var phase: float = (sin(elapsed * 3.0 + float(display_name.hash() % 11)) + 1.0) * 0.5
	if pulse != null:
		pulse.scale = _authored_pulse_scale * (1.0 + phase * 0.14)
	if marker != null:
		marker.modulate = Color(tint, 0.92)
	visible = true


func reset_visual() -> void:
	visible = true
	if pulse != null:
		pulse.scale = _authored_pulse_scale
