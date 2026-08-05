extends "res://scenes/actors/player/player_controller.gd"

const FLOW_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)
]
const FAR_ENEMY_DISTANCE_SQUARED: float = 470.0 * 470.0
const FAR_ENEMY_UPDATE_INTERVAL: float = 0.066
const LOS_CACHE_CELL_SIZE: float = 16.0

func _update_enemies(delta: float) -> void:
	_update_enemy_flow_field(delta)
	enemy_town_end_y_cache = _town_bounds_world().end.y
	enemy_visible_rect_cache = _visible_world_rect()
	var los_target_cell := Vector2i(floori(player_position.x / LOS_CACHE_CELL_SIZE), floori(player_position.y / LOS_CACHE_CELL_SIZE))
	if los_target_cell != enemy_los_target_cell or enemy_los_blocker_version != enemy_flow_blocker_version:
		enemy_los_target_cell = los_target_cell
		enemy_los_blocker_version = enemy_flow_blocker_version
		enemy_los_cache.clear()
	# Enemy spawns are appended during wave processing, so snapshot only the
	# count. A duplicate Array here was one of the largest steady-state run
	# allocations; newly spawned enemies are intentionally processed next frame.
	var enemy_count: int = enemies.size()
	for enemy_index: int in enemy_count:
		if enemy_index >= enemies.size():
			break
		var enemy: EnemyState = enemies[enemy_index]
		_eject_enemy_from_town(enemy)
		enemy.touch_cooldown = maxf(0.0, enemy.touch_cooldown - delta)
		enemy.attack_cooldown -= delta
		enemy.stagger = maxf(0.0, enemy.stagger - delta)
		enemy.pin_timer = maxf(0.0, enemy.pin_timer - delta)
		enemy.path_check_timer -= delta
		var to_player: Vector2 = player_position - enemy.position
		var distance_squared: float = to_player.length_squared()
		# Enemies outside the active play area do not need 60 Hz steering. They
		# remain simulated and continue to approach the player, but updating their
		# route at 15 Hz prevents a large off-screen wave from consuming the whole
		# frame budget. Specials stay frame based so elites and bosses remain exact.
		if not enemy.special and distance_squared > FAR_ENEMY_DISTANCE_SQUARED:
			enemy.simulation_timer = maxf(0.0, enemy.simulation_timer - delta)
			if enemy.simulation_timer > 0.0:
				continue
			enemy.simulation_timer = FAR_ENEMY_UPDATE_INTERVAL
		else:
			enemy.simulation_timer = 0.0
		var distance: float = sqrt(distance_squared)
		var direction: Vector2 = to_player.normalized() if distance > 0.1 else Vector2.ZERO
		if enemy.path_check_timer <= 0.0:
			# Direct-path checks are deliberately staggered. Their result remains
			# stable between checks while movement and collision stay frame-based.
			# Long-distance enemies use the shared flow field instead of each doing
			# a full ray march to the player. This keeps dense waves bounded while
			# retaining exact obstacle checks in combat range.
			var path_interval: float = 0.18 + float(enemy.uid % 7) * 0.018 if enemy.kind == "archer" else 0.28 + float(enemy.uid % 9) * 0.018
			enemy.path_check_timer = path_interval
			enemy.has_direct_path = distance <= 384.0 and _enemy_direct_path_clear(enemy.position, player_position, enemy.radius)
		if enemy.kind == "archer" and _enemy_inside_playable_bounds(enemy):
			var clear_shot: bool = enemy.has_direct_path
			if not clear_shot:
				# Archers do not fire through trees, ruins or walls. Search for a
				# nearby lateral step that opens a direct line to the player.
				_move_archer_toward_line_of_sight(enemy, direction, delta)
			elif distance_squared > 220.0 * 220.0:
				_move_enemy_with_collision(enemy, direction * enemy.speed * delta)
			elif distance_squared < 135.0 * 135.0:
				_move_enemy_with_collision(enemy, -direction * enemy.speed * 0.55 * delta)
			if clear_shot and distance_squared < 235.0 * 235.0 and enemy.attack_cooldown <= 0.0:
				enemy.attack_cooldown = 2.25
				_spawn_enemy_bolt(enemy.position, direction, enemy.damage)
		else:
			var stagger_scale: float = 0.35 if enemy.stagger > 0.0 else (0.58 if enemy.pin_timer > 0.0 else 1.0)
			var direct_path: bool = enemy.has_direct_path
			if not direct_path:
				var route_direction: Vector2 = _enemy_flow_direction(enemy)
				if route_direction.length_squared() > 0.001:
					direction = route_direction
			_move_enemy_with_collision(enemy, direction * enemy.speed * stagger_scale * delta)
		var touch_radius: float = enemy.radius + 11.0
		if distance_squared <= touch_radius * touch_radius and enemy.touch_cooldown <= 0.0:
			enemy.touch_cooldown = 0.75
			_damage_player(enemy.damage)
		if enemy.kind == "boss":
			var health_fraction: float = enemy.health / enemy.max_health
			var next_phase: int = 3 if health_fraction <= 0.33 else (2 if health_fraction <= 0.66 else 1)
			if next_phase != boss_phase:
				boss_phase = next_phase
				if boss_label != null:
					boss_label.text = "BARROW KNIGHT - PHASE %d" % boss_phase
			if enemy.attack_cooldown <= 0.0:
				enemy.attack_cooldown = 3.2 if boss_phase < 3 else 2.2
				var hazard_count: int = 1 if boss_phase == 1 else (2 if boss_phase == 2 else 3)
				for hazard_index: int in hazard_count:
					var hazard: HazardState = HazardState.new()
					hazard.position = player_position + last_move_vector.rotated(float(hazard_index - 1) * 0.65) * (24.0 + hazard_index * 18.0)
					hazard.radius = 48.0 if boss_phase < 3 else 38.0
					hazard.damage = enemy.damage * (1.25 if boss_phase < 3 else 1.45)
					hazards.append(hazard)
				if boss_phase >= 2:
					_spawn_enemy("blighted", true)

