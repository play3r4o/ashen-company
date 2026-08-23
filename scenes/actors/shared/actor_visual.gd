class_name AshenActorVisual
extends Node2D

@export var actor_id: String = ""
@export var directional: bool = false
@export var body_ground_offset: Vector2 = Vector2(0, -25)
## When enabled, player attack state selects the authored *_attack animation
## instead of the idle/walk strip.  The scene owns the animation art; gameplay
## only supplies the current attack direction and a short active window.
@export var attack_animation_enabled: bool = false
## Some source sheets provide a right-facing strip but no separate left strip.
## Mirroring is opt-in per authored actor scene so other actors are unchanged.
@export var mirror_left_direction: bool = false
## Use the authored opaque pixels to find the feet line instead of treating
## transparent padding in a large sprite sheet as part of the actor. This is
## especially important for the Tiny Swords monk frames, whose 192px canvas
## contains a small character in the middle. The value remains editable per
## actor scene through `depth_anchor_padding`.
@export var depth_anchor_from_alpha: bool = true
@export var depth_anchor_padding: float = 0.0
## The authored DepthAnchor child is the primary depth line.  The cached
## visual/collision calculation below remains a safe fallback for legacy actor
## scenes that do not yet contain that marker.
@export var depth_anchor_from_collision: bool = true

@onready var body_visual: AnimatedSprite2D = AshenSceneBindings.required(self, &"BodyVisual", "ActorVisual") as AnimatedSprite2D
@onready var health_bar: ProgressBar = AshenSceneBindings.optional(self, &"HealthBarWorld") as ProgressBar
@onready var depth_anchor: Marker2D = AshenSceneBindings.optional(self, &"DepthAnchor") as Marker2D
var last_health: float = -INF
var last_max_health: float = -INF
var last_health_bar_visible: bool = false
var _depth_anchor_offset_y: float = 0.0
static var _visible_bottom_cache: Dictionary = {}


func _ready() -> void:
	# BodyVisual.position is authored in the scene.  Do not overwrite it here:
	# moving the sprite in Godot must be the exact runtime result.
	_refresh_depth_anchor()


func _refresh_depth_anchor() -> void:
	"""Cache the visible ground line used by the shared world depth sorter.

	New actor scenes use their editable DepthAnchor marker directly.  This cache
	keeps older actor scenes safe if they are opened before the marker is added.
	The collider is only consulted when no frame can provide an alpha anchor.
	"""
	if body_visual == null or body_visual.sprite_frames == null or body_visual.animation.is_empty():
		_depth_anchor_offset_y = 0.0
		return
	var max_frame_bottom: float = -INF
	for animation_name: StringName in body_visual.sprite_frames.get_animation_names():
		var frame_count: int = body_visual.sprite_frames.get_frame_count(animation_name)
		for frame_index: int in range(frame_count):
			var frame_texture: Texture2D = body_visual.sprite_frames.get_frame_texture(animation_name, frame_index)
			if frame_texture == null:
				continue
			var frame_size: Vector2 = frame_texture.get_size()
			var visible_bottom: float = frame_size.y
			if depth_anchor_from_alpha:
				visible_bottom = _visible_bottom(frame_texture)
			var frame_bottom: float = visible_bottom - (frame_size.y * 0.5 if body_visual.centered else 0.0)
			frame_bottom += body_visual.offset.y
			frame_bottom *= absf(body_visual.scale.y)
			max_frame_bottom = maxf(max_frame_bottom, frame_bottom)
	if is_inf(max_frame_bottom):
		max_frame_bottom = body_visual.sprite_frames.get_frame_texture(body_visual.animation, body_visual.frame).get_size().y * (0.5 if body_visual.centered else 1.0)
		max_frame_bottom += body_visual.offset.y
		max_frame_bottom *= absf(body_visual.scale.y)
	var has_visual_anchor: bool = not is_inf(max_frame_bottom)
	_depth_anchor_offset_y = body_visual.position.y + max_frame_bottom + depth_anchor_padding
	if depth_anchor_from_collision and not has_visual_anchor:
		var body := AshenSceneBindings.optional(self, &"Body")
		var collision_shape := AshenSceneBindings.optional(body, &"CollisionShape2D") as CollisionShape2D
		if collision_shape != null and collision_shape.shape != null:
			# Shape.get_rect() is in the CollisionShape2D's local coordinates.
			# Include the node position, but leave the gameplay shape itself
			# untouched.  This is an authored physical anchor, not a guessed
			# texture offset.
			var collision_rect := collision_shape.shape.get_rect()
			var collision_bottom: float = collision_shape.position.y + collision_rect.end.y
			_depth_anchor_offset_y = collision_bottom


