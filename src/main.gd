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

# The anchor is the bottom-center of the sprite's transparent canvas. Each
# source sheet is bottom-aligned, so every tier grows upward from the same
# painted foundation while retaining its original aspect ratio.
const CAMP_STRUCTURE_LAYOUT: Dictionary = {
	"veterans_hall": {"anchor": Vector2(195.0, 360.0), "height": 198.0},
	"armory": {"anchor": Vector2(81.0, 458.0), "height": 160.0},
	"quartermaster": {"anchor": Vector2(316.0, 445.0), "height": 174.0},
	"blacksmith": {"anchor": Vector2(91.0, 582.0), "height": 170.0},
	"training": {"anchor": Vector2(319.0, 618.0), "height": 160.0},
	"campfire": {"anchor": Vector2(201.0, 650.0), "height": 112.0}
}

# Touch targets deliberately follow the occupied plot bands instead of each
# source image's transparent canvas. This keeps generous phone-sized targets
# without letting a lower building steal taps from the structure above it.
const CAMP_STRUCTURE_HIT_RECTS: Dictionary = {
	"veterans_hall": Rect2(86.0, 175.0, 218.0, 185.0),
	"armory": Rect2(13.0, 360.0, 168.0, 88.0),
	"quartermaster": Rect2(227.0, 360.0, 163.0, 82.0),
	"blacksmith": Rect2(7.0, 457.0, 172.0, 130.0),
	"training": Rect2(228.0, 498.0, 162.0, 112.0),
	"campfire": Rect2(120.0, 610.0, 170.0, 60.0)
}

# The walkable hub uses these anchors for diegetic interactions. The existing
# generous building buttons remain available as an accessibility shortcut.
const CAMP_INTERACTION_POINTS: Dictionary = {
	"veterans_hall": Vector2(195.0, 356.0),
	"armory": Vector2(116.0, 456.0),
	"quartermaster": Vector2(286.0, 454.0),
	"blacksmith": Vector2(125.0, 584.0),
	"training": Vector2(286.0, 620.0),
	"campfire": Vector2(201.0, 686.0),
	"gate": Vector2(195.0, 810.0)
}

const CAMP_INTERACTION_RADIUS: float = 74.0
const CAMP_WALK_SPEED: float = 104.0
const WORLD_WIDTH_SCREENS: float = 3.0
const WORLD_HEIGHT_SCREENS: float = 4.0
const CAMP_GATE_TRIGGER_LOCAL_Y: float = 826.0
const CAMP_GATE_HALF_WIDTH: float = 58.0
const GATE_CLEAR_DISTANCE: float = 72.0

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
	var bleed_ticks: int = 0
	var scorch_timer: float = 0.0
	var scorch_damage: float = 0.0
	var scorch_ticks: int = 0
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
	var target_uid: int = -1
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
	var kind: String = "caltrops"

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

class ExplorationPoint:
	var id: String = ""
	var kind: String = "cache"
	var label: String = ""
	var position: Vector2 = Vector2.ZERO
	var discovered: bool = false
	var silver: int = 0
	var provisions: int = 0
	var dread: float = 0.0

var screen: Screen = Screen.CAMP
var save: Dictionary = {}
var result_data: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var theme_main: Theme
var display_font: Font
var body_font: Font
var body_bold_font: Font
var camp_texture: Texture2D
var camp_foundation_texture: Texture2D
var camp_building_textures: Dictionary = {}
var camp_landmark_textures: Dictionary = {}
var camp_building_outline_textures: Dictionary = {}
var camp_landmark_outline_textures: Dictionary = {}
var moor_texture: Texture2D
var ui_frame_texture: Texture2D
var camp_title_crest_texture: Texture2D
var silver_icon_texture: Texture2D
var provisions_icon_texture: Texture2D
var settings_cog_texture: Texture2D
var actor_textures: Dictionary = {}
var actor_frames: Dictionary = {}
var ui_root: Control
var status_label: Label
var silver_value_label: Label
var provisions_value_label: Label
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
var weapon_picker_category: int = 0
var inventory_page: int = 0
var selected_item_uid: String = ""
var second_wind_used: bool = false
var camp_player_position: Vector2 = Vector2(195.0, 734.0)
var camp_elapsed: float = 0.0
var camp_move_vector: Vector2 = Vector2.ZERO
var camp_interaction_target: String = ""
var camp_interact_button: Button
var expedition_interact_button: Button

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
var run_dread_bonus: float = 0.0
var run_discoveries: int = 0
var run_exploration_silver: int = 0
var run_exploration_provisions: int = 0
var exploration_points: Array[ExplorationPoint] = []
var nearby_exploration_index: int = -1

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
var camp_highlighted_structure: String = ""
var world_size: Vector2 = Vector2(1170.0, 3376.0)
var camp_world_origin: Vector2 = Vector2(390.0, 0.0)
var camera_offset: Vector2 = Vector2(390.0, 0.0)
var run_gate_cleared: bool = false

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	camp_texture = load("res://assets/backgrounds/camp.png")
	camp_foundation_texture = load("res://assets/camp_layers/camp_foundation.png")
	_load_camp_layer_textures()
	moor_texture = load("res://assets/backgrounds/moor.png")
	ui_frame_texture = load("res://assets/ui/company_ledger_512.png")
	camp_title_crest_texture = load("res://assets/ui/generated/camp_title_crest.png")
	silver_icon_texture = load("res://assets/ui/generated/silver_icon.png")
	provisions_icon_texture = load("res://assets/ui/generated/provisions_icon.png")
	settings_cog_texture = load("res://assets/ui/generated/settings_cog.png")
	_load_actor_textures()
	theme_main = _build_theme()
	save = SaveService.load_data()
	_configure_world()
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
		if _camp_hub_active():
			_process_camp(delta)
		queue_redraw()

func _draw() -> void:
	draw_set_transform(-camera_offset)
	_draw_world_background()
	_draw_camp_buildings()
	if screen == Screen.CAMP and _camp_hub_active():
		_draw_camp_life()
	elif screen == Screen.RUN:
		_draw_run_world()
	draw_set_transform(Vector2.ZERO)
	if screen == Screen.RUN:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.18))
		_draw_run_controls()
	elif screen == Screen.CAMP:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.16))
		if _camp_hub_active():
			_draw_camp_controls()
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.027, 0.62))

func _configure_world() -> void:
	world_size = Vector2(size.x * WORLD_WIDTH_SCREENS, size.y * WORLD_HEIGHT_SCREENS)
	camp_world_origin = Vector2(size.x, 0.0)
	# Migrate the old screen-local camp position into the continuous map.
	if camp_player_position.x < size.x:
		camp_player_position += camp_world_origin
	camera_offset = camp_world_origin

func _draw_world_background() -> void:
	if moor_texture != null:
		for tile_x: int in int(WORLD_WIDTH_SCREENS):
			for tile_y: int in int(WORLD_HEIGHT_SCREENS):
				draw_texture_rect(moor_texture, Rect2(Vector2(tile_x * size.x, tile_y * size.y), size), false)
	var foundation: Texture2D = camp_foundation_texture if camp_foundation_texture != null else camp_texture
	if foundation != null:
		draw_texture_rect(foundation, Rect2(camp_world_origin, size), false)

func _visible_world_rect() -> Rect2:
	return Rect2(camera_offset, size)

func _update_world_camera(focus: Vector2, safe_town: bool, instant: bool = false) -> void:
	var desired: Vector2
	if safe_town:
		desired = camp_world_origin
	else:
		desired = focus - Vector2(size.x * 0.5, size.y * 0.52)
	desired.x = clampf(desired.x, 0.0, maxf(0.0, world_size.x - size.x))
	desired.y = clampf(desired.y, 0.0, maxf(0.0, world_size.y - size.y))
	camera_offset = desired if instant else camera_offset.lerp(desired, 0.16)

func _camp_gate_position() -> Vector2:
	return camp_world_origin + Vector2(size.x * 0.5, CAMP_GATE_TRIGGER_LOCAL_Y)

func _input(event: InputEvent) -> void:
	if screen == Screen.CAMP:
		if not _camp_hub_active():
			return
		var camp_stick_center := Vector2(66.0, size.y - 76.0)
		if event is InputEventScreenTouch:
			var camp_touch: InputEventScreenTouch = event
			if camp_touch.pressed and joystick_touch_id < 0 and camp_touch.position.distance_to(camp_stick_center) <= 72.0:
				joystick_touch_id = camp_touch.index
				joystick_origin = camp_stick_center
				joystick_position = camp_touch.position
				joystick_vector = (camp_touch.position - camp_stick_center).limit_length(46.0) / 46.0
			elif not camp_touch.pressed and camp_touch.index == joystick_touch_id:
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
		elif event is InputEventScreenDrag:
			var camp_drag: InputEventScreenDrag = event
			if camp_drag.index == joystick_touch_id:
				joystick_position = camp_drag.position
				joystick_vector = (camp_drag.position - camp_stick_center).limit_length(46.0) / 46.0
		if event.is_action_pressed("guard_step"):
			_interact_with_camp_target()
		return
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

func _camp_hub_active() -> bool:
	return screen == Screen.CAMP and is_instance_valid(camp_interact_button) and camp_interact_button.is_inside_tree()

func _process_camp(delta: float) -> void:
	camp_elapsed += delta
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	direction = direction.normalized() if direction.length_squared() > 0.01 else Vector2.ZERO
	camp_move_vector = direction
	if direction.length_squared() > 0.01:
		last_move_vector = direction
		var movement: Vector2 = direction * CAMP_WALK_SPEED * delta
		var next_x := Vector2(camp_player_position.x + movement.x, camp_player_position.y)
		var next_y := Vector2(camp_player_position.x, camp_player_position.y + movement.y)
		if not _camp_position_blocked(next_x):
			camp_player_position.x = next_x.x
		if not _camp_position_blocked(next_y):
			camp_player_position.y = next_y.y
	var camp_left: float = camp_world_origin.x + 16.0
	var camp_right: float = camp_world_origin.x + size.x - 16.0
	var gate: Vector2 = _camp_gate_position()
	camp_player_position.x = clampf(camp_player_position.x, camp_left, camp_right)
	camp_player_position.y = clampf(camp_player_position.y, camp_world_origin.y + 176.0, camp_world_origin.y + size.y + 34.0)
	if camp_player_position.y >= gate.y:
		if absf(camp_player_position.x - gate.x) <= CAMP_GATE_HALF_WIDTH:
			_begin_expedition_from_gate()
			return
		camp_player_position.y = gate.y - 1.0
	_update_world_camera(camp_player_position, true)
	camp_interaction_target = _nearest_camp_interaction()
	if camp_interaction_target in CAMP_STRUCTURE_LAYOUT:
		camp_highlighted_structure = camp_interaction_target
	elif not camp_highlighted_structure.is_empty():
		camp_highlighted_structure = ""
	_update_camp_interact_button()

func _camp_position_blocked(position: Vector2) -> bool:
	for structure_id: String in CAMP_STRUCTURE_LAYOUT:
		if structure_id == "campfire":
			continue
		var texture: Texture2D
		if structure_id == "veterans_hall":
			texture = camp_landmark_textures.get("veterans_hall") as Texture2D
		else:
			texture = _camp_tier_texture(structure_id, int(save.profile.get(structure_id + "_level", 0)))
		var obstacle: Rect2 = _camp_structure_rect(structure_id, texture).grow(-10.0)
		if obstacle.has_point(position):
			return true
	return false

func _camp_interaction_position(target: String) -> Vector2:
	if target == "gate":
		return _camp_gate_position() + Vector2(0.0, -16.0)
	return camp_world_origin + Vector2(CAMP_INTERACTION_POINTS.get(target, Vector2.ZERO))

