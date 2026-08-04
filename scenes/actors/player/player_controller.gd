extends "res://scenes/world/expedition/expedition_controller.gd"
func _update_weapons(delta: float) -> void:
	target_refresh -= delta
	if target_refresh <= 0.0:
		target_refresh = 0.1
		nearest_target = _find_nearest_enemy(player_position)
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = float(weapon_timers.get(weapon_id, 0.0)) - delta
		if float(weapon_timers[weapon_id]) <= 0.0 and nearest_target != null:
			_fire_weapon(weapon_id)

func _update_techniques(delta: float) -> void:
	if choosing_upgrade or run_paused or techniques.is_empty():
		return
	for technique_id: String in techniques:
		if not runtime_techniques.has(technique_id):
			continue
		var cooldown_tick: float = delta
		if traps.is_empty() and _training_node_modifier("arcane_reservoir", "inactive_cooldown_speed") > 0.0:
			cooldown_tick *= 1.0 + _training_node_modifier("arcane_reservoir", "inactive_cooldown_speed")
		var timer: float = float(technique_timers.get(technique_id, 0.0)) - cooldown_tick
		if timer > 0.0:
			technique_timers[technique_id] = timer
			continue
		var progress: Dictionary = _ability_progress(technique_id, int(techniques[technique_id]))
		var base_cooldown: float = float(progress.get("interval", runtime_techniques[technique_id].get("cooldown", 8.0)))
		var cooldown_reduction: float = _technique_total("technique_cooldown") + _equipment_total("technique_cooldown") + _training_total("technique_cooldown")
		var runebinder: bool = active_doctrines.has("runebinder") or active_doctrine == "runebinder"
		technique_timers[technique_id] = CombatStats.technique_cooldown(base_cooldown, cooldown_reduction, runebinder)
		_fire_training_technique(technique_id, int(techniques[technique_id]))

func _fire_training_technique(technique_id: String, rank: int) -> void:
	var safe_rank: int = clampi(rank, 1, 5)
	var progress: Dictionary = _ability_progress(technique_id, safe_rank)
	var power: float = 15.0 * (1.0 + float(progress.get("damage_bonus", 0.0))) * damage_multiplier
	var area_scale: float = 1.0 + float(progress.get("area_bonus", 0.0)) + _run_boon_total("area") + _training_total("area") + _doctrine_total("area")
	# General duration affects the technique itself. Persistent-area modifiers are
	# applied only when a zone is created, so Runebinder does not accidentally
	# lengthen dashes, Guard, War Cry, or other non-persistent effects.
	var duration_scale: float = 1.0 + float(progress.get("duration_bonus", 0.0)) + _run_boon_total("duration") + _training_total("duration")
	var flags: Array = progress.get("flags", [])
	var rank_stats: Dictionary = progress.get("stats", {})
	var school: String = TrainingContent.school_for_ability(technique_id)
	var effect_color: Color = TrainingContent.SCHOOL_COLORS.get(school, AMBER)
	if school == "vanguard" and active_doctrines.has("iron_vanguard"):
		technique_damage_reduction_timer = 2.0
	var target: EnemyState = _find_nearest_enemy(player_position)
	var target_position: Vector2 = target.position if target != null else player_position + last_move_vector * 96.0
	match technique_id:
		"ground_slam":
			var radius: float = 58.0 * area_scale
			_add_effect(player_position, radius, effect_color, "impact")
			_damage_training_area(player_position, radius, power, true, "stagger", technique_id)
			if "three_fissures" in flags:
				for fissure_index: int in 3:
					var fissure_position: Vector2 = player_position + Vector2.RIGHT.rotated(TAU * float(fissure_index) / 3.0) * radius * 0.70
					_add_effect(fissure_position, radius * 0.42, effect_color, "impact")
					_damage_training_area(fissure_position, radius * 0.42, power * 0.55, true, "stagger", technique_id)
			if "fractured_zone" in flags:
				_spawn_training_zone(player_position, radius * 0.72, power * 0.25, 2.5 * duration_scale, "fracture", technique_id)
			_apply_environment_ability(technique_id, player_position, radius)
		"shield_wall":
			guard_timer = maxf(guard_timer, 1.35 * duration_scale)
			var barrier_scale: float = 1.0 + _training_total("barrier_strength")
			player_barrier = maxf(player_barrier, player_max_hp * (0.08 + float(rank_stats.get("barrier_strength", 0.0))) * barrier_scale)
			_add_effect(player_position, 48.0 * area_scale, effect_color, "guard", last_move_vector)
			if "reflect_minor_projectiles" in flags:
				for projectile: ProjectileState in projectiles.duplicate():
					if projectile.faction == 1 and projectile.position.distance_to(player_position) <= 72.0 * area_scale:
						projectile.faction = 0
						projectile.velocity = -projectile.velocity
		"war_cry":
			var radius: float = 92.0 * area_scale
			war_cry_timer = maxf(war_cry_timer, 4.0 * duration_scale)
			war_cry_attack_speed = float(rank_stats.get("attack_speed", 0.10))
			_add_effect(player_position, radius, effect_color, "burst")
			for enemy: EnemyState in enemies.duplicate():
				if enemy.position.distance_to(player_position) <= radius + enemy.radius:
					enemy.stagger = maxf(enemy.stagger, 0.55 + safe_rank * 0.08)
		"rain_of_arrows":
			var rain_center: Vector2 = target_position
			var radius: float = 54.0 * area_scale
			var waves: int = maxi(1, int(progress.get("projectile_count", 1)))
			for wave: int in waves:
				_add_effect(rain_center, radius + wave * 4.0, effect_color, "rain")
				_damage_training_area(rain_center, radius, power * (1.50 if "heavy_final_wave" in flags and wave == waves - 1 else 0.75), false, "mark" if "mark_first_wave" in flags and wave == 0 else "pin", technique_id)
		"hunters_mark":
			if target != null:
				_apply_combat_status(target, "mark", technique_id, 0.0)
				_add_effect(target.position, 18.0 + safe_rank * 2.0, effect_color, "mark")
		"windstep":
			var step_direction: Vector2 = last_move_vector
			if step_direction.length_squared() <= 0.01 and target != null:
				step_direction = player_position.direction_to(target.position)
			if step_direction.length_squared() > 0.01:
				var step_target: Vector2 = player_position + step_direction.normalized() * (42.0 + safe_rank * 8.0)
				if not _run_position_blocked(step_target):
					player_position = step_target
				_add_effect(player_position, 26.0, effect_color, "dash", step_direction.normalized())
				post_mobility_timer = 2.5
				movement_burst_timer = 2.0
				if "gust" in flags:
					_damage_training_area(player_position, 48.0, power * 0.20, false, "stagger", technique_id)
				if "next_attack_projectiles" in flags:
					next_ranged_projectiles = maxi(next_ranged_projectiles, int(progress.get("projectile_count", 2)))
		"smoke_veil":
			guard_timer = maxf(guard_timer, 2.0 * duration_scale)
			movement_burst_timer = maxf(movement_burst_timer, 2.0 if "speed_inside_smoke" in flags else 0.0)
			_add_effect(player_position, 42.0 * area_scale, effect_color, "smoke")
		"poison_flask":
			var pool_radius: float = 36.0 * area_scale
			_spawn_training_zone(target_position, pool_radius, power * 0.55, 5.0 * duration_scale, "poison", technique_id)
			_add_effect(target_position, pool_radius, effect_color, "poison")
			_apply_environment_ability(technique_id, target_position, pool_radius)
		"shadowstep":
			var shadow_targets: Array[EnemyState] = _find_nearest_enemies(player_position, int(rank_stats.get("targets", 1)))
			for shadow_target: EnemyState in shadow_targets:
				var behind: Vector2 = shadow_target.position - shadow_target.position.direction_to(player_position) * (shadow_target.radius + 20.0)
				if not _run_position_blocked(behind):
					player_position = behind
				_damage_enemy(shadow_target, power * 1.15, true, "bleed", technique_id)
				_add_effect(player_position, 28.0, effect_color, "dash")
			post_mobility_timer = 2.5
		"fire_nova":
			var radius: float = 62.0 * area_scale * (1.0 + _training_total("fire_area"))
			_add_effect(player_position, radius, effect_color, "nova")
			_damage_training_area(player_position, radius, power, false, "burn", technique_id)
			if "burning_ring" in flags:
				_spawn_training_zone(player_position, radius * 0.80, power * 0.22, 3.0 * duration_scale, "ember", technique_id)
			if "expand_collapse_double_hit" in flags:
				_damage_training_area(player_position, radius * 0.72, power * 0.80, false, "burn", technique_id)
			_apply_environment_ability(technique_id, player_position, radius)
		"frost_ring":
			var radius: float = 58.0 * area_scale
			_add_effect(player_position, radius, effect_color, "frost")
			_damage_training_area(player_position, radius, power * 0.8, false, "chill", technique_id)
			_apply_environment_ability(technique_id, player_position, radius)
		"chain_lightning":
			var chain_count: int = 3 + int(rank_stats.get("additional_chains", 0)) + int(_training_total("chain_targets"))
			var chain_range: float = 240.0 * (1.0 + _training_total("chain_range"))
			var chain_targets: Array[EnemyState] = []
			for candidate: EnemyState in _find_nearest_enemies(player_position, chain_count):
				if candidate.position.distance_to(player_position) <= chain_range:
					chain_targets.append(candidate)
			var chain_damage: float = power
			for chain_target: EnemyState in chain_targets:
				_damage_enemy(chain_target, chain_damage, false, "shock", technique_id)
				_add_effect(chain_target.position, 12.0, effect_color, "lightning")
				chain_damage *= 0.78
			if "returning_chain_burst" in flags and not chain_targets.is_empty():
				_damage_training_area(chain_targets.back().position, 42.0, power * float(rank_stats.get("final_burst_power", 0.50)), false, "shock", technique_id)

