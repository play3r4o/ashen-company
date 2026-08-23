class_name AshenActorPresentationController
extends Node2D

const EnemyState = preload("res://src/state/enemy_state.gd")

const PLAYER_SCENES: Dictionary = {
	"warrior": preload("res://scenes/actors/player/player_visual_warrior.tscn"),
	"hunter": preload("res://scenes/actors/player/player_visual_hunter.tscn"),
	"rogue": preload("res://scenes/actors/player/player_visual_rogue.tscn"),
	"mage": preload("res://scenes/actors/player/player_visual_mage.tscn"),
}
const ENEMY_SCENES: Dictionary = {
	"wolf": preload("res://scenes/actors/enemies/wolf.tscn"),
	"raider": preload("res://scenes/actors/enemies/raider.tscn"),
	"archer": preload("res://scenes/actors/enemies/archer.tscn"),
	"reaver": preload("res://scenes/actors/enemies/reaver.tscn"),
	"blighted": preload("res://scenes/actors/enemies/blighted.tscn"),
	"crow": preload("res://scenes/actors/enemies/crow.tscn"),
	"houndmaster": preload("res://scenes/actors/enemies/houndmaster.tscn"),
	"grave_guard": preload("res://scenes/actors/enemies/grave_guard.tscn"),
	"barrow_knight": preload("res://scenes/actors/enemies/barrow_knight.tscn"),
}

var player_visual: Node2D
var player_class: String = ""
var active_enemies: Dictionary = {}
var enemy_pools: Dictionary = {}
var live_uids_scratch: Dictionary = {}
var stale_uids_scratch: Array = []
var enemy_sync_positions: Dictionary = {}
var enemy_sync_focus_cells: Dictionary = {}
var enemy_sync_health: Dictionary = {}
var enemy_sync_special: Dictionary = {}


func sync_frame(p_player_class: String, p_player_position: Vector2, p_player_direction: Vector2, p_player_moving: bool, p_player_health: float, p_player_max_health: float, enemy_states: Array, focus_position: Vector2, p_visible_world_rect: Rect2 = Rect2(), p_player_attacking: bool = false, p_player_attack_direction: Vector2 = Vector2.ZERO) -> void:
	_sync_player(p_player_class, p_player_position, p_player_direction, p_player_moving, p_player_health, p_player_max_health, p_player_attacking, p_player_attack_direction)
	live_uids_scratch.clear()
	stale_uids_scratch.clear()
	var has_visible_rect: bool = p_visible_world_rect.has_area()
	# Keep a small entry buffer so actors appear just before crossing the screen,
	# without retaining animated scenes for the entire spawn margin.
	var visible_rect: Rect2 = p_visible_world_rect.grow(72.0) if has_visible_rect else Rect2()
	for state: EnemyState in enemy_states:
		var uid: int = state.uid
		var enemy_id: String = state.id
		var enemy_position: Vector2 = state.position
		# Simulation keeps off-screen enemies alive, but their animated scenes do
		# not need to exist until they approach the camera. This is especially
		# important once a wave reaches the upper enemy cap.
		if has_visible_rect and not visible_rect.has_point(enemy_position):
			continue
		live_uids_scratch[uid] = true
		var visual := active_enemies.get(uid) as Node2D
		if visual == null:
			visual = _acquire_enemy(enemy_id)
			if visual == null:
				continue
			active_enemies[uid] = visual
		visual.visible = true
		# At fractional camera zooms, rounding a moving actor in world space creates
		# uneven 0/1-pixel steps on screen. Static art remains pixel-authored, while
		# dynamic actors retain their precise simulation position for smooth motion.
		if visual.position != enemy_position:
			visual.position = enemy_position
		# Use the same absolute ground-anchor depth as camp structures and
		# world dressing. The shared controller will resync this after dynamic
		# world nodes are added, but setting it here prevents a one-frame sort
		# mismatch when an actor first enters the scene.
		visual.z_as_relative = false
		visual.z_index = AshenWorldDepthSortController.depth_for_world_y(enemy_position.y + _depth_anchor_offset_y(visual))
		# Position/depth is still synchronized every frame, but the authored actor
		# only needs a new facing/health binding when it moved enough to cross a
		# direction bucket, the player focus crossed an 8px cell, or health/special
		# state changed. Stationary pooled actors therefore do no redundant scene
		# calls while preserving animation playback and gameplay state.
		# Facing does not need rebinding for every 8px of player travel. A wider
		# 24px bucket preserves responsive direction changes while avoiding a wave
		# of AnimatedSprite/health calls across every visible enemy several times
		# per second.
		var focus_cell := Vector2i(floori(focus_position.x / 24.0), floori(focus_position.y / 24.0))
		var special: bool = state.special or state.kind == "boss"
		var needs_sync: bool = not enemy_sync_positions.has(uid)
		if not needs_sync:
			var last_position: Vector2 = enemy_sync_positions[uid]
			needs_sync = last_position.distance_squared_to(enemy_position) >= 4.0
			needs_sync = needs_sync or enemy_sync_focus_cells.get(uid, Vector2i(-999999, -999999)) != focus_cell
			needs_sync = needs_sync or not is_equal_approx(float(enemy_sync_health.get(uid, -INF)), state.health)
			needs_sync = needs_sync or bool(enemy_sync_special.get(uid, not special)) != special
		if needs_sync:
			visual.call("sync_enemy", focus_position, true, state.health, state.max_health, special)
			enemy_sync_positions[uid] = enemy_position
			enemy_sync_focus_cells[uid] = focus_cell
			enemy_sync_health[uid] = state.health
			enemy_sync_special[uid] = special
	for uid: Variant in active_enemies:
		if live_uids_scratch.has(uid):
			continue
		stale_uids_scratch.append(uid)
	for uid: Variant in stale_uids_scratch:
		var old_visual := active_enemies[uid] as Node2D
		active_enemies.erase(uid)
		enemy_sync_positions.erase(uid)
		enemy_sync_focus_cells.erase(uid)
		enemy_sync_health.erase(uid)
		enemy_sync_special.erase(uid)
		_release_enemy(old_visual)


