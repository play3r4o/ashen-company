class_name AshenCombatPresentationController
extends Node2D

const PROJECTILE_SCENES: Dictionary = {
	"bow": preload("res://scenes/combat/projectiles/arrow.tscn"),
	"crossbow": preload("res://scenes/combat/projectiles/crossbow_bolt.tscn"),
	"sling": preload("res://scenes/combat/projectiles/sling_stone.tscn"),
	"throwing_knives": preload("res://scenes/combat/projectiles/throwing_knife.tscn"),
	"daggers": preload("res://scenes/combat/projectiles/dagger.tscn"),
	"chakrams": preload("res://scenes/combat/projectiles/chakram.tscn"),
	"staff": preload("res://scenes/combat/projectiles/staff_bolt.tscn"),
	"wand": preload("res://scenes/combat/projectiles/wand_bolt.tscn"),
	"runic_orb": preload("res://scenes/combat/projectiles/runic_orb.tscn"),
	"witchfire": preload("res://scenes/combat/projectiles/witchfire.tscn"),
	"enemy_arrow": preload("res://scenes/combat/projectiles/enemy_arrow.tscn"),
}
const PickupScene = preload("res://scenes/combat/pickups/experience_pickup.tscn")
const DamageNumberScene = preload("res://scenes/combat/floating_text/damage_number.tscn")
const HazardScene = preload("res://scenes/combat/effects/hazard_warning.tscn")
const EFFECT_SCENES: Dictionary = {
	"impact": preload("res://scenes/combat/effects/impact.tscn"),
	"guard": preload("res://scenes/combat/effects/guard.tscn"),
	"rain": preload("res://scenes/combat/effects/rain.tscn"),
	"mark": preload("res://scenes/combat/effects/mark.tscn"),
	"dash": preload("res://scenes/combat/effects/dash.tscn"),
	"smoke": preload("res://scenes/combat/effects/smoke.tscn"),
	"poison": preload("res://scenes/combat/effects/poison.tscn"),
	"nova": preload("res://scenes/combat/effects/nova.tscn"),
	"frost": preload("res://scenes/combat/effects/frost.tscn"),
	"lightning": preload("res://scenes/combat/effects/lightning.tscn"),
	"thrust": preload("res://scenes/combat/effects/thrust.tscn"),
	"arc": preload("res://scenes/combat/effects/arc.tscn"),
	"arcane": preload("res://scenes/combat/effects/arcane.tscn"),
	"ring": preload("res://scenes/combat/effects/ring.tscn"),
	"spark": preload("res://scenes/combat/effects/spark.tscn"),
	"burst": preload("res://scenes/combat/effects/burst.tscn"),
}
const TRAP_SCENES: Dictionary = {
	"caltrops": preload("res://scenes/combat/attacks/caltrops.tscn"),
	"ember": preload("res://scenes/combat/attacks/ember_zone.tscn"),
}

var active_projectiles: Dictionary = {}
var projectile_pools: Dictionary = {}
var active_pickups: Dictionary = {}
var active_damage_numbers: Dictionary = {}
var active_effects: Dictionary = {}
var active_hazards: Dictionary = {}
var active_traps: Dictionary = {}
var shared_pools: Dictionary = {}


func sync_projectiles(states: Array) -> void:
	var live_ids: Dictionary = {}
	for state: Variant in states:
		var state_id: int = state.get_instance_id()
		var projectile_id: String = String(state.get("kind"))
		live_ids[state_id] = true
		var visual := active_projectiles.get(state_id) as Area2D
		if visual == null:
			visual = _acquire(projectile_id)
			if visual == null:
				continue
			active_projectiles[state_id] = visual
		visual.call("sync_state", Vector2(state.get("position")), Vector2(state.get("velocity")), Color(state.get("color")))
	for state_id: Variant in active_projectiles.keys():
		if live_ids.has(state_id):
			continue
		var visual := active_projectiles[state_id] as Area2D
		active_projectiles.erase(state_id)
		_release(visual)


func sync_frame(pickup_states: Array, damage_states: Array, effect_states: Array, hazard_states: Array, trap_states: Array) -> void:
	_sync_shared(pickup_states, active_pickups, "pickup", PickupScene, func(visual: Node, state: Variant) -> void:
		visual.call("sync_state", Vector2(state.get("position"))))
	_sync_shared(damage_states, active_damage_numbers, "damage_number", DamageNumberScene, func(visual: Node, state: Variant) -> void:
		visual.call("sync_state", Vector2(state.get("position")), String(state.get("text")), Color(state.get("color")), float(state.get("life")) / 0.7))
	_sync_effects(effect_states)
	_sync_shared(hazard_states, active_hazards, "hazard", HazardScene, func(visual: Node, state: Variant) -> void:
		visual.call("sync_state", Vector2(state.get("position")), float(state.get("radius")), bool(state.get("triggered"))))
	_sync_traps(trap_states)


