extends Control

const GameContent = preload("res://src/content.gd")
const GameRules = preload("res://src/rules.gd")
const SaveService = preload("res://src/save_service.gd")

enum Screen { CAMP, RUN, RESULTS, SETTINGS }

const RUN_SECONDS: float = 480.0
const BOSS_TIME: float = 420.0
const MAX_ENEMIES: int = 180
const MAX_SPECIALS: int = 20
const MAX_PROJECTILES: int = 120
const MAX_PICKUPS: int = 80
const MAX_FLOAT_TEXTS: int = 30
const MAX_EFFECTS: int = 60

const INK: Color = Color("171a1c")
const PARCHMENT: Color = Color("e2d2ac")
const PARCHMENT_DARK: Color = Color("bca77a")
const IRON: Color = Color("596268")
const BURGUNDY: Color = Color("713f45")
const AMBER: Color = Color("d38a36")
const FOLKLORE: Color = Color("78aaa2")
const BLOOD: Color = Color("873f3e")
const ACTOR_IDS: Array[String] = ["player", "wolf", "raider", "archer", "reaver", "blighted", "crow", "houndmaster", "grave_guard", "barrow_knight"]

class EnemyState:
	var uid: int = 0
	var id: String = ""
	var position: Vector2 = Vector2.ZERO
	var health: float = 1.0
	var max_health: float = 1.0
	var speed: float = 1.0
	var damage: float = 1.0
	var xp: int = 1
	var radius: float = 10.0
	var color: Color = Color.WHITE
	var kind: String = "raider"
	var touch_cooldown: float = 0.0
	var attack_cooldown: float = 0.0
	var stagger: float = 0.0
	var special: bool = false
	var bleed_timer: float = 0.0
	var bleed_damage: float = 0.0
	var scorch_timer: float = 0.0
	var scorch_damage: float = 0.0
	var pin_timer: float = 0.0

class ProjectileState:
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var damage: float = 1.0
	var radius: float = 4.0
	var life: float = 1.0
	var pierce: int = 1
	var faction: int = 0
	var color: Color = Color.WHITE
	var kind: String = "line"
	var splash_radius: float = 0.0
	var homing: bool = false
	var status: String = ""
	var hit_ids: Dictionary = {}

class PickupState:
	var position: Vector2 = Vector2.ZERO
	var value: int = 1
	var velocity: Vector2 = Vector2.ZERO

class TrapState:
	var position: Vector2 = Vector2.ZERO
	var radius: float = 30.0
	var damage: float = 5.0
	var life: float = 7.0
	var tick: float = 0.0

class HazardState:
	var position: Vector2 = Vector2.ZERO
	var radius: float = 40.0
	var warning: float = 0.8
	var life: float = 1.0
	var damage: float = 15.0
	var triggered: bool = false

class FloatTextState:
	var position: Vector2 = Vector2.ZERO
	var text: String = ""
	var color: Color = Color.WHITE
	var life: float = 0.7

class EffectState:
	var position: Vector2 = Vector2.ZERO
	var radius: float = 20.0
	var color: Color = Color.WHITE
	var life: float = 0.25
	var kind: String = "ring"
	var direction: Vector2 = Vector2.RIGHT

var screen: Screen = Screen.CAMP
var save: Dictionary = {}
var result_data: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var theme_main: Theme
var display_font: Font
var body_font: Font
var body_bold_font: Font
var camp_texture: Texture2D
var moor_texture: Texture2D
var ui_frame_texture: Texture2D
var actor_textures: Dictionary = {}
var actor_frames: Dictionary = {}
var ui_root: Control
var status_label: Label
var resource_label: Label
var hud_label: Label
var health_bar: ProgressBar
var boss_label: Label
var objective_label: Label
var pause_label: Label
var skill_button: Button
var pause_button: Button
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_streams: Dictionary = {}
var current_music: String = ""
var sfx_cursor: int = 0
var sfx_throttle: float = 0.0

var player_position: Vector2 = Vector2(195.0, 430.0)
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_speed: float = 122.0
var player_armor: float = 0.0
var damage_multiplier: float = 1.0
var cooldown_reduction: float = 0.0
var critical_chance: float = 0.05
var pickup_radius: float = 54.0
var stagger_power: float = 0.0
var projectile_bonus: int = 0
var guard_cooldown: float = 0.0
var guard_timer: float = 0.0
var guard_empowered: bool = false
var recovery_timer: float = 0.0
var player_attack_timer: float = 0.0
var player_attack_duration: float = 0.22
var player_attack_direction: Vector2 = Vector2.RIGHT
var player_attack_kind: String = ""
var player_attack_color: Color = Color.WHITE
var active_class: String = "warrior"
var active_doctrine: String = "shield_line"
var active_curse: String = "none"
var relics: Dictionary = {}
var contract_id: String = ""
var contract_progress: float = 0.0
var contract_target: float = 0.0
var contract_complete: bool = false
var objective_id: String = ""
var objective_progress: float = 0.0
var objective_complete: bool = false
var boss_phase: int = 0
var skill_tree_branch: int = 0
var inventory_page: int = 0
var selected_item_uid: String = ""
var second_wind_used: bool = false

var run_elapsed: float = 0.0
var run_level: int = 1
var run_xp: int = 0
var next_xp: int = 14
var run_kills: int = 0
var run_elites: int = 0
var run_score: int = 0
var boss_spawned: bool = false
var boss_defeated: bool = false
var elite_one_spawned: bool = false
var elite_two_spawned: bool = false
var run_paused: bool = false
var choosing_upgrade: bool = false
var run_seed: int = 0
var autosave_timer: float = 0.0
var hud_timer: float = 0.0
var spawn_accumulator: float = 0.0
var target_refresh: float = 0.0
var nearest_target: EnemyState
var next_enemy_uid: int = 1

var weapons: Dictionary = {}
var techniques: Dictionary = {}
var mastered: Dictionary = {}
var run_loot: Array[Dictionary] = []
var weapon_timers: Dictionary = {}
var enemies: Array[EnemyState] = []
var projectiles: Array[ProjectileState] = []
var pickups: Array[PickupState] = []
var traps: Array[TrapState] = []
var hazards: Array[HazardState] = []
var float_texts: Array[FloatTextState] = []
var effects: Array[EffectState] = []
var enemy_pool: Array[EnemyState] = []
var projectile_pool: Array[ProjectileState] = []
var pickup_pool: Array[PickupState] = []
var spatial_grid: Dictionary = {}

var joystick_touch_id: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_position: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO
var last_move_vector: Vector2 = Vector2.DOWN
var player_move_vector: Vector2 = Vector2.ZERO
var shake_strength: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	camp_texture = load("res://assets/backgrounds/camp.png")
	moor_texture = load("res://assets/backgrounds/moor.png")
	ui_frame_texture = load("res://assets/ui/company_ledger_512.png")
	_load_actor_textures()
	theme_main = _build_theme()
	save = SaveService.load_data()
	_setup_audio()
	_apply_offline_progress()
	_show_camp()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == Screen.RUN:
		run_paused = true
		_reset_movement_input()
		_snapshot_run()
		SaveService.save_data(save)

func _process(delta: float) -> void:
	if screen == Screen.RUN:
		if not run_paused and not choosing_upgrade:
			_process_run(minf(delta, 0.05))
		else:
			guard_cooldown = maxf(0.0, guard_cooldown - delta)
		queue_redraw()
	elif screen == Screen.CAMP:
		queue_redraw()

func _draw() -> void:
	var texture: Texture2D = moor_texture if screen in [Screen.RUN, Screen.RESULTS] else camp_texture
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
	if screen == Screen.RUN:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.18))
		_draw_run_world()
	elif screen == Screen.CAMP:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.28))
		_draw_camp_progress()
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.62))

func _input(event: InputEvent) -> void:
	if screen != Screen.RUN:
		return
	if choosing_upgrade or run_paused:
		# Touch release events can be consumed by the pause/upgrade UI. Clear the
		# joystick here as well so a run can never resume with a dead touch id.
		_reset_movement_input()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and joystick_touch_id < 0 and touch.position.y > size.y * 0.34 and not _point_over_action_button(touch.position):
			joystick_touch_id = touch.index
			joystick_origin = touch.position
			joystick_position = touch.position
			joystick_vector = Vector2.ZERO
		elif not touch.pressed and touch.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == joystick_touch_id:
			joystick_position = drag.position
			var offset: Vector2 = joystick_position - joystick_origin
			joystick_vector = offset.limit_length(46.0) / 46.0
	if event.is_action_pressed("guard_step"):
		_guard_step()

func _process_run(delta: float) -> void:
	sfx_throttle = maxf(0.0, sfx_throttle - delta)
	run_elapsed += delta
	autosave_timer += delta
	hud_timer += delta
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	guard_timer = maxf(0.0, guard_timer - delta)
	player_attack_timer = maxf(0.0, player_attack_timer - delta)
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	shake_offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength)) if bool(save.settings.screen_shake) else Vector2.ZERO
	_update_player(delta)
	_update_wave(delta)
	_update_objective(delta)
	_update_weapons(delta)
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
	elif run_elapsed >= RUN_SECONDS:
		_finish_run(boss_defeated)

func _update_player(delta: float) -> void:
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		last_move_vector = direction
	else:
		direction = Vector2.ZERO
	player_move_vector = direction
	player_position += direction * player_speed * delta
	player_position.x = clampf(player_position.x, 18.0, size.x - 18.0)
	player_position.y = clampf(player_position.y, 82.0, size.y - 22.0)
	var field_recovery: float = _technique_total("recovery") + _relic_total("health") * 0.05
	if field_recovery > 0.0:
		recovery_timer += delta
		if recovery_timer >= 6.0:
			recovery_timer -= 6.0
			player_hp = minf(player_max_hp, player_hp + field_recovery)

func _update_wave(delta: float) -> void:
	if not elite_one_spawned and run_elapsed >= 120.0:
		elite_one_spawned = true
		_spawn_enemy("houndmaster", true)
		_offer_contract()
	if not elite_two_spawned and run_elapsed >= 300.0:
		elite_two_spawned = true
		_spawn_enemy("grave_guard", true)
		_offer_contract()
	if not boss_spawned and run_elapsed >= BOSS_TIME:
		boss_spawned = true
		_spawn_enemy("barrow_knight", true)
		if boss_label != null:
			boss_label.text = "THE BARROW KNIGHT HAS RISEN"
	var ordinary_count: int = 0
	for enemy: EnemyState in enemies:
		if not enemy.special:
			ordinary_count += 1
	if ordinary_count >= MAX_ENEMIES:
		return
	var progress: float = clampf(run_elapsed / RUN_SECONDS, 0.0, 1.0)
	var rate: float = lerpf(1.25, 5.0, progress)
	spawn_accumulator += delta * rate
	while spawn_accumulator >= 1.0 and ordinary_count < MAX_ENEMIES:
		spawn_accumulator -= 1.0
		var wave_enemy: String = _choose_wave_enemy()
		if (active_curse == "black_moon" or relics.has("barrow_candle")) and run_elapsed > 180.0 and rng.randf() < (0.22 if relics.has("barrow_candle") else 0.16):
			wave_enemy = "blighted"
		_spawn_enemy(wave_enemy, false)
		ordinary_count += 1

func _choose_wave_enemy() -> String:
	var roll: float = rng.randf()
	if run_elapsed < 90.0:
		return "wolf" if roll < 0.58 else "raider"
	if run_elapsed < 210.0:
		return "wolf" if roll < 0.32 else ("raider" if roll < 0.72 else "archer")
	if run_elapsed < 330.0:
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
	var definition: Dictionary = GameContent.ENEMIES[enemy_id]
	var curse: Dictionary = _curse_definition()
	var enemy: EnemyState = enemy_pool.pop_back() if not enemy_pool.is_empty() else EnemyState.new()
	enemy.uid = next_enemy_uid
	next_enemy_uid += 1
	enemy.id = enemy_id
	enemy.position = _random_edge_position()
	var difficulty: float = 1.0 + (run_elapsed / RUN_SECONDS) * 1.8
	enemy.health = float(definition.health) * difficulty * float(curse.get("health", 1.0))
	enemy.max_health = enemy.health
	enemy.speed = float(definition.speed)
	enemy.damage = float(definition.damage) * (1.0 + (run_elapsed / RUN_SECONDS) * 0.5) * float(curse.get("damage", 1.0))
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
	enemy.scorch_timer = 0.0
	enemy.scorch_damage = 0.0
	enemy.pin_timer = 0.0
	enemies.append(enemy)

func _random_edge_position() -> Vector2:
	var margin: float = 28.0
	match rng.randi_range(0, 3):
		0: return Vector2(rng.randf_range(0.0, size.x), -margin)
		1: return Vector2(size.x + margin, rng.randf_range(78.0, size.y))
		2: return Vector2(rng.randf_range(0.0, size.x), size.y + margin)
		_: return Vector2(-margin, rng.randf_range(78.0, size.y))

func _update_weapons(delta: float) -> void:
	target_refresh -= delta
	if target_refresh <= 0.0:
		target_refresh = 0.1
		nearest_target = _find_nearest_enemy(player_position)
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = float(weapon_timers.get(weapon_id, 0.0)) - delta
		if float(weapon_timers[weapon_id]) <= 0.0 and nearest_target != null:
			_fire_weapon(weapon_id)