func _sync_player(p_class: String, p_position: Vector2, p_direction: Vector2, moving: bool, health: float, max_health: float, attacking: bool = false, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if player_visual == null or player_class != p_class:
		if player_visual != null:
			player_visual.queue_free()
		if not PLAYER_SCENES.has(p_class):
			push_error("Missing player visual scene for class '%s'" % p_class)
			player_visual = null
			return
		player_visual = (PLAYER_SCENES[p_class] as PackedScene).instantiate() as Node2D
		player_visual.name = "PlayerVisual"
		add_child(player_visual)
		player_class = p_class
	player_visual.position = p_position
	player_visual.z_as_relative = false
	player_visual.z_index = AshenWorldDepthSortController.depth_for_world_y(p_position.y + _depth_anchor_offset_y(player_visual))
	player_visual.call("sync_player", p_direction, moving, health, max_health, attacking, attack_direction)


func _depth_anchor_offset_y(actor_visual: Node2D) -> float:
	# Actor roots are positioned directly in authored world coordinates. Asking
	# each actor for its local feet offset avoids global transform conversion and
	# a parent-chain walk for every visible actor on every rendered frame.
	if actor_visual != null and actor_visual.has_method("depth_anchor_offset_y"):
		return float(actor_visual.call("depth_anchor_offset_y"))
	return 0.0


func _depth_anchor_y(actor_visual: Node2D, fallback_y: float) -> float:
	# Compatibility entry point retained for scene-contract checks and external
	# tools. It now uses the same cached local offset as the fast frame path.
	return fallback_y + _depth_anchor_offset_y(actor_visual)


func _acquire_enemy(enemy_id: String) -> Node2D:
	var pool: Array = enemy_pools.get(enemy_id, [])
	var visual: Node2D
	if not pool.is_empty():
		visual = pool.pop_back() as Node2D
		enemy_pools[enemy_id] = pool
	else:
		if not ENEMY_SCENES.has(enemy_id):
			push_error("Missing enemy visual scene for '%s'" % enemy_id)
			return null
		visual = (ENEMY_SCENES[enemy_id] as PackedScene).instantiate() as Node2D
		add_child(visual)
	visual.set_meta("enemy_id", enemy_id)
	visual.call("reset_visual")
	return visual


func _release_enemy(visual: Node2D) -> void:
	visual.visible = false
	var enemy_id: String = String(visual.get_meta("enemy_id", ""))
	var pool: Array = enemy_pools.get(enemy_id, [])
	pool.append(visual)
	enemy_pools[enemy_id] = pool
