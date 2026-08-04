extends "res://scenes/actors/enemies/enemy_controller.gd"


func _add_float_text(position: Vector2, text: String, color: Color) -> void:
	if float_texts.size() >= MAX_FLOAT_TEXTS:
		return
	var item: FloatTextState = FloatTextState.new()
	item.position = position
	item.text = text
	item.color = color
	float_texts.append(item)


func _add_effect(position: Vector2, radius: float, color: Color, kind: String, direction: Vector2 = Vector2.RIGHT) -> void:
	if effects.size() >= floori(MAX_EFFECTS * float(save.settings.effect_density)):
		return
	var effect: EffectState = EffectState.new()
	effect.position = position
	effect.radius = radius
	effect.color = color
	effect.kind = kind
	effect.direction = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	effects.append(effect)


func _update_projectiles(delta: float) -> void:
	for projectile: ProjectileState in projectiles.duplicate():
		var previous_position: Vector2 = projectile.position
		if projectile.orbiting:
			projectile.orbit_angle += projectile.orbit_speed * delta
			projectile.position = player_position + Vector2.RIGHT.rotated(projectile.orbit_angle) * projectile.orbit_radius
		elif projectile.returning and projectile.return_delay >= 0.0:
			projectile.return_delay -= delta
			if projectile.return_delay <= 0.0:
				projectile.return_delay = -1.0
				projectile.hit_ids.clear()
				projectile.velocity = projectile.position.direction_to(player_position) * maxf(180.0, projectile.velocity.length())
		if projectile.faction == 0 and projectile.homing:
			var target: EnemyState = _find_enemy_by_uid(projectile.target_uid)
			if target == null:
				target = _find_nearest_enemy(projectile.position)
				if target != null:
					projectile.target_uid = target.uid
			if target != null:
				var desired: Vector2 = projectile.position.direction_to(target.position) * projectile.velocity.length()
				projectile.velocity = projectile.velocity.lerp(desired, minf(1.0, delta * 4.5))
		if not projectile.orbiting:
			projectile.position += projectile.velocity * delta
		projectile.life -= delta
		# Projectiles use a swept blocker test so arrows, stones and arcane shots
		# cannot tunnel through a fence, structure, tree, thorn patch or ruin
		# between frames. Obstacles consume the shot without dealing actor damage.
		var block_point: Vector2 = _projectile_block_point(previous_position, projectile.position, projectile.radius)
		if block_point.is_finite():
			if _resolve_projectile_environment_hit(projectile, previous_position, block_point):
				continue
			_recycle_projectile(projectile)
			continue
		if projectile.faction == 0:
			for enemy: EnemyState in _nearby_enemies(projectile.position):
				if projectile.hit_ids.has(enemy.uid):
					continue
				if enemy.position.distance_squared_to(projectile.position) <= pow(enemy.radius + projectile.radius, 2.0):
					projectile.hit_ids[enemy.uid] = true
					if projectile.splash_radius > 0.0:
						for splash_enemy: EnemyState in enemies.duplicate():
							if splash_enemy.position.distance_to(projectile.position) <= projectile.splash_radius + splash_enemy.radius:
								_damage_enemy(splash_enemy, projectile.damage, false, projectile.status, projectile.kind)
						if projectile.kind == "witchfire" and active_doctrine == "hedge_alchemist":
							_spawn_ember_zone(projectile.position, projectile.damage * 0.25)
						_add_effect(projectile.position, projectile.splash_radius, projectile.color, "ring")
						projectile.pierce = 0
					else:
						_damage_enemy(enemy, projectile.damage, projectile.kind == "spear", projectile.status, projectile.kind)
						projectile.pierce -= 1
					if projectile.pierce <= 0:
						break
		else:
			if player_position.distance_squared_to(projectile.position) <= pow(11.0 + projectile.radius, 2.0):
				_damage_player(projectile.damage)
				projectile.pierce = 0
		if projectile.life <= 0.0 or projectile.pierce <= 0 or not _visible_world_rect().grow(120.0).has_point(projectile.position):
			_recycle_projectile(projectile)

func _projectile_path_blocked(from_position: Vector2, to_position: Vector2, radius: float) -> bool:
	return _projectile_block_point(from_position, to_position, radius).is_finite()