func _fire_weapon(weapon_id: String) -> void:
	var definition: Dictionary = GameContent.WEAPONS[weapon_id]
	var rank: int = int(weapons[weapon_id])
	var mastery: bool = bool(mastered.get(weapon_id, false))
	var category: String = String(definition.category)
	var category_cooldown: float = (_technique_total("melee_cooldown") + _equipment_total("melee_cooldown")) if category == "MELEE" else ((_technique_total("arcane_cooldown") + _equipment_total("arcane_cooldown")) if category == "ARCANE" else (_technique_total("ranged_cooldown") + _equipment_total("ranged_cooldown")))
	var cooldown: float = float(definition.cooldown) * (1.0 - minf(0.48, cooldown_reduction + category_cooldown + float(rank - 1) * 0.045))
	weapon_timers[weapon_id] = maxf(0.16, cooldown)
	_play_sfx("strike", 0.08)
	var direction: Vector2 = (nearest_target.position - player_position).normalized()
	var category_damage: float = (_technique_total("melee_damage") + _equipment_total("melee_damage")) if category == "MELEE" else ((_technique_total("arcane_damage") + _equipment_total("arcane_damage")) if category == "ARCANE" else (_technique_total("ranged_damage") + _equipment_total("ranged_damage")))
	var damage: float = float(definition.damage) * damage_multiplier * (1.0 + category_damage) * (1.0 + float(rank - 1) * 0.22) * (1.5 if mastery else 1.0)
	if category == "RANGED":
		damage *= 1.0 - minf(0.25, _relic_total("guard_cooldown") * 0.05)
	if category != "MELEE" and relics.has("fletched_pennant"):
		damage *= 0.92
	if active_doctrine == "pursuer" and last_move_vector.dot(direction) > 0.65:
		damage *= 1.16
	if player_hp <= player_max_hp * 0.5:
		damage *= 1.0 + _relic_total("wounded_damage")
	var area_scale: float = 1.0 + _technique_total("area") + (0.18 if mastery else 0.0)
	var pierce: int = int(definition.pierce) + int(_technique_total("pierce")) + (2 if mastery else 0)
	var behavior: String = String(definition.behavior)
	player_attack_direction = direction
	player_attack_kind = behavior
	player_attack_color = definition.color
	player_attack_duration = 0.28 if category == "MELEE" else 0.18
	player_attack_timer = player_attack_duration
	if behavior == "thrust":
		var thrust_reach: float = float(definition.radius) * area_scale + _technique_total("reach") + _equipment_total("reach")
		_add_effect(player_position + direction * 14.0, thrust_reach, definition.color, "thrust", direction)
		for enemy: EnemyState in enemies.duplicate():
			var offset: Vector2 = enemy.position - player_position
			var distance: float = offset.length()
			if distance <= thrust_reach + enemy.radius and distance > 0.1 and direction.dot(offset.normalized()) >= 0.42:
				_damage_enemy(enemy, damage, true, "bleed")
		if guard_empowered:
			guard_empowered = false
	elif behavior == "sweep":
		var sweep_radius: float = float(definition.radius) * area_scale
		_add_effect(player_position, sweep_radius, definition.color, "arc", direction)
		for enemy: EnemyState in enemies.duplicate():
			if enemy.position.distance_to(player_position) <= sweep_radius + enemy.radius:
				_damage_enemy(enemy, damage, true, "bleed")
		if guard_empowered:
			guard_empowered = false
	elif behavior == "trap":
		if traps.size() < 12:
			var trap: TrapState = TrapState.new()
			trap.position = player_position - last_move_vector * 22.0
			trap.radius = float(definition.radius) * area_scale
			trap.damage = damage
			trap.life = 6.0 + float(rank)
			traps.append(trap)
	elif behavior == "fan":
		var count: int = 3 + projectile_bonus + (1 if rank >= 4 else 0)
		for index: int in count:
			var angle: float = deg_to_rad(lerpf(-18.0, 18.0, 0.5 if count == 1 else float(index) / float(count - 1)))
			_spawn_player_projectile(weapon_id, direction.rotated(angle), damage, pierce, 0.0, "bleed")
	else:
		var arcane_bonus: int = int(_technique_total("arcane_projectiles")) if category == "ARCANE" else 0
		var count: int = 1 + projectile_bonus + arcane_bonus + (1 if mastery and weapon_id == "bow" else 0)
		for index: int in count:
			var spread: float = deg_to_rad(float(index - (count - 1) / 2.0) * 7.0)
			_spawn_player_projectile(weapon_id, direction.rotated(spread), damage, pierce, 18.0 * area_scale if behavior == "hex" else (42.0 * area_scale if behavior == "splash" else 0.0), "scorch" if behavior == "hex" else ("stagger" if behavior == "splash" else ("pin" if weapon_id == "bow" else "")))
		if guard_empowered and weapon_id == "spear":
			guard_empowered = false

func _spawn_player_projectile(weapon_id: String, direction: Vector2, damage: float, pierce: int, splash_radius: float, status: String = "") -> void:
	if projectiles.size() >= MAX_PROJECTILES:
		return
	var definition: Dictionary = GameContent.WEAPONS[weapon_id]
	var projectile: ProjectileState = projectile_pool.pop_back() if not projectile_pool.is_empty() else ProjectileState.new()
	projectile.position = player_position + direction * 12.0
	projectile.velocity = direction * float(definition.speed)
	projectile.damage = damage * (1.35 if guard_empowered and weapon_id == "spear" else 1.0)
	projectile.radius = float(definition.radius)
	projectile.life = 0.34 if weapon_id == "spear" else 1.45
	projectile.pierce = pierce
	projectile.faction = 0
	projectile.color = definition.color
	projectile.kind = weapon_id
	projectile.splash_radius = splash_radius
	projectile.homing = weapon_id == "witchfire"
	projectile.status = status
	projectile.hit_ids.clear()
	projectiles.append(projectile)

func _update_enemies(delta: float) -> void:
	for enemy: EnemyState in enemies.duplicate():
		enemy.touch_cooldown = maxf(0.0, enemy.touch_cooldown - delta)
		enemy.attack_cooldown -= delta
		enemy.stagger = maxf(0.0, enemy.stagger - delta)
		enemy.pin_timer = maxf(0.0, enemy.pin_timer - delta)
		enemy.bleed_timer -= delta
		enemy.scorch_timer -= delta
		if enemy.bleed_timer <= 0.0 and enemy.bleed_damage > 0.0:
			enemy.bleed_timer = 0.8
			_damage_enemy(enemy, enemy.bleed_damage, false)
		if enemy.scorch_timer <= 0.0 and enemy.scorch_damage > 0.0:
			enemy.scorch_timer = 0.65
			_damage_enemy(enemy, enemy.scorch_damage, false)
		var to_player: Vector2 = player_position - enemy.position
		var distance: float = to_player.length()
		var direction: Vector2 = to_player.normalized() if distance > 0.1 else Vector2.ZERO
		if enemy.kind == "archer" and distance < 235.0:
			if distance < 135.0:
				enemy.position -= direction * enemy.speed * 0.55 * delta
			if enemy.attack_cooldown <= 0.0:
				enemy.attack_cooldown = 2.25
				_spawn_enemy_bolt(enemy.position, direction, enemy.damage)
		else:
			var stagger_scale: float = 0.35 if enemy.stagger > 0.0 else (0.58 if enemy.pin_timer > 0.0 else 1.0)
			enemy.position += direction * enemy.speed * stagger_scale * delta
		if distance <= enemy.radius + 11.0 and enemy.touch_cooldown <= 0.0:
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
	projectile.status = ""
	projectile.hit_ids.clear()
	projectiles.append(projectile)

func _rebuild_spatial_grid() -> void:
	spatial_grid.clear()
	for enemy: EnemyState in enemies:
		var cell: Vector2i = Vector2i(floori(enemy.position.x / 48.0), floori(enemy.position.y / 48.0))
		if not spatial_grid.has(cell):
			spatial_grid[cell] = []
		spatial_grid[cell].append(enemy)

func _nearby_enemies(position: Vector2) -> Array[EnemyState]:
	var result: Array[EnemyState] = []
	var center: Vector2i = Vector2i(floori(position.x / 48.0), floori(position.y / 48.0))
	for x: int in range(center.x - 1, center.x + 2):
		for y: int in range(center.y - 1, center.y + 2):
			var cell: Vector2i = Vector2i(x, y)
			if spatial_grid.has(cell):
				for enemy: EnemyState in spatial_grid[cell]:
					result.append(enemy)
	return result

func _update_projectiles(delta: float) -> void:
	for projectile: ProjectileState in projectiles.duplicate():
		if projectile.faction == 0 and projectile.homing:
			var target: EnemyState = _find_nearest_enemy(projectile.position)
			if target != null:
				var desired: Vector2 = projectile.position.direction_to(target.position) * projectile.velocity.length()
				projectile.velocity = projectile.velocity.lerp(desired, minf(1.0, delta * 4.5))
		projectile.position += projectile.velocity * delta
		projectile.life -= delta
		if projectile.faction == 0:
			for enemy: EnemyState in _nearby_enemies(projectile.position):
				if projectile.hit_ids.has(enemy.uid):
					continue
				if enemy.position.distance_squared_to(projectile.position) <= pow(enemy.radius + projectile.radius, 2.0):
					projectile.hit_ids[enemy.uid] = true
					if projectile.splash_radius > 0.0:
						for splash_enemy: EnemyState in enemies.duplicate():
							if splash_enemy.position.distance_to(projectile.position) <= projectile.splash_radius + splash_enemy.radius:
								_damage_enemy(splash_enemy, projectile.damage, false, projectile.status)
						_add_effect(projectile.position, projectile.splash_radius, projectile.color, "ring")
						projectile.pierce = 0
					else:
						_damage_enemy(enemy, projectile.damage, projectile.kind == "spear", projectile.status)
						projectile.pierce -= 1
					if projectile.pierce <= 0:
						break
		else:
			if player_position.distance_squared_to(projectile.position) <= pow(11.0 + projectile.radius, 2.0):
				_damage_player(projectile.damage)
				projectile.pierce = 0
		if projectile.life <= 0.0 or projectile.pierce <= 0 or not Rect2(-80.0, -80.0, size.x + 160.0, size.y + 160.0).has_point(projectile.position):
			_recycle_projectile(projectile)

func _update_traps(delta: float) -> void:
	for trap: TrapState in traps.duplicate():
		trap.life -= delta
		trap.tick -= delta
		if trap.tick <= 0.0:
			trap.tick = 0.55
			for enemy: EnemyState in enemies.duplicate():
				if enemy.position.distance_to(trap.position) <= trap.radius + enemy.radius:
					_damage_enemy(enemy, trap.damage, false)
					enemy.stagger = maxf(enemy.stagger, 0.32)
		if trap.life <= 0.0:
			traps.erase(trap)

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

func _damage_enemy(enemy: EnemyState, raw_damage: float, melee: bool, status: String = "") -> void:
	if not enemies.has(enemy):
		return
	var damage: float = raw_damage
	if enemy.special or enemy.kind == "boss":
		damage *= 1.0 + _technique_total("elite_damage") + _equipment_total("elite_damage")
	if enemy.kind == "shield" and not melee:
		damage *= 0.65
	if active_doctrine == "grave_listener":
		if enemy.id in ["blighted", "grave_guard", "barrow_knight"]:
			damage *= 1.18
		elif is_equal_approx(enemy.health, enemy.max_health):
			damage *= 0.97
	var critical: bool = rng.randf() < critical_chance
	if critical:
		damage *= 1.75
	enemy.health -= damage
	enemy.stagger = maxf(enemy.stagger, 0.08 + stagger_power)
	match status:
		"bleed":
			enemy.bleed_damage = maxf(enemy.bleed_damage, damage * 0.18)
			enemy.bleed_timer = maxf(enemy.bleed_timer, 0.8)
		"scorch":
			enemy.scorch_damage = maxf(enemy.scorch_damage, damage * 0.24)
			enemy.scorch_timer = maxf(enemy.scorch_timer, 0.65)
		"pin":
			enemy.pin_timer = maxf(enemy.pin_timer, 1.25)
	_add_float_text(enemy.position, str(roundi(damage)), AMBER if critical else PARCHMENT)
	if enemy.health <= 0.0:
		_kill_enemy(enemy)

func _damage_player(raw_damage: float) -> void:
	var class_definition: Dictionary = GameContent.CLASSES.get(active_class, GameContent.CLASSES.warrior)
	var reduction: float = (0.70 + minf(0.15, _technique_total("guard") + float(class_definition.guard) + _doctrine_total("guard"))) if guard_timer > 0.0 else 0.0
	var damage: float = GameRules.damage_after_armor(raw_damage, player_armor + reduction)
	player_hp -= damage
	if not second_wind_used and player_hp > 0.0 and player_hp <= player_max_hp * 0.30 and _technique_total("second_wind") > 0.0:
		second_wind_used = true
		player_hp = minf(player_max_hp, player_hp + _technique_total("second_wind"))
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
		run_score += 500
		if boss_label != null:
			boss_label.text = "THE BARROW IS QUIET"
	if enemy.special or enemy.kind == "boss":
		_roll_equipment_drop(enemy.kind == "boss")
	_spawn_pickup(enemy.position, enemy.xp)
	_add_effect(enemy.position, enemy.radius * 1.4, BLOOD if enemy.kind != "boss" else FOLKLORE, "burst")
	if enemy.special and relics.size() < 3:
		_show_relic_choices()
	enemies.erase(enemy)
	enemy_pool.append(enemy)

func _roll_equipment_drop(boss_drop: bool) -> void:
	var loot_bonus: float = GameContent.permanent_loot_bonus(save.profile.get("skill_tree", {})) + _technique_total("loot_luck") + _equipment_total("loot_luck")
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

func _guard_step() -> void:
	if screen != Screen.RUN or run_paused or choosing_upgrade or guard_cooldown > 0.0:
		return
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	if direction.length_squared() < 0.01:
		direction = last_move_vector
	player_position += direction.normalized() * 42.0
	player_position.x = clampf(player_position.x, 18.0, size.x - 18.0)
	player_position.y = clampf(player_position.y, 82.0, size.y - 22.0)
	guard_cooldown = maxf(3.5, 6.0 - _relic_total("guard_cooldown"))
	guard_timer = 0.25
	guard_empowered = true
	_play_sfx("guard")
	_add_effect(player_position, 26.0, PARCHMENT_DARK, "burst")
	var riposte_damage: float = _technique_total("guard_blast") + _equipment_total("guard_blast")
	if riposte_damage > 0.0:
		_add_effect(player_position, 62.0, AMBER.lightened(0.1), "ring")
		for enemy: EnemyState in enemies.duplicate():
			if enemy.position.distance_to(player_position) <= 62.0 + enemy.radius:
				_damage_enemy(enemy, riposte_damage * damage_multiplier, true, "stagger")