func _eject_enemy_from_town(enemy: EnemyState) -> void:
	var town_end_y: float = enemy_town_end_y_cache if is_finite(enemy_town_end_y_cache) else _town_bounds_world().end.y
	if enemy.position.y > town_end_y + enemy.radius + 4.0:
		return
	var exclusion: Rect2 = _enemy_town_exclusion_rect(enemy.radius)
	if exclusion.has_point(enemy.position):
		enemy.position.y = exclusion.end.y + 1.0

func _disperse_enemy_from_camp_gate(enemy: EnemyState) -> void:
	"""Keep a retained wanderer outside the camp's hostile-free gate radius."""
	if not _camp_gate_safe_zone_contains(enemy.position, enemy.radius):
		return
	var escape_position: Vector2 = _camp_gate_safe_exit_position(enemy.position, enemy.radius)
	# This is a boundary push, not a despawn: the enemy remains in the camp
	# wanderer pool and continues its slower ambient movement outside the gate.
	enemy.position = escape_position
	enemy.dispersing = true
	enemy.wander_timer = maxf(enemy.wander_timer, 1.2)
	var escape_direction: Vector2 = (escape_position - _camp_gate_safe_center()).normalized()
	enemy.wander_direction = escape_direction if escape_direction.length_squared() > 0.01 else Vector2.DOWN
	enemy.touch_cooldown = 0.0
	enemy.attack_cooldown = 99.0

func _enemy_town_exclusion_rect(radius: float = 0.0) -> Rect2:
	# One rectangular hostile exclusion is cheaper and more reliable than
	# checking every wall, structure and decoration independently.
	return _town_bounds_world().grow(radius + 4.0)

