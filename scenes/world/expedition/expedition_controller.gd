extends "res://scenes/world/camp/camp_controller.gd"
func _process_run(delta: float) -> void:
	run_elapsed += delta
	autosave_timer += delta
	hud_timer += delta
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	guard_timer = maxf(0.0, guard_timer - delta)
	time_since_player_damage += delta
	post_mobility_timer = maxf(0.0, post_mobility_timer - delta)
	war_cry_timer = maxf(0.0, war_cry_timer - delta)
	movement_burst_timer = maxf(0.0, movement_burst_timer - delta)
	vanishing_step_cooldown = maxf(0.0, vanishing_step_cooldown - delta)
	running_shot_cooldown = maxf(0.0, running_shot_cooldown - delta)
	toxic_blood_cooldown = maxf(0.0, toxic_blood_cooldown - delta)
	resonant_guard_cooldown = maxf(0.0, resonant_guard_cooldown - delta)
	technique_damage_reduction_timer = maxf(0.0, technique_damage_reduction_timer - delta)
	for target_value: Variant in elemental_echo_cooldowns.keys().duplicate():
		var target_id: int = int(target_value)
		elemental_echo_cooldowns[target_id] = float(elemental_echo_cooldowns[target_id]) - delta
		if float(elemental_echo_cooldowns[target_id]) <= 0.0:
			elemental_echo_cooldowns.erase(target_id)
	_tick_target_cooldowns(elemental_conduit_cooldowns, delta)
	_tick_target_cooldowns(volatile_mixture_cooldowns, delta)
	static_field_timer -= delta
	if static_field_timer <= 0.0:
		static_field_timer += 1.0
		_update_static_field()
	bloodbound_heal_window += delta
	if bloodbound_heal_window >= 1.0:
		bloodbound_heal_window = fmod(bloodbound_heal_window, 1.0)
		bloodbound_healed = 0.0
	_update_training_movement_state(delta)
	_update_environment_states(delta)
	player_attack_timer = maxf(0.0, player_attack_timer - delta)
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	shake_offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength)) if bool(save.settings.screen_shake) else Vector2.ZERO
	_update_player(delta)
	if screen != Screen.RUN:
		return
	run_camera_transition = minf(1.0, run_camera_transition + delta / RUN_CAMERA_TRANSITION_SECONDS)
	_update_world_camera(player_position, false)
	_update_exploration()
	_update_wave(delta)
	_update_objective(delta)
	_update_weapons(delta)
	_update_techniques(delta)
	_update_combat_statuses(delta)
	_update_enemies(delta)
	_rebuild_spatial_grid()
	_update_projectiles(delta)
	_update_traps(delta)
	_update_hazards(delta)
	_update_pickups(delta)
	_update_feedback(delta)
	if autosave_timer >= 15.0:
		autosave_timer = 0.0
		_snapshot_run()
		SaveService.save_data(save)
	if hud_timer >= 0.1:
		hud_timer = 0.0
		_update_hud()
	if player_hp <= 0.0:
		_finish_run(false)

func _update_player(delta: float) -> void:
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		last_move_vector = direction
	else:
		direction = Vector2.ZERO
	player_move_vector = direction
	var current_speed: float = player_speed * (1.0 + _training_total("movement_burst") if movement_burst_timer > 0.0 else 1.0)
	var movement: Vector2 = direction * current_speed * delta
	var next_x := Vector2(player_position.x + movement.x, player_position.y)
	var next_y := Vector2(player_position.x, player_position.y + movement.y)
	if not _run_position_blocked(next_x):
		player_position.x = next_x.x
	if not _run_position_blocked(next_y):
		player_position.y = next_y.y
	player_position.x = clampf(player_position.x, 18.0, world_size.x - 18.0)
	player_position.y = clampf(player_position.y, 18.0, world_size.y - 22.0)
	var gate: Vector2 = _camp_gate_position()
	# Extraction is a crossing event at the southern gate, not a blanket
	# "anything north of the camp" trigger. The run must first travel away from
	# the gate, then approach it from the field through its narrow opening.
	if player_position.y > gate.y + 26.0:
		run_gate_entry_armed = true
	var gate_band: bool = player_position.y >= gate.y - 18.0 and player_position.y <= gate.y + 8.0
	var moving_into_gate: bool = player_move_vector.y < -0.01
	if run_gate_entry_armed and gate_band and moving_into_gate and is_instance_valid(active_camp_scene) and active_camp_scene.gate_opening_contains_x(player_position.x):
		player_position.y = gate.y + 1.0
		if _gate_confirmations_enabled():
			_show_gate_confirmation(false)
		else:
			_confirm_finish_run(null)
		return
	var field_recovery: float = _technique_total("health_regen") + _equipment_total("health_regen") + _relic_total("health_regen")
	if field_recovery > 0.0:
		recovery_timer += delta
		if recovery_timer >= 5.0:
			recovery_timer -= 5.0
			_heal_player(field_recovery)

