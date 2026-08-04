class_name AshenCombatEffectVisual
extends Node2D

@onready var ring: Sprite2D = $Ring
@onready var arc: Sprite2D = $Arc
@onready var thrust: Sprite2D = $Thrust


func sync_state(world_position: Vector2, radius: float, tint: Color, opacity: float, kind: String, direction: Vector2) -> void:
	position = world_position.round()
	visible = true
	ring.visible = kind != "arc" and kind != "thrust"
	arc.visible = kind == "arc"
	thrust.visible = kind == "thrust"
	var alpha: float = clampf(opacity, 0.0, 1.0)
	if ring.visible:
		ring.scale = Vector2.ONE * maxf(radius / 32.0, 0.05)
		ring.modulate = Color(tint, alpha)
	if arc.visible:
		arc.scale = Vector2.ONE * maxf(radius / 32.0, 0.05)
		arc.rotation = direction.angle()
		arc.modulate = Color(tint, alpha)
	if thrust.visible:
		var length_scale: float = maxf(radius / 32.0, 0.05)
		thrust.scale = Vector2(length_scale, 0.5)
		thrust.rotation = direction.angle()
		thrust.modulate = Color(tint, alpha)


func reset_visual() -> void:
	visible = true
	rotation = 0.0
	scale = Vector2.ONE