func _load_actor_textures() -> void:
	for actor_id: String in ACTOR_IDS:
		for facing: String in ["left", "right"]:
			var key: String = "%s_%s" % [actor_id, facing]
			var path: String = "res://assets/characters/%s.png" % key
			var texture: Texture2D = load(path) as Texture2D
			if texture != null:
				actor_textures[key] = texture
	for class_id: String in ["warrior", "mage"]:
		var frames: Array[Texture2D] = []
		for frame_index: int in 8:
			var frame: Texture2D = load("res://assets/characters/generated/%s_%d.png" % [class_id, frame_index]) as Texture2D
			if frame != null:
				frames.append(frame)
		if frames.size() == 8:
			actor_frames[class_id] = frames

func _technique_total(stat: String) -> float:
	var total: float = 0.0
	for technique_id: String in techniques:
		var definition: Dictionary = GameContent.TECHNIQUES[technique_id]
		if String(definition.stat) == stat:
			total += float(definition.amount) * int(techniques[technique_id])
	return total

func _equipment_total(stat: String) -> float:
	var total: float = 0.0
	var equipped: Dictionary = save.profile.get("equipped", {})
	var inventory: Array = save.profile.get("inventory", [])
	for slot: String in equipped:
		var uid: String = String(equipped[slot])
		if uid.is_empty():
			continue
		for item_value: Variant in inventory:
			var item: Dictionary = item_value
			if String(item.get("uid", "")) != uid:
				continue
			for modifier_value: Variant in item.get("modifiers", []):
				var modifier: Dictionary = modifier_value
				if String(modifier.get("stat", "")) == stat:
					total += float(modifier.get("amount", 0.0))
			break
	return total

func _doctrine_total(stat: String) -> float:
	var doctrine: Dictionary = GameContent.DOCTRINES.get(active_doctrine, GameContent.DOCTRINES.shield_line)
	return float(doctrine.get(stat, 0.0))

func _relic_total(stat: String) -> float:
	var total: float = 0.0
	for relic_id: String in relics:
		var relic: Dictionary = GameContent.RELICS.get(relic_id, {})
		if String(relic.get("stat", "")) == stat:
			total += float(relic.get("amount", 0.0)) * int(relics[relic_id])
	return total

func _curse_definition() -> Dictionary:
	return GameContent.CURSES.get(active_curse, GameContent.CURSES.none)

func _recalculate_player_stats() -> void:
	var training: int = int(save.profile.training_level)
	var training_fraction: float = float(training) / 5.0
	var class_definition: Dictionary = GameContent.CLASSES.get(active_class, GameContent.CLASSES.warrior)
	player_max_hp = 100.0 * (1.0 + training_fraction * 0.15) + _technique_total("health") + _equipment_total("health") + float(class_definition.health) + _relic_total("health")
	player_hp = minf(player_hp, player_max_hp)
	player_speed = 122.0 * (1.0 + training_fraction * 0.08 + _technique_total("speed") + _equipment_total("speed") + _doctrine_total("speed"))
	damage_multiplier = (1.0 + training_fraction * 0.15) * (1.0 + _technique_total("damage") + _equipment_total("damage") + float(class_definition.damage) + _doctrine_total("damage"))
	cooldown_reduction = _technique_total("cooldown") + _equipment_total("cooldown")
	player_armor = _technique_total("armor") + _equipment_total("armor") + _doctrine_total("guard")
	critical_chance = 0.05 + _technique_total("critical") + _equipment_total("critical")
	pickup_radius = 54.0 + _technique_total("pickup") + _equipment_total("pickup")
	stagger_power = _technique_total("stagger") + _equipment_total("stagger")
	projectile_bonus = mini(3, int(_technique_total("projectiles") + _relic_total("projectiles")))

func _show_upgrade_choices() -> void:
	_reset_movement_input()
	choosing_upgrade = true
	run_paused = true
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "UpgradeOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.90)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(22.0, 120.0)
	box.size = Vector2(size.x - 44.0, size.y - 210.0)
	box.add_theme_constant_override("separation", 12)
	overlay.add_child(box)
	box.add_child(_make_label("CHOOSE YOUR TRAINING", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Level %d" % run_level, 13, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var choices: Array[Dictionary] = _build_upgrade_choices()
	for choice: Dictionary in choices:
		var button: Button = _make_button("%s\n%s\n%s" % [choice.name, choice.description, _upgrade_summary(choice)], 94.0, _upgrade_color(choice))
		button.pressed.connect(_apply_upgrade.bind(choice, overlay))
		box.add_child(button)

func _upgrade_summary(choice: Dictionary) -> String:
	if String(choice.type) != "technique":
		return "WEAPON FORM • AUTOMATIC ATTACK"
	var stat: String = String(choice.get("stat", ""))
	var amount: float = float(choice.get("amount", 0.0))
	match stat:
		"reach": return "MELEE REACH  +%d" % roundi(amount)
		"area": return "ARC WIDTH  +%d%%" % roundi(amount * 100.0)
		"pierce": return "PIERCING  +%d" % roundi(amount)
		"damage": return "ALL DAMAGE  +%d%%" % roundi(amount * 100.0)
		"melee_damage": return "MELEE DAMAGE  +%d%%" % roundi(amount * 100.0)
		"ranged_damage": return "RANGED DAMAGE  +%d%%" % roundi(amount * 100.0)
		"cooldown": return "ALL RECOVERY  +%d%%" % roundi(amount * 100.0)
		"melee_cooldown": return "MELEE RECOVERY  +%d%%" % roundi(amount * 100.0)
		"ranged_cooldown": return "RANGED RECOVERY  +%d%%" % roundi(amount * 100.0)
		"health": return "MAX HEALTH  +%d" % roundi(amount)
		"armor": return "ARMOR  +%d%%" % roundi(amount * 100.0)
		"guard": return "GUARD STEP  +%d%% REDUCTION" % roundi(amount * 100.0)
		"recovery": return "FIELD RECOVERY  +%d HP" % roundi(amount)
		"critical": return "CRITICAL CHANCE  +%d%%" % roundi(amount * 100.0)
		"speed": return "MOVEMENT  +%d%%" % roundi(amount * 100.0)
		"pickup": return "PICKUP REACH  +%d" % roundi(amount)
		"stagger": return "STAGGER  +%d%%" % roundi(amount * 100.0)
		"projectiles": return "PROJECTILE COUNT  +%d" % roundi(amount)
		"arcane_projectiles": return "ARCANE PROJECTILES  +%d" % roundi(amount)
		"guard_blast": return "GUARD RIPOSTE  %d DAMAGE" % roundi(amount)
		"elite_damage": return "ELITE DAMAGE  +%d%%" % roundi(amount * 100.0)
		"second_wind": return "ONE RECOVERY  +%d HP" % roundi(amount)
		"loot_luck": return "LOOT QUALITY  +%d%%" % roundi(amount * 100.0)
	return "FIELD TECHNIQUE"

func _upgrade_color(choice: Dictionary) -> Color:
	if String(choice.type) != "technique":
		return BURGUNDY
	var stat: String = String(choice.get("stat", ""))
	if stat in ["melee_damage", "reach", "area", "stagger", "guard"]:
		return BURGUNDY.darkened(0.08)
	if stat in ["ranged_damage", "ranged_cooldown", "pierce", "projectiles", "critical"]:
		return Color("4f5961")
	if stat in ["health", "armor", "recovery", "speed"]:
		return Color("4d5b55")
	return IRON.darkened(0.3)

func _build_upgrade_choices() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for weapon_id: String in weapons:
		var rank: int = int(weapons[weapon_id])
		if GameRules.mastery_available(weapon_id, rank, techniques, save.profile.get("skill_tree", {})) and not bool(mastered.get(weapon_id, false)):
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			candidates.append({"type": "mastery", "id": weapon_id, "name": String(weapon.mastery).to_upper(), "description": "Master this weapon's proven form."})
		elif rank < 5:
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			candidates.append({"type": "weapon", "id": weapon_id, "name": "%s  %d > %d" % [weapon.name, rank, rank + 1], "description": weapon.description})
	if weapons.size() < 4:
		for weapon_id: String in GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})):
			if not weapons.has(weapon_id):
				var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
				candidates.append({"type": "weapon", "id": weapon_id, "name": "TAKE %s" % String(weapon.name).to_upper(), "description": weapon.description})
	for technique_id: String in techniques:
		var rank: int = int(techniques[technique_id])
		if rank < 3:
			var technique: Dictionary = GameContent.TECHNIQUES[technique_id]
			candidates.append({"type": "technique", "id": technique_id, "name": "%s  %d > %d" % [technique.name, rank, rank + 1], "description": technique.description, "stat": technique.stat, "amount": technique.amount})
	if techniques.size() < 4:
		for technique_id: String in GameContent.unlocked_techniques(save.profile.get("skill_tree", {})):
			if not techniques.has(technique_id):
				var technique: Dictionary = GameContent.TECHNIQUES[technique_id]
				candidates.append({"type": "technique", "id": technique_id, "name": "LEARN %s" % String(technique.name).to_upper(), "description": technique.description, "stat": technique.stat, "amount": technique.amount})
	var choices: Array[Dictionary] = []
	var choice_count: int = GameContent.level_choice_count(save.profile.get("skill_tree", {}))
	while not candidates.is_empty() and choices.size() < choice_count:
		var index: int = rng.randi_range(0, candidates.size() - 1)
		choices.append(candidates.pop_at(index))
	if choices.is_empty():
		choices.append({"type": "heal", "id": "rations", "name": "FIELD RATIONS", "description": "Recover 30 health."})
	return choices

func _apply_upgrade(choice: Dictionary, overlay: Control) -> void:
	match String(choice.type):
		"weapon":
			var id: String = String(choice.id)
			weapons[id] = int(weapons.get(id, 0)) + 1
			weapon_timers[id] = 0.15
		"technique":
			var id: String = String(choice.id)
			techniques[id] = int(techniques.get(id, 0)) + 1
		"mastery":
			mastered[String(choice.id)] = true
		"heal":
			player_hp = minf(player_max_hp, player_hp + 30.0)
	_recalculate_player_stats()
	overlay.queue_free()
	_reset_movement_input()
	choosing_upgrade = false
	run_paused = false

func _reset_movement_input() -> void:
	joystick_touch_id = -1
	joystick_origin = Vector2.ZERO
	joystick_position = Vector2.ZERO
	joystick_vector = Vector2.ZERO
	player_move_vector = Vector2.ZERO

func _start_new_run(starting_weapon: String = "") -> void:
	_clear_run_state()
	run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	rng.seed = run_seed
	active_class = String(save.profile.get("starting_class", "warrior"))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrine = String(save.profile.get("starting_doctrine", "shield_line"))
	if not GameContent.DOCTRINES.has(active_doctrine):
		active_doctrine = "shield_line"
	active_curse = String(save.profile.get("starting_curse", "none"))
	if not GameContent.CURSES.has(active_curse):
		active_curse = "none"
	relics.clear()
	contract_id = ""
	contract_progress = 0.0
	contract_target = 0.0
	contract_complete = false
	objective_id = _choose_objective()
	objective_progress = 0.0
	objective_complete = false
	boss_phase = 0
	var chosen_weapon: String = starting_weapon if not starting_weapon.is_empty() else String(save.profile.starting_weapon)
	if not GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})).has(chosen_weapon):
		chosen_weapon = "spear"
	weapons[chosen_weapon] = 1
	weapon_timers[chosen_weapon] = 0.2
	_recalculate_player_stats()
	player_hp = player_max_hp
	save.active_run = {}
	SaveService.save_data(save)
	screen = Screen.RUN
	_play_music("moor")
	_build_run_ui()
	queue_redraw()