func _projectile_block_point(from_position: Vector2, to_position: Vector2, radius: float) -> Vector2:
	var distance: float = from_position.distance_to(to_position)
	# Sample at no more than roughly one projectile diameter so larger stones
	# and embers cannot skip a thin post or wall between frames.
	var step_size: float = clampf(radius * 1.5, 4.0, 8.0)
	var steps: int = maxi(1, ceili(distance / step_size))
	for step: int in range(1, steps + 1):
		var sample: Vector2 = from_position.lerp(to_position, float(step) / float(steps))
		if _run_position_blocked(sample):
			return sample
	return Vector2(NAN, NAN)

func _resolve_projectile_environment_hit(projectile: ProjectileState, previous_position: Vector2, block_point: Vector2) -> bool:
	if projectile.faction != 0:
		return false
	var target_tags: Array[String] = _environment_tags_at(block_point)
	var interactions: Array[Dictionary] = EnvironmentInteractions.resolve(projectile.source_tags, target_tags)
	for interaction: Dictionary in interactions:
		var results: Array = interaction.get("result", [])
		if "broken" in results:
			var cell: Vector2i = _region_cell_at(block_point)
			environment_states[str(cell)] = {"cell": cell, "results": ["broken"], "remaining": 6.0, "radius": 32.0}
			projectile.position = block_point + projectile.velocity.normalized() * 9.0
			return true
		if "ricochet" in results and projectile.ricochets > 0:
			projectile.ricochets -= 1
			var x_blocked: bool = _run_position_blocked(Vector2(block_point.x, previous_position.y))
			var y_blocked: bool = _run_position_blocked(Vector2(previous_position.x, block_point.y))
			if x_blocked and not y_blocked:
				projectile.velocity.x *= -1.0
			elif y_blocked and not x_blocked:
				projectile.velocity.y *= -1.0
			else:
				projectile.velocity *= -1.0
			projectile.position = previous_position + projectile.velocity.normalized() * 4.0
			projectile.damage *= 1.08
			if _training_node_modifier("tainted_quarry", "ricochet_bleed_chance") > 0.0 and rng.randf() <= _training_node_modifier("tainted_quarry", "ricochet_bleed_chance"):
				projectile.status = "bleed"
			_add_effect(block_point, 9.0, projectile.color, "spark")
			return true
	return false

func _update_traps(delta: float) -> void:
	for trap: TrapState in traps.duplicate():
		trap.life -= delta
		trap.tick -= delta
		if trap.tick <= 0.0:
			trap.tick = 0.55
			for enemy: EnemyState in enemies.duplicate():
				if enemy.position.distance_to(trap.position) <= trap.radius + enemy.radius:
					var trap_status: String = trap.status if not trap.status.is_empty() else ("scorch" if trap.kind == "ember" else ("poison" if trap.kind == "poison" else ""))
					var trap_source: String = trap.source_ability if not trap.source_ability.is_empty() else ("fire_nova" if trap.kind == "ember" else ("poison_flask" if trap.kind == "poison" else "ground_slam"))
					_damage_enemy(enemy, trap.damage, false, trap_status, trap_source)
					if trap.kind == "caltrops" and enemies.has(enemy):
						enemy.stagger = maxf(enemy.stagger, 0.32 + _weapon_rank_total("caltrops", "stagger"))
		if trap.life <= 0.0:
			traps.erase(trap)

func _spawn_ember_zone(position: Vector2, damage: float) -> void:
	if traps.size() >= 16:
		return
	var zone: TrapState = TrapState.new()
	zone.position = position
	zone.radius = 32.0
	zone.damage = damage
	zone.life = 2.4
	zone.tick = 0.55
	zone.kind = "ember"
	traps.append(zone)

func _update_hazards(delta: float) -> void:
	for hazard: HazardState in hazards.duplicate():
		hazard.life -= delta
		hazard.warning -= delta
		if hazard.warning <= 0.0 and not hazard.triggered:
			hazard.triggered = true
			if player_position.distance_to(hazard.position) <= hazard.radius + 10.0:
				_damage_player(hazard.damage)
			_add_effect(hazard.position, hazard.radius, FOLKLORE, "ring")
		if hazard.life <= 0.0:
			hazards.erase(hazard)

