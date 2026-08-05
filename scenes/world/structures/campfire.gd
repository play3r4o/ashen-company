@tool
class_name AshenCampfire
extends Node2D

@onready var flame: AnimatedSprite2D = $Flame
@onready var smoke: AnimatedSprite2D = $Smoke
@onready var outline: Sprite2D = $Outline


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
	return ($StaticBody2D/CollisionPolygon2D as CollisionPolygon2D).polygon


func interaction_polygon() -> PackedVector2Array:
	return ($InteractionArea/CollisionPolygon2D as CollisionPolygon2D).polygon