func _run_position_blocked(position: Vector2) -> bool:
	if position.y <= _camp_gate_position().y + 18.0:
		if _point_hits_camp_fence(position):
			return true
		for structure_id: String in camp_structure_definitions:
			if not _is_constructed(structure_id):
				continue
			var structure: StructureDefinition = camp_structure_definitions[structure_id]
			if structure.contains_ground_point_for_tier(position, 9.0, _structure_tier(structure_id)):
				return true
		if _point_hits_camp_decor(position, 9.0):
			return true
	if _region_position_blocked(position, 8.0):
		return true
	var unlocked_biomes: Array = save.profile.get("unlocked_biomes", ["blackthorn_moor"])
	if not unlocked_biomes.has("gloamwood"):
		var frontier: Vector2 = _frontier_gate_position()
		if Rect2(frontier - Vector2(68.0, 18.0), Vector2(136.0, 36.0)).has_point(position):
			return true
	return false

func _sync_collision_debug_scene() -> void:
	if not is_instance_valid(collision_debug_scene):
		return
	var enabled: bool = bool(save.get("settings", {}).get("collision_debug", false))
	if not enabled:
		collision_debug_scene.call("sync_geometry", false, [])
		return
	var entries: Array[Dictionary] = []
	for structure_id: String in camp_structure_definitions:
		var constructed: bool = _is_constructed(structure_id)
		if not constructed:
			continue
		var structure: StructureDefinition = camp_structure_definitions[structure_id]
		if constructed:
			var footprint: PackedVector2Array = structure.world_footprint_for_tier(_structure_tier(structure_id))
			if footprint.size() > 1:
				var closed_footprint: PackedVector2Array = footprint.duplicate()
				closed_footprint.append(footprint[0])
				entries.append({"points": closed_footprint, "color": Color(0.95, 0.25, 0.20, 0.95), "width": 2.0})
		var interaction_shape: PackedVector2Array = structure.world_interaction_polygon()
		if interaction_shape.size() > 1:
			var closed_interaction: PackedVector2Array = interaction_shape.duplicate()
			closed_interaction.append(interaction_shape[0])
			entries.append({"points": closed_interaction, "color": Color(0.95, 0.72, 0.20, 0.78), "width": 1.0})
	if is_instance_valid(active_camp_scene):
		for wall_polygon: PackedVector2Array in active_camp_scene.wall_collision_polygons_world():
			var closed_wall: PackedVector2Array = wall_polygon.duplicate()
			closed_wall.append(wall_polygon[0])
			entries.append({"points": closed_wall, "color": Color(0.92, 0.18, 0.20, 0.92), "width": 2.0})
	for decor_entry: Dictionary in _visible_camp_decor():
		var authored_polygon: PackedVector2Array = decor_entry.get("footprint", PackedVector2Array())
		if authored_polygon.size() >= 3:
			var authored_world := PackedVector2Array()
			for point: Vector2 in authored_polygon:
				authored_world.append(Vector2(decor_entry.get("anchor", Vector2.ZERO)) + point)
			authored_world.append(authored_world[0])
			entries.append({"points": authored_world, "color": Color(0.30, 0.75, 0.95, 0.90), "width": 1.0})
		else:
			var decor_rect: Rect2 = _camp_decor_footprint(decor_entry)
			entries.append({"points": PackedVector2Array([decor_rect.position, Vector2(decor_rect.end.x, decor_rect.position.y), decor_rect.end, Vector2(decor_rect.position.x, decor_rect.end.y), decor_rect.position]), "color": Color(0.30, 0.75, 0.95, 0.90), "width": 1.0})
	for blocker_value: Variant in generated_region.get("blockers", []):
		if blocker_value is Rect2:
			var blocker: Rect2 = blocker_value
			blocker.position += region_origin
			entries.append({"points": PackedVector2Array([blocker.position, Vector2(blocker.end.x, blocker.position.y), blocker.end, Vector2(blocker.position.x, blocker.end.y), blocker.position]), "color": Color(0.92, 0.18, 0.20, 0.72), "width": 1.0})
	collision_debug_scene.call("sync_geometry", true, entries)

