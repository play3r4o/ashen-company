class_name AshenExplorationMarker
extends Node2D

@onready var pulse: Node2D = $Pulse
@onready var marker: Sprite2D = $Pulse/Marker
@onready var label: Label = $Label


func sync_state(world_position: Vector2, display_name: String, kind: String, elapsed: float) -> void:
	position = world_position.round()
	label.text = display_name
	var tint := Color("78aaa2") if kind in ["shrine", "barrow"] else Color("d38a36")
	var phase: float = (sin(elapsed * 3.0 + float(display_name.hash() % 11)) + 1.0) * 0.5
	pulse.scale = Vector2.ONE * (1.0 + phase * 0.14)
	marker.modulate = Color(tint, 0.92)
	visible = true


func reset_visual() -> void:
	visible = true
	pulse.scale = Vector2.ONE