func _show_weapon_picker() -> void:
	if not is_instance_valid(ui_root):
		_show_camp()
		return
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "WeaponPickerOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var panel: PanelContainer = _make_panel(true)
	panel.position = Vector2(12.0, 42.0)
	panel.size = Vector2(maxf(260.0, size.x - 24.0), maxf(420.0, size.y - 78.0))
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	box.add_child(_make_label("CHOOSE YOUR ARMS", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("One weapon begins the expedition. You can build to four.", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("CHOOSE YOUR COMPANY ROLE", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var class_grid: GridContainer = GridContainer.new()
	class_grid.columns = 1 if size.x < 340.0 else 2
	class_grid.add_theme_constant_override("h_separation", 7)
	class_grid.add_theme_constant_override("v_separation", 7)
	for class_id: String in ["warrior", "mage"]:
		var class_definition: Dictionary = GameContent.CLASSES[class_id]
		var class_button: Button = _make_button("%s\n%s" % [String(class_definition.name).to_upper(), String(class_definition.description)], 72.0, BURGUNDY if class_id == String(save.profile.get("starting_class", "warrior")) else IRON.darkened(0.35))
		class_button.name = "Class%sButton" % class_id.capitalize()
		class_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		class_button.pressed.connect(_select_class.bind(class_id, overlay))
		class_grid.add_child(class_button)
	box.add_child(class_grid)
	box.add_child(_make_label("BUILD SETTINGS", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var doctrine_selector: OptionButton = OptionButton.new()
	doctrine_selector.name = "DoctrineSelector"
	doctrine_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doctrine_selector.custom_minimum_size.y = 34.0
	for doctrine_id: String in GameContent.DOCTRINES:
		doctrine_selector.add_item(String(GameContent.DOCTRINES[doctrine_id].name))
		doctrine_selector.set_item_metadata(doctrine_selector.item_count - 1, doctrine_id)
		if doctrine_id == String(save.profile.get("starting_doctrine", "shield_line")):
			doctrine_selector.select(doctrine_selector.item_count - 1)
	doctrine_selector.item_selected.connect(_starting_doctrine_selected.bind(doctrine_selector))
	box.add_child(doctrine_selector)
	var curse_selector: OptionButton = OptionButton.new()
	curse_selector.name = "CurseSelector"
	curse_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curse_selector.custom_minimum_size.y = 34.0
	for curse_id: String in GameContent.CURSES:
		curse_selector.add_item(String(GameContent.CURSES[curse_id].name))
		curse_selector.set_item_metadata(curse_selector.item_count - 1, curse_id)
		if curse_id == String(save.profile.get("starting_curse", "none")):
			curse_selector.select(curse_selector.item_count - 1)
	curse_selector.item_selected.connect(_starting_curse_selected.bind(curse_selector))
	box.add_child(curse_selector)
	box.add_child(_make_label("AVAILABLE WEAPONS", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 7)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	var unlocked: Array[String] = GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {}))
	for category: String in ["MELEE", "RANGED", "ARCANE"]:
		var category_weapons: Array[String] = []
		for weapon_id: String in unlocked:
			if String(GameContent.WEAPONS[weapon_id].category) == category:
				category_weapons.append(weapon_id)
		if category_weapons.is_empty():
			continue
		list.add_child(_make_label(category, 11, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
		var weapon_grid: GridContainer = GridContainer.new()
		weapon_grid.columns = 2 if size.x >= 360.0 else 1
		weapon_grid.add_theme_constant_override("h_separation", 7)
		weapon_grid.add_theme_constant_override("v_separation", 6)
		weapon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(weapon_grid)
		for weapon_id: String in category_weapons:
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			var suffix: String = "  • CURRENT DEFAULT" if weapon_id == String(save.profile.starting_weapon) else ""
			var button: Button = _make_button("%s%s\n%s" % [String(weapon.name).to_upper(), suffix, String(weapon.description)], 58.0, BURGUNDY if weapon_id == String(save.profile.starting_weapon) else IRON.darkened(0.35))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_choose_starting_weapon.bind(weapon_id, overlay))
			weapon_grid.add_child(button)
	var cancel: Button = _make_button("BACK TO CAMP", 50.0, BURGUNDY)
	cancel.pressed.connect(overlay.queue_free)
	box.add_child(cancel)

func _select_class(class_id: String, overlay: Control) -> void:
	if not GameContent.CLASSES.has(class_id):
		return
	save.profile.starting_class = class_id
	save.profile.starting_weapon = String(GameContent.CLASSES[class_id].starting_weapon)
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_weapon_picker()

func _starting_doctrine_selected(index: int, selector: OptionButton) -> void:
	save.profile.starting_doctrine = String(selector.get_item_metadata(index))
	SaveService.save_data(save)

func _starting_curse_selected(index: int, selector: OptionButton) -> void:
	save.profile.starting_curse = String(selector.get_item_metadata(index))
	SaveService.save_data(save)

func _choose_starting_weapon(weapon_id: String, overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_start_new_run(weapon_id)

func _offer_contract() -> void:
	if choosing_upgrade or ui_root == null or (not contract_id.is_empty() and not contract_complete):
		return
	if contract_complete:
		contract_id = ""
	var ids: Array[String] = []
	for id: String in GameContent.CONTRACTS:
		ids.append(id)
	ids.shuffle()
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "ContractOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(22.0, 180.0)
	box.size = Vector2(size.x - 44.0, size.y - 320.0)
	box.add_theme_constant_override("separation", 10)
	overlay.add_child(box)
	box.add_child(_make_label("A COMPANY CONTRACT", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Accept one risk for a better Veteran Record.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	for index: int in mini(2, ids.size()):
		var contract_id_option: String = ids[index]
		var contract: Dictionary = GameContent.CONTRACTS[contract_id_option]
		var button: Button = _make_button("%s\n%s" % [String(contract.name).to_upper(), String(contract.description)], 72.0, BURGUNDY if index == 0 else IRON.darkened(0.3))
		button.pressed.connect(_accept_contract.bind(contract_id_option, overlay))
		box.add_child(button)
	var decline: Button = _make_button("DECLINE", 50.0)
	decline.pressed.connect(_decline_contract.bind(overlay))
	box.add_child(decline)
	choosing_upgrade = true
	run_paused = true
	_reset_movement_input()

func _accept_contract(selected_id: String, overlay: Control) -> void:
	contract_id = selected_id
	contract_progress = 0.0
	var contract: Dictionary = GameContent.CONTRACTS[selected_id]
	contract_target = float(contract.get("target", contract.get("duration", 1.0)))
	contract_complete = false
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _decline_contract(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _show_relic_choices() -> void:
	if choosing_upgrade or ui_root == null:
		return
	var available: Array[String] = []
	for relic_id: String in GameContent.RELICS:
		if not relics.has(relic_id):
			available.append(relic_id)
	available.shuffle()
	if available.is_empty():
		return
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "RelicOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(22.0, 170.0)
	box.size = Vector2(size.x - 44.0, size.y - 300.0)
	box.add_theme_constant_override("separation", 10)
	overlay.add_child(box)
	box.add_child(_make_label("CLAIM A FIELD RELIC", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("A strong advantage with a cost. Choose one.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	for index: int in mini(3, available.size()):
		var relic_id: String = available[index]
		var relic: Dictionary = GameContent.RELICS[relic_id]
		var button: Button = _make_button("%s\n%s" % [String(relic.name).to_upper(), String(relic.description)], 72.0, Color("4d5b55") if index == 0 else IRON.darkened(0.3))
		button.pressed.connect(_claim_relic.bind(relic_id, overlay))
		box.add_child(button)
	choosing_upgrade = true
	run_paused = true
	_reset_movement_input()

func _claim_relic(relic_id: String, overlay: Control) -> void:
	relics[relic_id] = int(relics.get(relic_id, 0)) + 1
	_recalculate_player_stats()
	if is_instance_valid(overlay):
		overlay.queue_free()
	choosing_upgrade = false
	run_paused = false
	_reset_movement_input()

func _clear_run_state() -> void:
	for enemy: EnemyState in enemies:
		enemy_pool.append(enemy)
	for projectile: ProjectileState in projectiles:
		projectile_pool.append(projectile)
	for pickup: PickupState in pickups:
		pickup_pool.append(pickup)
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	traps.clear()
	hazards.clear()
	float_texts.clear()
	effects.clear()
	weapons.clear()
	techniques.clear()
	mastered.clear()
	run_loot.clear()
	weapon_timers.clear()
	player_position = Vector2(size.x * 0.5, size.y * 0.52)
	run_elapsed = 0.0
	run_level = 1
	run_xp = 0
	next_xp = 14
	run_kills = 0
	run_elites = 0
	run_score = 0
	boss_spawned = false
	boss_defeated = false
	elite_one_spawned = false
	elite_two_spawned = false
	active_doctrine = "shield_line"
	active_curse = "none"
	relics.clear()
	contract_id = ""
	contract_progress = 0.0
	contract_target = 0.0
	contract_complete = false
	objective_id = ""
	objective_progress = 0.0
	objective_complete = false
	boss_phase = 0
	run_paused = false
	choosing_upgrade = false
	autosave_timer = 0.0
	spawn_accumulator = 0.0
	guard_cooldown = 0.0
	guard_timer = 0.0
	guard_empowered = false
	second_wind_used = false
	joystick_touch_id = -1
	joystick_vector = Vector2.ZERO
	player_move_vector = Vector2.ZERO
	next_enemy_uid = 1

func _finish_run(victory: bool) -> void:
	if screen != Screen.RUN:
		return
	run_paused = true
	var curse_reward: float = float(_curse_definition().get("reward", 1.0))
	var silver: int = floori((float(run_kills) / 10.0 + run_elites * 10.0 + (60 if victory else 0)) * curse_reward)
	var provisions: int = floori((run_elapsed / 30.0 + (20 if victory else 0)) * curse_reward)
	if active_curse == "thin_rations":
		provisions += 8 if victory else 0
	var loot_result: Dictionary = _store_run_loot()
	silver += int(loot_result.salvaged_silver)
	var rating: float = GameRules.veteran_rating(run_elapsed, run_kills, run_elites, victory)
	result_data = {"victory": victory, "silver": silver, "provisions": provisions, "rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete, "class": active_class, "doctrine": active_doctrine, "curse": active_curse, "relics": relics.duplicate(true), "loot": run_loot.duplicate(true), "stored_loot": int(loot_result.stored), "salvaged_loot": int(loot_result.salvaged)}
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	var current_veteran: Dictionary = save.profile.veteran
	if current_veteran.is_empty() or rating > float(current_veteran.get("rating", 0.0)):
		save.profile.veteran = {"rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "boss": victory, "weapons": weapons.duplicate(true), "techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "class": active_class, "doctrine": active_doctrine, "curse": active_curse, "relics": relics.duplicate(true), "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete}
	var campaign_flags: Dictionary = save.profile.get("campaign_flags", {})
	if objective_complete:
		campaign_flags["objective_%s" % objective_id] = true
	if victory:
		campaign_flags["barrow_knight_defeated"] = true
	if active_curse != "none":
		campaign_flags["cursed_expeditions"] = true
	save.profile.campaign_flags = campaign_flags
	save.active_run = {}
	_update_last_seen()
	SaveService.save_data(save)
	screen = Screen.RESULTS
	_build_results_ui()
	queue_redraw()

func _store_run_loot() -> Dictionary:
	var inventory: Array = save.profile.get("inventory", [])
	var capacity: int = GameContent.inventory_capacity(save.profile.get("skill_tree", {}))
	var stored: int = 0
	var salvaged: int = 0
	var salvaged_silver: int = 0
	for item_value: Variant in run_loot:
		var item: Dictionary = item_value
		if inventory.size() < capacity:
			inventory.append(item.duplicate(true))
			stored += 1
		else:
			var rarity: Dictionary = GameContent.RARITIES.get(String(item.get("rarity", "common")), GameContent.RARITIES.common)
			salvaged += 1
			salvaged_silver += int(rarity.salvage)
	save.profile.inventory = inventory
	return {"stored": stored, "salvaged": salvaged, "salvaged_silver": salvaged_silver}

func _snapshot_run() -> void:
	if screen != Screen.RUN:
		return
	save.active_run = {
		"seed": run_seed, "rng_state": rng.state, "elapsed": run_elapsed, "hp": player_hp, "max_hp": player_max_hp,
		"class": active_class, "doctrine": active_doctrine, "curse": active_curse, "relics": relics.duplicate(true),
		"position": [player_position.x, player_position.y], "level": run_level, "xp": run_xp, "next_xp": next_xp,
		"kills": run_kills, "elites": run_elites, "score": run_score, "weapons": weapons.duplicate(true),
		"techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated, "elite_one": elite_one_spawned, "elite_two": elite_two_spawned, "boss_phase": boss_phase,
		"objective": objective_id, "objective_progress": objective_progress, "objective_complete": objective_complete,
		"contract": contract_id, "contract_progress": contract_progress, "contract_target": contract_target, "contract_complete": contract_complete,
		"run_loot": run_loot.duplicate(true), "second_wind_used": second_wind_used
	}
	_update_last_seen()

func _resume_run() -> void:
	var snapshot: Dictionary = save.active_run
	if snapshot.is_empty():
		_start_new_run()
		return
	_clear_run_state()
	run_seed = int(snapshot.get("seed", 1))
	rng.seed = run_seed
	rng.state = int(snapshot.get("rng_state", rng.state))
	active_class = String(snapshot.get("class", save.profile.get("starting_class", "warrior")))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrine = String(snapshot.get("doctrine", save.profile.get("starting_doctrine", "shield_line")))
	if not GameContent.DOCTRINES.has(active_doctrine):
		active_doctrine = "shield_line"
	active_curse = String(snapshot.get("curse", save.profile.get("starting_curse", "none")))
	if not GameContent.CURSES.has(active_curse):
		active_curse = "none"
	relics = snapshot.get("relics", {}).duplicate(true)
	run_elapsed = clampf(float(snapshot.get("elapsed", 0.0)), 0.0, RUN_SECONDS - 0.1)
	player_hp = float(snapshot.get("hp", 100.0))
	var position_data: Array = snapshot.get("position", [size.x * 0.5, size.y * 0.52])
	player_position = Vector2(float(position_data[0]), float(position_data[1]))
	run_level = int(snapshot.get("level", 1))
	run_xp = int(snapshot.get("xp", 0))
	next_xp = int(snapshot.get("next_xp", 14))
	run_kills = int(snapshot.get("kills", 0))
	run_elites = int(snapshot.get("elites", 0))
	run_score = int(snapshot.get("score", 0))
	weapons = snapshot.get("weapons", {"spear": 1}).duplicate(true)
	techniques = snapshot.get("techniques", {}).duplicate(true)
	mastered = snapshot.get("mastered", {}).duplicate(true)
	boss_spawned = bool(snapshot.get("boss_spawned", false))
	boss_defeated = bool(snapshot.get("boss_defeated", false))
	elite_one_spawned = bool(snapshot.get("elite_one", run_elapsed >= 120.0))
	elite_two_spawned = bool(snapshot.get("elite_two", run_elapsed >= 300.0))
	boss_phase = int(snapshot.get("boss_phase", 0))
	objective_id = String(snapshot.get("objective", _choose_objective()))
	objective_progress = float(snapshot.get("objective_progress", 0.0))
	objective_complete = bool(snapshot.get("objective_complete", false))
	contract_id = String(snapshot.get("contract", ""))
	contract_progress = float(snapshot.get("contract_progress", 0.0))
	contract_target = float(snapshot.get("contract_target", 0.0))
	contract_complete = bool(snapshot.get("contract_complete", false))
	run_loot.assign(snapshot.get("run_loot", []))
	second_wind_used = bool(snapshot.get("second_wind_used", false))
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = rng.randf_range(0.1, 0.5)
	_recalculate_player_stats()
	player_hp = minf(player_hp, player_max_hp)
	for index: int in mini(24, 6 + floori(run_elapsed / 25.0)):
		_spawn_enemy(_choose_wave_enemy(), false)
	if boss_spawned and not boss_defeated:
		_spawn_enemy("barrow_knight", true)
	screen = Screen.RUN
	run_paused = false
	_build_run_ui()

func _apply_offline_progress() -> void:
	var expedition: Dictionary = save.profile.expedition
	var now: float = Time.get_unix_time_from_system()
	if not expedition.has("started_at"):
		expedition.started_at = float(expedition.get("last_seen", now))
	var elapsed: float = maxf(0.0, now - float(expedition.get("last_seen", now)))
	var veteran: Dictionary = save.profile.veteran
	var rating: float = float(veteran.get("rating", 0.25))
	var reward: Dictionary = GameRules.offline_reward(String(expedition.get("operation", "forage")), elapsed, rating, int(save.profile.quartermaster_level))
	expedition.pending_silver = int(expedition.get("pending_silver", 0)) + int(reward.silver)
	expedition.pending_provisions = int(expedition.get("pending_provisions", 0)) + int(reward.provisions)
	expedition.last_seen = now
	save.profile.expedition = expedition
	SaveService.save_data(save)

func _expedition_status_text() -> String:
	var expedition: Dictionary = save.profile.expedition
	var operation: String = String(expedition.get("operation", "forage"))
	var cap_seconds: float = GameRules.offline_cap_hours(int(save.profile.quartermaster_level)) * 3600.0
	var started_at: float = float(expedition.get("started_at", expedition.get("last_seen", Time.get_unix_time_from_system())))
	var elapsed: float = clampf(Time.get_unix_time_from_system() - started_at, 0.0, cap_seconds)
	var veteran: Dictionary = save.profile.veteran
	var rating: float = float(veteran.get("rating", 0.25))
	var efficiency: float = lerpf(0.55, 1.0, clampf(rating, 0.25, 1.0))
	var quartermaster_bonus: float = 1.0 + float(save.profile.quartermaster_level) * 0.08
	var silver_rate: int = floori(11.0 * efficiency * quartermaster_bonus)
	var provisions_rate: int = floori(3.0 * efficiency * quartermaster_bonus)
	var rate_text: String = "%d silver/hour" % silver_rate if operation == "patrol" else "%d provisions/hour" % provisions_rate
	var pending_text: String = "%d silver / %d provisions pending" % [int(expedition.get("pending_silver", 0)), int(expedition.get("pending_provisions", 0))]
	return "ACTIVE: %s\nAWAY FOR %s / CAP %s\nYIELD: %s\n%s" % ["BORDER PATROL" if operation == "patrol" else "FORAGING", _format_time(elapsed), _format_time(cap_seconds), rate_text, pending_text]

func _update_last_seen() -> void:
	var expedition: Dictionary = save.profile.expedition
	expedition.last_seen = Time.get_unix_time_from_system()
	save.profile.expedition = expedition

func _claim_expedition() -> void:
	var expedition: Dictionary = save.profile.expedition
	var silver: int = int(expedition.get("pending_silver", 0))
	var provisions: int = int(expedition.get("pending_provisions", 0))
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	expedition.pending_silver = 0
	expedition.pending_provisions = 0
	save.profile.expedition = expedition
	SaveService.save_data(save)
	_show_camp("Collected %d silver and %d provisions." % [silver, provisions])

func _set_expedition(operation: String) -> void:
	_apply_offline_progress()
	save.profile.expedition.operation = operation
	save.profile.expedition.started_at = Time.get_unix_time_from_system()
	_update_last_seen()
	SaveService.save_data(save)
	_show_camp("Veterans assigned to %s." % ("Border Patrol" if operation == "patrol" else "Foraging"))

func _buy_building(building: String) -> void:
	var key: String = building + "_level"
	var level: int = int(save.profile[key])
	var costs: Array[Dictionary]
	match building:
		"armory": costs = GameContent.ARMORY_COSTS
		"training": costs = GameContent.TRAINING_COSTS
		_: costs = GameContent.QUARTERMASTER_COSTS
	if level >= costs.size():
		_show_camp("That part of camp is fully restored.")
		return
	var cost: Dictionary = costs[level]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		_show_camp("The company lacks the materials for that work.")
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	save.profile[key] = level + 1
	SaveService.save_data(save)
	_show_camp("The %s reaches tier %d." % [building.capitalize(), level + 1])

func _show_camp(message: String = "") -> void:
	screen = Screen.CAMP
	run_paused = true
	_apply_offline_progress()
	_play_music("camp")
	_clear_ui()
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 18)
	ui_root.add_theme_constant_override("margin_right", 18)
	ui_root.add_theme_constant_override("margin_top", 28)
	ui_root.add_theme_constant_override("margin_bottom", 18)
	ui_root.theme = theme_main
	add_child(ui_root)
	var camp_panel: PanelContainer = _make_panel(true)
	camp_panel.name = "CampPanel"
	ui_root.add_child(camp_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	camp_panel.add_child(column)
	column.add_child(_make_label("ASHEN COMPANY", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label("BLACKTHORN MOOR", 13, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	resource_label = _make_label("", 16, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(resource_label)
	_update_resource_label()
	if not message.is_empty():
		status_label = _make_label(message, 12, AMBER.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(status_label)
	var navigation: GridContainer = GridContainer.new()
	navigation.columns = 3
	navigation.add_theme_constant_override("h_separation", 6)
	var skills_button: Button = _make_button("SKILL TREE", 38.0, Color("4d5b55"))
	skills_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_button.pressed.connect(_show_skill_tree)
	navigation.add_child(skills_button)
	var inventory_button: Button = _make_button("EQUIPMENT", 38.0, Color("4c555d"))
	inventory_button.name = "InventoryButton"
	inventory_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_button.pressed.connect(_show_inventory)
	navigation.add_child(inventory_button)
	var settings_button_top: Button = _make_button("SETTINGS", 38.0)
	settings_button_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button_top.pressed.connect(_show_settings)
	navigation.add_child(settings_button_top)
	column.add_child(navigation)
	column.add_child(_make_label("CAMP OPERATIONS", 12, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var expedition_panel: PanelContainer = _make_panel()
	column.add_child(expedition_panel)
	var expedition_box: VBoxContainer = VBoxContainer.new()
	expedition_box.add_theme_constant_override("separation", 7)
	expedition_panel.add_child(expedition_box)
	expedition_box.add_child(_make_label("THE VETERANS' WORK", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var veteran: Dictionary = save.profile.veteran
	var veteran_text: String = "No proven company yet - complete an expedition." if veteran.is_empty() else "Veteran rating: %d%% / Best: %s" % [roundi(float(veteran.rating) * 100.0), _format_time(float(veteran.time))]
	expedition_box.add_child(_make_label(veteran_text, 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var campaign_flags: Dictionary = save.profile.get("campaign_flags", {})
	var chronicle_text: String = "COMPANY CHRONICLES: %d DISCOVERY%s" % [campaign_flags.size(), "" if campaign_flags.size() == 1 else "S"]
	expedition_box.add_child(_make_label(chronicle_text, 11, AMBER.lightened(0.1), HORIZONTAL_ALIGNMENT_CENTER))
	var operation_status: Label = _make_label(_expedition_status_text(), 12, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	operation_status.name = "ExpeditionStatus"
	operation_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operation_status.custom_minimum_size.y = 68.0
	expedition_box.add_child(operation_status)
	expedition_box.add_child(_make_label("ONE COMPANY SLOT - CHOOSE A NEW ASSIGNMENT TO SWITCH", 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var expedition: Dictionary = save.profile.expedition
	var assignment: GridContainer = GridContainer.new()
	assignment.columns = 2
	assignment.add_theme_constant_override("separation", 8)
	var current_operation: String = String(expedition.get("operation", "forage"))
	var patrol: Button = _make_button("BORDER PATROL\nProduces silver", 46.0, BURGUNDY if current_operation == "patrol" else IRON.darkened(0.35))
	patrol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patrol.pressed.connect(_set_expedition.bind("patrol"))
	assignment.add_child(patrol)
	var forage: Button = _make_button("FORAGING\nProduces provisions", 46.0, BURGUNDY if current_operation == "forage" else IRON.darkened(0.35))
	forage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forage.pressed.connect(_set_expedition.bind("forage"))
	assignment.add_child(forage)
	expedition_box.add_child(assignment)
	var pending_silver: int = int(expedition.get("pending_silver", 0))
	var pending_provisions: int = int(expedition.get("pending_provisions", 0))
	if pending_silver + pending_provisions > 0:
		var claim: Button = _make_button("COLLECT  %d SILVER / %d PROVISIONS" % [pending_silver, pending_provisions], 42.0, AMBER.darkened(0.35))
		claim.pressed.connect(_claim_expedition)
		expedition_box.add_child(claim)
	var start_button: Button = _make_button("MARCH INTO BLACKTHORN MOOR", 52.0, BURGUNDY)
	start_button.pressed.connect(_show_weapon_picker)
	column.add_child(start_button)
	if not save.active_run.is_empty():
		var resume_button: Button = _make_button("RESUME INTERRUPTED EXPEDITION", 42.0, IRON)
		resume_button.pressed.connect(_resume_run)
		column.add_child(resume_button)
	var buildings: GridContainer = GridContainer.new()
	buildings.name = "CampBuildings"
	buildings.columns = 3
	buildings.add_theme_constant_override("h_separation", 7)
	buildings.add_theme_constant_override("v_separation", 7)
	column.add_child(buildings)
	for building: String in ["armory", "training", "quartermaster"]:
		var level: int = int(save.profile[building + "_level"])
		var cost_label: String = "RESTORED"
		var building_costs: Array[Dictionary]
		match building:
			"armory": building_costs = GameContent.ARMORY_COSTS
			"training": building_costs = GameContent.TRAINING_COSTS
			_: building_costs = GameContent.QUARTERMASTER_COSTS
		if level < building_costs.size():
			var next_cost: Dictionary = building_costs[level]
			cost_label = "%d SILVER / %d PROV." % [int(next_cost.silver), int(next_cost.provisions)]
		var building_name: String = "QUARTER-\nMASTER" if building == "quartermaster" else building.to_upper()
		var button: Button = _make_button("%s\nTIER %d\n%s" % [building_name, level, cost_label], 68.0)
		button.add_theme_font_size_override("font_size", 11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_buy_building.bind(building))
		buildings.add_child(button)
	var footer: VBoxContainer = VBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	column.add_child(footer)
	if int(save.profile.armory_level) >= 3:
		footer.add_child(_make_label("STARTING WEAPON", 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_LEFT))
		var selector: OptionButton = OptionButton.new()
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unlocked: Array[String] = GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {}))
		for weapon_id: String in unlocked:
			selector.add_item(String(GameContent.WEAPONS[weapon_id].name))
			selector.set_item_metadata(selector.item_count - 1, weapon_id)
			if weapon_id == String(save.profile.starting_weapon):
				selector.select(selector.item_count - 1)
		selector.item_selected.connect(_starting_weapon_selected.bind(selector))
		footer.add_child(selector)
	queue_redraw()

func _starting_weapon_selected(index: int, selector: OptionButton) -> void:
	save.profile.starting_weapon = String(selector.get_item_metadata(index))
	SaveService.save_data(save)

func _show_inventory(message: String = "", requested_uid: String = "") -> void:
	screen = Screen.CAMP
	run_paused = true
	_play_music("camp")
	_clear_ui()
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 18)
	ui_root.add_theme_constant_override("margin_right", 18)
	ui_root.add_theme_constant_override("margin_top", 28)
	ui_root.add_theme_constant_override("margin_bottom", 18)
	ui_root.theme = theme_main
	add_child(ui_root)
	var panel: PanelContainer = _make_panel(true)
	panel.name = "InventoryPanel"
	ui_root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(column)
	column.add_child(_make_label("COMPANY EQUIPMENT", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var inventory: Array = save.profile.get("inventory", [])
	var capacity: int = GameContent.inventory_capacity(save.profile.get("skill_tree", {}))
	column.add_child(_make_label("%d / %d ITEMS  -  ELITE AND BOSS SPOILS" % [inventory.size(), capacity], 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	if not message.is_empty():
		column.add_child(_make_label(message, 11, AMBER.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
	var equipped: Dictionary = save.profile.get("equipped", {})
	var slot_grid: GridContainer = GridContainer.new()
	slot_grid.name = "EquipmentSlots"
	slot_grid.columns = 3
	slot_grid.add_theme_constant_override("h_separation", 5)
	slot_grid.add_theme_constant_override("v_separation", 5)
	column.add_child(slot_grid)
	for slot: String in ["head", "body", "hands", "boots", "trinket"]:
		var equipped_item: Dictionary = _find_inventory_item(String(equipped.get(slot, "")))
		var slot_text: String = "%s\n%s" % [slot.to_upper(), "EMPTY" if equipped_item.is_empty() else String(equipped_item.name)]
		var slot_button: Button = _make_button(slot_text, 48.0, Color("39433f") if not equipped_item.is_empty() else INK.lightened(0.06))
		slot_button.name = "EquipmentSlot_%s" % slot
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not equipped_item.is_empty():
			slot_button.pressed.connect(_show_inventory.bind("", String(equipped_item.uid)))
		slot_grid.add_child(slot_button)
	column.add_child(_make_label("FIELD CHEST", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var per_page: int = 6
	var page_count: int = maxi(1, ceili(float(inventory.size()) / float(per_page)))
	inventory_page = clampi(inventory_page, 0, page_count - 1)
	if not requested_uid.is_empty():
		selected_item_uid = requested_uid
	if _find_inventory_item(selected_item_uid).is_empty():
		selected_item_uid = String(inventory[0].uid) if not inventory.is_empty() else ""
	var item_grid: GridContainer = GridContainer.new()
	item_grid.name = "InventoryItems"
	item_grid.columns = 2
	item_grid.add_theme_constant_override("h_separation", 6)
	item_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(item_grid)
	var start_index: int = inventory_page * per_page
	for item_index: int in range(start_index, mini(inventory.size(), start_index + per_page)):
		var item: Dictionary = inventory[item_index]
		var rarity: Dictionary = GameContent.RARITIES.get(String(item.get("rarity", "common")), GameContent.RARITIES.common)
		var equipped_mark: String = "  [EQUIPPED]" if String(equipped.get(String(item.slot), "")) == String(item.uid) else ""
		var item_button: Button = _make_button("%s%s\n%s - %s" % [String(item.name).to_upper(), equipped_mark, String(rarity.name).to_upper(), String(item.slot).to_upper()], 58.0, BURGUNDY if String(item.uid) == selected_item_uid else Color(rarity.color).darkened(0.35))
		item_button.name = "InventoryItem_%s" % String(item.uid)
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.pressed.connect(_show_inventory.bind("", String(item.uid)))
		item_grid.add_child(item_button)
	while item_grid.get_child_count() < per_page:
		var empty_slot: PanelContainer = _make_panel()
		empty_slot.custom_minimum_size.y = 58.0
		empty_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_grid.add_child(empty_slot)
	var page_row: HBoxContainer = HBoxContainer.new()
	page_row.add_theme_constant_override("separation", 6)
	var previous: Button = _make_button("<", 34.0)
	previous.disabled = inventory_page <= 0
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	previous.pressed.connect(_change_inventory_page.bind(-1))
	page_row.add_child(previous)
	page_row.add_child(_make_label("PAGE %d / %d" % [inventory_page + 1, page_count], 11, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	var next: Button = _make_button(">", 34.0)
	next.disabled = inventory_page >= page_count - 1
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(_change_inventory_page.bind(1))
	page_row.add_child(next)
	column.add_child(page_row)
	var selected: Dictionary = _find_inventory_item(selected_item_uid)
	var detail: Label
	if selected.is_empty():
		detail = _make_label("No equipment recovered yet. The first elite in every expedition carries a guaranteed item.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var rarity: Dictionary = GameContent.RARITIES[String(selected.rarity)]
		var current_item: Dictionary = _find_inventory_item(String(equipped.get(String(selected.slot), "")))
		var comparison: String = "CURRENT: EMPTY"
		if not current_item.is_empty():
			comparison = "CURRENT: %s - %s" % [String(current_item.name).to_upper(), _equipment_modifier_text(current_item)]
		detail = _make_label("%s - %s\n%s\n%s\n%s" % [String(rarity.name).to_upper(), String(selected.slot).to_upper(), String(GameContent.EQUIPMENT[String(selected.base_id)].description), _equipment_modifier_text(selected), comparison], 11, rarity.color, HORIZONTAL_ALIGNMENT_CENTER)
	detail.name = "EquipmentDetail"
	detail.custom_minimum_size.y = 76.0
	column.add_child(detail)
	if not selected.is_empty():
		var action_row: HBoxContainer = HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 6)
		var equip: Button = _make_button("EQUIP", 42.0, Color("4d5b55"))
		equip.name = "EquipItemButton"
		equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equip.pressed.connect(_equip_item.bind(String(selected.uid)))
		action_row.add_child(equip)
		var salvage_value: int = int(GameContent.RARITIES[String(selected.rarity)].salvage)
		var dismantle: Button = _make_button("DISMANTLE  +%dS" % salvage_value, 42.0, BURGUNDY.darkened(0.12))
		dismantle.name = "DismantleItemButton"
		dismantle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dismantle.pressed.connect(_show_dismantle_confirm.bind(String(selected.uid)))
		action_row.add_child(dismantle)
		column.add_child(action_row)
	var back: Button = _make_button("BACK TO CAMP", 44.0, BURGUNDY)
	back.pressed.connect(_show_camp)
	column.add_child(back)
	queue_redraw()

func _find_inventory_item(uid: String) -> Dictionary:
	if uid.is_empty():
		return {}
	for item_value: Variant in save.profile.get("inventory", []):
		var item: Dictionary = item_value
		if String(item.get("uid", "")) == uid:
			return item
	return {}

func _equipment_modifier_text(item: Dictionary) -> String:
	var parts: PackedStringArray = []
	for modifier_value: Variant in item.get("modifiers", []):
		var modifier: Dictionary = modifier_value
		parts.append(_equipment_stat_text(String(modifier.stat), float(modifier.amount)))
	return "  |  ".join(parts)

func _equipment_stat_text(stat: String, amount: float) -> String:
	match stat:
		"health": return "+%d HEALTH" % roundi(amount)
		"pickup", "reach": return "+%d %s" % [roundi(amount), stat.to_upper()]
		"guard_blast": return "+%d RIPOSTE" % roundi(amount)
		"cooldown", "ranged_cooldown", "melee_cooldown", "arcane_cooldown": return "+%d%% RECOVERY" % roundi(amount * 100.0)
		_: return "+%d%% %s" % [roundi(amount * 100.0), stat.replace("_", " ").to_upper()]

func _change_inventory_page(delta: int) -> void:
	inventory_page += delta
	selected_item_uid = ""
	_show_inventory()

func _equip_item(uid: String) -> void:
	var item: Dictionary = _find_inventory_item(uid)
	if item.is_empty():
		return
	var equipped: Dictionary = save.profile.get("equipped", {})
	equipped[String(item.slot)] = uid
	save.profile.equipped = equipped
	SaveService.save_data(save)
	_recalculate_player_stats()
	_show_inventory("%s equipped." % String(item.name), uid)

func _show_dismantle_confirm(uid: String) -> void:
	var item: Dictionary = _find_inventory_item(uid)
	if item.is_empty() or ui_root == null:
		return
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "DismantleConfirm"
	overlay.color = Color(0.02, 0.025, 0.027, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(overlay)
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(20.0, 250.0)
	box.size = Vector2(size.x - 40.0, 250.0)
	box.add_theme_constant_override("separation", 10)
	overlay.add_child(box)
	box.add_child(_make_label("DISMANTLE %s?" % String(item.name).to_upper(), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("This permanently turns the item into silver.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var confirm: Button = _make_button("DISMANTLE", 48.0, BURGUNDY)
	confirm.pressed.connect(_dismantle_item.bind(uid, overlay))
	box.add_child(confirm)
	var cancel: Button = _make_button("KEEP ITEM", 44.0)
	cancel.pressed.connect(overlay.queue_free)
	box.add_child(cancel)

func _dismantle_item(uid: String, overlay: Control) -> void:
	var inventory: Array = save.profile.get("inventory", [])
	var salvage_value: int = 0
	for item_index: int in inventory.size():
		var item: Dictionary = inventory[item_index]
		if String(item.get("uid", "")) != uid:
			continue
		salvage_value = int(GameContent.RARITIES[String(item.rarity)].salvage)
		inventory.remove_at(item_index)
		break
	var equipped: Dictionary = save.profile.get("equipped", {})
	for slot: String in equipped:
		if String(equipped[slot]) == uid:
			equipped[slot] = ""
	save.profile.inventory = inventory
	save.profile.equipped = equipped
	save.profile.silver = int(save.profile.silver) + salvage_value
	selected_item_uid = ""
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_inventory("Equipment dismantled for %d silver." % salvage_value)

func _skill_cost(rank: int) -> Dictionary:
	return {"silver": 18 + rank * 14, "provisions": 6 + rank * 5}

func _show_skill_tree(message: String = "", branch_index: int = -1) -> void:
	screen = Screen.CAMP
	run_paused = true
	if branch_index >= 0:
		skill_tree_branch = branch_index
	var picker_overlay: Node = get_node_or_null("WeaponPickerOverlay")
	if picker_overlay != null:
		picker_overlay.queue_free()
	_play_music("camp")
	_clear_ui()
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 18)
	ui_root.add_theme_constant_override("margin_right", 18)
	ui_root.add_theme_constant_override("margin_top", 34)
	ui_root.add_theme_constant_override("margin_bottom", 24)
	ui_root.theme = theme_main
	add_child(ui_root)
	var panel: PanelContainer = _make_panel(true)
	panel.name = "SkillTreePanel"
	ui_root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(column)
	column.add_child(_make_label("FIELD SKILL TREE", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var description: Label = _make_label("Permanent training for every future expedition. Choose a branch and build it over time.", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	description.name = "SkillTreeDescription"
	description.custom_minimum_size.y = 30.0
	column.add_child(description)
	resource_label = _make_label("", 14, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(resource_label)
	_update_resource_label()
	if not message.is_empty():
		column.add_child(_make_label(message, 11, AMBER.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
	var branch_tabs: HBoxContainer = HBoxContainer.new()
	branch_tabs.name = "SkillBranchTabs"
	branch_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branch_tabs.add_theme_constant_override("separation", 5)
	var branch_names: Array = GameContent.SKILL_BRANCHES.keys()
	var branch_short_names: Array[String] = ["STEEL", "HUNT", "HEDGE", "CO."]
	for branch_index_option: int in branch_names.size():
		var branch_button: Button = _make_button(branch_short_names[branch_index_option], 38.0, BURGUNDY if branch_index_option == skill_tree_branch else IRON.darkened(0.3))
		branch_button.name = "SkillBranch%d" % branch_index_option
		branch_button.tooltip_text = String(branch_names[branch_index_option])
		branch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branch_button.pressed.connect(_show_skill_tree.bind("", branch_index_option))
		branch_tabs.add_child(branch_button)
	column.add_child(branch_tabs)
	var tree: Dictionary = save.profile.get("skill_tree", {})
	var selected_branch_name: String = String(branch_names[clampi(skill_tree_branch, 0, branch_names.size() - 1)])
	column.add_child(_make_label(selected_branch_name, 14, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var selected_ids: Array = GameContent.SKILL_BRANCHES[selected_branch_name]
	var node_grid: GridContainer = GridContainer.new()
	node_grid.name = "SkillNodes"
	node_grid.columns = 2 if size.x >= 360.0 else 1
	node_grid.add_theme_constant_override("h_separation", 6)
	node_grid.add_theme_constant_override("v_separation", 6)
	node_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(node_grid)
	for node_id_value: Variant in selected_ids:
		var node_id: String = String(node_id_value)
		var node: Dictionary = GameContent.PROGRESSION_NODES[node_id]
		var rank: int = int(tree.get(node_id, 0))
		var max_rank: int = int(node.max_rank)
		var cost: Dictionary = GameContent.progression_cost(node_id, rank)
		var requirements_met: bool = GameContent.progression_requirements_met(node_id, tree)
		var rank_text: String = "  %d/%d" % [rank, max_rank] if max_rank > 1 else ("  LEARNED" if rank > 0 else "")
		var node_text: String = "%s%s\n%s" % [String(node.name).to_upper(), rank_text, String(node.description)]
		if rank >= max_rank:
			node_text += "\nUNLOCKED"
		elif not requirements_met:
			var required_id: String = String(node.requires[0])
			node_text += "\nREQUIRES %s" % String(GameContent.PROGRESSION_NODES[required_id].name).to_upper()
		else:
			node_text += "\n%dS / %dP" % [int(cost.silver), int(cost.provisions)]
		if String(node.kind).contains("weapon"):
			node_text += "  -  ARMORY %d" % int(GameContent.WEAPON_UNLOCK_LEVEL[String(node.unlock)])
		var node_color: Color = Color("4d5b55") if rank > 0 else (IRON.darkened(0.3) if requirements_met else INK.lightened(0.04))
		var node_button: Button = _make_button(node_text, 82.0, node_color)
		node_button.name = "SkillNode_%s" % node_id
		node_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node_button.disabled = rank >= max_rank or not requirements_met
		node_button.pressed.connect(_buy_skill_node.bind(node_id))
		node_grid.add_child(node_button)
	for branch_name: String in []:
		var branch_panel: PanelContainer = _make_panel()
		column.add_child(branch_panel)
		var branch_box: VBoxContainer = VBoxContainer.new()
		branch_box.add_theme_constant_override("separation", 5)
		branch_panel.add_child(branch_box)
		branch_box.add_child(_make_label(branch_name, 14, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
		var ids: Array = GameContent.SKILL_BRANCHES[branch_name]
		for node_index: int in ids.size():
			var technique_id: String = String(ids[node_index])
			var technique: Dictionary = GameContent.TECHNIQUES[technique_id]
			var rank: int = int(tree.get(technique_id, 0))
			var cost: Dictionary = _skill_cost(rank)
			var node_text: String = "%s  %d/3\n%s" % [String(technique.name).to_upper(), rank, String(technique.description)]
			if rank < 3:
				node_text += "\nNEXT: %d SILVER / %d PROV." % [int(cost.silver), int(cost.provisions)]
			else:
				node_text += "\nMASTERED FOR THE COMPANY"
			var node_button: Button = _make_button(node_text, 70.0 if rank < 3 else 58.0, BURGUNDY if rank > 0 else IRON.darkened(0.3))
			node_button.name = "SkillNode_%s" % technique_id
			node_button.disabled = rank >= 3
			node_button.pressed.connect(_buy_skill_node.bind(technique_id))
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 5)
			row.add_child(_make_label("●" if node_index == 0 else "│", 15, AMBER.darkened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
			row.add_child(node_button)
			node_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			branch_box.add_child(row)
	var back: Button = _make_button("BACK TO CAMP", 50.0, BURGUNDY)
	back.pressed.connect(_show_camp)
	column.add_child(back)
	queue_redraw()

func _buy_skill_node(node_id: String) -> void:
	if not GameContent.PROGRESSION_NODES.has(node_id):
		return
	var tree: Dictionary = save.profile.get("skill_tree", {})
	var node: Dictionary = GameContent.PROGRESSION_NODES[node_id]
	var rank: int = int(tree.get(node_id, 0))
	if rank >= int(node.max_rank):
		_show_skill_tree("That skill is already mastered.")
		return
	if not GameContent.progression_requirements_met(node_id, tree):
		_show_skill_tree("The earlier lesson in this branch must be learned first.")
		return
	var cost: Dictionary = GameContent.progression_cost(node_id, rank)
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		_show_skill_tree("The company needs %d silver and %d provisions." % [int(cost.silver), int(cost.provisions)])
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	tree[node_id] = rank + 1
	save.profile.skill_tree = tree
	SaveService.save_data(save)
	_show_skill_tree("%s is now part of company training." % String(node.name))

func _build_run_ui() -> void:
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	hud_label = _make_label("", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hud_label.position = Vector2(14.0, 28.0)
	hud_label.size = Vector2(size.x - 76.0, 54.0)
	ui_root.add_child(hud_label)
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(14.0, 84.0)
	health_bar.size = Vector2(size.x - 100.0, 16.0)
	health_bar.max_value = player_max_hp
	health_bar.value = player_hp
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_theme_stylebox_override("background", _style_box(Color(0.05, 0.06, 0.06, 0.90), IRON.darkened(0.2), 1, 2))
	health_bar.add_theme_stylebox_override("fill", _style_box(BLOOD, AMBER, 1, 2))
	ui_root.add_child(health_bar)
	boss_label = _make_label("", 12, FOLKLORE.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
	boss_label.position = Vector2(34.0, 106.0)
	boss_label.size = Vector2(size.x - 68.0, 34.0)
	ui_root.add_child(boss_label)
	objective_label = _make_label("", 11, AMBER.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
	objective_label.position = Vector2(34.0, 132.0)
	objective_label.size = Vector2(size.x - 68.0, 32.0)
	ui_root.add_child(objective_label)
	pause_button = _make_button("II", 44.0)
	pause_button.position = Vector2(size.x - 58.0, 26.0)
	pause_button.size = Vector2(44.0, 44.0)
	pause_button.pressed.connect(_toggle_pause)
	ui_root.add_child(pause_button)
	skill_button = _make_button("GUARD\nSTEP", 74.0, IRON)
	skill_button.position = Vector2(size.x - 100.0, size.y - 112.0)
	skill_button.size = Vector2(82.0, 74.0)
	skill_button.pressed.connect(_guard_step)
	ui_root.add_child(skill_button)
	pause_label = _make_label("", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	pause_label.position = Vector2(40.0, size.y * 0.42)
	pause_label.size = Vector2(size.x - 80.0, 90.0)
	ui_root.add_child(pause_label)
	_update_hud()

func _toggle_pause() -> void:
	if choosing_upgrade:
		return
	run_paused = not run_paused
	pause_button.text = "GO" if run_paused else "II"
	pause_label.text = "EXPEDITION PAUSED\nProgress has been saved" if run_paused else ""
	if run_paused:
		_snapshot_run()
		SaveService.save_data(save)

func _update_hud() -> void:
	if hud_label == null:
		return
	var remaining: float = maxf(0.0, RUN_SECONDS - run_elapsed)
	hud_label.text = "%s    LEVEL %d\nHP %d/%d    XP %d/%d    KILLS %d" % [_format_time(remaining), run_level, ceili(player_hp), ceili(player_max_hp), run_xp, next_xp, run_kills]
	if health_bar != null:
		health_bar.max_value = player_max_hp
		health_bar.value = clampf(player_hp, 0.0, player_max_hp)
	if objective_label != null and GameContent.OBJECTIVES.has(objective_id):
		var objective: Dictionary = GameContent.OBJECTIVES[objective_id]
		var objective_state: String = "DONE" if objective_complete else "%d/%d" % [floori(objective_progress), ceili(float(objective.get("target", 1.0)))]
		objective_label.text = "OBJECTIVE: %s  %s" % [String(objective.name).to_upper(), objective_state]
	if skill_button != null:
		skill_button.text = "GUARD\nREADY" if guard_cooldown <= 0.0 else "GUARD\n%.1fs" % guard_cooldown
		skill_button.disabled = guard_cooldown > 0.0

func _build_results_ui() -> void:
	_clear_ui()
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 28)
	ui_root.add_theme_constant_override("margin_right", 28)
	ui_root.add_theme_constant_override("margin_top", 130)
	ui_root.add_theme_constant_override("margin_bottom", 100)
	ui_root.theme = theme_main
	add_child(ui_root)
	var panel: PanelContainer = _make_panel(true)
	panel.name = "ResultsPanel"
	ui_root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	box.add_child(_make_label("THE BARROW IS QUIET" if bool(result_data.victory) else "THE COMPANY WITHDRAWS", 23, FOLKLORE if bool(result_data.victory) else PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Time %s\n%d enemies / %d elites\nVeteran rating %d%%" % [_format_time(float(result_data.time)), int(result_data.kills), int(result_data.elites), roundi(float(result_data.rating) * 100.0)], 15, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("%s\n%s" % ["OBJECTIVE COMPLETE" if bool(result_data.get("objective_complete", false)) else "OBJECTIVE INCOMPLETE", "CONTRACT COMPLETE" if bool(result_data.get("contract_complete", false)) else "NO CONTRACT REWARD"], 12, AMBER.lightened(0.1), HORIZONTAL_ALIGNMENT_CENTER))
	var doctrine_name: String = String(GameContent.DOCTRINES.get(String(result_data.get("doctrine", active_doctrine)), {}).get("name", active_doctrine))
	var curse_name: String = String(GameContent.CURSES.get(String(result_data.get("curse", active_curse)), {}).get("name", active_curse))
	box.add_child(_make_label("%s / %s\nRelics carried: %d" % [doctrine_name.to_upper(), curse_name.to_upper(), relics.size()], 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var loot_count: int = int(result_data.get("stored_loot", 0))
	var salvaged_count: int = int(result_data.get("salvaged_loot", 0))
	box.add_child(_make_label("EQUIPMENT RECOVERED: %d%s" % [loot_count, "  -  %d DISMANTLED" % salvaged_count if salvaged_count > 0 else ""], 12, FOLKLORE.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("+%d SILVER     +%d PROVISIONS" % [int(result_data.silver), int(result_data.provisions)], 16, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
	var again: Button = _make_button("MARCH AGAIN", 58.0, BURGUNDY)
	again.pressed.connect(_show_weapon_picker)
	box.add_child(again)
	var camp: Button = _make_button("RETURN TO CAMP", 52.0)
	camp.pressed.connect(_show_camp)
	box.add_child(camp)

func _show_settings() -> void:
	screen = Screen.SETTINGS
	_clear_ui()
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 22)
	ui_root.add_theme_constant_override("margin_right", 22)
	ui_root.add_theme_constant_override("margin_top", 52)
	ui_root.add_theme_constant_override("margin_bottom", 32)
	ui_root.theme = theme_main
	add_child(ui_root)
	var panel: PanelContainer = _make_panel(true)
	panel.name = "SettingsPanel"
	ui_root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	box.add_child(_make_label("SETTINGS & FIELD LEDGER", 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	for setting_data: Dictionary in [{"key": "music", "name": "MUSIC"}, {"key": "sfx", "name": "SOUND"}, {"key": "effect_density", "name": "EFFECT DENSITY"}]:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_child(_make_label(String(setting_data.name), 12, PARCHMENT, HORIZONTAL_ALIGNMENT_LEFT))
		var slider: HSlider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(save.settings[String(setting_data.key)])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_setting_slider_changed.bind(String(setting_data.key)))
		row.add_child(slider)
		box.add_child(row)
	var shake: CheckButton = CheckButton.new()
	shake.text = "SCREEN SHAKE"
	shake.button_pressed = bool(save.settings.screen_shake)
	shake.toggled.connect(_setting_toggle_changed.bind("screen_shake"))
	box.add_child(shake)
	var handed: CheckButton = CheckButton.new()
	handed.text = "LEFT-HANDED ACTION BUTTON"
	handed.button_pressed = bool(save.settings.left_handed)
	handed.toggled.connect(_setting_toggle_changed.bind("left_handed"))
	box.add_child(handed)
	box.add_child(_make_label("SAVE BACKUP", 14, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
	var save_text: TextEdit = TextEdit.new()
	save_text.custom_minimum_size.y = 122.0
	save_text.placeholder_text = "Exported backup code appears here. Paste a code here to import it."
	save_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.add_child(save_text)
	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 8)
	var export_button: Button = _make_button("EXPORT", 46.0)
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.pressed.connect(_export_save.bind(save_text))
	save_row.add_child(export_button)
	var import_button: Button = _make_button("IMPORT", 46.0)
	import_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button.pressed.connect(_import_save.bind(save_text))
	save_row.add_child(import_button)
	box.add_child(save_row)
	var reload_button: Button = _make_button("RELOAD APP / CHECK FOR UPDATE", 50.0, AMBER.darkened(0.35))
	reload_button.name = "ReloadAppButton"
	reload_button.pressed.connect(_reload_app)
	box.add_child(reload_button)
	status_label = _make_label("", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(status_label)
	var back: Button = _make_button("BACK TO CAMP", 50.0, BURGUNDY)
	back.pressed.connect(_show_camp)
	box.add_child(back)
	queue_redraw()

func _setting_slider_changed(value: float, key: String) -> void:
	save.settings[key] = value
	_update_audio_volumes()
	SaveService.save_data(save)

func _setting_toggle_changed(value: bool, key: String) -> void:
	save.settings[key] = value
	SaveService.save_data(save)

func _reload_app() -> void:
	status_label.text = "Clearing the old build and downloading the latest one..."
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(async()=>{try{const registrations=await navigator.serviceWorker.getRegistrations();await Promise.all(registrations.map(r=>r.unregister()));const keys=await caches.keys();await Promise.all(keys.map(k=>caches.delete(k)));const base=new URL('.',location.href);const assets=['index.html','index.js','index.pck','index.wasm','index.service.worker.js'];await Promise.allSettled(assets.map(name=>fetch(new URL(name,base),{cache:'reload'})));}catch(e){}const u=new URL(location.href);u.searchParams.set('fresh',Date.now());location.replace(u.toString());})()")
	else:
		get_tree().reload_current_scene()

func _export_save(field: TextEdit) -> void:
	var code: String = SaveService.export_code(save)
	field.text = code
	field.select_all()
	DisplayServer.clipboard_set(code)
	status_label.text = "Backup shown above. Select and copy it."

func _import_save(field: TextEdit) -> void:
	var imported: Dictionary = SaveService.import_code(field.text)
	if imported.is_empty():
		status_label.text = "That backup code is not valid."
		return
	save = imported
	SaveService.save_data(save)
	status_label.text = "Backup restored. Return to camp to see it."

func _clear_ui() -> void:
	if is_instance_valid(ui_root):
		ui_root.queue_free()
	ui_root = null
	hud_label = null
	objective_label = null
	boss_label = null
	pause_label = null
	skill_button = null
	pause_button = null
	status_label = null
	resource_label = null
	health_bar = null

func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	add_child(music_player)
	music_player.finished.connect(_restart_music)
	for index: int in 4:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Sfx%d" % index
		add_child(player)
		sfx_players.append(player)
	sfx_streams = {
		"strike": load("res://assets/audio/strike.wav"),
		"guard": load("res://assets/audio/guard.wav"),
		"pickup": load("res://assets/audio/pickup.wav"),
		"hurt": load("res://assets/audio/hurt.wav")
	}
	_update_audio_volumes()

func _play_music(music_id: String) -> void:
	if music_player == null or (current_music == music_id and music_player.playing):
		return
	current_music = music_id
	music_player.stream = load("res://assets/audio/%s_theme.wav" % music_id)
	music_player.play()

func _restart_music() -> void:
	if music_player != null and music_player.stream != null:
		music_player.play()

func _play_sfx(sfx_id: String, throttle: float = 0.06) -> void:
	if sfx_players.is_empty() or not sfx_streams.has(sfx_id) or sfx_throttle > 0.0:
		return
	sfx_throttle = throttle
	var player: AudioStreamPlayer = sfx_players[sfx_cursor % sfx_players.size()]
	sfx_cursor += 1
	player.stream = sfx_streams[sfx_id]
	player.play()

func _update_audio_volumes() -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(maxf(0.001, float(save.settings.music)))
		music_player.stream_paused = float(save.settings.music) <= 0.001
	for player: AudioStreamPlayer in sfx_players:
		player.volume_db = linear_to_db(maxf(0.001, float(save.settings.sfx)))

func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	if display_font != null and body_font != null:
		label.add_theme_font_override("font", display_font if font_size >= 18 else body_font)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = float(font_size + 7) * float(text.count("\n") + 1)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.035, 0.038, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _make_button(text: String, minimum_height: float, color: Color = IRON.darkened(0.35)) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false
	button.custom_minimum_size.y = minimum_height
	if body_bold_font != null:
		button.add_theme_font_override("font", body_bold_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _style_box(color, PARCHMENT_DARK.darkened(0.25), 2))
	button.add_theme_stylebox_override("hover", _style_box(color.lightened(0.08), AMBER, 2))
	button.add_theme_stylebox_override("pressed", _style_box(color.darkened(0.12), AMBER.lightened(0.2), 3))
	button.add_theme_stylebox_override("disabled", _style_box(INK.lightened(0.08), IRON.darkened(0.2), 2))
	button.add_theme_color_override("font_color", PARCHMENT)
	button.add_theme_color_override("font_disabled_color", IRON.lightened(0.18))
	return button

func _make_panel(ornate: bool = false) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	if ornate and ui_frame_texture != null:
		var frame: StyleBoxTexture = StyleBoxTexture.new()
		frame.texture = ui_frame_texture
		frame.set_texture_margin(SIDE_LEFT, 42.0)
		frame.set_texture_margin(SIDE_TOP, 42.0)
		frame.set_texture_margin(SIDE_RIGHT, 42.0)
		frame.set_texture_margin(SIDE_BOTTOM, 42.0)
		frame.content_margin_left = 18.0
		frame.content_margin_top = 18.0
		frame.content_margin_right = 18.0
		frame.content_margin_bottom = 18.0
		panel.add_theme_stylebox_override("panel", frame)
	else:
		panel.add_theme_stylebox_override("panel", _style_box(Color(0.055, 0.063, 0.067, 0.92), PARCHMENT_DARK.darkened(0.35), 2, 14))
	return panel

func _style_box(color: Color, border: Color, width: int, padding: int = 10) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _build_theme() -> Theme:
	var result: Theme = Theme.new()
	display_font = load("res://assets/fonts/PixelifySans.ttf") if ResourceLoader.exists("res://assets/fonts/PixelifySans.ttf") else ThemeDB.fallback_font
	body_font = load("res://assets/fonts/AtkinsonHyperlegible-Regular.otf") if ResourceLoader.exists("res://assets/fonts/AtkinsonHyperlegible-Regular.otf") else ThemeDB.fallback_font
	body_bold_font = load("res://assets/fonts/AtkinsonHyperlegible-Bold.otf") if ResourceLoader.exists("res://assets/fonts/AtkinsonHyperlegible-Bold.otf") else body_font
	result.set_default_font(body_font)
	result.set_default_font_size(15)
	result.set_font("font", "Button", body_bold_font)
	result.set_font("font", "CheckButton", body_bold_font)
	result.set_color("font_color", "Label", PARCHMENT)
	result.set_color("font_color", "Button", PARCHMENT)
	result.set_color("font_color", "CheckButton", PARCHMENT)
	return result

func _update_resource_label() -> void:
	if resource_label != null:
		resource_label.text = "%d SILVER       %d PROVISIONS" % [int(save.profile.silver), int(save.profile.provisions)]

func _format_time(seconds: float) -> String:
	var safe: int = maxi(0, floori(seconds))
	return "%02d:%02d" % [safe / 60, safe % 60]

func _point_over_action_button(point: Vector2) -> bool:
	return (skill_button != null and skill_button.get_global_rect().has_point(point)) or (pause_button != null and pause_button.get_global_rect().has_point(point))

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

func _draw_run_world() -> void:
	for hazard: HazardState in hazards:
		var hazard_color: Color = Color(FOLKLORE, 0.18 if not hazard.triggered else 0.32)
		draw_circle(hazard.position + shake_offset, hazard.radius, hazard_color)
		draw_arc(hazard.position + shake_offset, hazard.radius, 0.0, TAU, 28, FOLKLORE, 2.0)
	for trap: TrapState in traps:
		_draw_trap(trap.position + shake_offset, trap.radius)
	for pickup: PickupState in pickups:
		var pos: Vector2 = pickup.position + shake_offset
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -5), pos + Vector2(4, 0), pos + Vector2(0, 5), pos + Vector2(-4, 0)]), AMBER)
	for projectile: ProjectileState in projectiles:
		var pos: Vector2 = projectile.position + shake_offset
		if projectile.kind == "enemy_arrow":
			draw_line(pos - projectile.velocity.normalized() * 8.0, pos + projectile.velocity.normalized() * 4.0, projectile.color, 2.0)
		elif projectile.kind == "witchfire":
			draw_circle(pos, projectile.radius + 3.0, Color(projectile.color, 0.16))
			draw_circle(pos, projectile.radius, projectile.color)
			draw_arc(pos, projectile.radius + 3.0, 0.0, TAU, 12, Color(projectile.color, 0.8), 1.5)
		else:
			draw_circle(pos, projectile.radius, projectile.color)
			draw_line(pos, pos - projectile.velocity.normalized() * 9.0, projectile.color.darkened(0.25), 2.0)
	for enemy: EnemyState in enemies:
		_draw_enemy(enemy, shake_offset)
	for effect: EffectState in effects:
		var alpha: float = clampf(effect.life / 0.25, 0.0, 1.0)
		if effect.kind == "thrust":
			var thrust_origin: Vector2 = effect.position + shake_offset
			var thrust_length: float = effect.radius * (1.12 - alpha * 0.18)
			var thrust_tip: Vector2 = thrust_origin + effect.direction * thrust_length
			var side: Vector2 = effect.direction.orthogonal() * 4.0
			draw_line(thrust_origin, thrust_tip, Color(effect.color, alpha), 4.0)
			draw_colored_polygon(PackedVector2Array([thrust_tip, thrust_tip - effect.direction * 9.0 + side, thrust_tip - effect.direction * 9.0 - side]), Color(effect.color, alpha))
		elif effect.kind == "arc":
			var arc_angle: float = effect.direction.angle()
			draw_arc(effect.position + shake_offset, effect.radius * (1.0 - alpha * 0.15), arc_angle - 1.15, arc_angle + 1.15, 18, Color(effect.color, alpha), 5.0)
		else:
			draw_arc(effect.position + shake_offset, effect.radius * (1.15 - alpha * 0.15), 0.0, TAU, 20, Color(effect.color, alpha), 2.0)
	_draw_player(player_position + shake_offset)
	var font: Font = theme_main.default_font
	for item: FloatTextState in float_texts:
		draw_string(font, item.position + shake_offset, item.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 13, Color(item.color, clampf(item.life / 0.7, 0.0, 1.0)))
	if joystick_touch_id >= 0:
		draw_circle(joystick_origin, 47.0, Color(0.08, 0.09, 0.10, 0.55))
		draw_arc(joystick_origin, 47.0, 0.0, TAU, 24, Color(PARCHMENT_DARK, 0.55), 2.0)
		draw_circle(joystick_origin + joystick_vector * 33.0, 18.0, Color(PARCHMENT, 0.55))

func _draw_player(pos: Vector2) -> void:
	var moving: bool = player_move_vector.length_squared() > 0.01
	var gait: float = sin(run_elapsed * 9.0) if moving else sin(run_elapsed * 3.0) * 0.22
	var bob: float = roundf(gait * (2.4 if moving else 0.65))
	var attack_phase: float = 0.0
	if player_attack_timer > 0.0:
		attack_phase = sin((1.0 - player_attack_timer / player_attack_duration) * PI)
	var attack_push: Vector2 = player_attack_direction * attack_phase * (7.0 if player_attack_kind in ["thrust", "sweep"] else 2.0)
	_draw_actor_shadow(pos + Vector2(0.0, 7.0), 11.0 * (1.0 + absf(gait) * 0.05), 0.58)
	var facing: String = "left" if last_move_vector.x < -0.08 else "right"
	var texture: Texture2D = actor_textures.get("player_%s" % facing) as Texture2D
	var class_frames: Array = actor_frames.get(active_class, [])
	if class_frames.size() == 8:
		var animation_sequence: Array[int] = [0, 1, 2, 3, 4, 3, 2, 1]
		var frame_index: int = 0
		if attack_phase > 0.1:
			frame_index = 6 if player_attack_kind in ["thrust", "sweep"] else 5
		elif moving:
			frame_index = animation_sequence[int(floor(run_elapsed * 8.0)) % animation_sequence.size()]
		texture = class_frames[frame_index] as Texture2D
	if texture != null:
		var texture_size: Vector2 = texture.get_size()
		var sprite_scale: Vector2 = Vector2(1.0 - gait * 0.035, 1.0 + gait * 0.035)
		var draw_size: Vector2 = texture_size * sprite_scale
		var sway: float = roundf(gait * 0.75) if moving else 0.0
		draw_texture_rect(texture, Rect2(pos.x - draw_size.x * 0.5 + sway + attack_push.x, pos.y - draw_size.y * 0.70 + bob + attack_push.y, draw_size.x, draw_size.y), false)
	else:
		var flash: Color = PARCHMENT.lightened(0.2) if guard_timer > 0.0 else PARCHMENT
		draw_rect(Rect2(pos + Vector2(-7, -9), Vector2(14, 19)), BURGUNDY)
		draw_rect(Rect2(pos + Vector2(-6, -13), Vector2(12, 8)), flash)
		draw_line(pos + Vector2(5, 0), pos + last_move_vector * 20.0, PARCHMENT_DARK, 3.0)
	if attack_phase > 0.0:
		if player_attack_kind == "thrust":
			draw_line(pos + player_attack_direction * 8.0, pos + player_attack_direction * (23.0 + attack_phase * 18.0), player_attack_color, 3.0)
		elif player_attack_kind == "sweep":
			draw_arc(pos, 25.0 + attack_phase * 8.0, player_attack_direction.angle() - 1.1, player_attack_direction.angle() + 1.1, 14, Color(player_attack_color, 0.9), 3.0)
		else:
			draw_circle(pos + player_attack_direction * 13.0, 3.0 + attack_phase * 2.0, Color(player_attack_color, 0.85))
	draw_arc(pos, 15.0, 0.0, TAU, 16, Color(AMBER, clampf(1.0 - guard_cooldown / 6.0, 0.15, 0.8)), 2.0)

func _draw_enemy(enemy: EnemyState, offset: Vector2) -> void:
	var pos: Vector2 = enemy.position + offset
	var gait_rate: float = 7.0
	if enemy.kind == "wolf":
		gait_rate = 11.0
	elif enemy.kind == "crow":
		gait_rate = 14.0
	elif enemy.special:
		gait_rate = 4.5
	var gait: float = sin(run_elapsed * gait_rate + float(enemy.uid) * 0.73)
	_draw_actor_shadow(pos + Vector2(0.0, enemy.radius * 0.42), enemy.radius * 0.82 * (1.0 + absf(gait) * 0.06), 0.48)
	if enemy.id in ["blighted", "grave_guard", "barrow_knight"]:
		var aura_alpha: float = 0.10 if enemy.id == "blighted" else (0.15 if enemy.id == "grave_guard" else 0.20)
		draw_circle(pos, enemy.radius * 1.18, Color(FOLKLORE, aura_alpha))
		if enemy.id == "barrow_knight":
			draw_arc(pos, enemy.radius + 5.0, 0.0, TAU, 24, Color(FOLKLORE, 0.8), 3.0)
	if enemy.pin_timer > 0.0:
		draw_arc(pos, enemy.radius + 3.0, 0.0, TAU, 12, Color("b9a58d", 0.8), 2.0)
	if enemy.bleed_damage > 0.0:
		draw_circle(pos + Vector2(-enemy.radius * 0.4, -enemy.radius * 0.2), 2.0, BLOOD)
	if enemy.scorch_damage > 0.0:
		draw_circle(pos + Vector2(enemy.radius * 0.4, -enemy.radius * 0.15), 2.0, FOLKLORE)
	var facing: String = "right" if player_position.x >= enemy.position.x else "left"
	var texture: Texture2D = actor_textures.get("%s_%s" % [enemy.id, facing]) as Texture2D
	var health_bar_y: float = pos.y - enemy.radius - 11.0
	if texture != null:
		var texture_size: Vector2 = texture.get_size()
		var bob: float = roundf(gait * (2.8 if enemy.kind == "crow" else 1.8))
		var sprite_scale: Vector2 = Vector2(1.0 - gait * 0.035, 1.0 + gait * 0.035)
		if enemy.kind == "crow":
			sprite_scale = Vector2(1.0 + absf(gait) * 0.05, 0.88 + (gait + 1.0) * 0.06)
		var draw_size: Vector2 = texture_size * sprite_scale
		var sway: float = roundf(gait * 0.65) if enemy.kind != "crow" else 0.0
		draw_texture_rect(texture, Rect2(pos.x - draw_size.x * 0.5 + sway, pos.y - draw_size.y * 0.70 + bob, draw_size.x, draw_size.y), false)
		health_bar_y = pos.y - draw_size.y * 0.70 - 5.0
	else:
		_draw_enemy_fallback(enemy, pos)
	if enemy.special:
		var width: float = enemy.radius * 2.2
		draw_rect(Rect2(Vector2(pos.x - width * 0.5, health_bar_y), Vector2(width, 3.0)), Color(0.08, 0.09, 0.1, 0.9))
		draw_rect(Rect2(Vector2(pos.x - width * 0.5, health_bar_y), Vector2(width * clampf(enemy.health / enemy.max_health, 0.0, 1.0), 3.0)), FOLKLORE if enemy.kind == "boss" else BURGUNDY.lightened(0.15))

func _draw_actor_shadow(pos: Vector2, radius: float, alpha: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 12:
		var angle: float = float(index) / 12.0 * TAU
		points.append(pos + Vector2(cos(angle) * radius, sin(angle) * radius * 0.34))
	draw_colored_polygon(points, Color(0.015, 0.018, 0.02, alpha))

func _draw_enemy_fallback(enemy: EnemyState, pos: Vector2) -> void:
	match enemy.kind:
		"wolf":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-11, 5), pos + Vector2(0, -7), pos + Vector2(13, 4), pos + Vector2(0, 9)]), enemy.color)
		"crow":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, 2), pos, pos + Vector2(0, 7), pos + Vector2(14, 2), pos + Vector2(3, -5), pos + Vector2(-3, -5)]), enemy.color)
		"boss":
			draw_rect(Rect2(pos + Vector2(-18, -22), Vector2(36, 43)), enemy.color.darkened(0.45))
		_:
			draw_rect(Rect2(pos + Vector2(-8, -11), Vector2(16, 23)), enemy.color)
			draw_circle(pos + Vector2(0, -12), 7.0, PARCHMENT_DARK.darkened(0.2))

func _draw_trap(pos: Vector2, radius: float) -> void:
	draw_circle(pos, radius, Color(0.12, 0.13, 0.14, 0.22))
	for index: int in 7:
		var point: Vector2 = pos + Vector2.RIGHT.rotated(float(index) / 7.0 * TAU) * radius * 0.62
		draw_colored_polygon(PackedVector2Array([point + Vector2(-3, 3), point + Vector2(0, -5), point + Vector2(3, 3)]), IRON.lightened(0.2))

func _draw_camp_progress() -> void:
	var armory: int = int(save.profile.armory_level)
	var training: int = int(save.profile.training_level)
	var quartermaster: int = int(save.profile.quartermaster_level)
	for index: int in armory:
		var x: float = 35.0 + index * 20.0
		draw_rect(Rect2(x, size.y * 0.70, 13.0, 30.0), Color(IRON, 0.75))
	for index: int in training:
		var x: float = size.x - 40.0 - index * 12.0
		draw_line(Vector2(x, size.y * 0.66), Vector2(x - 5.0, size.y * 0.71), Color(PARCHMENT_DARK, 0.8), 3.0)
	if quartermaster > 0:
		draw_circle(Vector2(size.x * 0.5, size.y * 0.63), 15.0 + quartermaster * 2.0, Color(AMBER, 0.18 + quartermaster * 0.05))