func _frontier_gate_position() -> Vector2:
	return region_origin + Vector2(generated_region.get("frontier_gate", Vector2(585.0, 3100.0)))

func _current_dread() -> float:
	return Expedition.dread(run_elapsed, run_dread_bonus)

func _generate_exploration_points() -> void:
	exploration_points.clear()
	var definitions: Array = generated_region.get("landmarks", [])
	for definition: Dictionary in definitions:
		var point := ExplorationPoint.new()
		point.id = String(definition.id)
		point.kind = String(definition.kind)
		point.label = {"cache": "ABANDONED CACHE", "shrine": "OLD WAYSTONE", "danger": "RAIDER HOLD", "barrow": "BARROW MARK"}.get(point.kind, "MOOR SITE")
		point.position = region_origin + Vector2(definition.position)
		point.dread = float(definition.dread)
		point.silver = 10 + int(point.dread * 2.0)
		point.provisions = 2 + int(definition.get("dread", 3.0) / 4.0)
		exploration_points.append(point)

func _update_exploration() -> void:
	nearby_exploration_index = -1
	var nearest_distance: float = 48.0
	for index: int in exploration_points.size():
		var point: ExplorationPoint = exploration_points[index]
		if point.discovered:
			continue
		var distance: float = player_position.distance_to(point.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearby_exploration_index = index
	if is_instance_valid(expedition_interact_button):
		expedition_interact_button.visible = nearby_exploration_index >= 0
		expedition_interact_button.disabled = nearby_exploration_index < 0
		if nearby_exploration_index >= 0:
			expedition_interact_button.text = "SEARCH\n%s" % exploration_points[nearby_exploration_index].label

func _interact_with_expedition() -> void:
	if screen != Screen.RUN or run_paused or choosing_upgrade:
		return
	if nearby_exploration_index < 0 or nearby_exploration_index >= exploration_points.size():
		return
	var point: ExplorationPoint = exploration_points[nearby_exploration_index]
	if point.discovered:
		return
	point.discovered = true
	run_discoveries += 1
	run_exploration_silver += point.silver
	run_exploration_provisions += point.provisions
	run_dread_bonus += point.dread
	run_score += point.silver + point.provisions * 3
	_add_float_text(point.position, "+%dS  +%dP" % [point.silver, point.provisions], AMBER.lightened(0.2))
	_add_effect(point.position, 30.0, FOLKLORE if point.kind in ["shrine", "barrow"] else AMBER, "ring")
	_play_sfx("pickup")
	if point.kind == "shrine":
		_heal_player(20.0)
	elif point.kind == "danger":
		for index: int in 4:
			_spawn_enemy("raider", false)
	elif point.kind == "barrow" and not elite_two_spawned:
		elite_two_spawned = true
		_spawn_enemy("grave_guard", true)
	nearby_exploration_index = -1
	_update_exploration()

func _update_wave(delta: float) -> void:
	var dread: float = _current_dread()
	if not elite_one_spawned and dread >= 25.0:
		elite_one_spawned = true
		_spawn_enemy("houndmaster", true)
		_offer_contract()
	if not elite_two_spawned and dread >= 62.0:
		elite_two_spawned = true
		_spawn_enemy("grave_guard", true)
		_offer_contract()
	var available_boss_cycle: int = Expedition.boss_cycle_for_dread(dread)
	if available_boss_cycle > boss_cycle_spawned and not boss_spawned:
		boss_cycle_spawned = available_boss_cycle
		boss_spawned = true
		boss_defeated = false
		_spawn_enemy("barrow_knight", true)
		if boss_label != null:
			boss_label.text = "BARROW KNIGHT  -  DREAD CYCLE %d" % available_boss_cycle
	var ordinary_count: int = 0
	for enemy: EnemyState in enemies:
		if not enemy.special:
			ordinary_count += 1
	if ordinary_count >= MAX_ENEMIES:
		return
	var progress: float = clampf(dread / 100.0, 0.0, 1.0)
	var rate: float = lerpf(1.25, 5.0, progress) + float(Expedition.threat_tier(dread)) * 0.35
	spawn_accumulator += delta * rate
	while spawn_accumulator >= 1.0 and ordinary_count < MAX_ENEMIES:
		spawn_accumulator -= 1.0
		var wave_enemy: String = _choose_wave_enemy()
		if (active_curse == "black_moon" or relics.has("barrow_candle")) and dread > 40.0 and rng.randf() < (0.22 if relics.has("barrow_candle") else 0.16):
			wave_enemy = "blighted"
		_spawn_enemy(wave_enemy, false)
		ordinary_count += 1

func _choose_wave_enemy() -> String:
	var roll: float = rng.randf()
	var dread: float = _current_dread()
	if dread < 20.0:
		return "wolf" if roll < 0.58 else "raider"
	if dread < 46.0:
		return "wolf" if roll < 0.32 else ("raider" if roll < 0.72 else "archer")
	if dread < 72.0:
		return "crow" if roll < 0.20 else ("archer" if roll < 0.40 else ("reaver" if roll < 0.62 else "raider"))
	return "blighted" if roll < 0.32 else ("reaver" if roll < 0.54 else ("crow" if roll < 0.73 else "archer"))

func _choose_objective() -> String:
	var ids: Array[String] = []
	for objective_id: String in GameContent.OBJECTIVES:
		ids.append(objective_id)
	return ids[rng.randi_range(0, ids.size() - 1)] if not ids.is_empty() else "night_watch"

func _update_objective(delta: float) -> void:
	if not contract_id.is_empty() and not contract_complete:
		var contract: Dictionary = GameContent.CONTRACTS.get(contract_id, {})
		if String(contract.get("kind", "")) == "survive":
			contract_progress += delta
			if contract_progress >= contract_target:
				contract_complete = true
				run_score += int(contract.get("reward", 0))
				_add_float_text(player_position + Vector2(0.0, -44.0), "CONTRACT COMPLETE", AMBER)
	if objective_complete or not GameContent.OBJECTIVES.has(objective_id):
		return
	var objective: Dictionary = GameContent.OBJECTIVES[objective_id]
	if String(objective.kind) == "survive":
		objective_progress = run_elapsed
	if objective_progress >= float(objective.get("target", 1.0)):
		objective_complete = true
		run_score += int(objective.get("reward", 0))
		_add_float_text(player_position + Vector2(0.0, -30.0), "OBJECTIVE COMPLETE", AMBER)

func _spawn_enemy(enemy_id: String, special: bool) -> void:
	if special:
		var specials: int = 0
		for existing: EnemyState in enemies:
			if existing.special:
				specials += 1
		if specials >= MAX_SPECIALS:
			return
	var enemy: EnemyState = enemy_pool.pop_back() if not enemy_pool.is_empty() else EnemyState.new()
	_configure_enemy_state(enemy, enemy_id, special, _current_dread())
	enemy.position = _random_edge_position(enemy.radius)
	enemies.append(enemy)

func _configure_enemy_state(enemy: EnemyState, enemy_id: String, special: bool, dread: float) -> void:
	var definition: Dictionary = GameContent.ENEMIES[enemy_id]
	var curse: Dictionary = _curse_definition()
	enemy.uid = next_enemy_uid
	next_enemy_uid += 1
	enemy.id = enemy_id
	enemy.health = float(definition.health) * Expedition.enemy_health_multiplier(dread) * float(curse.get("health", 1.0))
	enemy.max_health = enemy.health
	enemy.speed = float(definition.speed)
	enemy.damage = float(definition.damage) * Expedition.enemy_damage_multiplier(dread) * float(curse.get("damage", 1.0))
	enemy.xp = int(definition.xp)
	enemy.radius = float(definition.radius)
	enemy.color = definition.color
	enemy.kind = String(definition.kind)
	enemy.touch_cooldown = 0.0
	enemy.attack_cooldown = rng.randf_range(0.3, 1.2)
	enemy.stagger = 0.0
	enemy.special = special
	enemy.bleed_timer = 0.0
	enemy.bleed_damage = 0.0
	enemy.bleed_ticks = 0
	enemy.scorch_timer = 0.0
	enemy.scorch_damage = 0.0
	enemy.scorch_ticks = 0
	enemy.poison_timer = 0.0
	enemy.poison_damage = 0.0
	enemy.poison_ticks = 0
	enemy.mark_timer = 0.0
	enemy.pin_timer = 0.0
	enemy.wander_direction = Vector2.ZERO
	enemy.wander_timer = 0.0
	enemy.dispersing = false
	enemy.path_check_timer = 0.0
	enemy.has_direct_path = true
	enemy.last_hit_critical = false

func _random_edge_position(radius: float = 10.0) -> Vector2:
	var visible: Rect2 = _visible_world_rect()
	var spawn_bounds: Rect2 = visible.grow(ENEMY_SPAWN_VIEW_MARGIN)
	var town_exclusion: Rect2 = _enemy_town_exclusion_rect()
	var sides: Array[int] = []
	if spawn_bounds.position.x >= 8.0:
		sides.append(0)
	if spawn_bounds.end.x <= world_size.x - 8.0:
		sides.append(1)
	if spawn_bounds.position.y >= 8.0:
		sides.append(2)
	if spawn_bounds.end.y <= world_size.y - 8.0:
		sides.append(3)
	if sides.is_empty():
		# At least one horizontal side is available in the expanded field.
		sides.append(0 if visible.get_center().x > world_size.x * 0.5 else 1)
	var result: Vector2 = visible.get_center()
	for _attempt: int in 48:
		var side: int = sides[rng.randi_range(0, sides.size() - 1)]
		result = _edge_spawn_candidate(side, spawn_bounds, town_exclusion, rng.randf())
		if not _enemy_position_blocked(result, radius) and not _point_hits_refuge_forest(result, radius):
			return result
	# A deterministic edge scan guarantees a valid fallback when random samples
	# repeatedly land in thorn cells, forest canopies, or another blocker.
	for side: int in sides:
		for slot: int in 33:
			result = _edge_spawn_candidate(side, spawn_bounds, town_exclusion, float(slot) / 32.0)
			if not _enemy_position_blocked(result, radius) and not _point_hits_refuge_forest(result, radius):
				return result
	return result


func _edge_spawn_candidate(side: int, spawn_bounds: Rect2, town_exclusion: Rect2, edge_ratio: float) -> Vector2:
	var result: Vector2
	match side:
		0: result = Vector2(spawn_bounds.position.x, lerpf(spawn_bounds.position.y, spawn_bounds.end.y, edge_ratio))
		1: result = Vector2(spawn_bounds.end.x, lerpf(spawn_bounds.position.y, spawn_bounds.end.y, edge_ratio))
		2: result = Vector2(lerpf(spawn_bounds.position.x, spawn_bounds.end.x, edge_ratio), spawn_bounds.position.y)
		_: result = Vector2(lerpf(spawn_bounds.position.x, spawn_bounds.end.x, edge_ratio), spawn_bounds.end.y)
	# A large restored town can overlap the camera edge after the world gains
	# its surrounding margins. Push a selected edge spawn beyond the painted
	# town footprint instead of allowing an enemy to materialize inside it.
	if town_exclusion.has_point(result):
		if side == 0:
			result.x = town_exclusion.position.x - ENEMY_SPAWN_VIEW_MARGIN
		elif side == 1:
			result.x = town_exclusion.end.x + ENEMY_SPAWN_VIEW_MARGIN
		elif side == 2:
			result.y = town_exclusion.position.y - ENEMY_SPAWN_VIEW_MARGIN
		else:
			result.y = town_exclusion.end.y + ENEMY_SPAWN_VIEW_MARGIN
	result.x = clampf(result.x, 8.0, world_size.x - 8.0)
	result.y = clampf(result.y, 8.0, world_size.y - 8.0)
	return result
