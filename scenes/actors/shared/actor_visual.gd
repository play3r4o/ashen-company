class_name AshenActorVisual
extends Node2D

@export var actor_id: String = ""
@export var directional: bool = false
@export var body_ground_offset: Vector2 = Vector2(0, -25)

@onready var body_visual: AnimatedSprite2D = $BodyVisual
@onready var health_bar: ProgressBar = $HealthBarSocket/HealthBarWorld
var last_health: float = -INF
var last_max_health: float = -INF
var last_health_bar_visible: bool = false


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
	var direction := focus_position - global_position
	var facing := "down"
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x >= 0.0 else "left"
	elif direction.y < 0.0:
		facing = "up"
	body_visual.flip_h = facing == "left"
	var animation := "%s_%s" % [facing, "walk" if moving else "idle"]
	if body_visual.sprite_frames.has_animation(animation) and body_visual.animation != animation:
		body_visual.play(animation)
	_sync_health(health, max_health, special)


func _sync_health(health: float, max_health: float, visible_bar: bool) -> void:
	if visible_bar == last_health_bar_visible and not visible_bar:
		return
	if visible_bar == last_health_bar_visible and is_equal_approx(health, last_health) and is_equal_approx(max_health, last_max_health):
		return
	last_health = health
	last_max_health = max_health
	last_health_bar_visible = visible_bar
	health_bar.visible = visible_bar
	health_bar.max_value = maxf(1.0, max_health)
	health_bar.value = clampf(health, 0.0, health_bar.max_value)


func reset_visual() -> void:
	visible = true
	body_visual.flip_h = false
	health_bar.visible = false
	last_health = -INF
	last_max_health = -INF
	last_health_bar_visible = false