func _visible_bottom(texture: Texture2D) -> float:
	var key: String = str(texture.get_rid())
	if _visible_bottom_cache.has(key):
		return float(_visible_bottom_cache[key])
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return texture.get_size().y
	var bottom: int = -1
	for y: int in range(image.get_height() - 1, -1, -1):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.01:
				bottom = y
				break
		if bottom >= 0:
			break
	if bottom < 0:
		bottom = image.get_height() - 1
	var result: float = float(bottom + 1)
	_visible_bottom_cache[key] = result
	return result


func depth_anchor_world_y() -> float:
	"""Return the world-space feet line used for north/south ordering."""
	if is_instance_valid(depth_anchor):
		return depth_anchor.global_position.y
	return global_position.y + _depth_anchor_offset_y


func depth_anchor_offset_y() -> float:
	"""Return the authored feet offset without traversing the live scene tree."""
	if is_instance_valid(depth_anchor):
		return depth_anchor.position.y
	return _depth_anchor_offset_y


func sync_player(direction: Vector2, moving: bool, health: float, max_health: float, attacking: bool = false, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if body_visual == null:
		_sync_health(health, max_health, false)
		return
	var facing_direction: Vector2 = attack_direction if attacking and attack_direction.length_squared() > 0.001 else direction
	var facing := "down"
	if absf(facing_direction.x) > absf(facing_direction.y):
		facing = "right" if facing_direction.x >= 0.0 else "left"
	elif facing_direction.y < 0.0:
		facing = "up"
	var action := "attack" if attacking and attack_animation_enabled else ("walk" if moving else "idle")
	var should_flip: bool = mirror_left_direction and facing == "left"
	if body_visual.flip_h != should_flip:
		body_visual.flip_h = should_flip
	var animation := "%s_%s" % [facing, action]
	if not body_visual.sprite_frames.has_animation(animation):
		animation = "%s_%s" % [facing, "walk" if moving else "idle"]
	if body_visual.sprite_frames.has_animation(animation) and body_visual.animation != animation:
		body_visual.play(animation)
	_sync_health(health, max_health, false)


func sync_enemy(focus_position: Vector2, moving: bool, health: float, max_health: float, special: bool) -> void:
	if body_visual == null:
		_sync_health(health, max_health, special)
		return
	var direction := focus_position - global_position
	var facing := "down"
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x >= 0.0 else "left"
	elif direction.y < 0.0:
		facing = "up"
	var should_flip: bool = facing == "left"
	if body_visual.flip_h != should_flip:
		body_visual.flip_h = should_flip
	var animation := "%s_%s" % [facing, "walk" if moving else "idle"]
	if body_visual.sprite_frames.has_animation(animation) and body_visual.animation != animation:
		body_visual.play(animation)
	_sync_health(health, max_health, special)


func _sync_health(health: float, max_health: float, visible_bar: bool) -> void:
	if health_bar == null:
		return
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
	if body_visual != null:
		body_visual.flip_h = false
	if health_bar != null:
		health_bar.visible = false
	last_health = -INF
	last_max_health = -INF
	last_health_bar_visible = false
