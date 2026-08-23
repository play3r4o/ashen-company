@tool
class_name AshenCampfire
extends Node2D

@onready var flame: AnimatedSprite2D = AshenSceneBindings.optional(self, &"Flame") as AnimatedSprite2D
@onready var smoke: AnimatedSprite2D = AshenSceneBindings.optional(self, &"Smoke") as AnimatedSprite2D
@onready var outline: Sprite2D = AshenSceneBindings.optional(self, &"Outline") as Sprite2D


func _ready() -> void:
	if flame != null:
		flame.play("burn")
	if smoke != null:
		smoke.play("drift")
	set_highlighted(false)


func set_highlighted(value: bool) -> void:
	if outline != null:
		outline.visible = value


func footprint_polygon() -> PackedVector2Array:
	var shape := AshenSceneBindings.optional(self, &"CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()


func interaction_polygon() -> PackedVector2Array:
	var area := AshenSceneBindings.optional(self, &"InteractionArea")
	var shape := AshenSceneBindings.optional(area, &"CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()
