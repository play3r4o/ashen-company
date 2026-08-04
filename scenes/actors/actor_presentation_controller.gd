class_name AshenActorPresentationController
extends Node2D

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


func sync_frame(p_player_class: String, p_player_position: Vector2, p_player_direction: Vector2, p_player_moving: bool, p_player_health: float, p_player_max_health: float, enemy_states: Array, focus_position: Vector2) -> void:
	_sync_player(p_player_class, p_player_position, p_player_direction, p_player_moving, p_player_health, p_player_max_health)
	var live_uids: Dictionary = {}
	for state: Variant in enemy_states:
		var uid: int = int(state.get("uid"))
		var enemy_id: String = String(state.get("id"))
		live_uids[uid] = true
		var visual := active_enemies.get(uid) as Node2D
		if visual == null:
			visual = _acquire_enemy(enemy_id)
			if visual == null:
				continue
			active_enemies[uid] = visual
		visual.visible = true
		visual.position = Vector2(state.get("position")).round()
		visual.z_index = roundi(visual.position.y)
		visual.call("sync_enemy", focus_position, true, float(state.get("health")), float(state.get("max_health")), bool(state.get("special")) or String(state.get("kind")) == "boss")
	for uid: Variant in active_enemies.keys():
		if live_uids.has(uid):
			continue
		var old_visual := active_enemies[uid] as Node2D
		active_enemies.erase(uid)
		_release_enemy(old_visual)


func _sync_player(p_class: String, p_position: Vector2, p_direction: Vector2, moving: bool, health: float, max_health: float) -> void:
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
	player_visual.position = p_position.round()
	player_visual.z_index = roundi(player_visual.position.y)
	player_visual.call("sync_player", p_direction, moving, health, max_health)


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