func _nearest_camp_interaction() -> String:
	var nearest: String = ""
	var nearest_distance: float = CAMP_INTERACTION_RADIUS
	for target: String in CAMP_INTERACTION_POINTS:
		var distance: float = camp_player_position.distance_to(_camp_interaction_position(target))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	return nearest

func _camp_interaction_text(target: String) -> String:
	match target:
		"veterans_hall": return "TALK TO VETERANS"
		"armory": return "ENTER ARMORY"
		"quartermaster": return "VISIT QUARTERMASTER"
		"blacksmith": return "ENTER BLACKSMITH"
		"training": return "ENTER TRAINING YARD"
		"campfire": return "PREPARE EXPEDITION"
		"gate": return "CROSS GATE TO BEGIN"
	return "WALK THE CAMP"

func _update_camp_interact_button() -> void:
	if not is_instance_valid(camp_interact_button):
		return
	camp_interact_button.text = _camp_interaction_text(camp_interaction_target)
	camp_interact_button.disabled = camp_interaction_target.is_empty() or camp_interaction_target == "gate"

func _interact_with_camp_target() -> void:
	match camp_interaction_target:
		"veterans_hall": _show_camp_expeditions()
		"armory", "quartermaster", "blacksmith", "training": _show_building_detail(camp_interaction_target)
		"campfire": _show_weapon_picker()

func _begin_expedition_from_gate() -> void:
	if screen != Screen.CAMP:
		return
	_reset_movement_input()
	if not save.active_run.is_empty():
		_resume_run()
		return
	_start_new_run(String(save.profile.get("starting_weapon", "spear")), true)

func _draw_camp_life() -> void:
	# A restrained ambient layer makes the restored hub feel occupied without
	# requiring physics or expensive particle systems on mobile web.
	var fire_phase: float = (sin(camp_elapsed * 8.0) + 1.0) * 0.5
	var fire_position := camp_world_origin + Vector2(201.0, 648.0)
	draw_circle(fire_position, 18.0 + fire_phase * 4.0, Color(AMBER, 0.08 + fire_phase * 0.04))
	for smoke_index: int in 3:
		var smoke_time: float = fmod(camp_elapsed * 17.0 + float(smoke_index) * 23.0, 72.0)
		var smoke_position := fire_position + Vector2(sin(camp_elapsed * 1.8 + smoke_index) * 6.0, -18.0 - smoke_time)
		draw_circle(smoke_position, 3.0 + smoke_time * 0.035, Color(0.45, 0.45, 0.42, maxf(0.0, 0.18 - smoke_time * 0.0022)))
	var gate_position := _camp_interaction_position("gate")
	var gate_alpha: float = 0.42 + (sin(camp_elapsed * 3.0) + 1.0) * 0.10
	draw_line(gate_position + Vector2(-18.0, -7.0), gate_position, Color(AMBER, gate_alpha), 2.0)
	draw_line(gate_position, gate_position + Vector2(18.0, -7.0), Color(AMBER, gate_alpha), 2.0)
	draw_string(theme_main.default_font, gate_position + Vector2(-52.0, -18.0), "CROSS TO BEGIN", HORIZONTAL_ALIGNMENT_CENTER, 104.0, 9, Color(PARCHMENT, 0.82))
	_draw_camp_player(camp_player_position)

func _draw_camp_controls() -> void:
	var stick_center := Vector2(66.0, size.y - 76.0)
	draw_circle(stick_center, 47.0, Color(0.08, 0.09, 0.10, 0.42))
	draw_arc(stick_center, 47.0, 0.0, TAU, 24, Color(PARCHMENT_DARK, 0.48), 2.0)
	draw_circle(stick_center + joystick_vector * 33.0, 18.0, Color(PARCHMENT, 0.50))

func _draw_camp_player(position: Vector2) -> void:
	var moving: bool = camp_move_vector.length_squared() > 0.01
	var gait: float = sin(camp_elapsed * 8.0) if moving else sin(camp_elapsed * 2.5) * 0.18
	var bob: float = roundf(gait * (2.2 if moving else 0.5))
	_draw_actor_shadow(position + Vector2(0.0, 7.0), 11.0, 0.52)
	var class_id: String = String(save.profile.get("starting_class", "warrior"))
	var frames: Array = actor_frames.get(class_id, [])
	var texture: Texture2D
	if frames.size() == 8:
		var sequence: Array[int] = [0, 1, 2, 3, 4, 3, 2, 1]
		var frame_index: int = sequence[int(floor(camp_elapsed * 8.0)) % sequence.size()] if moving else 0
		texture = frames[frame_index] as Texture2D
	else:
		var facing: String = "left" if last_move_vector.x < -0.08 else "right"
		texture = actor_textures.get("player_%s" % facing) as Texture2D
	if texture != null:
		var draw_size: Vector2 = texture.get_size()
		draw_texture_rect(texture, Rect2(position.x - draw_size.x * 0.5, position.y - draw_size.y * 0.70 + bob, draw_size.x, draw_size.y), false)

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
	if screen != Screen.RUN:
		return
	_update_world_camera(player_position, false)
	_update_exploration()
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
	# Dread reaching 100% is now nightfall rather than an abrupt failure. The
	# field remains playable long enough to defeat the boss and reach extraction,
	# with a twelve-minute safety limit for abandoned runs.
	elif run_elapsed >= RUN_SECONDS * 1.5:
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
	player_position.x = clampf(player_position.x, 18.0, world_size.x - 18.0)
	player_position.y = clampf(player_position.y, 18.0, world_size.y - 22.0)
	var gate: Vector2 = _camp_gate_position()
	if not run_gate_cleared and player_position.y >= gate.y + GATE_CLEAR_DISTANCE:
		run_gate_cleared = true
	elif run_gate_cleared and player_position.y <= gate.y and absf(player_position.x - gate.x) <= CAMP_GATE_HALF_WIDTH:
		_finish_run(false, true)
		return
	var field_recovery: float = _technique_total("health_regen") + _equipment_total("health_regen") + _relic_total("health_regen")
	if field_recovery > 0.0:
		recovery_timer += delta
		if recovery_timer >= 5.0:
			recovery_timer -= 5.0
			player_hp = minf(player_max_hp, player_hp + field_recovery)

func _current_dread() -> float:
	return clampf(run_elapsed / RUN_SECONDS * 100.0 + run_dread_bonus, 0.0, 100.0)

func _generate_exploration_points() -> void:
	exploration_points.clear()
	var definitions: Array[Dictionary] = [
		{"id": "abandoned_cart", "kind": "cache", "label": "ABANDONED CART", "position": Vector2(world_size.x * 0.30, size.y * 1.45), "silver": 14, "provisions": 2, "dread": 3.0},
		{"id": "waystone", "kind": "shrine", "label": "OLD WAYSTONE", "position": Vector2(world_size.x * 0.72, size.y * 1.62), "silver": 8, "provisions": 0, "dread": 5.0},
		{"id": "raider_camp", "kind": "danger", "label": "RAIDER CAMP", "position": Vector2(world_size.x * 0.25, size.y * 2.55), "silver": 24, "provisions": 4, "dread": 8.0},
		{"id": "barrow_mark", "kind": "barrow", "label": "BARROW MARK", "position": Vector2(world_size.x * 0.76, size.y * 3.20), "silver": 18, "provisions": 6, "dread": 10.0}
	]
	for definition: Dictionary in definitions:
		var point := ExplorationPoint.new()
		point.id = String(definition.id)
		point.kind = String(definition.kind)
		point.label = String(definition.label)
		point.position = definition.position
		point.silver = int(definition.silver)
		point.provisions = int(definition.provisions)
		point.dread = float(definition.dread)
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
		player_hp = minf(player_max_hp, player_hp + 20.0)
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
	if not boss_spawned and dread >= 88.0:
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
	var progress: float = dread / 100.0
	var rate: float = lerpf(1.25, 5.0, progress)
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
	enemy.bleed_ticks = 0
	enemy.scorch_timer = 0.0
	enemy.scorch_damage = 0.0
	enemy.scorch_ticks = 0
	enemy.pin_timer = 0.0
	enemies.append(enemy)

func _random_edge_position() -> Vector2:
	var margin: float = 28.0
	var visible: Rect2 = _visible_world_rect()
	var result: Vector2
	match rng.randi_range(0, 3):
		0: result = Vector2(rng.randf_range(visible.position.x, visible.end.x), visible.position.y - margin)
		1: result = Vector2(visible.end.x + margin, rng.randf_range(visible.position.y, visible.end.y))
		2: result = Vector2(rng.randf_range(visible.position.x, visible.end.x), visible.end.y + margin)
		_: result = Vector2(visible.position.x - margin, rng.randf_range(visible.position.y, visible.end.y))
	result.x = clampf(result.x, 8.0, world_size.x - 8.0)
	result.y = clampf(result.y, _camp_gate_position().y + 8.0, world_size.y - 8.0)
	return result

func _update_weapons(delta: float) -> void:
	target_refresh -= delta
	if target_refresh <= 0.0:
		target_refresh = 0.1
		nearest_target = _find_nearest_enemy(player_position)
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = float(weapon_timers.get(weapon_id, 0.0)) - delta
		if float(weapon_timers[weapon_id]) <= 0.0 and nearest_target != null:
			_fire_weapon(weapon_id)

func _weapon_rank_total(weapon_id: String, stat: String) -> float:
	if not GameContent.WEAPONS.has(weapon_id):
		return 0.0
	var total: float = 0.0
	var rank: int = int(weapons.get(weapon_id, 1))
	var bonuses: Array = GameContent.WEAPONS[weapon_id].get("rank_bonuses", [])
	for bonus_index: int in mini(rank - 1, bonuses.size()):
		total += float(Dictionary(bonuses[bonus_index]).get(stat, 0.0))
	return total

func _weapon_mastery_total(weapon_id: String, stat: String) -> float:
	if not bool(mastered.get(weapon_id, false)) or not GameContent.WEAPONS.has(weapon_id):
		return 0.0
	return float(GameContent.WEAPONS[weapon_id].get("mastery_stats", {}).get(stat, 0.0))

