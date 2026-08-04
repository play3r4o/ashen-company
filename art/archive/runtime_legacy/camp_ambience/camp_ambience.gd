class_name AshenCampAmbience
extends Node2D

@onready var lanterns: Node2D = $Lanterns
@onready var gate_prompt: Node2D = $GatePrompt


func sync_frame(animation_time: float, _density: float, _refuge_bounds: Rect2, _fire_position: Vector2, hall_position: Vector2, _smith_position: Vector2, _smith_visible: bool, _brazier_position: Vector2, _brazier_visible: bool, gate_position: Vector2) -> void:
	visible = true
	var lantern_index: int = 0
	for lantern_side: float in [-1.0, 1.0]:
		var lantern := lanterns.get_child(lantern_index) as Sprite2D
		lantern.position = (hall_position + Vector2(lantern_side * 30.0, -44.0)).round()
		lantern.modulate.a = 0.46 + (sin(animation_time * 4.0 + lantern_side * 1.7) + 1.0) * 0.10
		lantern_index += 1
	gate_prompt.position = gate_position.round()
	gate_prompt.modulate.a = 0.82