func _update_pickups(delta: float) -> void:
	for pickup: PickupState in pickups.duplicate():
		var distance: float = pickup.position.distance_to(player_position)
		if distance < pickup_radius * 2.0:
			pickup.velocity = pickup.position.direction_to(player_position) * lerpf(70.0, 290.0, 1.0 - distance / (pickup_radius * 2.0))
		pickup.position += pickup.velocity * delta
		if distance <= 15.0:
			run_xp += pickup.value
			_play_sfx("pickup", 0.12)
			_recycle_pickup(pickup)
	while run_xp >= next_xp and not choosing_upgrade:
		run_xp -= next_xp
		run_level += 1
		next_xp = 12 + run_level * 7
		_show_upgrade_choices()

func _update_feedback(delta: float) -> void:
	for item: FloatTextState in float_texts.duplicate():
		item.life -= delta
		item.position.y -= 22.0 * delta
		if item.life <= 0.0:
			float_texts.erase(item)
	for effect: EffectState in effects.duplicate():
		effect.life -= delta
		if effect.life <= 0.0:
			effects.erase(effect)

func _damage_enemy(enemy: EnemyState, raw_damage: float, melee: bool, status: String = "", source_weapon: String = "") -> void:
	if not enemies.has(enemy):
		return
	var damage: float = raw_damage
	var source_definition: Dictionary = TrainingContent.abilities().get(source_weapon, {})
	var source_tags: Array = source_definition.get("tags", [])
	var hit_key: String = "%d:%s" % [enemy.uid, source_weapon]
	var previous_hits: int = int(repeated_hit_counts.get(hit_key, 0))
	repeated_hit_counts[hit_key] = previous_hits + 1
	if previous_hits == 0:
		damage *= 1.0 + _training_total("first_hit_damage")
	elif _training_total("repeat_loss") < 0.0:
		damage *= 1.0 + maxf(_training_total("repeat_loss_cap"), _training_total("repeat_loss") * float(previous_hits))
	if melee:
		var facing_dot: float = last_move_vector.normalized().dot(player_position.direction_to(enemy.position)) if last_move_vector.length_squared() > 0.01 else 1.0
		damage *= 1.0 + (_training_total("frontal_damage") if facing_dot >= 0.0 else _training_total("rear_damage"))
		if player_barrier > 0.0:
			damage *= 1.0 + _training_total("barrier_melee_damage")
	if "heavy" in source_tags:
		damage *= 1.0 + _training_total("heavy_damage")
		var consumable_bleeds: int = mini(int(_training_total("bleed_consume_limit")), combat_statuses.stacks_for(enemy.uid, "bleed"))
		if enemy.kind == "boss":
			consumable_bleeds = mini(consumable_bleeds, combat_statuses.stacks_for(enemy.uid, "bleed") / 2)
		if consumable_bleeds > 0:
			damage *= 1.0 + float(consumable_bleeds) * _training_total("bleed_consume_damage")
			combat_statuses.consume_stacks(enemy.uid, "bleed", consumable_bleeds)
	if "rapid" in source_tags:
		damage *= 1.0 + _training_total("rapid_damage")
	if enemy.special or enemy.kind == "boss":
		damage *= 1.0 + _technique_total("elite_damage") + _equipment_total("elite_damage") + _training_total("elite_damage")
	if enemy.kind == "shield" and not melee:
		damage *= 0.65
	var supernatural: bool = enemy.id in ["blighted", "grave_guard", "barrow_knight"]
	if supernatural:
		damage *= 1.0 + _doctrine_total("supernatural_damage")
	else:
		damage *= 1.0 + _doctrine_total("ordinary_damage")
	if combat_statuses.has(enemy.uid, "mark"):
		damage *= 1.15 + _training_total("marked_damage")
	if combat_statuses.has(enemy.uid, "poison"):
		damage *= 1.0 + _training_total("poisoned_damage")
	if combat_statuses.has(enemy.uid, "burn"):
		damage *= 1.0 + _training_total("burning_damage")
	if combat_statuses.has(enemy.uid, "chill"):
		damage *= 1.0 + _training_total("chilled_damage")
	if combat_statuses.has(enemy.uid, "shock"):
		damage *= 1.0 + _training_total("shocked_damage")
	var distance_to_player: float = enemy.position.distance_to(player_position)
	if distance_to_player > 192.0:
		damage *= 1.0 + _training_total("distant_damage") + _doctrine_total("distant_damage")
	elif distance_to_player < 72.0:
		damage *= 1.0 + _doctrine_total("adjacent_damage") + _training_total("close_damage")
	if combat_statuses.count_for(enemy.uid) >= 2:
		damage *= 1.0 + _training_total("multi_status_damage")
	if enemy.health <= enemy.max_health * 0.25:
		damage *= 1.0 + _training_total("execution_damage")
		if player_move_vector.length_squared() > 0.01:
			damage *= 1.0 + _training_total("moving_execution_damage")
	if player_hp <= player_max_hp * 0.30:
		damage *= 1.0 + _training_total("low_health_damage")
	if not melee and post_mobility_timer > 0.0:
		damage *= 1.0 + _training_total("mobility_projectile_damage")
	var elemental_source: bool = "fire" in source_tags or "frost" in source_tags or "lightning" in source_tags or source_weapon in ["fire_nova", "frost_ring", "chain_lightning"]
	if elemental_source and combat_statuses.count_for(enemy.uid) < 2:
		damage *= 1.0 + _training_total("single_element_damage")
	var situational_critical: float = 0.0
	if enemy.health >= enemy.max_health - 0.01:
		situational_critical += _training_total("full_health_critical")
	if distance_to_player < 96.0 and not melee:
		situational_critical += _training_total("close_critical")
	if post_mobility_timer > 0.0:
		situational_critical += _training_total("mobility_critical")
	if duelist_momentum >= 6:
		situational_critical += _doctrine_total("momentum_crit")
	var critical: bool = rng.randf() < CombatStats.critical_chance(maxf(0.0, critical_chance - CombatStats.CRITICAL_CHANCE_BASE + situational_critical))
	if critical:
		damage *= CombatStats.critical_damage(_technique_total("critical_damage") + _equipment_total("critical_damage") + _run_boon_total("critical_damage") + _doctrine_total("critical_damage"))
		if enemy.health <= enemy.max_health * 0.25:
			damage *= 1.0 + _training_total("low_health_critical_damage")
		if not melee and _training_node_modifier("predators_focus", "mark_duration") > 0.0:
			_apply_combat_status(enemy, "mark", source_weapon, damage)
	enemy.last_hit_critical = critical
	enemy.health -= damage
	if "blade" in source_tags:
		blade_hit_count += 1
		var blade_interval: int = int(_training_node_modifier("serrated_rhythm", "blade_hit_interval"))
		if blade_interval > 0 and blade_hit_count % blade_interval == 0:
			_apply_combat_status(enemy, "bleed", source_weapon, damage)
	if critical and active_doctrines.has("hexblade") and status.is_empty():
		_apply_combat_status(enemy, ["burn", "chill", "shock"][rng.randi_range(0, 2)], source_weapon, damage)
	if active_doctrines.has("arcane_archer") and TrainingContent.school_for_ability(source_weapon) == "arcanist" and TrainingContent.abilities().get(source_weapon, {}).get("category", "") == "technique":
		_apply_combat_status(enemy, "mark", source_weapon, damage)
	if melee and combat_statuses.has(enemy.uid, "bleed") and _doctrine_total("bleed_heal") > 0.0:
		var heal_cap: float = player_max_hp * 0.02
		var heal_amount: float = minf(player_max_hp * _doctrine_total("bleed_heal"), maxf(0.0, heal_cap - bloodbound_healed))
		if heal_amount > 0.0:
			bloodbound_healed += heal_amount
			_heal_player(heal_amount, false)
	enemy.stagger = maxf(enemy.stagger, 0.08 + stagger_power + _weapon_rank_total(source_weapon, "stagger") + _weapon_mastery_total(source_weapon, "stagger"))
	match status:
		"bleed", "poison", "scorch", "burn", "chill", "shock", "mark":
			_apply_combat_status(enemy, status, source_weapon, damage)
		"stagger":
			enemy.stagger = maxf(enemy.stagger, 0.30 + stagger_power + _weapon_rank_total(source_weapon, "stagger") + _weapon_mastery_total(source_weapon, "stagger"))
		"pin":
			enemy.pin_timer = maxf(enemy.pin_timer, 1.25)
	_add_float_text(enemy.position, str(roundi(damage)), AMBER if critical else PARCHMENT)
	if enemy.health <= 0.0:
		_kill_enemy(enemy)