func _handoff_run_enemies_to_camp() -> void:
	# Extraction ends combat, not the existence of everything outside the gate.
	# Keep the closest ordinary hostiles in-place and let them visibly lose
	# interest while the camp HUD replaces the expedition HUD.
	var candidates: Array[EnemyState] = []
	for enemy: EnemyState in enemies:
		if not enemy.special and enemy.kind != "boss":
			candidates.append(enemy)
	candidates.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		return a.position.distance_squared_to(player_position) < b.position.distance_squared_to(player_position)
	)
	for enemy: EnemyState in candidates:
		if camp_wanderers.size() >= MAX_CAMP_WANDERERS:
			break
		# Establish the safe-town boundary before choosing the dispersal vector.
		# This avoids a first-frame teleport fighting the outward wander motion
		# when an enemy is touching the gate at the instant of extraction.
		_eject_enemy_from_town(enemy)
		_disperse_enemy_from_camp_gate(enemy)
		enemy.dispersing = true
		enemy.wander_timer = rng.randf_range(2.8, 5.2)
		var away: Vector2 = (enemy.position - _town_bounds_world().get_center()).normalized()
		enemy.wander_direction = (away if away.length_squared() > 0.01 else Vector2.DOWN).rotated(rng.randf_range(-0.32, 0.32))
		enemy.touch_cooldown = 0.0
		enemy.attack_cooldown = 99.0
		enemy.stagger = 0.0
		enemy.pin_timer = 0.0
		enemy.bleed_damage = 0.0
		enemy.scorch_damage = 0.0
		enemy.poison_damage = 0.0
		enemy.poison_ticks = 0
		enemy.mark_timer = 0.0
		camp_wanderers.append(enemy)
		enemies_by_uid.erase(enemy.uid)
	for enemy: EnemyState in enemies:
		if not camp_wanderers.has(enemy):
			enemy_pool.append(enemy)
	enemies.clear()
	enemies_by_uid.clear()
	for projectile: ProjectileState in projectiles:
		projectile_pool.append(projectile)
	for pickup: PickupState in pickups:
		pickup_pool.append(pickup)
	projectiles.clear()
	pickups.clear()
	traps.clear()
	hazards.clear()
	float_texts.clear()
	effects.clear()
	nearest_target = null
	_ensure_camp_wanderers()

func _ensure_camp_wanderers() -> void:
	if camp_wanderers.size() >= MIN_CAMP_WANDERERS:
		return
	var town: Rect2 = _town_bounds_world()
	var center: Vector2 = town.get_center()
	var slots: Array[Vector2] = [
		Vector2(town.position.x - 58.0, town.position.y + town.size.y * 0.34),
		Vector2(town.end.x + 58.0, town.position.y + town.size.y * 0.42),
		Vector2(town.position.x - 44.0, town.end.y + 92.0),
		Vector2(town.end.x + 44.0, town.end.y + 124.0),
	]
	var ids: Array[String] = ["wolf", "raider", "crow", "raider"]
	while camp_wanderers.size() < MIN_CAMP_WANDERERS:
		var index: int = camp_wanderers.size()
		var enemy: EnemyState = enemy_pool.pop_back() if not enemy_pool.is_empty() else EnemyState.new()
		_configure_enemy_state(enemy, ids[index % ids.size()], false, 0.0)
		enemy.position = slots[index % slots.size()]
		if _enemy_position_blocked(enemy.position, enemy.radius):
			enemy.position = center + Vector2(0.0, town.size.y * 0.5 + 90.0 + index * 22.0)
		enemy.wander_direction = (enemy.position - center).normalized().orthogonal()
		enemy.wander_timer = rng.randf_range(1.2, 3.8)
		camp_wanderers.append(enemy)

func _update_camp_wanderers(delta: float) -> void:
	_ensure_camp_wanderers()
	var center: Vector2 = _town_bounds_world().get_center()
	for enemy: EnemyState in camp_wanderers:
		_eject_enemy_from_town(enemy)
		# The refuge gate is a small hostile-free threshold.  Push retained
		# wanderers back out before they can overlap the player or the exit.
		_disperse_enemy_from_camp_gate(enemy)
		enemy.wander_timer -= delta
		if enemy.wander_timer <= 0.0:
			enemy.dispersing = false
			var radial: Vector2 = enemy.position - center
			if radial.length() > 390.0:
				enemy.wander_direction = -radial.normalized()
			elif radial.length() < maxf(_town_bounds_world().size.x, _town_bounds_world().size.y) * 0.58:
				enemy.wander_direction = radial.normalized()
			else:
				enemy.wander_direction = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
			enemy.wander_timer = rng.randf_range(1.8, 4.6)
		var pace: float = 0.46 if enemy.dispersing else 0.20
		var before: Vector2 = enemy.position
		_move_enemy_with_collision(enemy, enemy.wander_direction * enemy.speed * pace * delta)
		if enemy.position.distance_squared_to(before) < 0.01:
			# At the gate, a diagonal dispersal vector can brush a blocker even
			# though the direct route away from town is open. Fall back to that
			# radial route immediately so the actor never appears frozen.
			var radial_escape: Vector2 = (enemy.position - center).normalized()
			enemy.wander_direction = radial_escape if radial_escape.length_squared() > 0.01 else Vector2.DOWN
			_move_enemy_with_collision(enemy, enemy.wander_direction * enemy.speed * pace * delta)
			if enemy.position.distance_squared_to(before) < 0.01:
				# A corner can block both the original diagonal and the pure radial
				# vector. Try both tangents in the same frame instead of leaving a
				# newly dispersed enemy visibly frozen until the next update.
				for turn: float in [PI * 0.5, -PI * 0.5]:
					enemy.wander_direction = radial_escape.rotated(turn) if radial_escape.length_squared() > 0.01 else Vector2.RIGHT.rotated(turn)
					_move_enemy_with_collision(enemy, enemy.wander_direction * enemy.speed * pace * delta)
					if enemy.position.distance_squared_to(before) >= 0.01:
						break