func _fire_weapon(weapon_id: String) -> void:
	var definition: Dictionary = GameContent.WEAPONS[weapon_id]
	var category: String = String(definition.category)
	var category_key: String = category.to_lower()
	var attack_speed: float = cooldown_reduction + _technique_total(category_key + "_attack_speed") + _equipment_total(category_key + "_attack_speed") + _class_total(category_key + "_attack_speed") + _doctrine_total(category_key + "_attack_speed") + _relic_total(category_key + "_attack_speed") + _weapon_rank_total(weapon_id, "attack_speed") + _weapon_mastery_total(weapon_id, "attack_speed")
	var cooldown: float = float(definition.cooldown) / maxf(0.35, 1.0 + attack_speed)
	weapon_timers[weapon_id] = maxf(0.16, cooldown)
	_play_sfx("strike", 0.08)
	var direction: Vector2 = (nearest_target.position - player_position).normalized()
	var category_damage: float = _technique_total(category_key + "_damage") + _equipment_total(category_key + "_damage") + _class_total(category_key + "_damage") + _doctrine_total(category_key + "_damage") + _relic_total(category_key + "_damage")
	var damage: float = float(definition.damage) * damage_multiplier * (1.0 + category_damage + _weapon_rank_total(weapon_id, "damage") + _weapon_mastery_total(weapon_id, "damage"))
	if active_doctrine == "pursuer" and last_move_vector.dot(direction) > 0.65:
		damage *= 1.0 + _doctrine_total("pursuit_damage")
	if player_hp <= player_max_hp * 0.5:
		damage *= 1.0 + _relic_total("wounded_damage") + _equipment_total("wounded_damage")
	var guard_strike: bool = guard_empowered and category == "MELEE"
	if guard_strike:
		damage *= 1.35
	var melee_area_scale: float = 1.0 + _technique_total("melee_area") + _weapon_rank_total(weapon_id, "melee_area") + _weapon_mastery_total(weapon_id, "melee_area")
	var pierce: int = int(definition.pierce) + int(_technique_total("pierce") + _weapon_rank_total(weapon_id, "pierce") + _weapon_mastery_total(weapon_id, "pierce"))
	var behavior: String = String(definition.behavior)
	player_attack_direction = direction
	player_attack_kind = behavior
	player_attack_color = definition.color
	player_attack_duration = 0.28 if category == "MELEE" else 0.18
	player_attack_timer = player_attack_duration
	if behavior == "thrust":
		var thrust_reach: float = float(definition.radius) + _technique_total("melee_range") + _equipment_total("melee_range") + _weapon_rank_total(weapon_id, "melee_range") + _weapon_mastery_total(weapon_id, "melee_range")
		_add_effect(player_position + direction * 14.0, thrust_reach, definition.color, "thrust", direction)
		for enemy: EnemyState in enemies.duplicate():
			var offset: Vector2 = enemy.position - player_position
			var distance: float = offset.length()
			if distance <= thrust_reach + enemy.radius and distance > 0.1 and direction.dot(offset.normalized()) >= 0.42 - minf(0.18, (melee_area_scale - 1.0) * 0.3):
				_damage_enemy(enemy, damage, true, "bleed", weapon_id)
				if guard_strike:
					enemy.stagger = maxf(enemy.stagger, 0.55)
		if guard_empowered:
			guard_empowered = false
	elif behavior == "sweep":
		var sweep_radius: float = float(definition.radius) * melee_area_scale
		_add_effect(player_position, sweep_radius, definition.color, "arc", direction)
		for enemy: EnemyState in enemies.duplicate():
			var offset: Vector2 = enemy.position - player_position
			if offset.length() <= sweep_radius + enemy.radius and (offset.length() < 0.1 or direction.dot(offset.normalized()) >= -0.15):
				_damage_enemy(enemy, damage, true, "bleed", weapon_id)
				var follow_up: float = _weapon_rank_total(weapon_id, "follow_up") + _weapon_mastery_total(weapon_id, "follow_up")
				if follow_up > 0.0 and enemies.has(enemy):
					_damage_enemy(enemy, damage * follow_up, true, "", weapon_id)
				if guard_strike and enemies.has(enemy):
					enemy.stagger = maxf(enemy.stagger, 0.55)
		if guard_empowered:
			guard_empowered = false
	elif behavior == "trap":
		if traps.size() < 12:
			var trap: TrapState = TrapState.new()
			trap.position = player_position - last_move_vector * 22.0
			trap.radius = float(definition.radius) * (1.0 + _technique_total("trap_area") + _weapon_rank_total(weapon_id, "trap_area") + _weapon_mastery_total(weapon_id, "trap_area"))
			trap.damage = damage
			trap.life = 6.0 * (1.0 + _technique_total("trap_duration") + _weapon_rank_total(weapon_id, "trap_duration") + _weapon_mastery_total(weapon_id, "trap_duration"))
			traps.append(trap)
	elif behavior == "fan":
		var count: int = 3 + projectile_bonus + int(_weapon_rank_total(weapon_id, "ranged_projectiles") + _weapon_mastery_total(weapon_id, "ranged_projectiles"))
		for index: int in count:
			var angle: float = deg_to_rad(lerpf(-18.0, 18.0, 0.5 if count == 1 else float(index) / float(count - 1)))
			_spawn_player_projectile(weapon_id, direction.rotated(angle), damage, pierce, 0.0, "bleed")
	elif behavior == "splash":
		var count: int = 3 + projectile_bonus + int(_weapon_rank_total(weapon_id, "ranged_projectiles") + _weapon_mastery_total(weapon_id, "ranged_projectiles"))
		var splash_scale: float = 1.0 + _technique_total("splash_area") + _weapon_rank_total(weapon_id, "splash_area") + _weapon_mastery_total(weapon_id, "splash_area")
		for index: int in count:
			var angle: float = deg_to_rad(lerpf(-24.0, 24.0, 0.5 if count == 1 else float(index) / float(count - 1)))
			_spawn_player_projectile(weapon_id, direction.rotated(angle), damage, pierce, 42.0 * splash_scale, "stagger")
	else:
		var category_projectiles: int = int(_technique_total("arcane_projectiles") + _class_total("arcane_projectiles") + _weapon_rank_total(weapon_id, "arcane_projectiles") + _weapon_mastery_total(weapon_id, "arcane_projectiles")) if category == "ARCANE" else projectile_bonus + int(_weapon_rank_total(weapon_id, "ranged_projectiles") + _weapon_mastery_total(weapon_id, "ranged_projectiles"))
		var count: int = 1 + category_projectiles
		var homing_targets: Array[EnemyState] = _find_nearest_enemies(player_position, count) if behavior == "hex" else []
		for index: int in count:
			var spread: float = deg_to_rad(float(index - (count - 1) / 2.0) * 7.0)
			var projectile_direction: Vector2 = direction.rotated(spread)
			var target_uid: int = -1
			if not homing_targets.is_empty():
				var homing_target: EnemyState = homing_targets[index % homing_targets.size()]
				projectile_direction = player_position.direction_to(homing_target.position)
				target_uid = homing_target.uid
			var splash_scale: float = 1.0 + _technique_total("splash_area") + _weapon_rank_total(weapon_id, "splash_area") + _weapon_mastery_total(weapon_id, "splash_area")
			_spawn_player_projectile(weapon_id, projectile_direction, damage, pierce, 18.0 * splash_scale if behavior == "hex" else (42.0 * splash_scale if behavior == "splash" else 0.0), "scorch" if behavior == "hex" else ("stagger" if behavior == "splash" else ("pin" if weapon_id == "bow" else "")), target_uid)
		if guard_empowered and weapon_id == "spear":
			guard_empowered = false

func _spawn_player_projectile(weapon_id: String, direction: Vector2, damage: float, pierce: int, splash_radius: float, status: String = "", target_uid: int = -1) -> void:
	if projectiles.size() >= MAX_PROJECTILES:
		return
	var definition: Dictionary = GameContent.WEAPONS[weapon_id]
	var projectile: ProjectileState = projectile_pool.pop_back() if not projectile_pool.is_empty() else ProjectileState.new()
	projectile.position = player_position + direction * 12.0
	var speed_bonus: float = _technique_total("projectile_speed") + _equipment_total("projectile_speed") + _weapon_rank_total(weapon_id, "projectile_speed") + _weapon_mastery_total(weapon_id, "projectile_speed")
	projectile.velocity = direction * float(definition.speed) * (1.0 + speed_bonus)
	projectile.damage = damage
	projectile.radius = float(definition.radius)
	projectile.life = 0.34 if weapon_id == "spear" else 1.45
	projectile.pierce = pierce
	projectile.faction = 0
	projectile.color = definition.color
	projectile.kind = weapon_id
	projectile.splash_radius = splash_radius
	projectile.homing = weapon_id == "witchfire"
	projectile.target_uid = target_uid
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
		if enemy.bleed_timer <= 0.0 and enemy.bleed_damage > 0.0 and enemy.bleed_ticks > 0:
			enemy.bleed_timer = 0.8
			enemy.bleed_ticks -= 1
			_damage_enemy(enemy, enemy.bleed_damage, false)
			if enemy.bleed_ticks <= 0:
				enemy.bleed_damage = 0.0
		if enemy.scorch_timer <= 0.0 and enemy.scorch_damage > 0.0 and enemy.scorch_ticks > 0:
			enemy.scorch_timer = 0.65
			enemy.scorch_ticks -= 1
			_damage_enemy(enemy, enemy.scorch_damage, false)
			if enemy.scorch_ticks <= 0:
				enemy.scorch_damage = 0.0
		var to_player: Vector2 = player_position - enemy.position
		var distance: float = to_player.length()
		var direction: Vector2 = to_player.normalized() if distance > 0.1 else Vector2.ZERO
		if enemy.kind == "archer" and distance < 235.0 and _enemy_inside_playable_bounds(enemy):
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

func _enemy_inside_playable_bounds(enemy: EnemyState) -> bool:
	return _visible_world_rect().grow(-enemy.radius).has_point(enemy.position)

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
			var target: EnemyState = _find_enemy_by_uid(projectile.target_uid)
			if target == null:
				target = _find_nearest_enemy(projectile.position)
				if target != null:
					projectile.target_uid = target.uid
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

func _update_traps(delta: float) -> void:
	for trap: TrapState in traps.duplicate():
		trap.life -= delta
		trap.tick -= delta
		if trap.tick <= 0.0:
			trap.tick = 0.55
			for enemy: EnemyState in enemies.duplicate():
				if enemy.position.distance_to(trap.position) <= trap.radius + enemy.radius:
					_damage_enemy(enemy, trap.damage, false, "scorch" if trap.kind == "ember" else "", "witchfire" if trap.kind == "ember" else "caltrops")
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
	if enemy.special or enemy.kind == "boss":
		damage *= 1.0 + _technique_total("elite_damage") + _equipment_total("elite_damage")
	if enemy.kind == "shield" and not melee:
		damage *= 0.65
	var supernatural: bool = enemy.id in ["blighted", "grave_guard", "barrow_knight"]
	if supernatural:
		damage *= 1.0 + _doctrine_total("supernatural_damage")
	else:
		damage *= 1.0 + _doctrine_total("ordinary_damage")
	var critical: bool = rng.randf() < critical_chance
	if critical:
		damage *= 1.75
	enemy.health -= damage
	enemy.stagger = maxf(enemy.stagger, 0.08 + stagger_power + _weapon_rank_total(source_weapon, "stagger") + _weapon_mastery_total(source_weapon, "stagger"))
	match status:
		"bleed":
			var bleed_bonus: float = _technique_total("bleed_damage") + _weapon_rank_total(source_weapon, "bleed_damage") + _weapon_mastery_total(source_weapon, "bleed_damage")
			enemy.bleed_damage = maxf(enemy.bleed_damage, damage * 0.18 * (1.0 + bleed_bonus))
			enemy.bleed_timer = maxf(enemy.bleed_timer, 0.8)
			enemy.bleed_ticks = maxi(enemy.bleed_ticks, 3)
		"scorch":
			var scorch_bonus: float = _technique_total("scorch_damage") + _weapon_rank_total("witchfire", "scorch_damage") + _weapon_mastery_total("witchfire", "scorch_damage")
			enemy.scorch_damage = maxf(enemy.scorch_damage, damage * 0.24 * (1.0 + scorch_bonus))
			enemy.scorch_timer = maxf(enemy.scorch_timer, 0.65)
			enemy.scorch_ticks = maxi(enemy.scorch_ticks, 3)
		"stagger":
			enemy.stagger = maxf(enemy.stagger, 0.30 + stagger_power + _weapon_rank_total(source_weapon, "stagger") + _weapon_mastery_total(source_weapon, "stagger"))
		"pin":
			enemy.pin_timer = maxf(enemy.pin_timer, 1.25)
	_add_float_text(enemy.position, str(roundi(damage)), AMBER if critical else PARCHMENT)
	if enemy.health <= 0.0:
		_kill_enemy(enemy)

func _damage_player(raw_damage: float) -> void:
	var guard_bonus: float = _technique_total("guard_strength") + _equipment_total("guard_strength") + _class_total("guard_strength") + _doctrine_total("guard_strength")
	var reduction: float = (0.70 + minf(0.20, guard_bonus)) if guard_timer > 0.0 else 0.0
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
	player_position += direction.normalized() * 42.0
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