func _damage_player(raw_damage: float) -> void:
	if rng.randf() < minf(0.15, maxf(0.0, _training_total("evasion"))):
		_add_float_text(player_position + Vector2(0.0, -18.0), "EVADE", PARCHMENT)
		return
	time_since_player_damage = 0.0
	if player_barrier > 0.0:
		var absorbed: float = minf(player_barrier, raw_damage)
		player_barrier -= absorbed
		raw_damage -= absorbed
		if absorbed > 0.0 and resonant_guard_cooldown <= 0.0 and _training_node_modifier("resonant_guard", "barrier_cooldown_reduction") > 0.0:
			for technique_id: String in technique_timers:
				technique_timers[technique_id] = maxf(0.0, float(technique_timers[technique_id]) - _training_node_modifier("resonant_guard", "barrier_cooldown_reduction"))
			resonant_guard_cooldown = maxf(0.1, _training_node_modifier("resonant_guard", "cooldown"))
		if raw_damage <= 0.0:
			return
	var guard_bonus: float = _technique_total("guard_strength") + _equipment_total("guard_strength") + _class_total("guard_strength") + _doctrine_total("guard_strength")
	var effective_armor: float = player_armor
	if player_hp <= player_max_hp * 0.30:
		effective_armor += _training_total("low_health_armor")
	if player_move_vector.length() < 0.5:
		effective_armor += _training_total("slow_armor")
	var damage: float = CombatStats.damage_after_armor(raw_damage, effective_armor)
	if duelist_momentum >= 6:
		damage *= 1.0 - _doctrine_total("momentum_reduction")
	if technique_damage_reduction_timer > 0.0:
		damage *= 1.0 - _doctrine_total("vanguard_technique_damage_reduction")
	if guard_timer > 0.0:
		var guard_reduction: float = clampf(0.70 + minf(0.20, guard_bonus), 0.0, 0.90)
		damage = maxf(1.0, damage * (1.0 - guard_reduction))
	player_hp -= damage
	if vanishing_step_cooldown <= 0.0 and raw_damage >= player_max_hp * _training_node_modifier("vanishing_step", "damage_threshold") and _training_node_modifier("vanishing_step", "movement_burst") > 0.0:
		movement_burst_timer = maxf(movement_burst_timer, _training_node_modifier("vanishing_step", "burst_duration"))
		vanishing_step_cooldown = maxf(0.1, _training_node_modifier("vanishing_step", "cooldown"))
	if toxic_blood_cooldown <= 0.0 and _training_node_modifier("toxic_blood", "poison_burst") > 0.0:
		toxic_blood_cooldown = maxf(0.1, _training_node_modifier("toxic_blood", "cooldown"))
		_damage_training_area(player_position, 58.0, 8.0 * _training_node_modifier("toxic_blood", "poison_burst"), false, "poison", "toxic_blood")
	if not second_wind_used and player_hp > 0.0 and player_hp <= player_max_hp * 0.30 and _technique_total("second_wind") > 0.0:
		second_wind_used = true
		_heal_player(_technique_total("second_wind"))
		_add_float_text(player_position + Vector2(0.0, -24.0), "SECOND WIND", FOLKLORE.lightened(0.2))
	_play_sfx("hurt", 0.16)
	shake_strength = maxf(shake_strength, 3.5 * float(save.settings.effect_density))
	_add_float_text(player_position + Vector2(0.0, -18.0), "-" + str(roundi(damage)), BLOOD.lightened(0.25))