func _activate_camp_wanderers_for_run() -> void:
	for enemy: EnemyState in camp_wanderers:
		_eject_enemy_from_town(enemy)
		_disperse_enemy_from_camp_gate(enemy)
		var preserved_position: Vector2 = enemy.position
		var preserved_id: String = enemy.id
		_configure_enemy_state(enemy, preserved_id, false, _current_dread())
		enemy.position = preserved_position
		enemy.attack_cooldown = rng.randf_range(0.6, 1.4)
		enemies.append(enemy)
		enemies_by_uid[enemy.uid] = enemy
	camp_wanderers.clear()

func _move_enemy_with_collision(enemy: EnemyState, movement: Vector2) -> void:
	if movement.length_squared() <= 0.0001:
		return
	# Path steering chooses the route; collision resolution only performs the
	# requested axis-separated step. It no longer invents a tangent direction,
	# which was the source of enemies endlessly sliding along a wall.
	var next_x := Vector2(enemy.position.x + movement.x, enemy.position.y)
	if not _enemy_position_blocked(next_x, enemy.radius):
		enemy.position.x = next_x.x
	var next_y := Vector2(enemy.position.x, enemy.position.y + movement.y)
	if not _enemy_position_blocked(next_y, enemy.radius):
		enemy.position.y = next_y.y
	enemy.position.x = clampf(enemy.position.x, enemy.radius, world_size.x - enemy.radius)
	enemy.position.y = clampf(enemy.position.y, enemy.radius, world_size.y - enemy.radius)