func _damage_training_area(center: Vector2, radius: float, damage: float, melee: bool, status: String, source: String) -> void:
	for enemy: EnemyState in enemies.duplicate():
		if enemy.position.distance_to(center) <= radius + enemy.radius:
			_damage_enemy(enemy, damage, melee, status, source)

func _spawn_training_zone(position: Vector2, radius: float, damage: float, duration: float, kind: String, source_ability: String = "") -> void:
	if traps.size() >= 16:
		return
	var zone := TrapState.new()
	zone.position = position
	zone.radius = radius
	var persistent_duration: float = 1.0 + _training_total("persistent_duration") + _doctrine_total("persistent_duration")
	zone.damage = damage * maxf(0.0, 1.0 + _training_total("persistent_tick_damage"))
	zone.life = duration * maxf(0.1, persistent_duration)
	zone.tick = 0.2
	zone.kind = kind
	zone.source_ability = source_ability if not source_ability.is_empty() else kind
	zone.status = {"ember": "burn", "poison": "poison", "fracture": "stagger", "stagger": "stagger"}.get(kind, "")
	traps.append(zone)

func _apply_environment_ability(ability_id: String, center: Vector2, radius: float) -> void:
	var source_tags: Array[String] = []
	match ability_id:
		"fire_nova": source_tags = ["fire"]
		"frost_ring": source_tags = ["frost"]
		"chain_lightning": source_tags = ["lightning"]
		"ground_slam", "greatsword": source_tags = ["impact"]
		"poison_flask": source_tags = ["poison"]
		_: return
	var target_tags: Array[String] = _environment_tags_at(center)
	for result: Dictionary in EnvironmentInteractions.resolve(source_tags, target_tags):
		var cell: Vector2i = _region_cell_at(center)
		environment_states[str(cell)] = {"cell": cell, "results": result.get("result", []), "remaining": maxf(0.1, float(result.get("duration", 0.1))), "radius": radius}