func _kill_enemy(enemy: EnemyState) -> void:
	if not enemies.has(enemy):
		return
	run_kills += 1
	run_score += 2
	if not objective_complete and GameContent.OBJECTIVES.has(objective_id):
		var objective: Dictionary = GameContent.OBJECTIVES[objective_id]
		if String(objective.kind) == "kills" and not enemy.special:
			objective_progress += 1.0
		elif String(objective.kind) == "elite" and enemy.special and enemy.kind != "boss":
			objective_progress += 1.0
		if objective_progress >= float(objective.get("target", 1.0)):
			objective_complete = true
			run_score += int(objective.get("reward", 0))
	if not contract_id.is_empty() and not contract_complete:
		var contract: Dictionary = GameContent.CONTRACTS.get(contract_id, {})
		if String(contract.get("kind", "")) == "elite_kill" and enemy.special and enemy.kind != "boss":
			contract_progress += 1.0
		elif String(contract.get("kind", "")) == "reaver_kills" and enemy.id == "reaver":
			contract_progress += 1.0
		if String(contract.get("kind", "")) == "survive":
			contract_progress = 0.0
		if contract_progress >= contract_target:
			contract_complete = true
			run_score += int(contract.get("reward", 0))
			_add_float_text(enemy.position, "CONTRACT COMPLETE", AMBER)
	if enemy.special:
		run_elites += 1 if enemy.kind != "boss" else 0
		run_score += 50
	if enemy.kind == "boss":
		boss_defeated = true
		boss_spawned = false
		run_bosses_defeated += 1
		run_boss_keys += 1
		run_score += 500
		if boss_label != null:
			boss_label.text = "THE BARROW IS QUIET"
	if enemy.special or enemy.kind == "boss":
		_roll_equipment_drop(enemy.kind == "boss")
	if combat_statuses.has(enemy.uid, "mark"):
		if _training_total("marked_cooldown_reduction") > 0.0:
			for technique_id: String in technique_timers:
				technique_timers[technique_id] = maxf(0.0, float(technique_timers[technique_id]) - _training_total("marked_cooldown_reduction"))
		var transfer_target: EnemyState
		var transfer_distance: float = INF
		if _training_total("mark_transfer") > 0.0 or _training_node_modifier("tainted_quarry", "marked_poison_stack") > 0.0:
			for candidate: EnemyState in enemies:
				if candidate == enemy:
					continue
				var candidate_distance: float = candidate.position.distance_squared_to(enemy.position)
				if candidate_distance < transfer_distance:
					transfer_distance = candidate_distance
					transfer_target = candidate
		if transfer_target != null:
			if _training_total("mark_transfer") > 0.0 and rng.randf() <= _training_total("mark_transfer"):
				combat_statuses.apply(transfer_target.uid, "mark", "hero", "mark_transfer", 1.0, 0.15, 8.0, 1, transfer_target.kind == "boss", "ranger", [])
			if _training_node_modifier("tainted_quarry", "marked_poison_stack") > 0.0:
				combat_statuses.apply(transfer_target.uid, "poison", "hero", "tainted_quarry", 1.0, 1.0, -1.0, int(_training_node_modifier("tainted_quarry", "marked_poison_stack")), transfer_target.kind == "boss", "hybrid", ["moving_target"])
	if enemy.last_hit_critical and active_doctrines.has("nightblade"):
		for technique_id: String in technique_timers:
			if TrainingContent.school_for_ability(technique_id) == "shadow":
				technique_timers[technique_id] = maxf(0.0, float(technique_timers[technique_id]) * (1.0 - _doctrine_total("shadow_cooldown_on_crit_kill")))
	if war_cry_timer > 0.0 and _ability_progress("war_cry", int(techniques.get("war_cry", 0))).get("stats", {}).has("kill_extension"):
		var cry_stats: Dictionary = Dictionary(_ability_progress("war_cry", int(techniques.get("war_cry", 0))).get("stats", {}))
		war_cry_timer = minf(float(cry_stats.get("max_extension", 6.0)), war_cry_timer + float(cry_stats.get("kill_extension", 0.75)))
	if combat_statuses.has(enemy.uid, "poison") and _training_total("poison_spread_potency") > 0.0:
		for nearby: EnemyState in enemies:
			if nearby != enemy and nearby.position.distance_to(enemy.position) <= 80.0:
				combat_statuses.apply(nearby.uid, "poison", "hero", "toxic_momentum", 1.0, _training_total("poison_spread_potency"), -1.0, 1, nearby.kind == "boss", "shadow", ["moving_target"])
	var shatter_death: bool = enemy.pin_timer > 0.0 and _training_node_modifier("shatter", "freeze_explosion_power") > 0.0
	combat_statuses.remove_target(enemy.uid)
	elemental_echo_cooldowns.erase(enemy.uid)
	elemental_conduit_cooldowns.erase(enemy.uid)
	volatile_mixture_cooldowns.erase(enemy.uid)
	for hit_key_value: Variant in repeated_hit_counts.keys().duplicate():
		if String(hit_key_value).begins_with("%d:" % enemy.uid):
			repeated_hit_counts.erase(hit_key_value)
	_spawn_pickup(enemy.position, enemy.xp)
	_add_effect(enemy.position, enemy.radius * 1.4, BLOOD if enemy.kind != "boss" else FOLKLORE, "burst")
	if enemy.special and relics.size() < 3:
		_show_relic_choices()
	enemies.erase(enemy)
	enemy_pool.append(enemy)
	if shatter_death:
		_damage_training_area(enemy.position, 56.0, 20.0 * _training_node_modifier("shatter", "freeze_explosion_power") * damage_multiplier, false, "chill", "shatter")

