class_name AshenFrontierGate
extends Node2D

@onready var gate: Sprite2D = AshenSceneBindings.optional(self, &"Gate") as Sprite2D
@onready var label: Label = AshenSceneBindings.optional(self, &"Label") as Label
@onready var lock: Node2D = AshenSceneBindings.optional(self, &"Lock") as Node2D


func bind_state(world_position: Vector2, unlocked: bool) -> void:
	position = world_position.round()
	if label != null:
		label.text = "GLOAMWOOD OPEN" if unlocked else "FRONTIER SEALED  -  BARROW KEY + RESTORATION"
		label.modulate = Color("78aaa2") if unlocked else Color("bca77a")
	if lock != null:
		lock.visible = not unlocked
	visible = true