func _move_archer_toward_line_of_sight(enemy: EnemyState, direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.001:
		return
	var step_distance: float = enemy.speed * delta
	var route_direction: Vector2 = _enemy_flow_direction(enemy)
	if route_direction.length_squared() > 0.001:
		_move_enemy_with_collision(enemy, route_direction * step_distance)
		return
	_move_enemy_with_collision(enemy, direction * step_distance)

func _update_enemy_flow_field(delta: float) -> void:
	var target_cell: Vector2i = _path_cell_for_position(player_position)
	enemy_flow_repath_timer = maxf(0.0, enemy_flow_repath_timer - delta)
	# The target cell and blocker version are the actual invalidation inputs.
	# Rebuilding on a fixed timer made the whole BFS run every 0.35 seconds even
	# while the player stood still. Direct movement/path checks remain frame
	# based, so this only avoids redundant route planning work.
	if enemy_flow_target_cell == target_cell and enemy_flow_built_blocker_version == enemy_flow_blocker_version and not enemy_flow_distance.is_empty():
		return
	enemy_flow_repath_timer = 0.35
	enemy_flow_target_cell = target_cell
	enemy_flow_distance.clear()
	enemy_flow_open_cache.clear()
	enemy_flow_built_blocker_version = enemy_flow_blocker_version
	var flow_rect: Rect2 = _visible_world_rect().grow(256.0)
	var world_max_cell := Vector2i(ceili(world_size.x / 32.0) - 1, ceili(world_size.y / 32.0) - 1)
	enemy_flow_min_cell = Vector2i(maxi(0, floori(flow_rect.position.x / 32.0)), maxi(0, floori(flow_rect.position.y / 32.0)))
	enemy_flow_max_cell = Vector2i(mini(world_max_cell.x, ceili(flow_rect.end.x / 32.0)), mini(world_max_cell.y, ceili(flow_rect.end.y / 32.0)))
	if target_cell.x < enemy_flow_min_cell.x or target_cell.y < enemy_flow_min_cell.y or target_cell.x > enemy_flow_max_cell.x or target_cell.y > enemy_flow_max_cell.y:
		enemy_flow_min_cell = Vector2i(maxi(0, target_cell.x - 14), maxi(0, target_cell.y - 20))
		enemy_flow_max_cell = Vector2i(mini(world_max_cell.x, target_cell.x + 14), mini(world_max_cell.y, target_cell.y + 20))
	var goal: Vector2i = target_cell
	if not _flow_cell_open(goal):
		for radius: int in range(1, 4):
			var found_goal: bool = false
			for y: int in range(-radius, radius + 1):
				for x: int in range(-radius, radius + 1):
					var candidate: Vector2i = target_cell + Vector2i(x, y)
					if _flow_cell_open(candidate):
						goal = candidate
						found_goal = true
						break
				if found_goal:
					break
			if found_goal:
				break
	if not _flow_cell_open(goal):
		return
	var queue: Array[Vector2i] = [goal]
	enemy_flow_distance[goal] = 0
	var queue_index: int = 0
	var max_cell := Vector2i(ceili(world_size.x / 32.0) - 1, ceili(world_size.y / 32.0) - 1)
	while queue_index < queue.size():
		var current: Vector2i = queue[queue_index]
		queue_index += 1
		var next_distance: int = int(enemy_flow_distance[current]) + 1
		for offset: Vector2i in FLOW_OFFSETS:
			var neighbor: Vector2i = current + offset
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x > max_cell.x or neighbor.y > max_cell.y:
				continue
			if enemy_flow_distance.has(neighbor) or not _flow_cell_open(neighbor):
				continue
			if offset.x != 0 and offset.y != 0 and (not _flow_cell_open(current + Vector2i(offset.x, 0)) or not _flow_cell_open(current + Vector2i(0, offset.y))):
				continue
			enemy_flow_distance[neighbor] = next_distance
			queue.append(neighbor)

func _flow_cell_open(cell: Vector2i) -> bool:
	if cell.x < enemy_flow_min_cell.x or cell.y < enemy_flow_min_cell.y or cell.x > enemy_flow_max_cell.x or cell.y > enemy_flow_max_cell.y:
		return false
	if enemy_flow_open_cache.has(cell):
		return bool(enemy_flow_open_cache[cell])
	var open: bool = _path_cell_open(cell, 18.0)
	enemy_flow_open_cache[cell] = open
	return open

func _enemy_direct_path_clear(from_position: Vector2, to_position: Vector2, radius: float) -> bool:
	# Line of sight follows the same authored blockers as projectiles, but it is
	# an AI query rather than a projectile collision. Quantized cache keys let
	# enemies sharing a tile reuse the result, while the coarser 16 px sweep
	# avoids doing a 4-8 px projectile sweep for every archer every few frames.
	var query_radius: float = maxf(2.0, radius * 0.35)
	var from_cell := Vector2i(floori(from_position.x / LOS_CACHE_CELL_SIZE), floori(from_position.y / LOS_CACHE_CELL_SIZE))
	var key: String = "%d:%d:%d:%d:%d" % [from_cell.x, from_cell.y, enemy_los_target_cell.x, enemy_los_target_cell.y, roundi(query_radius)]
	if enemy_los_cache.has(key):
		return bool(enemy_los_cache[key])
	var distance: float = from_position.distance_to(to_position)
	if distance <= 0.01:
		enemy_los_cache[key] = true
		return true
	var steps: int = maxi(1, ceili(distance / 16.0))
	var clear: bool = true
	for step: int in range(1, steps + 1):
		var sample: Vector2 = from_position.lerp(to_position, float(step) / float(steps))
		if _run_position_blocked(sample):
			clear = false
			break
	enemy_los_cache[key] = clear
	return clear

func _enemy_flow_direction(enemy: EnemyState) -> Vector2:
	var current: Vector2i = _path_cell_for_position(enemy.position)
	if not enemy_flow_distance.has(current):
		return Vector2.ZERO
	var best_cell: Vector2i = current
	var best_distance: int = int(enemy_flow_distance[current])
	for offset: Vector2i in FLOW_OFFSETS:
		var candidate: Vector2i = current + offset
		if not enemy_flow_distance.has(candidate):
			continue
		var candidate_distance: int = int(enemy_flow_distance[candidate])
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best_cell = candidate
	if best_cell == current:
		return Vector2.ZERO
	return enemy.position.direction_to(_path_cell_center(best_cell))

func _path_cell_for_position(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))