func _load_camp_layer_textures() -> void:
	var tier_counts: Dictionary = {"armory": 4, "blacksmith": 4, "quartermaster": 4, "training": 6}
	for building: String in tier_counts:
		var tiers: Array[Texture2D] = []
		var outlines: Array[Texture2D] = []
		for tier: int in int(tier_counts[building]):
			var texture: Texture2D = load("res://assets/camp_layers/buildings/%s_%d.png" % [building, tier]) as Texture2D
			var outline: Texture2D = load("res://assets/camp_layers/buildings/outlines/%s_%d.png" % [building, tier]) as Texture2D
			if texture != null:
				tiers.append(texture)
			if outline != null:
				outlines.append(outline)
		camp_building_textures[building] = tiers
		camp_building_outline_textures[building] = outlines
	for landmark: String in ["veterans_hall", "campfire"]:
		var texture: Texture2D = load("res://assets/camp_layers/buildings/%s.png" % landmark) as Texture2D
		var outline: Texture2D = load("res://assets/camp_layers/buildings/outlines/%s.png" % landmark) as Texture2D
		if texture != null:
			camp_landmark_textures[landmark] = texture
		if outline != null:
			camp_landmark_outline_textures[landmark] = outline

func _technique_total(stat: String) -> float:
	var total: float = 0.0
	for technique_id: String in techniques:
		var definition: Dictionary = GameContent.TECHNIQUES[technique_id]
		var stats: Dictionary = definition.get("stats", {})
		total += float(stats.get(stat, 0.0)) * int(techniques[technique_id])
	return total

func _equipment_total(stat: String) -> float:
	var total: float = 0.0
	var smithing_bonus: float = 1.0 + float(save.profile.get("blacksmith_level", 0)) * 0.05
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
					var amount: float = float(modifier.get("amount", 0.0))
					total += amount * smithing_bonus if amount > 0.0 else amount
			break
	return total

func _doctrine_total(stat: String) -> float:
	var doctrine: Dictionary = GameContent.DOCTRINES.get(active_doctrine, GameContent.DOCTRINES.shield_line)
	return float(doctrine.get("stats", {}).get(stat, 0.0))

func _class_total(stat: String) -> float:
	var class_definition: Dictionary = GameContent.CLASSES.get(active_class, GameContent.CLASSES.warrior)
	return float(class_definition.get("stats", {}).get(stat, 0.0))

func _relic_total(stat: String) -> float:
	var total: float = 0.0
	for relic_id: String in relics:
		var relic: Dictionary = GameContent.RELICS.get(relic_id, {})
		var stats: Dictionary = relic.get("stats", {})
		total += float(stats.get(stat, 0.0)) * int(relics[relic_id])
	return total

func _curse_definition() -> Dictionary:
	return GameContent.CURSES.get(active_curse, GameContent.CURSES.none)

func _recalculate_player_stats() -> void:
	var training: int = int(save.profile.training_level)
	var training_fraction: float = float(training) / 5.0
	player_max_hp = 100.0 * (1.0 + training_fraction * 0.15) + _technique_total("health") + _equipment_total("health") + _class_total("health") + _relic_total("health")
	player_hp = minf(player_hp, player_max_hp)
	player_speed = 122.0 * (1.0 + training_fraction * 0.08 + _technique_total("speed") + _equipment_total("speed") + _class_total("speed") + _doctrine_total("speed"))
	damage_multiplier = (1.0 + training_fraction * 0.15) * (1.0 + _technique_total("damage") + _equipment_total("damage") + _class_total("damage"))
	cooldown_reduction = _technique_total("attack_speed") + _equipment_total("attack_speed") + _relic_total("attack_speed")
	player_armor = _technique_total("armor") + _equipment_total("armor")
	critical_chance = 0.05 + _technique_total("critical") + _equipment_total("critical")
	pickup_radius = 54.0 + _technique_total("pickup") + _equipment_total("pickup")
	stagger_power = _technique_total("stagger") + _equipment_total("stagger")
	projectile_bonus = mini(4, int(_technique_total("ranged_projectiles") + _relic_total("ranged_projectiles")))

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
		var button: Button = _make_stat_button("%s\n%s" % [choice.name, choice.description], _upgrade_summary(choice), 98.0, _upgrade_color(choice), 25.0)
		button.pressed.connect(_apply_upgrade.bind(choice, overlay))
		box.add_child(button)

func _upgrade_summary(choice: Dictionary) -> String:
	if choice.has("summary"):
		return String(choice.summary)
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
		"cooldown": return "ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"melee_cooldown": return "MELEE ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"ranged_cooldown": return "RANGED ATTACK SPEED  +%d%%" % roundi(amount * 100.0)
		"health": return "MAX HEALTH  +%d" % roundi(amount)
		"armor": return "ARMOR  +%d%%" % roundi(amount * 100.0)
		"guard": return "GUARD STEP  +%d%% REDUCTION" % roundi(amount * 100.0)
		"recovery": return "HEALTH REGEN  +%d / 5s" % roundi(amount)
		"critical": return "CRITICAL CHANCE  +%d%%" % roundi(amount * 100.0)
		"speed": return "MOVEMENT  +%d%%" % roundi(amount * 100.0)
		"pickup": return "PICKUP REACH  +%d" % roundi(amount)
		"stagger": return "STAGGER DURATION  +%.2fs" % amount
		"projectiles": return "PROJECTILE COUNT  +%d" % roundi(amount)
		"arcane_projectiles": return "ARCANE PROJECTILES  +%d" % roundi(amount)
		"guard_blast": return "GUARD RIPOSTE  %d DAMAGE" % roundi(amount)
		"elite_damage": return "ELITE DAMAGE  +%d%%" % roundi(amount * 100.0)
		"second_wind": return "SECOND WIND  +%d HEALTH" % roundi(amount)
		"loot_luck": return "LOOT QUALITY  +%d%%" % roundi(amount * 100.0)
	return "FIELD TECHNIQUE"

func _weapon_stats_text(weapon_id: String) -> String:
	var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
	var behavior: String = String(weapon.behavior)
	var shape_text: String
	match behavior:
		"thrust": shape_text = "RANGE %d  |  BLEED 3 x 18%%" % roundi(float(weapon.radius))
		"sweep": shape_text = "AREA %d  |  BLEED 3 x 18%%" % roundi(float(weapon.radius))
		"splash": shape_text = "3 STONES  |  48 DEG SPREAD  |  BLAST 42"
		"trap": shape_text = "AREA %d  |  DURATION 6.0s" % roundi(float(weapon.radius))
		"fan": shape_text = "3 KNIVES  |  BLEED 3 x 18%"
		"hex": shape_text = "BLAST 18  |  SCORCH 3 x 24%"
		_: shape_text = "PIERCING %d  |  PIN 1.25s" % int(weapon.pierce)
	return "DAMAGE %d  |  ATTACK EVERY %.2fs\n%s" % [roundi(float(weapon.damage)), float(weapon.cooldown), shape_text]

func _curse_stats_text(curse_id: String) -> String:
	var curse: Dictionary = GameContent.CURSES[curse_id]
	if curse_id == "none":
		return "STANDARD ENEMIES  |  STANDARD REWARDS"
	var parts: PackedStringArray = []
	var health_bonus: int = roundi((float(curse.health) - 1.0) * 100.0)
	var damage_bonus: int = roundi((float(curse.damage) - 1.0) * 100.0)
	if health_bonus != 0:
		parts.append("+%d%% ENEMY HEALTH" % health_bonus)
	if damage_bonus != 0:
		parts.append("+%d%% ENEMY DAMAGE" % damage_bonus)
	parts.append("+%d%% REWARDS" % roundi((float(curse.reward) - 1.0) * 100.0))
	if curse_id == "thin_rations":
		parts.append("-18% XP DROPS")
		parts.append("+8 VICTORY PROVISIONS")
	return "  |  ".join(parts)

func _class_stats_text(class_id: String) -> String:
	if class_id == "warrior":
		return "+20 HEALTH  |  +10% MELEE DAMAGE\n+5% GUARD  |  +0.08s GUARD TIME"
	return "+15% ARCANE DAMAGE  |  +12% ATTACK SPEED\n+1 ARCANE PROJECTILE"

func _upgrade_color(choice: Dictionary) -> Color:
	if String(choice.type) != "technique":
		return BURGUNDY
	var stats: Dictionary = choice.get("stats", {})
	var stat: String = String(stats.keys()[0]) if not stats.is_empty() else ""
	if stat in ["melee_damage", "melee_range", "melee_area", "stagger", "guard_strength", "guard_damage"]:
		return BURGUNDY.darkened(0.08)
	if stat in ["ranged_damage", "ranged_attack_speed", "pierce", "ranged_projectiles", "critical"]:
		return Color("4f5961")
	if stat in ["health", "armor", "health_regen", "speed"]:
		return Color("4d5b55")
	return IRON.darkened(0.3)

func _build_upgrade_choices() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for weapon_id: String in weapons:
		var rank: int = int(weapons[weapon_id])
		if GameRules.mastery_available(weapon_id, rank, techniques, save.profile.get("skill_tree", {})) and not bool(mastered.get(weapon_id, false)):
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			candidates.append({"type": "mastery", "id": weapon_id, "name": String(weapon.mastery).to_upper(), "description": "Complete this weapon's proven final form.", "summary": GameContent.stats_text(weapon.mastery_stats)})
		elif rank < 5:
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			var rank_stats: Dictionary = weapon.rank_bonuses[rank - 1]
			candidates.append({"type": "weapon", "id": weapon_id, "name": "%s  %d > %d" % [weapon.name, rank, rank + 1], "description": weapon.description, "summary": GameContent.stats_text(rank_stats)})
	if weapons.size() < 4:
		for weapon_id: String in GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})):
			if not weapons.has(weapon_id):
				var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
				candidates.append({"type": "weapon", "id": weapon_id, "name": "TAKE %s" % String(weapon.name).to_upper(), "description": weapon.description, "summary": _weapon_stats_text(weapon_id)})
	for technique_id: String in techniques:
		var rank: int = int(techniques[technique_id])
		if rank < 3:
			var technique: Dictionary = GameContent.TECHNIQUES[technique_id]
			candidates.append({"type": "technique", "id": technique_id, "name": "%s  %d > %d" % [technique.name, rank, rank + 1], "description": technique.description, "stats": technique.stats, "summary": GameContent.stats_text(technique.stats)})
	if techniques.size() < 4:
		for technique_id: String in GameContent.unlocked_techniques(save.profile.get("skill_tree", {})):
			if not techniques.has(technique_id):
				var technique: Dictionary = GameContent.TECHNIQUES[technique_id]
				candidates.append({"type": "technique", "id": technique_id, "name": "LEARN %s" % String(technique.name).to_upper(), "description": technique.description, "stats": technique.stats, "summary": GameContent.stats_text(technique.stats)})
	var choices: Array[Dictionary] = []
	var choice_count: int = GameContent.level_choice_count(save.profile.get("skill_tree", {}))
	while not candidates.is_empty() and choices.size() < choice_count:
		var index: int = rng.randi_range(0, candidates.size() - 1)
		choices.append(candidates.pop_at(index))
	if choices.is_empty():
		choices.append({"type": "heal", "id": "rations", "name": "FIELD RATIONS", "description": "Restore 30 health immediately.", "summary": "+30 CURRENT HEALTH"})
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

func _start_new_run(starting_weapon: String = "", from_gate: bool = false) -> void:
	var departure_position: Vector2 = camp_player_position
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
	_generate_exploration_points()
	_recalculate_player_stats()
	player_hp = player_max_hp
	var gate: Vector2 = _camp_gate_position()
	player_position = departure_position if from_gate else gate + Vector2(0.0, GATE_CLEAR_DISTANCE + 12.0)
	player_position.y = maxf(player_position.y, gate.y + 14.0)
	run_gate_cleared = player_position.y >= gate.y + GATE_CLEAR_DISTANCE
	_update_world_camera(player_position, false)
	save.active_run = {}
	SaveService.save_data(save)
	screen = Screen.RUN
	_play_music("moor")
	_build_run_ui()
	queue_redraw()

