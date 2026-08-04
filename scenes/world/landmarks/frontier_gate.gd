class_name AshenFrontierGate
extends Node2D

@onready var gate: Sprite2D = $Gate
@onready var label: Label = $Label
@onready var lock: Node2D = $Lock


func bind_state(world_position: Vector2, unlocked: bool) -> void:
	position = world_position.round()
	label.text = "GLOAMWOOD OPEN" if unlocked else "FRONTIER SEALED  -  BARROW KEY + RESTORATION"
	label.modulate = Color("78aaa2") if unlocked else Color("bca77a")
	lock.visible = not unlocked
	visible = true