func _path_cell_center(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 0.5) * 32.0)

func _path_cell_open(cell: Vector2i, radius: float) -> bool:
	var max_cell: Vector2i = Vector2i(ceili(world_size.x / 32.0) - 1, ceili(world_size.y / 32.0) - 1)
	if cell.x < 0 or cell.y < 0 or cell.x > max_cell.x or cell.y > max_cell.y:
		return false
	return not _enemy_position_blocked(_path_cell_center(cell), radius)

func _enemy_position_blocked(position: Vector2, radius: float) -> bool:
	# Hostile actors treat the complete safe-town footprint as solid. Player
	# collision keeps the painted gate open, but enemies never enter that lane.
	var town_end_y: float = enemy_town_end_y_cache if is_finite(enemy_town_end_y_cache) else _town_bounds_world().end.y
	# The town ends at the southern gate. Most field queries are below it, so
	# skip the authored-town rectangle and structure checks entirely for those
	# positions and test only Moor blockers/frontier locks.
	if position.y > town_end_y + radius + 4.0:
		if _region_position_blocked(position, radius):
			return true
		var unlocked_field_biomes: Array = save.profile.get("unlocked_biomes", ["blackthorn_moor"])
		if not unlocked_field_biomes.has("gloamwood"):
			var field_frontier: Vector2 = _frontier_gate_position()
			if Rect2(field_frontier - Vector2(68.0, 18.0), Vector2(136.0, 36.0)).grow(radius).has_point(position):
				return true
		return false
	if _enemy_town_exclusion_rect(radius).has_point(position):
		return true
	if _region_position_blocked(position, radius):
		return true
	var unlocked_biomes: Array = save.profile.get("unlocked_biomes", ["blackthorn_moor"])
	if not unlocked_biomes.has("gloamwood"):
		var frontier: Vector2 = _frontier_gate_position()
		if Rect2(frontier - Vector2(68.0, 18.0), Vector2(136.0, 36.0)).grow(radius).has_point(position):
			return true
	return false

func _region_position_blocked(position: Vector2, radius: float) -> bool:
	var local_position: Vector2 = position - region_origin
	var center_cell := Vector2i(floori(local_position.x / 32.0), floori(local_position.y / 32.0))
	# Most movement queries are nowhere near a generated blocker. A compact
	# neighbourhood mask rejects those queries without nine dictionary lookups;
	# the exact rectangle checks below still decide every near-blocker collision.
	if radius <= 32.0 and broken_environment_cells.is_empty() and center_cell.x >= 0 and center_cell.y >= 0 and center_cell.x < region_blocker_width and center_cell.y < region_blocker_height:
		var neighborhood_index: int = center_cell.y * region_blocker_width + center_cell.x
		if neighborhood_index >= 0 and neighborhood_index < region_blocker_neighborhood.size() and region_blocker_neighborhood[neighborhood_index] == 0:
			return false
	# The center cell plus ceil(radius / tile_size) neighbours covers every
	# rectangle that can overlap the query circle. The previous extra ring made
	# every ordinary enemy collision inspect 25 cells instead of 9.
	var search_radius: int = maxi(1, ceili(radius / 32.0))
	for cell_y: int in range(center_cell.y - search_radius, center_cell.y + search_radius + 1):
		for cell_x: int in range(center_cell.x - search_radius, center_cell.x + search_radius + 1):
			var cell := Vector2i(cell_x, cell_y)
			if broken_environment_cells.has(cell):
				continue
			if region_blocker_grid.has(cell) and Rect2(region_blocker_grid[cell]).grow(radius).has_point(local_position):
				return true
	return false