func _show_weapon_picker(category_index: int = -1) -> void:
	if not is_instance_valid(ui_root):
		_show_camp()
		return
	if category_index >= 0:
		weapon_picker_category = category_index
	var existing_picker: Node = get_node_or_null("WeaponPickerOverlay")
	if existing_picker != null:
		existing_picker.name = "ClosingWeaponPicker"
		existing_picker.queue_free()
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "WeaponPickerOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var panel: PanelContainer = _make_panel(true)
	panel.name = "WeaponPickerPanel"
	panel.position = Vector2(12.0, 42.0)
	panel.size = Vector2(maxf(260.0, size.x - 24.0), maxf(420.0, size.y - 78.0))
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
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
		var class_button: Button = _make_button(String(class_definition.name).to_upper(), 34.0, BURGUNDY if class_id == String(save.profile.get("starting_class", "warrior")) else IRON.darkened(0.35))
		class_button.name = "Class%sButton" % class_id.capitalize()
		class_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		class_button.pressed.connect(_select_class.bind(class_id, overlay))
		class_grid.add_child(class_button)
	box.add_child(class_grid)
	var selected_class_id: String = String(save.profile.get("starting_class", "warrior"))
	var class_detail: Label = _make_label(String(GameContent.CLASSES[selected_class_id].description), 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	class_detail.name = "ClassDetail"
	class_detail.custom_minimum_size.y = 17.0
	box.add_child(class_detail)
	var class_stats: Label = _make_label(_class_stats_text(selected_class_id), 9, AMBER.lightened(0.32), HORIZONTAL_ALIGNMENT_CENTER)
	class_stats.name = "ClassStats"
	class_stats.custom_minimum_size.y = 25.0
	box.add_child(class_stats)
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
	var doctrine_id: String = String(save.profile.get("starting_doctrine", "shield_line"))
	var doctrine_detail: Label = _make_label(String(GameContent.DOCTRINES[doctrine_id].description), 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	doctrine_detail.name = "DoctrineDetail"
	doctrine_detail.custom_minimum_size.y = 17.0
	box.add_child(doctrine_detail)
	var doctrine_stats: Label = _make_label(GameContent.stats_text(GameContent.DOCTRINES[doctrine_id].stats), 9, AMBER.lightened(0.32), HORIZONTAL_ALIGNMENT_CENTER)
	doctrine_stats.name = "DoctrineStats"
	doctrine_stats.custom_minimum_size.y = 25.0
	box.add_child(doctrine_stats)
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
	var curse_id: String = String(save.profile.get("starting_curse", "none"))
	var curse_detail: Label = _make_label(String(GameContent.CURSES[curse_id].description), 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	curse_detail.name = "CurseDetail"
	curse_detail.custom_minimum_size.y = 17.0
	box.add_child(curse_detail)
	var curse_stats: Label = _make_label(_curse_stats_text(curse_id), 9, AMBER.lightened(0.32), HORIZONTAL_ALIGNMENT_CENTER)
	curse_stats.name = "CurseStats"
	curse_stats.custom_minimum_size.y = 25.0
	box.add_child(curse_stats)
	box.add_child(_make_label("AVAILABLE WEAPONS", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var category_tabs: HBoxContainer = HBoxContainer.new()
	category_tabs.add_theme_constant_override("separation", 5)
	var categories: Array[String] = ["MELEE", "RANGED", "ARCANE"]
	for category_index_option: int in categories.size():
		var category_button: Button = _make_button(categories[category_index_option], 34.0, BURGUNDY if category_index_option == weapon_picker_category else IRON.darkened(0.35))
		category_button.name = "WeaponCategory%s" % categories[category_index_option].capitalize()
		category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_button.pressed.connect(_show_weapon_picker.bind(category_index_option))
		category_tabs.add_child(category_button)
	box.add_child(category_tabs)
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 7)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	var unlocked: Array[String] = GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {}))
	for category: String in [categories[clampi(weapon_picker_category, 0, categories.size() - 1)]]:
		var category_weapons: Array[String] = []
		for weapon_id: String in unlocked:
			if String(GameContent.WEAPONS[weapon_id].category) == category:
				category_weapons.append(weapon_id)
		if category_weapons.is_empty():
			continue
		var weapon_grid: GridContainer = GridContainer.new()
		weapon_grid.columns = mini(2, category_weapons.size()) if size.x >= 360.0 else 1
		weapon_grid.add_theme_constant_override("h_separation", 7)
		weapon_grid.add_theme_constant_override("v_separation", 6)
		weapon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(weapon_grid)
		for weapon_id: String in category_weapons:
			var weapon: Dictionary = GameContent.WEAPONS[weapon_id]
			var suffix: String = " - CURRENT" if weapon_id == String(save.profile.starting_weapon) else ""
			var button: Button = _make_stat_button("%s%s\n%s" % [String(weapon.name).to_upper(), suffix, String(weapon.description)], _weapon_stats_text(weapon_id), 88.0, BURGUNDY if weapon_id == String(save.profile.starting_weapon) else IRON.darkened(0.35), 31.0)
			button.name = "WeaponChoice_%s" % weapon_id
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_choose_starting_weapon.bind(weapon_id, overlay))
			weapon_grid.add_child(button)
	var cancel: Button = _make_button("BACK TO CAMP", 50.0, BURGUNDY)
	cancel.name = "WeaponPickerBack"
	cancel.pressed.connect(overlay.queue_free)
	box.add_child(cancel)

func _select_class(class_id: String, overlay: Control) -> void:
	if not GameContent.CLASSES.has(class_id):
		return
	save.profile.starting_class = class_id
	save.profile.starting_weapon = String(GameContent.CLASSES[class_id].starting_weapon)
	weapon_picker_category = 2 if class_id == "mage" else 0
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_weapon_picker()

func _starting_doctrine_selected(index: int, selector: OptionButton) -> void:
	save.profile.starting_doctrine = String(selector.get_item_metadata(index))
	SaveService.save_data(save)
	var detail: Label = find_child("DoctrineDetail", true, false) as Label
	if detail != null:
		detail.text = String(GameContent.DOCTRINES[String(save.profile.starting_doctrine)].description)
	var stats: Label = find_child("DoctrineStats", true, false) as Label
	if stats != null:
		stats.text = GameContent.stats_text(GameContent.DOCTRINES[String(save.profile.starting_doctrine)].stats)

func _starting_curse_selected(index: int, selector: OptionButton) -> void:
	save.profile.starting_curse = String(selector.get_item_metadata(index))
	SaveService.save_data(save)
	var detail: Label = find_child("CurseDetail", true, false) as Label
	if detail != null:
		detail.text = String(GameContent.CURSES[String(save.profile.starting_curse)].description)
	var stats: Label = find_child("CurseStats", true, false) as Label
	if stats != null:
		stats.text = _curse_stats_text(String(save.profile.starting_curse))

func _choose_starting_weapon(weapon_id: String, overlay: Control) -> void:
	if not GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})).has(weapon_id):
		return
	save.profile.starting_weapon = weapon_id
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()

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
	box.add_child(_make_label("Accept one task for an immediate expedition reward.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	for index: int in mini(2, ids.size()):
		var contract_id_option: String = ids[index]
		var contract: Dictionary = GameContent.CONTRACTS[contract_id_option]
		var button: Button = _make_stat_button("%s\n%s" % [String(contract.name).to_upper(), String(contract.description)], GameContent.reward_text(contract), 78.0, BURGUNDY if index == 0 else IRON.darkened(0.3), 20.0)
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
	box.add_child(_make_label("A run-changing advantage. Choose one.", 12, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	for index: int in mini(3, available.size()):
		var relic_id: String = available[index]
		var relic: Dictionary = GameContent.RELICS[relic_id]
		var button: Button = _make_stat_button("%s\n%s" % [String(relic.name).to_upper(), String(relic.description)], GameContent.stats_text(relic.stats), 78.0, Color("4d5b55") if index == 0 else IRON.darkened(0.3), 20.0)
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
	exploration_points.clear()
	player_position = _camp_gate_position() + Vector2(0.0, GATE_CLEAR_DISTANCE + 12.0)
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
	run_dread_bonus = 0.0
	run_discoveries = 0
	run_exploration_silver = 0
	run_exploration_provisions = 0
	nearby_exploration_index = -1
	run_gate_cleared = false

func _finish_run(victory: bool, extracted: bool = false) -> void:
	if screen != Screen.RUN:
		return
	run_paused = true
	var curse_reward: float = float(_curse_definition().get("reward", 1.0))
	var silver: int = floori((float(run_kills) / 10.0 + run_elites * 10.0 + (60 if victory else 0)) * curse_reward)
	var provisions: int = floori((run_elapsed / 30.0 + (20 if victory else 0)) * curse_reward)
	silver += run_exploration_silver
	provisions += run_exploration_provisions
	if active_curse == "thin_rations":
		provisions += 8 if victory else 0
	if objective_complete and GameContent.OBJECTIVES.has(objective_id):
		var objective_reward: Dictionary = GameContent.OBJECTIVES[objective_id]
		silver += int(objective_reward.get("silver", 0))
		provisions += int(objective_reward.get("provisions", 0))
	if contract_complete and GameContent.CONTRACTS.has(contract_id):
		var contract_reward: Dictionary = GameContent.CONTRACTS[contract_id]
		silver += int(contract_reward.get("silver", 0))
		provisions += int(contract_reward.get("provisions", 0))
	var loot_result: Dictionary = _store_run_loot()
	silver += int(loot_result.salvaged_silver)
	var rating: float = GameRules.veteran_rating(run_elapsed, run_kills, run_elites, victory)
	result_data = {"victory": victory, "extracted": extracted, "silver": silver, "provisions": provisions, "rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "discoveries": run_discoveries, "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete, "class": active_class, "doctrine": active_doctrine, "curse": active_curse, "relics": relics.duplicate(true), "loot": run_loot.duplicate(true), "stored_loot": int(loot_result.stored), "salvaged_loot": int(loot_result.salvaged)}
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
	if run_discoveries > 0:
		campaign_flags["moor_discoveries"] = int(campaign_flags.get("moor_discoveries", 0)) + run_discoveries
	save.profile.campaign_flags = campaign_flags
	save.active_run = {}
	camp_player_position = _camp_gate_position() + Vector2(0.0, -34.0)
	camera_offset = camp_world_origin
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
	var discovered_points: Array[String] = []
	for point: ExplorationPoint in exploration_points:
		if point.discovered:
			discovered_points.append(point.id)
	save.active_run = {
		"world_map": true,
		"seed": run_seed, "rng_state": rng.state, "elapsed": run_elapsed, "hp": player_hp, "max_hp": player_max_hp,
		"class": active_class, "doctrine": active_doctrine, "curse": active_curse, "relics": relics.duplicate(true),
		"position": [player_position.x, player_position.y], "level": run_level, "xp": run_xp, "next_xp": next_xp,
		"kills": run_kills, "elites": run_elites, "score": run_score, "weapons": weapons.duplicate(true),
		"techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated, "elite_one": elite_one_spawned, "elite_two": elite_two_spawned, "boss_phase": boss_phase,
		"objective": objective_id, "objective_progress": objective_progress, "objective_complete": objective_complete,
		"contract": contract_id, "contract_progress": contract_progress, "contract_target": contract_target, "contract_complete": contract_complete,
		"run_loot": run_loot.duplicate(true), "second_wind_used": second_wind_used,
		"dread_bonus": run_dread_bonus, "discoveries": run_discoveries,
		"exploration_silver": run_exploration_silver, "exploration_provisions": run_exploration_provisions,
		"discovered_points": discovered_points
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
	run_elapsed = clampf(float(snapshot.get("elapsed", 0.0)), 0.0, RUN_SECONDS * 1.5 - 0.1)
	player_hp = float(snapshot.get("hp", 100.0))
	var position_data: Array = snapshot.get("position", [_camp_gate_position().x, _camp_gate_position().y + GATE_CLEAR_DISTANCE + 12.0])
	if bool(snapshot.get("world_map", false)):
		player_position = Vector2(float(position_data[0]), float(position_data[1]))
	else:
		# Old snapshots used screen coordinates. Resume them just beyond the same
		# physical gate instead of placing the player inside the rebuilt town.
		player_position = _camp_gate_position() + Vector2(0.0, GATE_CLEAR_DISTANCE + 12.0)
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
	run_dread_bonus = float(snapshot.get("dread_bonus", 0.0))
	run_discoveries = int(snapshot.get("discoveries", 0))
	run_exploration_silver = int(snapshot.get("exploration_silver", 0))
	run_exploration_provisions = int(snapshot.get("exploration_provisions", 0))
	_generate_exploration_points()
	var discovered_points: Array = snapshot.get("discovered_points", [])
	for point: ExplorationPoint in exploration_points:
		point.discovered = discovered_points.has(point.id)
	for weapon_id: String in weapons:
		weapon_timers[weapon_id] = rng.randf_range(0.1, 0.5)
	_recalculate_player_stats()
	player_hp = minf(player_hp, player_max_hp)
	player_position.x = clampf(player_position.x, 18.0, world_size.x - 18.0)
	player_position.y = clampf(player_position.y, _camp_gate_position().y + 14.0, world_size.y - 22.0)
	run_gate_cleared = player_position.y >= _camp_gate_position().y + GATE_CLEAR_DISTANCE
	_update_world_camera(player_position, false, true)
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
		"blacksmith": costs = GameContent.BLACKSMITH_COSTS
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

func _building_effect_text(building: String, level: int, maximum: int) -> String:
	if building == "armory":
		var access: Array[String] = ["AXE ACCESS", "BOW + KNIVES ACCESS", "CALTROPS + START PICK"]
		return "ALL WEAPON ACCESS" if level >= maximum else access[level]
	if building == "blacksmith":
		var shown_level: int = level if level >= maximum else level + 1
		return "+%d%% POSITIVE EQUIPMENT STATS" % (shown_level * 5)
	if building == "training":
		var shown_level: int = level if level >= maximum else level + 1
		return "+%d%% HP & DAMAGE  |  +%.1f%% MOVEMENT" % [roundi(float(shown_level) / 5.0 * 15.0), float(shown_level) / 5.0 * 8.0]
	var shown_level: int = level if level >= maximum else level + 1
	return "+%d%% IDLE YIELD  |  %.1fH CAP" % [shown_level * 8, GameRules.offline_cap_hours(shown_level)]

func _show_camp(message: String = "") -> void:
	screen = Screen.CAMP
	run_paused = true
	camp_highlighted_structure = ""
	if camp_player_position.x < size.x:
		camp_player_position += camp_world_origin
	_update_world_camera(camp_player_position, true, true)
	_apply_offline_progress()
	_play_music("camp")
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)

	var locations: Control = Control.new()
	locations.name = "CampLocations"
	locations.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	locations.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(locations)

	var veteran: Dictionary = save.profile.veteran
	var expedition: Dictionary = save.profile.expedition
	var current_operation: String = String(expedition.get("operation", "forage"))
	var pending_silver: int = int(expedition.get("pending_silver", 0))
	var pending_provisions: int = int(expedition.get("pending_provisions", 0))
	var operation_name: String = "PATROL" if current_operation == "patrol" else "FORAGING"
	var pending_text: String = "%dS / %dP READY" % [pending_silver, pending_provisions] if pending_silver + pending_provisions > 0 else "TAP FOR EXPEDITIONS"
	var veterans_button: Button = _make_camp_hotspot("VeteranTentButton", "VETERANS' HALL  -  " + operation_name, pending_text, CAMP_STRUCTURE_HIT_RECTS.veterans_hall, AMBER)
	_wire_camp_highlight(veterans_button, "veterans_hall")
	# Open on touch-down so a tiny finger drift during release cannot cancel this
	# central hotspot on mobile Safari.
	veterans_button.button_down.connect(_show_camp_expeditions)

	var buildings: Control = Control.new()
	buildings.name = "CampBuildings"
	buildings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buildings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locations.add_child(buildings)
	for building: String in ["armory", "quartermaster", "blacksmith", "training"]:
		var level: int = int(save.profile[building + "_level"])
		var building_costs: Array[Dictionary]
		match building:
			"armory": building_costs = GameContent.ARMORY_COSTS
			"blacksmith": building_costs = GameContent.BLACKSMITH_COSTS
			"training": building_costs = GameContent.TRAINING_COSTS
			_: building_costs = GameContent.QUARTERMASTER_COSTS
		var building_name: String = "QUARTERMASTER" if building == "quartermaster" else building.to_upper()
		var tier_text: String = "RESTORED" if level >= building_costs.size() else "TIER %d / %d" % [level, building_costs.size()]
		var button: Button = _make_camp_hotspot("CampBuilding_%s" % building, building_name, tier_text, CAMP_STRUCTURE_HIT_RECTS[building], Color("91a985") if level >= building_costs.size() else AMBER)
		_wire_camp_highlight(button, building)
		button.pressed.connect(_show_building_detail.bind(building))
		buildings.add_child(button)

	var march_title: String = "EXPEDITION TABLE" if not save.active_run.is_empty() else "CAMPFIRE"
	var march_stats: String = "RESUME OR RE-EQUIP" if not save.active_run.is_empty() else "PREPARE YOUR COMPANY"
	var march_button: Button = _make_camp_hotspot("CampfireButton", march_title, march_stats, CAMP_STRUCTURE_HIT_RECTS.campfire, BURGUNDY.lightened(0.18))
	_wire_camp_highlight(march_button, "campfire")
	march_button.pressed.connect(_show_weapon_picker)
	locations.add_child(march_button)

	var camp_panel: Control = Control.new()
	camp_panel.name = "CampPanel"
	camp_panel.position = Vector2.ZERO
	camp_panel.size = Vector2(size.x, 154.0)
	camp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(camp_panel)
	var title_crest: TextureRect = TextureRect.new()
	title_crest.name = "CampTitleCrest"
	title_crest.texture = camp_title_crest_texture
	title_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Keep the painted crest compact; its source artwork contains a lot of
	# hardware around the lettering, so a wide shallow box quickly dominates
	# the portrait camp screen. Set size after expand_mode so Godot does not
	# restore the texture's 768x230 native dimensions.
	var crest_width: float = minf(380.0, size.x - 10.0)
	var crest_height: float = crest_width * float(camp_title_crest_texture.get_height()) / float(camp_title_crest_texture.get_width())
	var crest_size := Vector2(crest_width, crest_height)
	title_crest.position = Vector2((size.x - crest_size.x) * 0.5, 6.0)
	title_crest.size = crest_size
	title_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camp_panel.add_child(title_crest)
	var currency_backdrop: ColorRect = ColorRect.new()
	currency_backdrop.name = "CurrencyBarBackground"
	currency_backdrop.position = Vector2(0.0, 124.0)
	currency_backdrop.size = Vector2(size.x, 28.0)
	currency_backdrop.color = Color(0.02, 0.025, 0.027, 0.70)
	currency_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camp_panel.add_child(currency_backdrop)
	var currency_center: CenterContainer = CenterContainer.new()
	currency_center.name = "CurrencyBarCenter"
	currency_center.position = Vector2(0.0, 124.0)
	currency_center.size = Vector2(size.x, 28.0)
	currency_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resource_strip: HBoxContainer = _make_resource_strip(12, 24.0)
	currency_center.add_child(resource_strip)
	camp_panel.add_child(currency_center)
	var settings_button_top: Button = Button.new()
	settings_button_top.name = "SettingsCogButton"
	settings_button_top.position = Vector2(size.x - 58.0, size.y - 58.0)
	settings_button_top.size = Vector2(48.0, 48.0)
	settings_button_top.icon = settings_cog_texture
	settings_button_top.expand_icon = true
	settings_button_top.focus_mode = Control.FOCUS_NONE
	settings_button_top.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	settings_button_top.tooltip_text = "Settings"
	settings_button_top.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	settings_button_top.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	settings_button_top.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	settings_button_top.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	settings_button_top.pressed.connect(_show_settings)
	# Keep the cog above the crest and the currency strip in the scene tree so
	# its transparent icon remains visible on every renderer.
	ui_root.add_child(settings_button_top)
	camp_interact_button = _make_button("WALK THE CAMP", 52.0, BURGUNDY)
	camp_interact_button.name = "CampInteractButton"
	camp_interact_button.position = Vector2(size.x - 166.0, size.y - 126.0)
	camp_interact_button.size = Vector2(150.0, 52.0)
	camp_interact_button.disabled = true
	camp_interact_button.pressed.connect(_interact_with_camp_target)
	ui_root.add_child(camp_interact_button)
	camp_player_position.x = clampf(camp_player_position.x, camp_world_origin.x + 16.0, camp_world_origin.x + size.x - 16.0)
	camp_player_position.y = clampf(camp_player_position.y, camp_world_origin.y + 176.0, _camp_gate_position().y - 12.0)
	camp_interaction_target = _nearest_camp_interaction()
	_update_camp_interact_button()
	if not message.is_empty():
		status_label = _make_label(message, 10, AMBER.lightened(0.25), HORIZONTAL_ALIGNMENT_CENTER)
		status_label.position = Vector2(32.0, 166.0)
		status_label.size = Vector2(size.x - 64.0, 22.0)
		ui_root.add_child(status_label)
	# Add this central hotspot last so the compact header cannot win Godot's
	# hit test in the narrow gap beneath it on mobile web.
	ui_root.add_child(veterans_button)
	queue_redraw()

func _show_building_detail(building: String) -> void:
	var building_costs: Array[Dictionary]
	var building_name: String
	var linked_menu: String
	match building:
		"armory":
			building_costs = GameContent.ARMORY_COSTS
			building_name = "ARMORY"
			linked_menu = "CHOOSE LOADOUT"
		"blacksmith":
			building_costs = GameContent.BLACKSMITH_COSTS
			building_name = "BLACKSMITH"
			linked_menu = "OPEN EQUIPMENT"
		"training":
			building_costs = GameContent.TRAINING_COSTS
			building_name = "TRAINING YARD"
			linked_menu = "OPEN SKILL TREE"
		_:
			building_costs = GameContent.QUARTERMASTER_COSTS
			building_name = "QUARTERMASTER"
			linked_menu = "VETERANS' WORK"
	var level: int = int(save.profile[building + "_level"])
	var overlay: ColorRect = _make_camp_overlay("CampBuildingOverlay")
	var panel: PanelContainer = _make_panel(true)
	panel.position = Vector2(24.0, 202.0)
	panel.size = Vector2(size.x - 48.0, 390.0)
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_make_label(building_name, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("RESTORATION TIER %d / %d" % [level, building_costs.size()], 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
	var effect_heading: String = "CURRENT RESTORATION" if level >= building_costs.size() else "NEXT RESTORATION"
	box.add_child(_make_label(effect_heading, 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var effect_label: Label = _make_label(_building_effect_text(building, level, building_costs.size()), 13, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	effect_label.name = "BuildingEffectLabel"
	box.add_child(effect_label)
	if level < building_costs.size():
		var cost: Dictionary = building_costs[level]
		var can_afford: bool = int(save.profile.silver) >= int(cost.silver) and int(save.profile.provisions) >= int(cost.provisions)
		var upgrade: Button = _make_button("RESTORE TIER %d\nCOST  %d SILVER / %d PROVISIONS" % [level + 1, int(cost.silver), int(cost.provisions)], 66.0, BURGUNDY if can_afford else IRON.darkened(0.35))
		upgrade.name = "BuildingUpgradeButton"
		upgrade.disabled = not can_afford
		upgrade.pressed.connect(_buy_building.bind(building))
		box.add_child(upgrade)
	else:
		box.add_child(_make_label("THIS BUILDING IS FULLY RESTORED", 12, Color("91a985"), HORIZONTAL_ALIGNMENT_CENTER))
	var menu_button: Button = _make_button(linked_menu, 48.0, Color("4d5b55"))
	match building:
		"armory": menu_button.pressed.connect(_show_weapon_picker)
		"blacksmith": menu_button.pressed.connect(_show_inventory)
		"training": menu_button.pressed.connect(_show_skill_tree)
		_: menu_button.pressed.connect(_replace_camp_overlay_with_expeditions.bind(overlay))
	box.add_child(menu_button)
	var close: Button = _make_button("RETURN TO CAMP", 46.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _show_camp_expeditions() -> void:
	var overlay: ColorRect = _make_camp_overlay("CampExpeditionOverlay")
	var panel: PanelContainer = _make_panel(true)
	panel.position = Vector2(24.0, 164.0)
	panel.size = Vector2(size.x - 48.0, 512.0)
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_make_label("THE VETERANS' WORK", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var veteran: Dictionary = save.profile.veteran
	var veteran_text: String = "Complete a run to establish a veteran company." if veteran.is_empty() else "RATING %d%%  |  BEST %s" % [roundi(float(veteran.rating) * 100.0), _format_time(float(veteran.time))]
	box.add_child(_make_label(veteran_text, 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var operation_status: Label = _make_label(_expedition_status_text(), 12, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	operation_status.name = "ExpeditionStatusDetail"
	operation_status.custom_minimum_size.y = 76.0
	box.add_child(operation_status)
	var expedition: Dictionary = save.profile.expedition
	var veteran_rating: float = float(save.profile.veteran.get("rating", 0.25))
	var efficiency: float = lerpf(0.55, 1.0, clampf(veteran_rating, 0.25, 1.0))
	var bonus: float = 1.0 + float(save.profile.quartermaster_level) * 0.08
	var assignment: GridContainer = GridContainer.new()
	assignment.columns = 2
	assignment.add_theme_constant_override("h_separation", 8)
	var current_operation: String = String(expedition.get("operation", "forage"))
	var patrol: Button = _make_stat_button("BORDER PATROL", "%d SILVER / HOUR" % floori(11.0 * efficiency * bonus), 56.0, BURGUNDY if current_operation == "patrol" else IRON.darkened(0.35), 18.0)
	patrol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patrol.pressed.connect(_set_expedition.bind("patrol"))
	assignment.add_child(patrol)
	var forage: Button = _make_stat_button("FORAGING", "%d PROVISIONS / HOUR" % floori(3.0 * efficiency * bonus), 56.0, BURGUNDY if current_operation == "forage" else IRON.darkened(0.35), 18.0)
	forage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forage.pressed.connect(_set_expedition.bind("forage"))
	assignment.add_child(forage)
	box.add_child(assignment)
	var pending_silver: int = int(expedition.get("pending_silver", 0))
	var pending_provisions: int = int(expedition.get("pending_provisions", 0))
	if pending_silver + pending_provisions > 0:
		var claim: Button = _make_button("COLLECT  %d SILVER / %d PROVISIONS" % [pending_silver, pending_provisions], 48.0, AMBER.darkened(0.35))
		claim.pressed.connect(_claim_expedition)
		box.add_child(claim)
	var close: Button = _make_button("RETURN TO CAMP", 46.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _replace_camp_overlay_with_expeditions(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_camp_expeditions()

func _show_march_detail() -> void:
	if save.active_run.is_empty():
		_show_weapon_picker()
		return
	var overlay: ColorRect = _make_camp_overlay("CampMarchOverlay")
	var panel: PanelContainer = _make_panel(true)
	panel.position = Vector2(32.0, 256.0)
	panel.size = Vector2(size.x - 64.0, 280.0)
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_make_label("THE MOOR AWAITS", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("An interrupted expedition can still be recovered.", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var resume: Button = _make_button("RESUME EXPEDITION", 56.0, Color("4d5b55"))
	resume.pressed.connect(_resume_run)
	box.add_child(resume)
	var new_run: Button = _make_button("BEGIN A NEW EXPEDITION", 56.0, BURGUNDY)
	new_run.pressed.connect(_replace_camp_overlay_with_weapon_picker.bind(overlay))
	box.add_child(new_run)
	var close: Button = _make_button("RETURN TO CAMP", 44.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _replace_camp_overlay_with_weapon_picker(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_weapon_picker()

func _make_camp_overlay(node_name: String) -> ColorRect:
	var existing: Node = ui_root.get_node_or_null(node_name) if ui_root != null else null
	if existing != null:
		existing.queue_free()
	var overlay: ColorRect = ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0.025, 0.028, 0.03, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	return overlay

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
		detail.custom_minimum_size.y = 70.0
		column.add_child(detail)
	else:
		var rarity: Dictionary = GameContent.RARITIES[String(selected.rarity)]
		var current_item: Dictionary = _find_inventory_item(String(equipped.get(String(selected.slot), "")))
		var comparison: String = "CURRENT: EMPTY"
		if not current_item.is_empty():
			comparison = "CURRENT: %s - %s" % [String(current_item.name).to_upper(), _equipment_modifier_text(current_item)]
		detail = _make_label("%s - %s\n%s" % [String(rarity.name).to_upper(), String(selected.slot).to_upper(), String(GameContent.EQUIPMENT[String(selected.base_id)].description)], 11, rarity.color, HORIZONTAL_ALIGNMENT_CENTER)
		detail.custom_minimum_size.y = 34.0
		column.add_child(detail)
		var item_stats: Label = _make_label(_equipment_modifier_text(selected), 9, AMBER.lightened(0.32), HORIZONTAL_ALIGNMENT_CENTER)
		item_stats.name = "EquipmentStats"
		item_stats.custom_minimum_size.y = 20.0
		column.add_child(item_stats)
		var comparison_label: Label = _make_label(comparison, 9, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		comparison_label.custom_minimum_size.y = 20.0
		column.add_child(comparison_label)
	detail.name = "EquipmentDetail"
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
	return GameContent.stat_text(stat, amount)

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
	column.add_child(_make_resource_strip(14, 26.0))
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
		var rank_text: String = "  %d/%d" % [rank, max_rank] if max_rank > 1 else ""
		var node_text: String = "%s%s" % [String(node.name).to_upper(), rank_text]
		if rank < max_rank and not requirements_met:
			var required_id: String = String(node.requires[0])
			node_text += "\nREQUIRES %s" % String(GameContent.PROGRESSION_NODES[required_id].name).to_upper()
		elif rank < max_rank:
			node_text += "\n%dS / %dP" % [int(cost.silver), int(cost.provisions)]
		if rank < max_rank and String(node.kind).contains("weapon"):
			node_text += "  -  ARMORY %d" % int(GameContent.WEAPON_UNLOCK_LEVEL[String(node.unlock)])
		var learned: bool = rank >= max_rank
		var node_color: Color = Color("3f5b4c") if learned else (IRON.darkened(0.3) if requirements_met else INK.lightened(0.02))
		var node_button: Button = _make_stat_button(node_text, String(node.description), 96.0, node_color, 38.0)
		node_button.name = "SkillNode_%s" % node_id
		node_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node_button.disabled = learned or not requirements_met
		if learned:
			node_button.add_theme_stylebox_override("disabled", _style_box(Color("3f5b4c"), Color("819274"), 2))
			node_button.add_theme_color_override("font_disabled_color", PARCHMENT)
		elif not requirements_met:
			node_button.add_theme_stylebox_override("disabled", _style_box(Color("272b2d"), Color("555b5d"), 2))
			node_button.add_theme_color_override("font_disabled_color", Color("85898a"))
			var locked_primary: Label = node_button.find_child("CardDescription", true, false) as Label
			var locked_stats: Label = node_button.find_child("CardStats", true, false) as Label
			var locked_divider: ColorRect = node_button.find_child("StatDivider", true, false) as ColorRect
			if locked_primary != null:
				locked_primary.add_theme_color_override("font_color", Color("85898a"))
			if locked_stats != null:
				locked_stats.add_theme_color_override("font_color", Color("696e70"))
			if locked_divider != null:
				locked_divider.color = Color("555b5d")
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
	objective_label.size = Vector2(size.x - 68.0, 68.0)
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
	expedition_interact_button = _make_button("SEARCH", 48.0, Color("4d5b55"))
	expedition_interact_button.name = "ExpeditionInteractButton"
	expedition_interact_button.position = Vector2(size.x - 118.0, size.y - 174.0)
	expedition_interact_button.size = Vector2(100.0, 50.0)
	expedition_interact_button.visible = false
	expedition_interact_button.disabled = true
	expedition_interact_button.pressed.connect(_interact_with_expedition)
	ui_root.add_child(expedition_interact_button)
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
	var field_phase: String = "NIGHTFALL" if run_elapsed >= RUN_SECONDS else "DUSK %s" % _format_time(remaining)
	hud_label.text = "%s   DREAD %d%%   FOUND %d/4\nLV%d  HP %d/%d  XP %d/%d  KILLS %d" % [field_phase, roundi(_current_dread()), run_discoveries, run_level, ceili(player_hp), ceili(player_max_hp), run_xp, next_xp, run_kills]
	if health_bar != null:
		health_bar.max_value = player_max_hp
		health_bar.value = clampf(player_hp, 0.0, player_max_hp)
	if objective_label != null and GameContent.OBJECTIVES.has(objective_id):
		var objective: Dictionary = GameContent.OBJECTIVES[objective_id]
		var objective_state: String = "DONE" if objective_complete else "%d/%d" % [floori(objective_progress), ceili(float(objective.get("target", 1.0)))]
		var field_text: String = "OBJECTIVE: %s  %s\n%s" % [String(objective.name).to_upper(), objective_state, GameContent.reward_text(objective)]
		if not contract_id.is_empty() and GameContent.CONTRACTS.has(contract_id):
			var contract: Dictionary = GameContent.CONTRACTS[contract_id]
			var contract_state: String = "DONE" if contract_complete else "%d/%d" % [floori(contract_progress), ceili(contract_target)]
			field_text += "\nCONTRACT: %s  %s  %s" % [String(contract.name).to_upper(), contract_state, GameContent.reward_text(contract)]
		if run_discoveries >= 2:
			field_text += "\nRETURN ROUTE OPEN AT THE SOUTHERN MARKER"
		objective_label.text = field_text
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
	var result_heading: String = "THE BARROW IS QUIET" if bool(result_data.victory) else ("THE COMPANY RETURNS" if bool(result_data.get("extracted", false)) else "THE COMPANY WITHDRAWS")
	box.add_child(_make_label(result_heading, 23, FOLKLORE if bool(result_data.victory) else PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Time %s\n%d enemies / %d elites / %d discoveries\nVeteran rating %d%%" % [_format_time(float(result_data.time)), int(result_data.kills), int(result_data.elites), int(result_data.get("discoveries", 0)), roundi(float(result_data.rating) * 100.0)], 15, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	var objective_result: Dictionary = GameContent.OBJECTIVES.get(String(result_data.get("objective", "")), {})
	var contract_result: Dictionary = GameContent.CONTRACTS.get(String(result_data.get("contract", "")), {})
	var objective_result_text: String = "OBJECTIVE: %s" % GameContent.reward_text(objective_result) if bool(result_data.get("objective_complete", false)) else "OBJECTIVE INCOMPLETE"
	var contract_result_text: String = "CONTRACT: %s" % GameContent.reward_text(contract_result) if bool(result_data.get("contract_complete", false)) else "NO CONTRACT REWARD"
	box.add_child(_make_label("%s\n%s" % [objective_result_text, contract_result_text], 12, AMBER.lightened(0.1), HORIZONTAL_ALIGNMENT_CENTER))
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
	silver_value_label = null
	provisions_value_label = null
	health_bar = null
	camp_interact_button = null
	expedition_interact_button = null

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

func _make_stat_button(primary_text: String, stat_text: String, minimum_height: float, color: Color = IRON.darkened(0.35), stat_height: float = 24.0) -> Button:
	var button: Button = _make_button("", minimum_height, color)
	var primary: Label = _make_label(primary_text, 10, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	primary.name = "CardDescription"
	primary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	primary.offset_left = 7.0
	primary.offset_top = 4.0
	primary.offset_right = -7.0
	primary.offset_bottom = -stat_height - 6.0
	primary.custom_minimum_size = Vector2.ZERO
	if body_bold_font != null:
		primary.add_theme_font_override("font", body_bold_font)
	button.add_child(primary)
	var divider: ColorRect = ColorRect.new()
	divider.name = "StatDivider"
	divider.color = Color(PARCHMENT_DARK, 0.42)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	divider.offset_left = 9.0
	divider.offset_top = -stat_height - 5.0
	divider.offset_right = -9.0
	divider.offset_bottom = -stat_height - 4.0
	button.add_child(divider)
	var stats: Label = _make_label(stat_text, 9, AMBER.lightened(0.32), HORIZONTAL_ALIGNMENT_CENTER)
	stats.name = "CardStats"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	stats.offset_left = 7.0
	stats.offset_top = -stat_height - 4.0
	stats.offset_right = -7.0
	stats.offset_bottom = -4.0
	stats.custom_minimum_size = Vector2.ZERO
	stats.add_theme_constant_override("outline_size", 2)
	button.add_child(stats)
	return button

func _make_camp_hotspot(node_name: String, title: String, subtitle: String, area: Rect2, _accent: Color = AMBER) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.position = area.position
	button.size = area.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var caption: Label = _make_label(title + ("\n" + subtitle if not subtitle.is_empty() else ""), 9, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	caption.name = "CampLocationCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left = -8.0
	caption.offset_top = -42.0
	caption.offset_right = 8.0
	caption.offset_bottom = -2.0
	caption.custom_minimum_size = Vector2.ZERO
	caption.add_theme_color_override("font_outline_color", Color(0.015, 0.018, 0.02, 1.0))
	caption.add_theme_constant_override("outline_size", 5)
	button.add_child(caption)
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
	if silver_value_label != null:
		silver_value_label.text = str(int(save.profile.silver))
	if provisions_value_label != null:
		provisions_value_label.text = str(int(save.profile.provisions))

func _make_resource_strip(font_size: int = 12, icon_size: float = 24.0) -> HBoxContainer:
	var strip: HBoxContainer = HBoxContainer.new()
	strip.name = "ResourceIconStrip"
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 12)
	var silver_group: HBoxContainer = HBoxContainer.new()
	silver_group.add_theme_constant_override("separation", 2)
	var silver_icon: TextureRect = TextureRect.new()
	silver_icon.name = "SilverIcon"
	silver_icon.texture = silver_icon_texture
	silver_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	silver_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	silver_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	silver_icon.tooltip_text = "Silver"
	silver_group.add_child(silver_icon)
	silver_value_label = _make_label("", font_size, PARCHMENT, HORIZONTAL_ALIGNMENT_LEFT)
	silver_value_label.name = "SilverValueLabel"
	silver_value_label.custom_minimum_size.x = 30.0
	silver_group.add_child(silver_value_label)
	strip.add_child(silver_group)
	var provisions_group: HBoxContainer = HBoxContainer.new()
	provisions_group.add_theme_constant_override("separation", 2)
	var provisions_icon: TextureRect = TextureRect.new()
	provisions_icon.name = "ProvisionsIcon"
	provisions_icon.texture = provisions_icon_texture
	provisions_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	provisions_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	provisions_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	provisions_icon.tooltip_text = "Provisions"
	provisions_group.add_child(provisions_icon)
	provisions_value_label = _make_label("", font_size, PARCHMENT, HORIZONTAL_ALIGNMENT_LEFT)
	provisions_value_label.name = "ProvisionsValueLabel"
	provisions_value_label.custom_minimum_size.x = 30.0
	provisions_group.add_child(provisions_value_label)
	strip.add_child(provisions_group)
	_update_resource_label()
	return strip

func _format_time(seconds: float) -> String:
	var safe: int = maxi(0, floori(seconds))
	return "%02d:%02d" % [safe / 60, safe % 60]

func _point_over_action_button(point: Vector2) -> bool:
	return (skill_button != null and skill_button.get_global_rect().has_point(point)) or (pause_button != null and pause_button.get_global_rect().has_point(point)) or (expedition_interact_button != null and expedition_interact_button.visible and expedition_interact_button.get_global_rect().has_point(point))

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
	for point: ExplorationPoint in exploration_points:
		_draw_exploration_point(point)
	for hazard: HazardState in hazards:
		var hazard_color: Color = Color(FOLKLORE, 0.18 if not hazard.triggered else 0.32)
		draw_circle(hazard.position + shake_offset, hazard.radius, hazard_color)
		draw_arc(hazard.position + shake_offset, hazard.radius, 0.0, TAU, 28, FOLKLORE, 2.0)
	for trap: TrapState in traps:
		if trap.kind == "ember":
			draw_circle(trap.position + shake_offset, trap.radius, Color(FOLKLORE, 0.12))
			draw_arc(trap.position + shake_offset, trap.radius, 0.0, TAU, 18, Color(FOLKLORE, 0.65), 2.0)
		else:
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

func _draw_run_controls() -> void:
	if joystick_touch_id >= 0:
		draw_circle(joystick_origin, 47.0, Color(0.08, 0.09, 0.10, 0.55))
		draw_arc(joystick_origin, 47.0, 0.0, TAU, 24, Color(PARCHMENT_DARK, 0.55), 2.0)
		draw_circle(joystick_origin + joystick_vector * 33.0, 18.0, Color(PARCHMENT, 0.55))

func _draw_exploration_point(point: ExplorationPoint) -> void:
	if point.discovered:
		return
	var pulse: float = (sin(run_elapsed * 3.0 + float(point.id.hash() % 11)) + 1.0) * 0.5
	var color: Color = FOLKLORE if point.kind in ["shrine", "barrow"] else AMBER
	draw_circle(point.position, 17.0 + pulse * 3.0, Color(color, 0.08 + pulse * 0.05))
	draw_arc(point.position, 12.0 + pulse * 2.0, 0.0, TAU, 12, Color(color, 0.72), 2.0)
	var diamond := PackedVector2Array([
		point.position + Vector2(0.0, -7.0), point.position + Vector2(7.0, 0.0),
		point.position + Vector2(0.0, 7.0), point.position + Vector2(-7.0, 0.0)
	])
	draw_colored_polygon(diamond, Color(color, 0.72))
	var font: Font = theme_main.default_font
	draw_string(font, point.position + Vector2(-46.0, -20.0), point.label, HORIZONTAL_ALIGNMENT_CENTER, 92.0, 9, Color(PARCHMENT, 0.88))

func _draw_extraction_marker(position: Vector2) -> void:
	var pulse: float = (sin(run_elapsed * 4.0) + 1.0) * 0.5
	draw_circle(position, 25.0 + pulse * 3.0, Color(AMBER, 0.08))
	draw_arc(position, 22.0, PI, TAU, 14, Color(AMBER, 0.82), 3.0)
	draw_line(position + Vector2(-22.0, 0.0), position + Vector2(-22.0, 16.0), Color(AMBER, 0.82), 3.0)
	draw_line(position + Vector2(22.0, 0.0), position + Vector2(22.0, 16.0), Color(AMBER, 0.82), 3.0)
	var font: Font = theme_main.default_font
	draw_string(font, position + Vector2(-44.0, -30.0), "RETURN TO CAMP", HORIZONTAL_ALIGNMENT_CENTER, 88.0, 9, PARCHMENT)

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

func _camp_tier_texture(building: String, level: int) -> Texture2D:
	var tiers: Array = camp_building_textures.get(building, [])
	if tiers.is_empty():
		return null
	return tiers[clampi(level, 0, tiers.size() - 1)] as Texture2D

func _camp_tier_outline_texture(building: String, level: int) -> Texture2D:
	var tiers: Array = camp_building_outline_textures.get(building, [])
	if tiers.is_empty():
		return null
	return tiers[clampi(level, 0, tiers.size() - 1)] as Texture2D

func _camp_structure_rect(structure_id: String, texture: Texture2D) -> Rect2:
	if texture == null or not CAMP_STRUCTURE_LAYOUT.has(structure_id):
		return Rect2()
	var layout: Dictionary = CAMP_STRUCTURE_LAYOUT[structure_id]
	var anchor: Vector2 = layout.anchor
	var draw_height: float = float(layout.height)
	var texture_size: Vector2 = texture.get_size()
	var draw_width: float = draw_height * texture_size.x / maxf(1.0, texture_size.y)
	return Rect2(camp_world_origin + Vector2(anchor.x - draw_width * 0.5, anchor.y - draw_height), Vector2(draw_width, draw_height))

func _wire_camp_highlight(button: Button, structure_id: String) -> void:
	button.button_down.connect(_set_camp_highlight.bind(structure_id))
	button.button_up.connect(_clear_camp_highlight.bind(structure_id))
	button.mouse_entered.connect(_set_camp_highlight.bind(structure_id))
	button.mouse_exited.connect(_clear_camp_highlight.bind(structure_id))

func _set_camp_highlight(structure_id: String) -> void:
	camp_highlighted_structure = structure_id
	queue_redraw()

func _clear_camp_highlight(structure_id: String = "") -> void:
	if structure_id.is_empty() or camp_highlighted_structure == structure_id:
		camp_highlighted_structure = ""
		queue_redraw()

func _draw_camp_structure(structure_id: String, texture: Texture2D, outline: Texture2D) -> void:
	if texture == null:
		return
	var rect: Rect2 = _camp_structure_rect(structure_id, texture)
	if camp_highlighted_structure == structure_id and outline != null:
		draw_texture_rect(outline, rect, false)
	draw_texture_rect(texture, rect, false)

func _draw_camp_buildings() -> void:
	var veterans: Texture2D = camp_landmark_textures.get("veterans_hall") as Texture2D
	var campfire: Texture2D = camp_landmark_textures.get("campfire") as Texture2D
	var armory: Texture2D = _camp_tier_texture("armory", int(save.profile.armory_level))
	var blacksmith: Texture2D = _camp_tier_texture("blacksmith", int(save.profile.blacksmith_level))
	var quartermaster: Texture2D = _camp_tier_texture("quartermaster", int(save.profile.quartermaster_level))
	var training: Texture2D = _camp_tier_texture("training", int(save.profile.training_level))
	var veterans_outline: Texture2D = camp_landmark_outline_textures.get("veterans_hall") as Texture2D
	var campfire_outline: Texture2D = camp_landmark_outline_textures.get("campfire") as Texture2D
	var armory_outline: Texture2D = _camp_tier_outline_texture("armory", int(save.profile.armory_level))
	var blacksmith_outline: Texture2D = _camp_tier_outline_texture("blacksmith", int(save.profile.blacksmith_level))
	var quartermaster_outline: Texture2D = _camp_tier_outline_texture("quartermaster", int(save.profile.quartermaster_level))
	var training_outline: Texture2D = _camp_tier_outline_texture("training", int(save.profile.training_level))
	# Draw from the far side of camp toward the gate so lower structures overlap
	# higher ones naturally in the three-quarter perspective.
	_draw_camp_structure("veterans_hall", veterans, veterans_outline)
	_draw_camp_structure("armory", armory, armory_outline)
	_draw_camp_structure("quartermaster", quartermaster, quartermaster_outline)
	_draw_camp_structure("blacksmith", blacksmith, blacksmith_outline)
	_draw_camp_structure("training", training, training_outline)
	_draw_camp_structure("campfire", campfire, campfire_outline)
