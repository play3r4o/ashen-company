class_name AshenStructureVisual
extends Node2D

@export var structure_id: String = ""
@export var tier: int = 0

@onready var outline: Sprite2D = $Outline


func set_highlighted(value: bool) -> void:
	if outline != null:
		outline.visible = value


func footprint_polygon() -> PackedVector2Array:
	var shape := get_node_or_null("StaticBody2D/CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()


func interaction_polygon() -> PackedVector2Array:
	var shape := get_node_or_null("InteractionArea/CollisionPolygon2D") as CollisionPolygon2D
	return shape.polygon if shape != null else PackedVector2Array()