func _roll_equipment_drop(boss_drop: bool) -> void:
	var loot_bonus: float = GameContent.permanent_loot_bonus(save.profile.get("skill_tree", {})) + _technique_total("loot_quality") + _equipment_total("loot_quality")
	if not boss_drop and run_elites > 1 and rng.randf() > 0.72 + loot_bonus:
		return
	var uid: int = int(save.profile.get("next_item_uid", 1))
	var item: Dictionary = GameRules.generate_equipment(rng.randi(), boss_drop, loot_bonus, uid)
	save.profile.next_item_uid = uid + 1
	run_loot.append(item)
	var rarity: Dictionary = GameContent.RARITIES[String(item.rarity)]
	_add_float_text(player_position + Vector2(0.0, -34.0), "%s GEAR" % String(rarity.name).to_upper(), rarity.color)

func _spawn_pickup(position: Vector2, value: int) -> void:
	if value <= 0:
		return
	if active_curse == "thin_rations" and rng.randf() < 0.18:
		return
	if pickups.size() >= MAX_PICKUPS:
		var nearest: PickupState
		var nearest_distance: float = INF
		for existing: PickupState in pickups:
			var distance: float = existing.position.distance_squared_to(position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = existing
		if nearest != null:
			nearest.value += value
		return
	var pickup: PickupState = pickup_pool.pop_back() if not pickup_pool.is_empty() else PickupState.new()
	pickup.position = position
	pickup.value = value
	pickup.velocity = Vector2.ZERO
	pickups.append(pickup)

func _recycle_projectile(projectile: ProjectileState) -> void:
	if projectiles.has(projectile):
		projectiles.erase(projectile)
		projectile_pool.append(projectile)

func _recycle_pickup(pickup: PickupState) -> void:
	if pickups.has(pickup):
		pickups.erase(pickup)
		pickup_pool.append(pickup)

func _find_nearest_enemy(from: Vector2) -> EnemyState:
	var result: EnemyState
	var best: float = INF
	for enemy: EnemyState in enemies:
		var distance: float = from.distance_squared_to(enemy.position)
		if distance < best:
			best = distance
			result = enemy
	return result

func _find_nearest_enemies(from: Vector2, count: int) -> Array[EnemyState]:
	var result: Array[EnemyState] = []
	var selected: Dictionary = {}
	for target_index: int in mini(count, enemies.size()):
		var nearest: EnemyState
		var best: float = INF
		for enemy: EnemyState in enemies:
			if selected.has(enemy.uid):
				continue
			var distance: float = from.distance_squared_to(enemy.position)
			if distance < best:
				best = distance
				nearest = enemy
		if nearest == null:
			break
		selected[nearest.uid] = true
		result.append(nearest)
	return result

func _find_enemy_by_uid(uid: int) -> EnemyState:
	if uid < 0:
		return null
	for enemy: EnemyState in enemies:
		if enemy.uid == uid:
			return enemy
	return null

func _guard_step() -> void:
	if screen != Screen.RUN or run_paused or choosing_upgrade or guard_cooldown > 0.0:
		return
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	if direction.length_squared() < 0.01:
		direction = last_move_vector
	var remaining: float = 42.0
	var step_direction: Vector2 = direction.normalized()
	while remaining > 0.0:
		var distance: float = minf(6.0, remaining)
		var candidate: Vector2 = player_position + step_direction * distance
		if _run_position_blocked(candidate):
			break
		player_position = candidate
		remaining -= distance
	player_position.x = clampf(player_position.x, 18.0, world_size.x - 18.0)
	player_position.y = clampf(player_position.y, 18.0, world_size.y - 22.0)
	guard_cooldown = maxf(3.5, 6.0 - _relic_total("guard_cooldown") - _equipment_total("guard_cooldown"))
	guard_timer = 0.25 + _class_total("guard_duration") + _doctrine_total("guard_duration")
	guard_empowered = true
	_play_sfx("guard")
	_add_effect(player_position, 26.0, PARCHMENT_DARK, "burst")
	var riposte_damage: float = _technique_total("guard_damage") + _equipment_total("guard_damage")
	if riposte_damage > 0.0:
		_add_effect(player_position, 62.0, AMBER.lightened(0.1), "ring")
		for enemy: EnemyState in enemies.duplicate():
			if enemy.position.distance_to(player_position) <= 62.0 + enemy.radius:
				_damage_enemy(enemy, riposte_damage * damage_multiplier, true, "stagger")