func _region_cell_at(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position - region_origin
	return Vector2i(floori(local_position.x / 32.0), floori(local_position.y / 32.0))

func _environment_tags_at(world_position: Vector2) -> Array[String]:
	var cell: Vector2i = _region_cell_at(world_position)
	var result: Array[String] = []
	var size_tiles: Vector2i = generated_region.get("size_tiles", Vector2i.ZERO)
	var cells: Array = generated_region.get("cells", [])
	if cell.x >= 0 and cell.y >= 0 and cell.x < size_tiles.x and cell.y < size_tiles.y:
		var index: int = cell.y * size_tiles.x + cell.x
		if index >= 0 and index < cells.size():
			var kind: String = String(Dictionary(cells[index]).get("kind", "earth"))
			if kind in ["mud", "water"]:
				result.append_array(["wet", "freezable"])
			if kind in ["thorn", "barrier"]:
				result.append_array(["brittle", "breakable_heavy", "solid_ricochet", "cuttable"])
	if _run_position_blocked(world_position) and "solid_ricochet" not in result:
		result.append("solid_ricochet")
	return result

func _weapon_rank_total(weapon_id: String, stat: String) -> float:
	# The Training Grounds registry is the sole source of rank progression for
	# canonical v3 abilities. Its cumulative rank data is consumed by
	# _ability_progress(); reading the compatibility adapter too would apply the
	# same rank twice. Legacy weapons retain the old adapter during migration.
	if TrainingContent.abilities().has(weapon_id):
		return 0.0
	if not runtime_weapons.has(weapon_id):
		return 0.0
	var total: float = 0.0
	var rank: int = int(weapons.get(weapon_id, 1))
	var bonuses: Array = runtime_weapons[weapon_id].get("rank_bonuses", [])
	for bonus_index: int in mini(rank - 1, bonuses.size()):
		total += float(Dictionary(bonuses[bonus_index]).get(stat, 0.0))
	return total

func _weapon_mastery_total(weapon_id: String, stat: String) -> float:
	if TrainingContent.abilities().has(weapon_id):
		return 0.0
	if not bool(mastered.get(weapon_id, false)) or not runtime_weapons.has(weapon_id):
		return 0.0
	return float(runtime_weapons[weapon_id].get("mastery_stats", {}).get(stat, 0.0))

func _fire_weapon(weapon_id: String) -> void:
	var definition: Dictionary = runtime_weapons[weapon_id]
	var rank: int = clampi(int(weapons.get(weapon_id, 1)), 1, 5)
	var progress: Dictionary = _ability_progress(weapon_id, rank)
	var rank_stats: Dictionary = Dictionary(progress.get("stats", {}))
	var flags: Array = progress.get("flags", [])
	var attack_number: int = int(weapon_attack_counts.get(weapon_id, 0)) + 1
	weapon_attack_counts[weapon_id] = attack_number
	var category: String = String(definition.category)
	var category_key: String = category.to_lower()
	var attack_speed: float = cooldown_reduction + _technique_total(category_key + "_attack_speed") + _equipment_total(category_key + "_attack_speed") + _class_total(category_key + "_attack_speed") + _doctrine_total(category_key + "_attack_speed") + _relic_total(category_key + "_attack_speed") + _weapon_rank_total(weapon_id, "attack_speed") + _weapon_mastery_total(weapon_id, "attack_speed")
	attack_speed += float(rank_stats.get("attack_speed", 0.0))
	if war_cry_timer > 0.0:
		attack_speed += war_cry_attack_speed
	if active_doctrines.has("windrunner") and player_move_vector.length_squared() > 0.01:
		attack_speed += minf(0.25, maxf(0.0, player_speed / 122.0 - 1.0) * 0.5)
	if not is_zero_approx(_training_total("moving_attack_speed")) and player_move_vector.length_squared() > 0.01:
		attack_speed += _training_total("moving_attack_speed")
	if not is_zero_approx(_training_total("stationary_attack_speed")) and stationary_time >= 1.0:
		attack_speed += _training_total("stationary_attack_speed")
	if "heavy" in definition.get("tags", []):
		attack_speed -= _training_total("heavy_interval_penalty")
	var cooldown: float = CombatStats.attack_interval(float(progress.get("interval", definition.cooldown)), attack_speed)
	if "heavy" in definition.get("tags", []):
		cooldown *= 1.0 + _training_node_modifier("reckless_cleaver", "heavy_interval")
	weapon_timers[weapon_id] = maxf(0.16, cooldown)
	_play_sfx("strike", 0.08)
	var direction: Vector2 = (nearest_target.position - player_position).normalized()
	var category_damage: float = _technique_total(category_key + "_damage") + _equipment_total(category_key + "_damage") + _class_total(category_key + "_damage") + _doctrine_total(category_key + "_damage") + _relic_total(category_key + "_damage")
	category_damage += _run_boon_total("damage")
	category_damage += _doctrine_total("raw_damage") + _doctrine_total("direct_damage")
	if category != "MELEE":
		category_damage += _doctrine_total("projectile_damage")
	var damage: float = float(definition.damage) * damage_multiplier * (1.0 + float(progress.get("damage_bonus", 0.0)) + category_damage + _weapon_rank_total(weapon_id, "damage") + _weapon_mastery_total(weapon_id, "damage"))
	if post_mobility_timer > 0.0:
		damage *= 1.0 + _doctrine_total("post_mobility_damage") + _training_total("post_mobility_damage")
	if stationary_time >= _training_node_modifier("steady_aim", "stationary_seconds") and category != "MELEE" and _training_node_modifier("steady_aim", "stationary_seconds") > 0.0:
		damage *= 1.0 + _training_node_modifier("steady_aim", "projectile_damage")
	if active_doctrine == "pursuer" and last_move_vector.dot(direction) > 0.65:
		damage *= 1.0 + _doctrine_total("pursuit_damage")
	if player_hp <= player_max_hp * 0.5:
		damage *= 1.0 + _relic_total("wounded_damage") + _equipment_total("wounded_damage")
	var marching_distance: float = _training_node_modifier("marching_reach", "moving_distance")
	var movement_bonus_consumed: bool = false
	if marching_distance > 0.0 and recent_movement_distance >= marching_distance:
		damage *= 1.0 + _training_node_modifier("marching_reach", "next_attack_damage")
		movement_bonus_consumed = true
	var running_distance: float = _training_node_modifier("running_shot", "moving_distance")
	if category != "MELEE" and running_shot_cooldown <= 0.0 and running_distance > 0.0 and recent_movement_distance >= running_distance:
		next_ranged_projectiles += int(_training_node_modifier("running_shot", "bonus_projectiles"))
		running_shot_cooldown = maxf(0.1, _training_node_modifier("running_shot", "internal_cooldown"))
		movement_bonus_consumed = true
	if movement_bonus_consumed:
		recent_movement_distance = 0.0
	var guard_strike: bool = guard_empowered and category == "MELEE"
	if guard_strike:
		damage *= 1.35
	var melee_area_scale: float = 1.0 + float(progress.get("area_bonus", 0.0)) + _technique_total("melee_area") + _weapon_rank_total(weapon_id, "melee_area") + _weapon_mastery_total(weapon_id, "melee_area") + _run_boon_total("area")
	var pierce: int = int(definition.pierce) + int(progress.get("pierce", 0)) + int(_technique_total("pierce") + _weapon_rank_total(weapon_id, "pierce") + _weapon_mastery_total(weapon_id, "pierce"))
	var behavior: String = String(definition.behavior)
	var status: String = String(Dictionary(progress.get("status", {})).get("status", ""))
	if weapon_id == "bow" and rank >= 4:
		status = ""
	if weapon_id in ["staff", "wand"] and rank >= 3:
		status = ["burn", "chill", "shock"][(attack_number - 1) % 3]
	player_attack_direction = direction
	player_attack_kind = behavior
	player_attack_color = definition.color
	player_attack_duration = 0.28 if category == "MELEE" else 0.18
	player_attack_timer = player_attack_duration
	if behavior == "thrust" or weapon_id == "spear":
		var thrust_reach: float = float(definition.radius) + _technique_total("melee_range") + _equipment_total("melee_range") + _weapon_rank_total(weapon_id, "melee_range") + _weapon_mastery_total(weapon_id, "melee_range")
		thrust_reach *= 1.0 + _training_total("projectile_speed") * _training_node_modifier("drilled_ballistics", "speed_to_reach")
		thrust_reach *= melee_area_scale * (1.0 + float(rank_stats.get("reach", 0.0)))
		var impaling: bool = int(rank_stats.get("impaling_interval", 0)) > 0 and attack_number % int(rank_stats.impaling_interval) == 0
		if impaling:
			thrust_reach *= 1.25
			damage *= 1.20
		_add_effect(player_position + direction * 14.0, thrust_reach, definition.color, "thrust", direction)
		for enemy: EnemyState in enemies.duplicate():
			var offset: Vector2 = enemy.position - player_position
			var distance: float = offset.length()
			if distance <= thrust_reach + enemy.radius and distance > 0.1 and direction.dot(offset.normalized()) >= 0.42 - minf(0.18, (melee_area_scale - 1.0) * 0.3):
				var thrust_damage: float = damage * (1.0 + float(rank_stats.get("elite_damage", 0.0)) if impaling and enemy.special else 1.0)
				_damage_enemy(enemy, thrust_damage, true, status, weapon_id)
				if "pin_near_solid" in flags and _run_position_blocked(enemy.position + direction * 14.0):
					enemy.pin_timer = maxf(enemy.pin_timer, float(rank_stats.get("wall_pin_seconds", 1.25)))
				if guard_strike:
					enemy.stagger = maxf(enemy.stagger, 0.55)
		if guard_empowered:
			guard_empowered = false
		if "phalanx_side_thrusts" in flags:
			for side_angle: float in [-0.24, 0.24]:
				_fire_spectral_thrust(weapon_id, direction.rotated(side_angle), damage * float(rank_stats.get("spectral_side_damage", 0.65)), thrust_reach, status)
	elif behavior == "sweep" or weapon_id in ["sword", "greatsword", "daggers"]:
		var sweep_radius: float = float(definition.radius) * melee_area_scale
		sweep_radius *= 1.0 + float(rank_stats.get("target_range", 0.0))
		var circle_attack: bool = int(rank_stats.get("circle_interval", 0)) > 0 and attack_number % int(rank_stats.circle_interval) == 0
		if circle_attack:
			sweep_radius *= 1.0 + float(rank_stats.get("circle_area", 0.0))
		_add_effect(player_position, sweep_radius, definition.color, "arc", direction)
		for enemy: EnemyState in enemies.duplicate():
			var offset: Vector2 = enemy.position - player_position
			if offset.length() <= sweep_radius + enemy.radius and (circle_attack or offset.length() < 0.1 or direction.dot(offset.normalized()) >= -0.15):
				_damage_enemy(enemy, damage, true, status, weapon_id)
				var follow_up: float = _weapon_rank_total(weapon_id, "follow_up") + _weapon_mastery_total(weapon_id, "follow_up")
				if follow_up > 0.0 and enemies.has(enemy):
					_damage_enemy(enemy, damage * follow_up, true, "", weapon_id)
				if guard_strike and enemies.has(enemy):
					enemy.stagger = maxf(enemy.stagger, 0.55)
		if guard_empowered:
			guard_empowered = false
		var double_interval: int = int(rank_stats.get("double_cut_interval", 0))
		if double_interval > 0 and attack_number % double_interval == 0:
			_fire_spectral_thrust(weapon_id, direction.rotated(-0.16), damage * float(rank_stats.get("double_cut_damage", 0.70)), sweep_radius, status)
		if "ground_shockwave" in flags:
			var shockwave := _spawn_player_projectile(weapon_id, direction, damage * float(rank_stats.get("shockwave_damage", 0.35)), 2, sweep_radius * 0.45, "stagger")
			if shockwave != null:
				shockwave.radius = maxf(7.0, float(definition.radius) * 0.10)
		if int(rank_stats.get("fissure_interval", 0)) > 0 and attack_number % int(rank_stats.fissure_interval) == 0:
			_spawn_training_zone(player_position + direction * sweep_radius * 0.65, sweep_radius * 0.45, damage * 0.22, float(rank_stats.get("fissure_duration", 2.5)), "stagger", weapon_id)
	elif behavior == "trap":
		if traps.size() < 12:
			var trap: TrapState = TrapState.new()
			trap.position = player_position - last_move_vector * 22.0
			trap.radius = float(definition.radius) * (1.0 + _technique_total("trap_area") + _weapon_rank_total(weapon_id, "trap_area") + _weapon_mastery_total(weapon_id, "trap_area"))
			trap.damage = damage
			trap.life = 6.0 * (1.0 + _technique_total("trap_duration") + _weapon_rank_total(weapon_id, "trap_duration") + _weapon_mastery_total(weapon_id, "trap_duration"))
			traps.append(trap)
	elif behavior == "fan":
		var count: int = maxi(3, int(progress.get("projectile_count", 3))) + projectile_bonus + next_ranged_projectiles
		next_ranged_projectiles = 0
		for index: int in count:
			var spread_scale: float = 1.0 + float(rank_stats.get("spread", 0.0))
			var angle: float = deg_to_rad(lerpf(-18.0 * spread_scale, 18.0 * spread_scale, 0.5 if count == 1 else float(index) / float(count - 1)))
			var projectile := _spawn_player_projectile(weapon_id, direction.rotated(angle), damage, pierce, 0.0, status)
			_configure_ranked_projectile(projectile, weapon_id, progress, attack_number, index, count)
	elif behavior == "splash":
		var count: int = maxi(3, int(progress.get("projectile_count", 3))) + projectile_bonus + next_ranged_projectiles
		next_ranged_projectiles = 0
		if int(rank_stats.get("meteor_interval", 0)) > 0 and attack_number % int(rank_stats.meteor_interval) == 0:
			count += int(rank_stats.get("fracture_count", 4))
		var splash_scale: float = 1.0 + _technique_total("splash_area") + _weapon_rank_total(weapon_id, "splash_area") + _weapon_mastery_total(weapon_id, "splash_area")
		for index: int in count:
			var angle: float = deg_to_rad(lerpf(-28.0, 28.0, 0.5 if count == 1 else float(index) / float(count - 1)))
			var projectile := _spawn_player_projectile(weapon_id, direction.rotated(angle), damage, pierce, 42.0 * splash_scale, "stagger")
			_configure_ranked_projectile(projectile, weapon_id, progress, attack_number, index, count)
	else:
		var category_projectiles: int = int(_technique_total("arcane_projectiles") + _class_total("arcane_projectiles") + _weapon_rank_total(weapon_id, "arcane_projectiles") + _weapon_mastery_total(weapon_id, "arcane_projectiles")) if category == "ARCANE" else projectile_bonus
		var extra_projectiles: int = category_projectiles + next_ranged_projectiles
		var persistent_count: int = maxi(1, int(progress.get("projectile_count", 1))) + extra_projectiles
		var count: int = persistent_count
		next_ranged_projectiles = 0
		# Patterned volleys use one projectile on their ordinary attacks and only
		# fan out on the named interval.  The old code started from the largest
		# rank projectile count, which made a rank-five Bow silently fire its
		# five-arrow volley on every attack and made the offer text misleading.
		var split_interval: int = int(rank_stats.get("split_interval", 0))
		var repeat_interval: int = int(rank_stats.get("repeat_interval", 0))
		var fork_interval: int = int(rank_stats.get("fork_interval", 0))
		var volley_interval: int = int(rank_stats.get("volley_interval", 0))
		var has_pattern: bool = split_interval > 0 or repeat_interval > 0 or fork_interval > 0 or volley_interval > 0
		if has_pattern:
			count = 1 + extra_projectiles
			if split_interval > 0 and attack_number % split_interval == 0:
				count = maxi(count, persistent_count)
			if repeat_interval > 0 and attack_number % repeat_interval == 0:
				count = maxi(count, persistent_count)
			if fork_interval > 0 and attack_number % fork_interval == 0:
				count = maxi(count, persistent_count)
			if volley_interval > 0 and attack_number % volley_interval == 0:
				var volley_count: int = int(rank_stats.get("volley_projectile_count", persistent_count))
				count = maxi(count, volley_count + extra_projectiles)
		if int(rank_stats.get("charge_threshold", 0)) > 0 and attack_number % int(rank_stats.charge_threshold) == 0:
			count = maxi(count, int(rank_stats.get("seeking_bolts", 5)))
		# Keep the empty branch explicitly typed. Assigning a bare `[]` here makes
		# Godot reject the value at runtime when a line/returning/orbit weapon fires,
		# aborting the attack before any projectile is created.
		var homing_targets: Array[EnemyState] = []
		if behavior == "hex":
			homing_targets = _find_nearest_enemies(player_position, count)
		if weapon_id in ["staff", "wand"] and rank >= 5:
			homing_targets = _find_nearest_enemies(player_position, count)
		for index: int in count:
			var spread: float = deg_to_rad(float(index - (count - 1) / 2.0) * 7.0)
			var projectile_direction: Vector2 = direction.rotated(spread)
			var target_uid: int = -1
			if not homing_targets.is_empty():
				var homing_target: EnemyState = homing_targets[index % homing_targets.size()]
				projectile_direction = player_position.direction_to(homing_target.position)
				target_uid = homing_target.uid
			var splash_scale: float = 1.0 + _technique_total("splash_area") + _weapon_rank_total(weapon_id, "splash_area") + _weapon_mastery_total(weapon_id, "splash_area")
			var projectile_damage: float = damage
			if count >= 5 and index == count / 2 and rank_stats.has("central_arrow_damage"):
				projectile_damage *= float(rank_stats.central_arrow_damage)
			var projectile := _spawn_player_projectile(weapon_id, projectile_direction, projectile_damage, pierce, 18.0 * splash_scale if behavior == "hex" else 0.0, status, target_uid)
			_configure_ranked_projectile(projectile, weapon_id, progress, attack_number, index, count)
		if guard_empowered and weapon_id == "spear":
			guard_empowered = false
	if "heavy" in definition.get("tags", []) and _training_node_modifier("elemental_impact", "heavy_element_wave") > 0.0:
		var impact_status: String = ["burn", "chill", "shock"][attack_number % 3]
		var impact_projectile := _spawn_player_projectile(weapon_id, direction, 20.0 * _training_node_modifier("elemental_impact", "heavy_element_wave") * damage_multiplier, 1, 16.0, impact_status)
		if impact_projectile != null:
			impact_projectile.color = Color("8bc6bd")
	_update_duelist_momentum(definition.get("tags", []))

func _fire_spectral_thrust(weapon_id: String, direction: Vector2, damage: float, reach: float, status: String) -> void:
	_add_effect(player_position + direction * 14.0, reach, runtime_weapons[weapon_id].color, "thrust", direction)
	for enemy: EnemyState in enemies.duplicate():
		var offset: Vector2 = enemy.position - player_position
		if offset.length() <= reach + enemy.radius and offset.length() > 0.1 and direction.dot(offset.normalized()) >= 0.45:
			_damage_enemy(enemy, damage, true, status, weapon_id)

func _configure_ranked_projectile(projectile: ProjectileState, weapon_id: String, progress: Dictionary, attack_number: int, index: int, count: int) -> void:
	if projectile == null:
		return
	var stats: Dictionary = Dictionary(progress.get("stats", {}))
	var flags: Array = progress.get("flags", [])
	if weapon_id == "sling":
		projectile.ricochets = maxi(1, int(stats.get("ricochet_count", 1)))
	if weapon_id in ["throwing_knives", "chakrams"] and ("rebound" in flags or "twin_orbit" in flags or "circling_blades" in flags or "blade_constellation" in flags):
		projectile.returning = true
		projectile.return_delay = 0.45
	if weapon_id == "runic_orb":
		projectile.orbiting = true
		projectile.orbit_radius = 34.0 * (1.0 + _training_total("orbit_area")) * (float(stats.get("outer_orbit_multiplier", 1.0)) if index % 2 == 1 else 1.0)
		projectile.orbit_angle = TAU * float(index) / float(maxi(1, count))
		projectile.orbit_speed = 2.2 * (-1.0 if index % 2 == 1 else 1.0)
		projectile.life = 3.5
	if weapon_id in ["bow", "staff", "wand"] and ("home_on_marked" in flags or "grand_convergence" in flags or "arcane_torrent" in flags):
		projectile.homing = true
	if weapon_id == "crossbow" and int(stats.get("ballista_interval", 0)) > 0 and attack_number % int(stats.ballista_interval) == 0:
		projectile.radius *= 1.8
		projectile.damage *= 1.4
		projectile.pierce += 3

func _update_duelist_momentum(tags: Array) -> void:
	if not active_doctrines.has("duelist"):
		return
	var category: String = "heavy" if "heavy" in tags else ("rapid" if "rapid" in tags else "")
	if category.is_empty():
		return
	if duelist_last_category.is_empty() or duelist_last_category != category:
		duelist_momentum = mini(6, duelist_momentum + 1)
	else:
		duelist_momentum = maxi(0, duelist_momentum - 2)
	duelist_last_category = category

func _spawn_player_projectile(weapon_id: String, direction: Vector2, damage: float, pierce: int, splash_radius: float, status: String = "", target_uid: int = -1) -> ProjectileState:
	if projectiles.size() >= MAX_PROJECTILES:
		return null
	var definition: Dictionary = runtime_weapons[weapon_id]
	var projectile: ProjectileState = projectile_pool.pop_back() if not projectile_pool.is_empty() else ProjectileState.new()
	projectile.position = player_position + direction * 12.0
	var rank_progress: Dictionary = _ability_progress(weapon_id, int(weapons.get(weapon_id, 1)))
	var speed_bonus: float = _technique_total("projectile_speed") + _equipment_total("projectile_speed") + float(Dictionary(rank_progress.get("stats", {})).get("projectile_speed", 0.0)) + _weapon_rank_total(weapon_id, "projectile_speed") + _weapon_mastery_total(weapon_id, "projectile_speed") + _run_boon_total("projectile_speed")
	projectile.velocity = direction * float(definition.speed) * (1.0 + speed_bonus)
	projectile.damage = damage
	projectile.radius = float(definition.radius)
	var converted_reach: float = (_training_total("melee_range") / 100.0) * _training_node_modifier("drilled_ballistics", "reach_to_projectile")
	projectile.life = (0.34 if weapon_id == "spear" else 1.45) * (1.0 + _training_total("projectile_lifetime") + converted_reach)
	# `pierce` counts remaining impacts, not whether the projectile is allowed
	# to exist. Canonical Training Grounds weapons use zero bonus pierce at rank
	# one, so assigning that value directly caused their shots to be recycled at
	# the end of the first frame. Every player projectile must survive until its
	# first collision; explicit pierce bonuses are added above this one hit.
	projectile.pierce = maxi(1, pierce)
	projectile.faction = 0
	projectile.color = definition.color
	projectile.kind = weapon_id
	projectile.splash_radius = splash_radius
	projectile.homing = bool(definition.get("homing", false)) or weapon_id == "witchfire"
	projectile.target_uid = target_uid
	projectile.status = status
	if active_doctrines.has("arcane_archer") and projectile.status.is_empty() and weapon_id in ["bow", "sling", "crossbow", "throwing_knives", "chakrams"]:
		projectile.status = ["burn", "chill", "shock"][absi(weapon_id.hash()) % 3]
	projectile.source_tags.assign(TrainingContent.abilities().get(weapon_id, {}).get("tags", []))
	if weapon_id not in projectile.source_tags:
		projectile.source_tags.append(weapon_id)
	projectile.returning = false
	projectile.return_delay = 0.0
	projectile.orbiting = false
	projectile.orbit_angle = 0.0
	projectile.orbit_radius = 0.0
	projectile.orbit_speed = 0.0
	projectile.ricochets = 0
	projectile.hit_ids.clear()
	projectiles.append(projectile)
	return projectile

func _update_training_movement_state(delta: float) -> void:
	var movement_distance: float = player_move_vector.length() * player_speed * delta
	recent_movement_distance += movement_distance
	if player_position.distance_to(stationary_anchor) <= 32.0:
		stationary_time += delta
	else:
		stationary_anchor = player_position
		stationary_time = 0.0
	if time_since_player_damage >= maxf(0.1, _training_total("barrier_avoid_seconds")) and _training_total("barrier_max_health") > 0.0:
		player_barrier = maxf(player_barrier, player_max_hp * _training_total("barrier_max_health") * (1.0 + _training_total("barrier_strength")))

func _update_combat_statuses(delta: float) -> void:
	for event: Dictionary in combat_statuses.tick(delta):
		var enemy: EnemyState = _find_enemy_by_uid(int(event.get("target_id", -1)))
		if enemy == null:
			continue
		var status_id: String = String(event.get("status_id", ""))
		var stacks: int = maxi(1, int(event.get("stacks", 1)))
		var potency: float = maxf(0.0, float(event.get("potency", 1.0)))
		var tick_damage: float = {"bleed": 2.4, "poison": 1.5, "burn": 2.0}.get(status_id, 0.0) * float(stacks) * potency
		if status_id == "poison" and active_doctrines.has("venom_pact"):
			tick_damage *= 0.85
		if tick_damage <= 0.0:
			continue
		enemy.health -= tick_damage
		_add_float_text(enemy.position, str(roundi(tick_damage)), Color("8eb27f") if status_id == "poison" else (Color("e78642") if status_id == "burn" else BURGUNDY.lightened(0.25)))
		if enemy.health <= 0.0:
			_kill_enemy(enemy)

func _tick_target_cooldowns(cooldowns: Dictionary, delta: float) -> void:
	for target_value: Variant in cooldowns.keys().duplicate():
		var target_id: int = int(target_value)
		cooldowns[target_id] = float(cooldowns[target_id]) - delta
		if float(cooldowns[target_id]) <= 0.0:
			cooldowns.erase(target_id)

func _update_static_field() -> void:
	var arc_chance: float = _training_node_modifier("static_field", "shock_arc_chance")
	if arc_chance <= 0.0:
		return
	var arc_damage: float = 20.0 * _training_node_modifier("static_field", "shock_arc_power") * damage_multiplier
	for source_enemy: EnemyState in enemies.duplicate():
		if not combat_statuses.has(source_enemy.uid, "shock") or rng.randf() > arc_chance:
			continue
		var best_target: EnemyState
		var best_distance: float = INF
		for target_enemy: EnemyState in enemies:
			if target_enemy == source_enemy:
				continue
			var conductive: bool = combat_statuses.has(target_enemy.uid, "shock") or "wet" in _environment_tags_at(target_enemy.position)
			var distance: float = source_enemy.position.distance_squared_to(target_enemy.position)
			if conductive and distance <= 160.0 * 160.0 and distance < best_distance:
				best_target = target_enemy
				best_distance = distance
		if best_target != null:
			_damage_enemy(best_target, arc_damage, false, "shock", "static_field")
			_add_effect(best_target.position, 12.0, Color("8bc6bd"), "lightning")

func _ability_progress(ability_id: String, rank: int) -> Dictionary:
	var definition: Dictionary = TrainingContent.abilities().get(ability_id, {})
	var progress: Dictionary = {
		"damage_bonus": 0.0, "area_bonus": 0.0, "duration_bonus": 0.0,
		"interval": float(Dictionary(definition.get("base_stats", {})).get("interval", Dictionary(definition.get("base_stats", {})).get("cooldown", 1.0))),
		"projectile_count": 1 if String(definition.get("category", "")) != "technique" else 0,
		"pierce": 0, "stats": {}, "flags": [], "status": {}
	}
	var ranks: Array = definition.get("ranks", [])
	for rank_index: int in range(mini(clampi(rank, 0, 5), ranks.size())):
		var rank_data: Dictionary = Dictionary(ranks[rank_index])
		progress.damage_bonus = float(progress.damage_bonus) + float(rank_data.get("damage_multiplier", 1.0)) - 1.0
		progress.area_bonus = float(progress.area_bonus) + float(rank_data.get("area_multiplier", 1.0)) - 1.0
		progress.duration_bonus = float(progress.duration_bonus) + float(rank_data.get("duration_multiplier", 1.0)) - 1.0
		var rank_interval: float = float(rank_data.get("cooldown_or_interval", 0.0))
		if rank_interval > 0.0:
			progress.interval = rank_interval
		progress.projectile_count = maxi(int(progress.projectile_count), int(rank_data.get("projectile_count", 0)))
		progress.pierce = int(progress.pierce) + int(rank_data.get("pierce", 0))
		for stat: String in Dictionary(rank_data.get("stat_changes", {})):
			progress.stats[stat] = Dictionary(rank_data.stat_changes)[stat]
		for flag_value: Variant in rank_data.get("behavior_flags", []):
			var flag: String = String(flag_value)
			if flag not in progress.flags:
				progress.flags.append(flag)
		if not Dictionary(rank_data.get("status_application", {})).is_empty():
			progress.status = Dictionary(rank_data.status_application).duplicate(true)
	return progress

func _apply_combat_status(enemy: EnemyState, requested_status: String, source_ability: String, hit_damage: float) -> void:
	if enemy == null or requested_status.is_empty():
		return
	var status_id: String = {"scorch": "burn"}.get(requested_status, requested_status)
	if status_id not in ["bleed", "poison", "burn", "chill", "shock", "mark"]:
		return
	var rank: int = int(weapons.get(source_ability, techniques.get(source_ability, 1)))
	var progress: Dictionary = _ability_progress(source_ability, rank)
	var application: Dictionary = Dictionary(progress.get("status", {}))
	if application.is_empty():
		application = {
			"bleed": {"status": "bleed", "chance": 1.0, "potency": 1.0, "duration": 5.0},
			"poison": {"status": "poison", "chance": 1.0, "potency": 1.0, "duration": 8.0},
			"burn": {"status": "burn", "chance": 1.0, "potency": 1.0, "duration": 4.0},
			"chill": {"status": "chill", "chance": 1.0, "potency": 0.25, "duration": 5.0, "stacks": 25},
			"shock": {"status": "shock", "chance": 1.0, "potency": 1.0, "duration": 5.0},
			"mark": {"status": "mark", "chance": 1.0, "potency": 0.15, "duration": 8.0}
		}.get(status_id, {})
	var chance: float = float(application.get("chance", 1.0))
	if not application.is_empty() and String(application.get("status", status_id)) != status_id:
		chance = 1.0
	chance += _training_total(status_id + "_chance")
	if rng.randf() > chance:
		return
	var potency: float = float(application.get("potency", 1.0))
	if status_id == "bleed":
		potency *= 1.0 + _training_total("bleed_potency") + _doctrine_total("bleed_potency")
	elif status_id == "poison":
		potency *= 1.0 + _training_total("poison_potency")
	elif status_id in ["burn", "chill", "shock"]:
		potency *= 1.0 + _doctrine_total("elemental_status")
	var duration: float = float(application.get("duration", -1.0))
	if duration > 0.0:
		if status_id == "bleed":
			duration += _training_total("bleed_duration")
		else:
			duration *= 1.0 + _training_total(status_id + "_duration")
	if status_id == "poison":
		duration *= 1.0 + _doctrine_total("poison_duration")
	if status_id == "mark":
		var current_mark: Dictionary = combat_statuses.state_for(enemy.uid, "mark")
		var mark_extension: float = _training_node_modifier("predators_focus", "mark_extend")
		if not current_mark.is_empty() and mark_extension > 0.0:
			duration = minf(12.0, maxf(duration, float(current_mark.get("remaining", 0.0)) + mark_extension))
	var tags: Array[String] = ["moving_target"]
	if active_doctrines.has("venom_pact"):
		tags.append("venom_pact")
	var stacks: int = int(application.get("stacks", 1))
	if status_id == "chill":
		stacks = maxi(1, roundi(float(stacks) * (1.0 + _training_total("chill_potency") + _training_total("elemental_status_buildup"))))
	if status_id in ["bleed", "poison"] and (combat_statuses.has(enemy.uid, "burn") or combat_statuses.has(enemy.uid, "chill") or combat_statuses.has(enemy.uid, "shock")):
		potency *= 1.0 + _doctrine_total("elemental_status_dot")
	if status_id == "bleed" and "heavy" in Array(TrainingContent.abilities().get(source_ability, {}).get("tags", [])):
		stacks += int(_training_total("bleed_stacks"))
	var prior_element_count: int = 0
	for element_id: String in ["burn", "chill", "shock"]:
		prior_element_count += 1 if combat_statuses.has(enemy.uid, element_id) else 0
	if status_id == "burn" and combat_statuses.has(enemy.uid, "poison") and not volatile_mixture_cooldowns.has(enemy.uid) and _training_node_modifier("volatile_mixture", "poison_consume_burst") > 0.0:
		var consumed_poison: int = combat_statuses.consume_stacks(enemy.uid, "poison", 3)
		if consumed_poison > 0:
			enemy.health -= hit_damage * 0.25 * float(consumed_poison) * _training_node_modifier("volatile_mixture", "poison_consume_burst")
			volatile_mixture_cooldowns[enemy.uid] = maxf(0.1, _training_node_modifier("volatile_mixture", "cooldown"))
			_add_effect(enemy.position, 30.0, Color("b9c864"), "burst")
	var result: Dictionary = combat_statuses.apply(enemy.uid, status_id, "hero", source_ability, chance, potency, duration, stacks, enemy.kind == "boss", TrainingContent.school_for_ability(source_ability), tags)
	if status_id in ["burn", "chill", "shock"] and prior_element_count > 0 and not elemental_echo_cooldowns.has(enemy.uid) and _training_node_modifier("elemental_echo", "reaction_power") > 0.0:
		elemental_echo_cooldowns[enemy.uid] = maxf(0.1, _training_node_modifier("elemental_echo", "target_cooldown"))
		enemy.health -= 20.0 * _training_node_modifier("elemental_echo", "reaction_power") * damage_multiplier
		_add_effect(enemy.position, 24.0, Color("8bc6bd"), "arcane")
	var freeze_threshold: int = clampi(roundi(100.0 + _training_total("freeze_threshold")), 25, 100)
	if status_id == "chill" and int(result.get("stacks", 0)) >= freeze_threshold:
		combat_statuses.remove(enemy.uid, "chill")
		if enemy.kind == "boss":
			enemy.stagger = maxf(enemy.stagger, 0.55)
		else:
			enemy.pin_timer = maxf(enemy.pin_timer, 1.25)
	if active_doctrines.has("elemental_conduit") and not elemental_conduit_cooldowns.has(enemy.uid) and combat_statuses.has(enemy.uid, "burn") and combat_statuses.has(enemy.uid, "chill") and combat_statuses.has(enemy.uid, "shock"):
		for element: String in ["burn", "chill", "shock"]:
			combat_statuses.remove(enemy.uid, element)
		elemental_conduit_cooldowns[enemy.uid] = 4.0
		_damage_enemy(enemy, 20.0 * _doctrine_total("elemental_reaction") * (1.0 + _training_total("reaction_power")), false, "", "elemental_conduit")

func _update_environment_states(delta: float) -> void:
	for key_value: Variant in environment_states.keys().duplicate():
		var key: String = String(key_value)
		var state: Dictionary = environment_states[key]
		state.remaining = float(state.get("remaining", 0.0)) - delta
		if float(state.remaining) <= 0.0:
			environment_states.erase(key)
		else:
			environment_states[key] = state
