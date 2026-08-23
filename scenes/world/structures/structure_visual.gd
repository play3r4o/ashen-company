class_name AshenStructureVisual
extends Node2D

@export var structure_id: String = ""
@export var tier: int = 0

@onready var outline: Sprite2D = AshenSceneBindings.optional(self, &"Outline") as Sprite2D


func set_highlighted(value: bool) -> void:
	if outline != null:
		outline.visible = value


func footprint_polygon() -> PackedVector2Array:
	var body := AshenSceneBindings.optional(self, &"StaticBody2D")
	var shape := AshenSceneBindings.optional(body, &"CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()


func interaction_polygon() -> PackedVector2Array:
	var area := AshenSceneBindings.optional(self, &"InteractionArea")
	var shape := AshenSceneBindings.optional(area, &"CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()
