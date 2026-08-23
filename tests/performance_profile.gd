extends SceneTree

const EnemyState = preload("res://src/state/enemy_state.gd")
const ProjectileState = preload("res://src/state/projectile_state.gd")
const PickupState = preload("res://src/state/pickup_state.gd")
const EffectState = preload("res://src/state/effect_state.gd")

const PROFILE_FRAMES: int = 240
const ENEMY_COUNT: int = 180
const PROJECTILE_COUNT: int = 120
const PICKUP_COUNT: int = 80
const EFFECT_COUNT: int = 60


func _init() -> void:
	call_deferred("_run_profile")


func _run_profile() -> void:
	var packed := load("res://main.tscn") as PackedScene
	var game := packed.instantiate() as Control
	root.add_child(game)
	await process_frame
	game._start_new_run("bow")
	game.player_hp = 1000000.0
	game.player_max_hp = 1000000.0
	game.player_position = game.world_size * Vector2(0.5, 0.72)
	game._update_world_camera(game.player_position, false, true)
	_populate_dense_visible_state(game)
	game._rebuild_spatial_grid()
	# Warm pools, animation resources, and visibility caches before measuring.
	game._sync_actor_presentation(1.0 / 60.0)
	await process_frame

	var actor_started: int = Time.get_ticks_usec()
	for frame: int in PROFILE_FRAMES:
		game._sync_actor_presentation(1.0 / 60.0)
	var actor_usec: int = Time.get_ticks_usec() - actor_started
	var enemy_started: int = Time.get_ticks_usec()
	for frame: int in PROFILE_FRAMES:
		game._update_enemies(1.0 / 60.0)
	var enemy_usec: int = Time.get_ticks_usec() - enemy_started
	var grid_started: int = Time.get_ticks_usec()
	for frame: int in PROFILE_FRAMES:
		game._rebuild_spatial_grid()
	var grid_usec: int = Time.get_ticks_usec() - grid_started
	var projectile_started: int = Time.get_ticks_usec()
	for frame: int in PROFILE_FRAMES:
		game._update_projectiles(1.0 / 60.0)
	var projectile_usec: int = Time.get_ticks_usec() - projectile_started

	var simulation_started: int = Time.get_ticks_usec()
	for frame: int in PROFILE_FRAMES:
		game._process_run(1.0 / 60.0)
	var simulation_usec: int = Time.get_ticks_usec() - simulation_started

	print("PERF dense presentation: %.3f ms/frame (%d enemies, %d projectiles)" % [float(actor_usec) / 1000.0 / PROFILE_FRAMES, ENEMY_COUNT, PROJECTILE_COUNT])
	print("PERF enemy simulation only: %.3f ms/frame" % [float(enemy_usec) / 1000.0 / PROFILE_FRAMES])
	print("PERF spatial rebuild only: %.3f ms/frame" % [float(grid_usec) / 1000.0 / PROFILE_FRAMES])
	print("PERF projectile simulation only: %.3f ms/frame" % [float(projectile_usec) / 1000.0 / PROFILE_FRAMES])
	print("PERF dense simulation: %.3f ms/frame" % [float(simulation_usec) / 1000.0 / PROFILE_FRAMES])
	print("PERF active visual nodes: actors=%d projectiles=%d pickups=%d effects=%d" % [
		game.actor_presentation.active_enemies.size(),
		game.combat_presentation.active_projectiles.size(),
		game.combat_presentation.active_pickups.size(),
		game.combat_presentation.active_effects.size(),
	])
	await process_frame
	print("PERF render snapshot: objects=%d primitives=%d draw_calls=%d video_memory=%.1f MiB" % [
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1048576.0,
	])
	game.free()
	game = null
	packed = null
	quit(0)


func _populate_dense_visible_state(game: Control) -> void:
	game.enemies.clear()
	game.enemies_by_uid.clear()
	game.projectiles.clear()
	game.pickups.clear()
	game.effects.clear()
	var visible: Rect2 = game._visible_world_rect()
	for index: int in ENEMY_COUNT:
		var enemy := EnemyState.new()
		enemy.uid = index + 1
		enemy.id = ["wolf", "raider", "archer", "reaver"][index % 4]
		enemy.kind = enemy.id
		enemy.position = visible.position + Vector2(20.0 + float(index % 15) * 24.0, 40.0 + float(index / 15) * 54.0)
		enemy.health = 10000.0
		enemy.max_health = 10000.0
		enemy.speed = 0.0
		enemy.damage = 0.0
		enemy.radius = 10.0
		game.enemies.append(enemy)
		game.enemies_by_uid[enemy.uid] = enemy
	for index: int in PROJECTILE_COUNT:
		var projectile := ProjectileState.new()
		projectile.position = visible.position + Vector2(12.0 + float(index % 12) * 31.0, 90.0 + float(index / 12) * 58.0)
		projectile.velocity = Vector2.ZERO
		projectile.damage = 0.0
		projectile.life = 30.0
		projectile.pierce = 999
		projectile.kind = ["bow", "sling", "wand_bolt", "enemy_arrow"][index % 4]
		if projectile.kind == "wand_bolt":
			projectile.kind = "wand"
		game.projectiles.append(projectile)
	for index: int in PICKUP_COUNT:
		var pickup := PickupState.new()
		pickup.position = visible.position + Vector2(10.0 + float(index % 10) * 37.0, 120.0 + float(index / 10) * 78.0)
		game.pickups.append(pickup)
	for index: int in EFFECT_COUNT:
		var effect := EffectState.new()
		effect.position = visible.position + Vector2(15.0 + float(index % 10) * 36.0, 150.0 + float(index / 10) * 96.0)
		effect.kind = ["impact", "spark", "ring", "arcane"][index % 4]
		effect.life = 30.0
		game.effects.append(effect)
