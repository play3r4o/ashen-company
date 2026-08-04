class_name AshenActorVisual
extends Node2D

@export var actor_id: String = ""
@export var directional: bool = false
@export var body_ground_offset: Vector2 = Vector2(0, -25)

@onready var body_visual: AnimatedSprite2D = $BodyVisual
@onready var health_bar: ProgressBar = $HealthBarWorld


func _ready() -> void:
	body_visual.position = body_ground_offset


func sync_player(direction: Vector2, moving: bool, health: float, max_health: float) -> void:
	var facing := "down"
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x >= 0.0 else "left"
	elif direction.y < 0.0:
		facing = "up"
	var animation := "%s_%s" % [facing, "walk" if moving else "idle"]
	if body_visual.sprite_frames.has_animation(animation) and body_visual.animation != animation:
		body_visual.play(animation)
	_sync_health(health, max_health, false)


func sync_enemy(focus_position: Vector2, moving: bool, health: float, max_health: float, special: bool) -> void:
	body_visual.flip_h = focus_position.x < global_position.x
	var animation := "walk" if moving else "idle"
	if body_visual.sprite_frames.has_animation(animation) and body_visual.animation != animation:
		body_visual.play(animation)
	_sync_health(health, max_health, special)


func _sync_health(health: float, max_health: float, visible_bar: bool) -> void:
	health_bar.visible = visible_bar
	health_bar.max_value = maxf(1.0, max_health)
	health_bar.value = clampf(health, 0.0, health_bar.max_value)


func reset_visual() -> void:
	visible = true
	body_visual.flip_h = false
	health_bar.visible = false