func _cache_region_blockers() -> void:
	region_blocker_grid.clear()
	region_blocker_width = int(Vector2i(generated_region.get("size_tiles", Vector2i.ZERO)).x)
	region_blocker_height = int(Vector2i(generated_region.get("size_tiles", Vector2i.ZERO)).y)
	region_blocker_neighborhood = PackedByteArray()
	if region_blocker_width > 0 and region_blocker_height > 0:
		region_blocker_neighborhood.resize(region_blocker_width * region_blocker_height)
	enemy_flow_open_cache.clear()
	enemy_flow_blocker_version += 1
	for blocker_value: Variant in generated_region.get("blockers", []):
		if blocker_value is Rect2:
			var blocker: Rect2 = blocker_value
			var cell := Vector2i(floori(blocker.get_center().x / 32.0), floori(blocker.get_center().y / 32.0))
			region_blocker_grid[cell] = blocker
			for offset_y: int in range(-1, 2):
				for offset_x: int in range(-1, 2):
					var neighborhood_cell: Vector2i = cell + Vector2i(offset_x, offset_y)
					if neighborhood_cell.x >= 0 and neighborhood_cell.y >= 0 and neighborhood_cell.x < region_blocker_width and neighborhood_cell.y < region_blocker_height:
						region_blocker_neighborhood[neighborhood_cell.y * region_blocker_width + neighborhood_cell.x] = 1

func _enemy_inside_playable_bounds(enemy: EnemyState) -> bool:
	var visible: Rect2 = enemy_visible_rect_cache if enemy_visible_rect_cache.has_area() else _visible_world_rect()
	return visible.grow(-enemy.radius).has_point(enemy.position)

func _spawn_enemy_bolt(origin: Vector2, direction: Vector2, damage: float) -> void:
	if projectiles.size() >= MAX_PROJECTILES:
		return
	var projectile: ProjectileState = projectile_pool.pop_back() if not projectile_pool.is_empty() else ProjectileState.new()
	projectile.position = origin
	projectile.velocity = direction * 175.0
	projectile.damage = damage
	projectile.radius = 4.0
	projectile.life = 2.2
	projectile.pierce = 1
	projectile.faction = 1
	projectile.color = BURGUNDY.lightened(0.25)
	projectile.kind = "enemy_arrow"
	projectile.splash_radius = 0.0
	projectile.homing = false
	projectile.target_uid = -1
	projectile.status = ""
	projectile.source_tags.clear()
	projectile.returning = false
	projectile.return_delay = 0.0
	projectile.orbiting = false
	projectile.orbit_angle = 0.0
	projectile.orbit_radius = 0.0
	projectile.orbit_speed = 0.0
	projectile.ricochets = 0
	projectile.hit_ids.clear()
	projectiles.append(projectile)

func _rebuild_spatial_grid() -> void:
	# Reuse the per-cell arrays instead of allocating a new Array for every
	# occupied grid cell on every frame.
	for cell: Vector2i in spatial_grid_used_cells:
		var previous: Array = spatial_grid.get(cell, [])
		previous.clear()
	spatial_grid_used_cells.clear()
	for enemy: EnemyState in enemies:
		var cell: Vector2i = Vector2i(floori(enemy.position.x / 48.0), floori(enemy.position.y / 48.0))
		var cell_value: Variant = spatial_grid.get(cell, null)
		if cell_value == null:
			var new_cell: Array = []
			spatial_grid[cell] = new_cell
			spatial_grid_used_cells.append(cell)
			new_cell.append(enemy)
		else:
			var cell_enemies: Array = cell_value
			if cell_enemies.is_empty():
				spatial_grid_used_cells.append(cell)
			cell_enemies.append(enemy)

func _nearby_enemies(position: Vector2) -> Array[EnemyState]:
	nearby_enemy_scratch.clear()
	var center: Vector2i = Vector2i(floori(position.x / 48.0), floori(position.y / 48.0))
	for x: int in range(center.x - 1, center.x + 2):
		for y: int in range(center.y - 1, center.y + 2):
			var cell: Vector2i = Vector2i(x, y)
			if spatial_grid.has(cell):
				for enemy: EnemyState in spatial_grid[cell]:
					nearby_enemy_scratch.append(enemy)
	return nearby_enemy_scratch