func _sync_effects(states: Array) -> void:
	var live_ids: Dictionary = {}
	for state: Variant in states:
		var state_id: int = state.get_instance_id()
		var effect_id: String = String(state.get("kind"))
		live_ids[state_id] = true
		var visual := active_effects.get(state_id) as Node2D
		if visual == null:
			if not EFFECT_SCENES.has(effect_id):
				push_error("Missing authored effect scene for '%s'" % effect_id)
				continue
			visual = _acquire_shared("effect:%s" % effect_id, EFFECT_SCENES[effect_id] as PackedScene) as Node2D
			visual.set_meta("pool_id", "effect:%s" % effect_id)
			active_effects[state_id] = visual
		visual.call("sync_state", Vector2(state.get("position")), float(state.get("radius")), float(state.get("life")) / 0.25, Vector2(state.get("direction")))
	for state_id: Variant in active_effects.keys():
		if live_ids.has(state_id):
			continue
		var visual := active_effects[state_id] as Node2D
		active_effects.erase(state_id)
		_release_shared(String(visual.get_meta("pool_id", "")), visual)


func _sync_shared(states: Array, active: Dictionary, pool_id: String, scene: PackedScene, binder: Callable) -> void:
	var live_ids: Dictionary = {}
	for state: Variant in states:
		var state_id: int = state.get_instance_id()
		live_ids[state_id] = true
		var visual := active.get(state_id) as Node
		if visual == null:
			visual = _acquire_shared(pool_id, scene)
			active[state_id] = visual
		binder.call(visual, state)
	for state_id: Variant in active.keys():
		if live_ids.has(state_id):
			continue
		var visual := active[state_id] as Node
		active.erase(state_id)
		_release_shared(pool_id, visual)


func _sync_traps(states: Array) -> void:
	var live_ids: Dictionary = {}
	for state: Variant in states:
		var state_id: int = state.get_instance_id()
		var kind: String = String(state.get("kind"))
		live_ids[state_id] = true
		var visual := active_traps.get(state_id) as Node
		if visual == null:
			if not TRAP_SCENES.has(kind):
				push_error("Missing trap scene for '%s'" % kind)
				continue
			visual = _acquire_shared("trap:%s" % kind, TRAP_SCENES[kind] as PackedScene)
			visual.set_meta("pool_id", "trap:%s" % kind)
			active_traps[state_id] = visual
		visual.call("sync_state", Vector2(state.get("position")), float(state.get("radius")))
	for state_id: Variant in active_traps.keys():
		if live_ids.has(state_id):
			continue
		var visual := active_traps[state_id] as Node
		active_traps.erase(state_id)
		_release_shared(String(visual.get_meta("pool_id", "")), visual)


func _acquire_shared(pool_id: String, scene: PackedScene) -> Node:
	var pool: Array = shared_pools.get(pool_id, [])
	var visual: Node
	if not pool.is_empty():
		visual = pool.pop_back() as Node
		shared_pools[pool_id] = pool
	else:
		visual = scene.instantiate()
		add_child(visual)
	visual.call("reset_visual")
	return visual


func _release_shared(pool_id: String, visual: Node) -> void:
	visual.set("visible", false)
	var pool: Array = shared_pools.get(pool_id, [])
	pool.append(visual)
	shared_pools[pool_id] = pool


func _acquire(projectile_id: String) -> Area2D:
	var pool: Array = projectile_pools.get(projectile_id, [])
	var visual: Area2D
	if not pool.is_empty():
		visual = pool.pop_back() as Area2D
		projectile_pools[projectile_id] = pool
	else:
		if not PROJECTILE_SCENES.has(projectile_id):
			push_error("Missing projectile scene for '%s'" % projectile_id)
			return null
		visual = (PROJECTILE_SCENES[projectile_id] as PackedScene).instantiate() as Area2D
		add_child(visual)
	visual.set_meta("projectile_id", projectile_id)
	visual.call("reset_visual")
	return visual


func _release(visual: Area2D) -> void:
	visual.visible = false
	var projectile_id: String = String(visual.get_meta("projectile_id", ""))
	var pool: Array = projectile_pools.get(projectile_id, [])
	pool.append(visual)
	projectile_pools[projectile_id] = pool
