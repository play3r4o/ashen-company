extends Control

const GameContent = preload("res://src/content.gd")
const GameRules = preload("res://src/rules.gd")
const SaveService = preload("res://src/save_service.gd")
const StructureDefinitionResource = preload("res://src/foundation/structure_definition.gd")
const RegionGeneratorService = preload("res://src/services/region_generator.gd")
const Expedition = preload("res://src/services/expedition_service.gd")
const Roster = preload("res://src/services/roster_service.gd")
const TerrainLayerScript = preload("res://src/render/terrain_layer.gd")
const CampLayerScript = preload("res://src/render/camp_layer.gd")
const RenderTheme = preload("res://src/render/render_theme.gd")
const HudLayoutScene = preload("res://src/ui/hud_layout.tscn")
const VisualLayoutScene = preload("res://src/ui/visual_layout.tscn")
const CampMenuLayoutScene = preload("res://src/ui/camp_menu_layout.tscn")
const RunMenuLayoutScene = preload("res://src/ui/run_menu_layout.tscn")
const ResultsMenuLayoutScene = preload("res://src/ui/results_menu_layout.tscn")
const SettingsMenuLayoutScene = preload("res://src/ui/settings_menu_layout.tscn")
const TrainingTreeScreenScene = preload("res://src/ui/training_tree_screen.tscn")
const ArsenalScreenScene = preload("res://src/ui/arsenal_screen.tscn")
const TrainingContent = preload("res://src/content/training_grounds_content.gd")
const ArsenalService = preload("res://src/services/arsenal_service.gd")
const TrainingGroundsService = preload("res://src/services/training_grounds_service.gd")
const UpgradeOfferService = preload("res://src/services/upgrade_offer_service.gd")
const CombatStats = preload("res://src/services/combat_stat_service.gd")
const CombatStatusService = preload("res://src/services/status_service.gd")
const EnvironmentInteractions = preload("res://src/services/environment_interaction_service.gd")
const CampLayoutScenes: Array[PackedScene] = [
	preload("res://src/foundation/camp_layout.tscn"),
	preload("res://src/foundation/camp_layout_tier1.tscn"),
	preload("res://src/foundation/camp_layout_tier2.tscn"),
	preload("res://src/foundation/camp_layout_tier3.tscn"),
	preload("res://src/foundation/camp_layout_tier4.tscn")
]

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
	"veterans_hall": {"anchor": Vector2(585.0, 210.0), "height": 112.0},
	"armory": {"anchor": Vector2(460.0, 335.0), "height": 112.0},
	"quartermaster": {"anchor": Vector2(710.0, 335.0), "height": 112.0},
	"blacksmith": {"anchor": Vector2(460.0, 470.0), "height": 112.0},
	"training": {"anchor": Vector2(710.0, 470.0), "height": 112.0},
	"campfire": {"anchor": Vector2(585.0, 390.0), "height": 72.0}
}

# Hall upgrades reveal these neutral foundations in order. A plot has no
# service identity until the player walks to it and chooses what to construct.
const CAMP_PLOT_ORDER: Array[String] = ["plot_1", "plot_2", "plot_3", "plot_4"]
const CAMP_PLOT_LAYOUT: Dictionary = {
	"plot_1": {"anchor": Vector2(460.0, 335.0)},
	"plot_2": {"anchor": Vector2(710.0, 335.0)},
	"plot_3": {"anchor": Vector2(460.0, 470.0)},
	"plot_4": {"anchor": Vector2(710.0, 470.0)}
}

const TOWN_LEVELS: Array[Dictionary] = [
	# The Refuge uses the approved portrait composition: Hall at the rear, fire
	# at the warm center and a clear gate lane. Each restoration step expands
	# gradually while preserving those anchors and the city-builder capacity.
	{"name": "REFUGE", "capacity": 2, "bounds": Rect2(415.0, 105.0, 340.0, 480.0)},
	{"name": "OUTPOST", "capacity": 3, "bounds": Rect2(395.0, 80.0, 380.0, 530.0)},
	{"name": "HAMLET", "capacity": 4, "bounds": Rect2(375.0, 55.0, 420.0, 580.0)},
	{"name": "VILLAGE", "capacity": 5, "bounds": Rect2(350.0, 30.0, 470.0, 630.0)},
	{"name": "ASHEN TOWN", "capacity": 6, "bounds": Rect2(325.0, 5.0, 520.0, 680.0)}
]

# Touch targets deliberately follow the occupied plot bands instead of each
# source image's transparent canvas. This keeps generous phone-sized targets
# without letting a lower building steal taps from the structure above it.
const CAMP_STRUCTURE_HIT_RECTS: Dictionary = {
	"veterans_hall": Rect2(445.0, 118.0, 280.0, 230.0),
	"armory": Rect2(92.0, 310.0, 280.0, 184.0),
	"quartermaster": Rect2(798.0, 302.0, 280.0, 184.0),
	"blacksmith": Rect2(112.0, 510.0, 292.0, 184.0),
	"training": Rect2(778.0, 510.0, 292.0, 184.0),
	"campfire": Rect2(480.0, 590.0, 210.0, 126.0)
}

# The walkable hub uses these anchors for diegetic interactions. The existing
# generous building buttons remain available as an accessibility shortcut.
const CAMP_INTERACTION_POINTS: Dictionary = {
	"veterans_hall": Vector2(585.0, 360.0),
	"armory": Vector2(246.0, 502.0),
	"quartermaster": Vector2(920.0, 500.0),
	"blacksmith": Vector2(275.0, 704.0),
	"training": Vector2(898.0, 704.0),
	"campfire": Vector2(585.0, 716.0),
	"gate": Vector2(585.0, 760.0)
}

const CAMP_GATE_EDGE_INDEX: int = 3
const CAMP_FENCE_COLLISION_RADIUS: float = 20.0
const CAMP_INTERACTION_RADIUS: float = 74.0
const CAMP_WALK_SPEED: float = 104.0
# The original content occupies a three-by-four screen field. Keep that
# authored area at its native scale, then add one full screen of moor on every
# side so the camp is a true four-direction starting hub.
const WORLD_CONTENT_WIDTH_SCREENS: float = 3.0
const WORLD_CONTENT_HEIGHT_SCREENS: float = 4.0
const WORLD_WIDTH_SCREENS: float = 5.0
const WORLD_HEIGHT_SCREENS: float = 6.0
const CAMP_GATE_HALF_WIDTH: float = 66.0
const FIELD_START_DISTANCE: float = 72.0
const RUN_CAMERA_TRANSITION_SECONDS: float = 1.0
const ENEMY_SPAWN_VIEW_MARGIN: float = 96.0
const MAX_CAMP_WANDERERS: int = 10
const MIN_CAMP_WANDERERS: int = 4

const CAMP_DECOR_FOOTPRINTS: Dictionary = {
	"barrels": Vector2(19.0, 11.0),
	"crates": Vector2(24.0, 11.0),
	"firewood": Vector2(24.0, 9.0),
	"drying_rack": Vector2(24.0, 7.0),
	"banner": Vector2(7.0, 6.0),
	"weapon_rack": Vector2(27.0, 9.0),
	"handcart": Vector2(29.0, 12.0),
	"brazier": Vector2(12.0, 9.0)
}

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
	var poison_timer: float = 0.0
	var poison_damage: float = 0.0
	var poison_ticks: int = 0
	var mark_timer: float = 0.0
	var pin_timer: float = 0.0
	var wander_direction: Vector2 = Vector2.ZERO
	var wander_timer: float = 0.0
	var dispersing: bool = false
	var route_waypoints: Array[Vector2] = []
	var route_target_cell: Vector2i = Vector2i(-9999, -9999)
	var route_repath_timer: float = 0.0
	var path_check_timer: float = 0.0
	var has_direct_path: bool = true
	var last_hit_critical: bool = false

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
	var source_tags: Array[String] = []
	var returning: bool = false
	var return_delay: float = 0.0
	var orbiting: bool = false
	var orbit_angle: float = 0.0
	var orbit_radius: float = 0.0
	var orbit_speed: float = 0.0
	var ricochets: int = 0

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
	var source_ability: String = ""
	var status: String = ""

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
var camp_decor_textures: Dictionary = {}
var camp_building_outline_textures: Dictionary = {}
var camp_landmark_outline_textures: Dictionary = {}
var moor_texture: Texture2D
var world_map_texture: Texture2D
var camp_palisade_texture: Texture2D
var foundation_terrain_atlas: Texture2D
var foundation_terrain_overlay_atlas: Texture2D
var forest_cluster_textures: Array[Texture2D] = []
var forest_detail_textures: Array[Texture2D] = []
var foundation_wall_textures: Dictionary = {}
var foundation_hero_textures: Dictionary = {}
var hero_animation_textures: Dictionary = {}
var enemy_animation_textures: Dictionary = {}
var camp_structure_definitions: Dictionary = {}
var generated_region: Dictionary = {}
var region_blocker_grid: Dictionary = {}
var enemy_flow_distance: Dictionary = {}
var enemy_flow_open_cache: Dictionary = {}
var enemy_flow_target_cell: Vector2i = Vector2i(-9999, -9999)
var enemy_flow_repath_timer: float = 0.0
var enemy_flow_min_cell: Vector2i = Vector2i.ZERO
var enemy_flow_max_cell: Vector2i = Vector2i.ZERO
var region_origin: Vector2 = Vector2(-7.0, 800.0)
var ui_frame_texture: Texture2D
var camp_title_crest_texture: Texture2D
var resource_banner_texture: Texture2D
var silver_icon_texture: Texture2D
var provisions_icon_texture: Texture2D
var settings_cog_texture: Texture2D
var reference_resource_rail_texture: Texture2D
var reference_action_button_texture: Texture2D
var reference_icon_textures: Dictionary = {}
var campfire_flame_texture: Texture2D
var campfire_glow_texture: Texture2D
var campfire_animation_texture: Texture2D
var actor_textures: Dictionary = {}
var actor_frames: Dictionary = {}
var ui_root: Control
var status_label: Label
var silver_value_label: Label
var provisions_value_label: Label
var hud_label: Label
var health_bar: ProgressBar
var active_hud_layout: AshenHudLayout
var camp_arrival_crest: TextureRect
var camp_arrival_crest_elapsed: float = 0.0
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
var active_doctrines: Array[String] = []
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
var boss_cycle_spawned: int = 0
var run_bosses_defeated: int = 0
var run_boss_keys: int = 0
var selected_roster_hero_id: String = "hunter"
var skill_tree_branch: int = 0
var weapon_picker_category: int = 0
var inventory_page: int = 0
var selected_item_uid: String = ""
var second_wind_used: bool = false
var camp_player_position: Vector2 = Vector2(585.0, 610.0)
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
var run_gate_entry_armed: bool = false
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
var run_boons: Dictionary = {}
var prepared_arsenal: Dictionary = {}
var run_rerolls: int = 0
var upgrade_offer_index: int = 0
var recently_rejected_choices: Array[String] = []
var rejected_choice_levels: Dictionary = {}
var combat_statuses := CombatStatusService.new()
var environment_states: Dictionary = {}
var weapon_attack_counts: Dictionary = {}
var player_barrier: float = 0.0
var time_since_player_damage: float = 999.0
var stationary_time: float = 0.0
var stationary_anchor: Vector2 = Vector2.ZERO
var recent_movement_distance: float = 0.0
var post_mobility_timer: float = 0.0
var bloodbound_heal_window: float = 0.0
var bloodbound_healed: float = 0.0
var duelist_momentum: int = 0
var duelist_last_category: String = ""
var war_cry_timer: float = 0.0
var war_cry_attack_speed: float = 0.0
var movement_burst_timer: float = 0.0
var vanishing_step_cooldown: float = 0.0
var next_ranged_projectiles: int = 0
var running_shot_cooldown: float = 0.0
var toxic_blood_cooldown: float = 0.0
var resonant_guard_cooldown: float = 0.0
var technique_damage_reduction_timer: float = 0.0
var elemental_echo_cooldowns: Dictionary = {}
var elemental_conduit_cooldowns: Dictionary = {}
var volatile_mixture_cooldowns: Dictionary = {}
var repeated_hit_counts: Dictionary = {}
var cached_training_modifiers: Dictionary = {}
var static_field_timer: float = 1.0
var blade_hit_count: int = 0
var technique_timers: Dictionary = {}
var run_loot: Array[Dictionary] = []
var weapon_timers: Dictionary = {}
var enemies: Array[EnemyState] = []
var camp_wanderers: Array[EnemyState] = []
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
var world_content_origin: Vector2 = Vector2.ZERO
var world_content_size: Vector2 = Vector2(1170.0, 3376.0)
var camp_world_origin: Vector2 = Vector2.ZERO
var camera_offset: Vector2 = Vector2.ZERO
var run_camera_transition: float = 1.0
var camp_uses_field_camera: bool = false
var camp_camera_anchor_x: float = 0.5
var camp_camera_anchor_y: float = 0.52
var camp_hotspot_buttons: Dictionary = {}
var camp_construction_plot_texture: Texture2D
var camp_construction_plot_outline: Texture2D
var safe_area_top: float = 0.0
var world_root: Node2D
var terrain_layer: AshenTerrainLayer
var camp_static_layer: AshenCampLayer
var camp_front_layer: AshenCampLayer
var camp_static_commands_cache: Array[Dictionary] = []
var static_visual_signature: String = ""
var camp_layout_data: CampLayout
var cached_town_bounds_world: Rect2 = Rect2()
var cached_town_bounds_level: int = -1
var hud_layout_data: AshenHudLayout
var visual_layout_data: AshenVisualLayout
var camp_menu_layout_data: AshenVisualLayout
var run_menu_layout_data: AshenVisualLayout
var results_menu_layout_data: AshenVisualLayout
var settings_menu_layout_data: AshenVisualLayout
# GameContent keeps the original catalogue as immutable constants for legacy
# compatibility.  The rebuilt Training Grounds adds canonical IDs to these
# private mutable copies instead of attempting to mutate the constants.
var runtime_weapons: Dictionary = GameContent.WEAPONS.duplicate(true)
var runtime_techniques: Dictionary = GameContent.TECHNIQUES.duplicate(true)

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	_load_camp_layer_textures()
	camp_layout_data = CampLayoutScenes[0].instantiate() as CampLayout
	camp_layout_data.visible = false
	add_child(camp_layout_data)
	hud_layout_data = null
	visual_layout_data = VisualLayoutScene.instantiate() as AshenVisualLayout
	visual_layout_data.visible = false
	add_child(visual_layout_data)
	camp_menu_layout_data = CampMenuLayoutScene.instantiate() as AshenVisualLayout
	run_menu_layout_data = RunMenuLayoutScene.instantiate() as AshenVisualLayout
	results_menu_layout_data = ResultsMenuLayoutScene.instantiate() as AshenVisualLayout
	settings_menu_layout_data = SettingsMenuLayoutScene.instantiate() as AshenVisualLayout
	for menu_library: AshenVisualLayout in [camp_menu_layout_data, run_menu_layout_data, results_menu_layout_data, settings_menu_layout_data]:
		menu_library.visible = false
		add_child(menu_library)
	world_map_texture = null
	camp_palisade_texture = null
	foundation_terrain_atlas = load("res://assets/foundation/terrain/blackthorn_tiles_reference.png")
	foundation_terrain_overlay_atlas = load("res://assets/foundation/terrain/blackthorn_overlays_reference.png")
	for forest_index: int in 4:
		var forest_texture: Texture2D = load("res://assets/foundation/terrain/forest_cluster_%d.png" % forest_index) as Texture2D
		if forest_texture != null:
			forest_cluster_textures.append(forest_texture)
	_load_foundation_art()
	_load_reference_modular_art()
	_register_training_runtime_content()
	ui_frame_texture = load("res://assets/generated/reference_v4/ui/menu_background.png")
	camp_title_crest_texture = load("res://assets/ui/generated/camp_title_crest.png")
	resource_banner_texture = load("res://assets/ui/generated/resource_banner_frame.png")
	silver_icon_texture = load("res://assets/ui/generated/silver_icon.png")
	provisions_icon_texture = load("res://assets/ui/generated/provisions_icon.png")
	settings_cog_texture = load("res://assets/generated/reference_v2/ui/settings_cog.png")
	reference_resource_rail_texture = load("res://assets/generated/reference_v2/ui/resource_rail.png")
	reference_action_button_texture = load("res://assets/generated/reference_v2/ui/action_button.png")
	for icon_id: String in ["heart", "level", "key", "dread", "silver", "provisions"]:
		reference_icon_textures[icon_id] = load("res://assets/generated/reference_v2/ui/%s_icon.png" % icon_id)
	campfire_flame_texture = load("res://assets/foundation/town/campfire_flames.png")
	campfire_glow_texture = load("res://assets/foundation/town/campfire_glow.png")
	_load_actor_textures()
	theme_main = _build_theme()
	_refresh_safe_area_inset()
	save = SaveService.load_data()
	_load_camp_layout_for_tier(_town_level())
	_build_structure_definitions()
	_sync_structure_anchors()
	_sync_active_hero_fields()
	generated_region = RegionGeneratorService.generate_blackthorn(int(save.profile.get("region_seed", 41041)))
	_cache_region_blockers()
	_configure_world()
	_setup_visual_layers()
	_sync_visual_layers(true)
	_setup_audio()
	_apply_offline_progress()
	_show_camp()

func _load_camp_layout_for_tier(tier: int) -> void:
	var desired_tier: int = clampi(tier, 0, CampLayoutScenes.size() - 1)
	if camp_layout_data != null and int(camp_layout_data.layout_tier) == desired_tier:
		return
	if is_instance_valid(camp_layout_data):
		camp_layout_data.queue_free()
	camp_layout_data = CampLayoutScenes[desired_tier].instantiate() as CampLayout
	camp_layout_data.visible = false
	add_child(camp_layout_data)
	cached_town_bounds_level = -1
	enemy_flow_open_cache.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == Screen.RUN:
		run_paused = true
		_reset_movement_input()
		_snapshot_run()
		SaveService.save_data(save)

func _refresh_safe_area_inset() -> void:
	# Installed iOS PWAs expose the notch through CSS env(safe-area-inset-top)
	# once viewport-fit=cover is enabled. Browsers and devices without a notch
	# resolve the same measurement to zero, keeping the compact layout intact.
	safe_area_top = 0.0
	if not OS.has_feature("web"):
		return
	var measured: Variant = JavaScriptBridge.eval("(function(){try{var e=document.createElement('div');e.style.cssText='position:absolute;left:0;top:0;width:1px;height:env(safe-area-inset-top);pointer-events:none;';document.body.appendChild(e);var h=e.getBoundingClientRect().height;e.remove();return Math.ceil(h);}catch(_){return 0;}})()")
	if measured is int or measured is float:
		safe_area_top = maxf(0.0, float(measured))

func _add_safe_area_band(parent: Control) -> void:
	var band: ColorRect = ColorRect.new()
	band.name = "SafeAreaTopBand"
	band.position = Vector2.ZERO
	band.size = Vector2(size.x, safe_area_top)
	band.color = Color.BLACK
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.z_index = 100
	parent.add_child(band)

func _add_live_hud(mode: String) -> AshenHudLayout:
	var live_hud := HudLayoutScene.instantiate() as AshenHudLayout
	live_hud.name = "LiveHud"
	live_hud.theme = theme_main
	live_hud.configure(mode, safe_area_top)
	ui_root.add_child(live_hud)
	active_hud_layout = live_hud
	hud_layout_data = live_hud
	return live_hud

func _make_authored_panel(node_path: NodePath, fallback: Rect2, runtime_name: String) -> PanelContainer:
	var library: AshenVisualLayout = visual_layout_data
	var path_text := String(node_path)
	if path_text.begins_with("Camp/"):
		library = camp_menu_layout_data
	elif path_text.begins_with("Run/"):
		library = run_menu_layout_data
	elif path_text.begins_with("Results/"):
		library = results_menu_layout_data
	elif path_text.begins_with("Settings/"):
		library = settings_menu_layout_data
	if library == null:
		var fallback_panel := _make_panel(true)
		fallback_panel.name = runtime_name
		fallback_panel.position = fallback.position
		fallback_panel.size = fallback.size
		return fallback_panel
	return library.instantiate_panel(node_path, fallback, runtime_name)

func _attach_panel_content(panel: PanelContainer, content: Control) -> void:
	var content_root := panel.get_node_or_null("ContentRoot") as Control
	if content_root == null:
		panel.add_child(content)
		return
	content_root.add_child(content)
	content.anchor_left = 0.0
	content.anchor_top = 0.0
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = 0.0
	content.offset_top = 0.0
	content.offset_right = 0.0
	content.offset_bottom = 0.0

func _process(delta: float) -> void:
	_sync_visual_layers()
	_update_arrival_crest(delta)
	if is_instance_valid(world_root):
		world_root.position = -camera_offset.round()
	if screen == Screen.RUN:
		if not run_paused and not choosing_upgrade:
			_process_run(minf(delta, 0.05))
		else:
			guard_cooldown = maxf(0.0, guard_cooldown - delta)
		queue_redraw()
	elif screen == Screen.CAMP:
		if _camp_hub_active():
			_process_camp(delta)
		_sync_camp_depth_layers()
		queue_redraw()

func _draw() -> void:
	draw_set_transform(-camera_offset.round())
	_draw_camp_highlights()
	_draw_camp_ambience()
	if screen == Screen.CAMP and _camp_hub_active():
		_draw_camp_life()
	elif screen == Screen.RUN:
		_draw_run_world()
	if bool(save.get("settings", {}).get("collision_debug", false)):
		_draw_collision_debug()
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

func _update_arrival_crest(delta: float) -> void:
	if not is_instance_valid(camp_arrival_crest) or not camp_arrival_crest.visible:
		return
	camp_arrival_crest_elapsed += delta
	if camp_arrival_crest_elapsed <= 2.6:
		camp_arrival_crest.modulate.a = 1.0
	elif camp_arrival_crest_elapsed < 3.5:
		camp_arrival_crest.modulate.a = 1.0 - (camp_arrival_crest_elapsed - 2.6) / 0.9
	else:
		camp_arrival_crest.visible = false
		camp_arrival_crest.modulate.a = 0.0

func _configure_world() -> void:
	world_content_size = Vector2(size.x * WORLD_CONTENT_WIDTH_SCREENS, size.y * WORLD_CONTENT_HEIGHT_SCREENS)
	world_size = Vector2(size.x * WORLD_WIDTH_SCREENS, size.y * WORLD_HEIGHT_SCREENS)
	world_content_origin = (world_size - world_content_size) * 0.5
	var content_scale := Vector2(world_content_size.x / 1170.0, world_content_size.y / 3376.0)
	# Keep the authored Blackthorn region attached to the same three-by-four
	# content field while the surrounding margin becomes traversable moor.
	region_origin = world_content_origin + Vector2(-7.0 * content_scale.x, 800.0 * content_scale.y)
	camp_world_origin = Vector2.ZERO
	_sync_structure_anchors()
	camp_player_position = _safe_camp_spawn_position()
	camera_offset = Vector2.ZERO


func _setup_visual_layers() -> void:
	if is_instance_valid(world_root):
		world_root.queue_free()
	world_root = Node2D.new()
	world_root.name = "WorldRoot"
	# Keep the retained world layers around the root draw pass so the camp can
	# place south-facing objects in front of the actor while northern objects
	# remain behind it.
	world_root.z_index = 0
	world_root.position = -camera_offset.round()
	add_child(world_root)
	terrain_layer = TerrainLayerScript.new()
	terrain_layer.name = "TerrainStaticLayer"
	terrain_layer.z_index = -100
	world_root.add_child(terrain_layer)
	camp_static_layer = CampLayerScript.new()
	camp_static_layer.name = "CampStaticLayer"
	camp_static_layer.z_index = -10
	world_root.add_child(camp_static_layer)
	camp_front_layer = CampLayerScript.new()
	camp_front_layer.name = "CampFrontLayer"
	camp_front_layer.z_index = 10
	world_root.add_child(camp_front_layer)
	static_visual_signature = ""


func _visual_state_signature() -> String:
	var profile: Dictionary = save.get("profile", {})
	return "%d:%d:%s:%s:%d:%d:%d:%d:%d:%s" % [
		int(generated_region.get("seed", profile.get("region_seed", 41041))),
		_town_level(),
		str(_constructed_buildings()),
		str(_building_plots()),
		int(profile.get("armory_level", 0)),
		int(profile.get("blacksmith_level", 0)),
		int(profile.get("quartermaster_level", 0)),
		int(profile.get("training_level", 0)),
		RenderTheme.VISUAL_VERSION,
		str(size),
	]


func _sync_visual_layers(force: bool = false) -> void:
	if not is_instance_valid(terrain_layer) or not is_instance_valid(camp_static_layer) or not is_instance_valid(camp_front_layer) or save.is_empty():
		return
	var signature: String = _visual_state_signature()
	if not force and signature == static_visual_signature:
		return
	static_visual_signature = signature
	terrain_layer.rebuild(
		generated_region,
		region_origin,
		int(generated_region.get("seed", save.get("profile", {}).get("region_seed", 41041))),
		RenderTheme.terrain_config(foundation_terrain_atlas, foundation_terrain_overlay_atlas, world_size, _town_bounds_world())
	)
	camp_static_commands_cache = _camp_static_commands()
	camp_static_layer.rebuild({"signature": signature + ":back", "commands": camp_static_commands_cache})
	camp_front_layer.rebuild({"signature": signature + ":front", "commands": []})
	_sync_camp_depth_layers()

func _sync_camp_depth_layers() -> void:
	if not is_instance_valid(camp_static_layer) or not is_instance_valid(camp_front_layer):
		return
	if screen != Screen.CAMP or not _camp_hub_active():
		camp_static_layer.update_commands(camp_static_commands_cache)
		camp_front_layer.update_commands([])
		return
	var actor_y: float = camp_player_position.y
	var back: Array[Dictionary] = []
	var front: Array[Dictionary] = []
	for command: Dictionary in camp_static_commands_cache:
		var sort_y: float = float(command.get("sort_y", _command_ground_y(command)))
		if sort_y <= actor_y:
			back.append(command)
		else:
			front.append(command)
	camp_static_layer.update_commands(back)
	camp_front_layer.update_commands(front)

func _command_ground_y(command: Dictionary) -> float:
	var rect: Rect2 = command.get("rect", Rect2())
	return rect.end.y


func _camp_static_commands() -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var pole: Texture2D = foundation_wall_textures.get("wall_pole") as Texture2D
	var gate: Texture2D = foundation_wall_textures.get("town_gate") as Texture2D
	var bounds: Rect2 = _town_bounds_world()
	var gate_position: Vector2 = _camp_gate_position()
	_append_forest_ring_commands(commands, bounds)
	if pole != null and gate != null:
		if camp_layout_data != null and _town_level() == 0 and not camp_layout_data.wall_segments(0).is_empty():
			_append_authored_wall_commands(commands, pole)
		else:
			var rear_ground_y: float = bounds.position.y + 32.0
			var front_ground_y: float = bounds.end.y + 32.0
			for anchor: Vector2 in _horizontal_wall_pole_anchors(bounds.position.x, bounds.end.x, rear_ground_y):
				commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0))})
			for side_x: float in [bounds.position.x, bounds.end.x]:
				for anchor: Vector2 in _vertical_wall_pole_anchors(side_x, rear_ground_y, front_ground_y):
					commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0))})
			for anchor: Vector2 in _horizontal_wall_pole_anchors(bounds.position.x, gate_position.x - 44.0, front_ground_y):
				commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0))})
			for anchor: Vector2 in _horizontal_wall_pole_anchors(gate_position.x + 44.0, bounds.end.x, front_ground_y):
				commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0) )})
		var authored_gate_layout: bool = camp_layout_data != null and (camp_layout_data.layout_tier == 0 or camp_layout_data.has_explicit_tier(_town_level()))
		var gate_sprite: Dictionary = camp_layout_data.gate_sprite_properties(0) if authored_gate_layout and camp_layout_data.gate_anchor(0) != Vector2.ZERO else {}
		var gate_rect: Rect2 = _town_gate_draw_rect(gate_position)
		if not gate_sprite.is_empty():
			var gate_reference_anchor := camp_layout_data.gate_anchor(0)
			gate_rect = _authored_sprite_rect(_world_map_point(gate_reference_anchor), gate_reference_anchor, gate, gate_sprite)
		commands.append({"texture": gate, "rect": gate_rect, "flip_h": _authored_flip_h(gate_sprite), "flip_v": _authored_flip_v(gate_sprite)})

	_append_structure_command(commands, "veterans_hall", _camp_tier_texture("veterans_hall", _town_level()))
	for plot_id: String in _revealed_plot_ids().slice(0, 2):
		_append_plot_or_building_command(commands, plot_id)
	# The complete campfire-and-benches sprite is drawn as one authored frame on
	# the ambience layer. It is never added to the retained static commands, so
	# a static base cannot overlap the animated strip.
	for plot_id: String in _revealed_plot_ids().slice(2):
		_append_plot_or_building_command(commands, plot_id)
	for entry: Dictionary in _visible_camp_decor():
		var texture: Texture2D = camp_decor_textures.get(String(entry.id)) as Texture2D
		if texture != null:
			var sprite: Dictionary = entry.get("sprite", {})
			var anchor_reference: Vector2 = Vector2(entry.get("anchor_reference", Vector2.ZERO))
			var rect: Rect2 = _authored_sprite_rect(Vector2(entry.anchor), anchor_reference, texture, sprite)
			commands.append({"texture": texture, "rect": rect, "flip_h": _authored_flip_h(sprite), "flip_v": _authored_flip_v(sprite)})
	return commands

func _append_authored_wall_commands(commands: Array[Dictionary], pole: Texture2D) -> void:
	for segment: Dictionary in camp_layout_data.wall_segments(0):
		var polygon: PackedVector2Array = segment.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var world_points := PackedVector2Array()
		for point: Vector2 in polygon:
			world_points.append(_world_map_point(point))
		var world_bounds := Rect2(world_points[0], Vector2.ZERO)
		for point: Vector2 in world_points:
			world_bounds = world_bounds.expand(point)
		if world_bounds.size.x >= world_bounds.size.y:
			for x: float in _wall_axis_positions(world_bounds.position.x, world_bounds.end.x, 12.0):
				var anchor := Vector2(x, world_bounds.end.y)
				commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0))})
		else:
			var segment_id: String = String(segment.get("id", ""))
			var wall_x: float = world_bounds.position.x if segment_id == "west" else world_bounds.end.x if segment_id == "east" else world_bounds.get_center().x
			for y: float in _wall_axis_positions(world_bounds.position.y, world_bounds.end.y, 20.0):
				var anchor := Vector2(wall_x, y)
				commands.append({"texture": pole, "rect": Rect2(anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0))})

func _append_structure_command(commands: Array[Dictionary], structure_id: String, texture: Texture2D) -> void:
	if texture != null:
		var sprite: Dictionary = camp_layout_data.structure_sprite_properties(0, structure_id) if camp_layout_data != null and camp_layout_data.has_anchor(0, structure_id) else {}
		commands.append({"texture": texture, "rect": _camp_structure_rect(structure_id, texture), "flip_h": _authored_flip_h(sprite), "flip_v": _authored_flip_v(sprite)})


func _append_plot_or_building_command(commands: Array[Dictionary], plot_id: String) -> void:
	var building: String = _building_for_plot(plot_id)
	if not building.is_empty() and _is_constructed(building):
		_append_structure_command(commands, building, _camp_tier_texture(building, _structure_tier(building)))
	elif _is_plot_visible(plot_id) and camp_construction_plot_texture != null:
		var plot_sprite: Dictionary = camp_layout_data.plot_sprite_properties(0, plot_id) if camp_layout_data != null and camp_layout_data.has_plot(0, plot_id) else {}
		var plot_rect: Rect2
		if not plot_sprite.is_empty():
			var plot_reference: Vector2 = camp_layout_data.plot_anchor(0, plot_id)
			plot_rect = _authored_sprite_rect(_plot_anchor(plot_id), plot_reference, camp_construction_plot_texture, plot_sprite)
		else:
			var texture_size: Vector2 = camp_construction_plot_texture.get_size()
			var draw_height: float = minf(76.0, texture_size.y)
			var draw_width: float = draw_height * texture_size.x / maxf(1.0, texture_size.y)
			plot_rect = Rect2(_plot_anchor(plot_id) - Vector2(draw_width * 0.5, draw_height), Vector2(draw_width, draw_height))
		commands.append({"texture": camp_construction_plot_texture, "rect": plot_rect, "tint": Color(0.88, 0.84, 0.72, 0.94), "flip_h": _authored_flip_h(plot_sprite), "flip_v": _authored_flip_v(plot_sprite)})


func _append_forest_ring_commands(commands: Array[Dictionary], bounds: Rect2) -> void:
	if forest_cluster_textures.is_empty():
		return
	var forest_commands: Array[Dictionary] = []
	for forest_entry: Dictionary in _forest_ring_entries(bounds):
		var forest_anchor: Vector2 = Vector2(forest_entry.anchor)
		var hash_value: int = absi(tile_hash(Vector2i(floori(forest_anchor.x / 16.0), floori(forest_anchor.y / 16.0))))
		var texture: Texture2D = forest_cluster_textures[hash_value % forest_cluster_textures.size()]
		var tint: Color = Color(0.90, 0.94, 0.88, 1.0) if int(forest_entry.ring) == 0 else Color(0.82, 0.87, 0.80, 0.96)
		forest_commands.append({"texture": texture, "rect": Rect2(forest_anchor - Vector2(texture.get_width() * 0.5, texture.get_height()), texture.get_size()), "tint": tint, "sort_y": forest_anchor.y, "forest_ring": int(forest_entry.ring)})
	if forest_detail_textures.is_empty():
		forest_commands.sort_custom(_sort_world_art_by_ground_y)
		commands.append_array(forest_commands)
		return
	# Smaller shrubs, stumps and roots break up the tree line without occupying
	# the gate road or being mistaken for the physical palisade.
	for detail_index: int in 9:
		var side: int = detail_index % 3
		var detail_hash: int = absi(tile_hash(Vector2i(detail_index * 23, _town_level() * 47 + 11)))
		var detail_anchor: Vector2
		if side == 0:
			detail_anchor = Vector2(bounds.position.x - 64.0 - float(detail_hash % 42), bounds.position.y + float((detail_hash / 5) % int(bounds.size.y)))
		elif side == 1:
			detail_anchor = Vector2(bounds.end.x + 64.0 + float(detail_hash % 42), bounds.position.y + float((detail_hash / 7) % int(bounds.size.y)))
		else:
			detail_anchor = Vector2(bounds.position.x + float(detail_hash % int(bounds.size.x)), bounds.position.y - 70.0 - float(detail_hash % 38))
		var detail_texture: Texture2D = forest_detail_textures[detail_hash % forest_detail_textures.size()]
		forest_commands.append({"texture": detail_texture, "rect": Rect2(detail_anchor - Vector2(detail_texture.get_width() * 0.5, detail_texture.get_height()), detail_texture.get_size()), "sort_y": detail_anchor.y})
	forest_commands.sort_custom(_sort_world_art_by_ground_y)
	commands.append_array(forest_commands)


func _sort_world_art_by_ground_y(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("sort_y", 0.0)) < float(b.get("sort_y", 0.0))


func _forest_ring_entries(bounds: Rect2) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for ring: int in 2:
		var outward: float = 42.0 if ring == 0 else 94.0
		var spacing: float = 44.0 if ring == 0 else 58.0
		var side_end_y: float = bounds.end.y - 54.0
		var side_count: int = ceili((side_end_y - (bounds.position.y - 8.0)) / spacing)
		for slot: int in side_count + 1:
			var side_y: float = lerpf(bounds.position.y - 8.0, side_end_y, float(slot) / float(side_count))
			for edge_id: int in 2:
				if ring == 0 or _forest_outer_slot_selected(edge_id, slot):
					var side_x: float = bounds.position.x - outward if edge_id == 0 else bounds.end.x + outward
					entries.append({"anchor": Vector2(side_x, side_y), "ring": ring, "edge": edge_id, "slot": slot})
		var top_count: int = ceili((bounds.size.x + 2.0 * spacing) / spacing)
		for slot: int in top_count + 1:
			if ring == 0 or _forest_outer_slot_selected(2, slot):
				var top_x: float = lerpf(bounds.position.x - spacing, bounds.end.x + spacing, float(slot) / float(top_count))
				entries.append({"anchor": Vector2(top_x, bounds.position.y - outward + 12.0), "ring": ring, "edge": 2, "slot": slot})
		# Keep the southern palisade and gate approach fully visible for now.
	return entries


func _forest_outer_slot_selected(edge_id: int, slot: int) -> bool:
	# String hashing mixes adjacent indices much better than tile_hash parity,
	# avoiding the artificial 1,0,1,0 pattern while staying deterministic.
	var mixed: int = absi(hash("forest:%d:%d:%d" % [_town_level(), edge_id, slot]))
	return mixed % 100 < 50


func _point_hits_refuge_forest(position: Vector2, clearance: float = 0.0) -> bool:
	if forest_cluster_textures.is_empty():
		return false
	for forest_entry: Dictionary in _forest_ring_entries(_town_bounds_world()):
		var anchor: Vector2 = Vector2(forest_entry.anchor)
		var hash_value: int = absi(tile_hash(Vector2i(floori(anchor.x / 16.0), floori(anchor.y / 16.0))))
		var texture: Texture2D = forest_cluster_textures[hash_value % forest_cluster_textures.size()]
		var canopy: Rect2 = Rect2(anchor - Vector2(texture.get_width() * 0.5, texture.get_height()), texture.get_size()).grow(clearance)
		if canopy.has_point(position):
			return true
	return false

func _draw_world_background() -> void:
	if foundation_terrain_atlas == null:
		return
	var visible: Rect2 = _visible_world_rect().grow(32.0)
	var min_tile := Vector2i(maxi(0, floori(visible.position.x / 32.0)), maxi(0, floori(visible.position.y / 32.0)))
	var max_tile := Vector2i(mini(ceili(world_size.x / 32.0), ceili(visible.end.x / 32.0)), mini(ceili(world_size.y / 32.0), ceili(visible.end.y / 32.0)))
	var region_size: Vector2i = generated_region.get("size_tiles", Vector2i(36, 78))
	var region_cells: Array = generated_region.get("cells", [])
	for tile_y: int in range(min_tile.y, max_tile.y + 1):
		for tile_x: int in range(min_tile.x, max_tile.x + 1):
			var world_position := Vector2(tile_x * 32.0, tile_y * 32.0)
			var kind: String = _town_tile_kind(world_position)
			if world_position.y >= region_origin.y:
				var local_tile := Vector2i(floori((world_position.x - region_origin.x) / 32.0), floori((world_position.y - region_origin.y) / 32.0))
				if local_tile.x >= 0 and local_tile.y >= 0 and local_tile.x < region_size.x and local_tile.y < region_size.y:
					var cell_index: int = local_tile.y * region_size.x + local_tile.x
					if cell_index >= 0 and cell_index < region_cells.size():
						kind = String(region_cells[cell_index].get("kind", "earth"))
				else:
					# The generated Moor now opens on all four sides. The one-screen
					# margins beyond its authored tiles are still Moor, not a blank
					# barrier texture, so the player can reach future biome gates.
					kind = "moss" if absi(tile_hash(Vector2i(tile_x, tile_y))) % 3 == 0 else "earth"
			_draw_foundation_tile(world_position, kind)
	_draw_modular_palisade()

func _town_tile_kind(world_position: Vector2) -> String:
	var center: Vector2 = world_position + Vector2(16.0, 16.0)
	var town_bounds: Rect2 = _town_bounds_world()
	if not town_bounds.has_point(center):
		var outside_hash: int = absi(tile_hash(Vector2i(floori(center.x / 32.0), floori(center.y / 32.0))))
		return "moss" if outside_hash % 3 == 0 else "earth"
	# The palisade encloses one deliberately legible safe surface. Keeping the
	# complete interior cobbled separates town from the regenerated moor and
	# prevents grass patches from reading as unrevealed construction plots.
	return "cobble"

func tile_hash(tile: Vector2i) -> int:
	return tile.x * 73856093 ^ tile.y * 19349663

func _draw_foundation_tile(position: Vector2, kind: String) -> void:
	var atlas_cells: Dictionary = {
		"earth": Vector2i(0, 0), "road": Vector2i(1, 0), "mud": Vector2i(1, 0),
		"moss": Vector2i(2, 0), "water": Vector2i(3, 0), "cobble": Vector2i(0, 1),
		"thorn": Vector2i(1, 1), "barrier": Vector2i(2, 1), "gate": Vector2i(3, 1)
	}
	var atlas_cell: Vector2i = atlas_cells.get(kind, Vector2i.ZERO)
	draw_texture_rect_region(foundation_terrain_atlas, Rect2(position, Vector2(32.0, 32.0)), Rect2(Vector2(atlas_cell * 32), Vector2(32.0, 32.0)))

func _draw_modular_palisade() -> void:
	var pole: Texture2D = foundation_wall_textures.get("wall_pole") as Texture2D
	var gate: Texture2D = foundation_wall_textures.get("town_gate") as Texture2D
	if pole == null or gate == null:
		return
	var bounds: Rect2 = _town_bounds_world()
	var gate_position: Vector2 = _camp_gate_position()
	var rear_ground_y: float = bounds.position.y + 32.0
	var front_ground_y: float = bounds.end.y + 32.0
	# One native 16x64 pole builds every wall. Horizontal rows place poles side
	# by side; side walls place the same poles from far to near so they overlap
	# naturally in depth. No sprite is stretched, cropped or allowed to gap.
	for anchor: Vector2 in _horizontal_wall_pole_anchors(bounds.position.x, bounds.end.x, rear_ground_y):
		_draw_palisade_pole(pole, anchor)
	for side_x: float in [bounds.position.x, bounds.end.x]:
		for anchor: Vector2 in _vertical_wall_pole_anchors(side_x, rear_ground_y, front_ground_y):
			_draw_palisade_pole(pole, anchor)
	# The gate sprite's own posts are centered about 44 pixels from its middle.
	# Stop the repeated poles at those post centers and draw the gate last.
	var gate_post_half_span: float = 44.0
	for anchor: Vector2 in _horizontal_wall_pole_anchors(bounds.position.x, gate_position.x - gate_post_half_span, front_ground_y):
		_draw_palisade_pole(pole, anchor)
	for anchor: Vector2 in _horizontal_wall_pole_anchors(gate_position.x + gate_post_half_span, bounds.end.x, front_ground_y):
		_draw_palisade_pole(pole, anchor)
	draw_texture_rect(gate, _town_gate_draw_rect(gate_position), false)

func _draw_palisade_pole(texture: Texture2D, ground_anchor: Vector2) -> void:
	draw_texture_rect(texture, Rect2(ground_anchor - Vector2(8.0, 64.0), Vector2(16.0, 64.0)), false)

func _town_gate_draw_rect(gate_position: Vector2) -> Rect2:
	# The gate posts share the horizontal wall's bottom edge. The old bottom-
	# center anchor placed the entire gate 32 pixels inside the safe area.
	return Rect2(gate_position - Vector2(64.0, 48.0), Vector2(128.0, 80.0))

func _wall_axis_positions(start_value: float, end_value: float, preferred_spacing: float) -> Array[float]:
	var positions: Array[float] = []
	var span: float = end_value - start_value
	if span < 0.0:
		return positions
	if span <= 0.01:
		return [start_value]
	var intervals: int = maxi(1, roundi(span / preferred_spacing))
	for index: int in intervals + 1:
		positions.append(lerpf(start_value, end_value, float(index) / float(intervals)))
	return positions

func _horizontal_wall_pole_anchors(start_x: float, end_x: float, ground_y: float) -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	for x: float in _wall_axis_positions(start_x, end_x, 12.0):
		anchors.append(Vector2(x, ground_y))
	return anchors

func _vertical_wall_pole_anchors(x: float, start_ground_y: float, end_ground_y: float) -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	for ground_y: float in _wall_axis_positions(start_ground_y, end_ground_y, 20.0):
		anchors.append(Vector2(x, ground_y))
	return anchors

func _world_map_point(reference_point: Vector2) -> Vector2:
	return world_content_origin + Vector2(reference_point.x * world_content_size.x / 1170.0, reference_point.y * world_content_size.y / 3376.0)

func _world_map_rect(reference_rect: Rect2) -> Rect2:
	return Rect2(_world_map_point(reference_rect.position), Vector2(reference_rect.size.x * world_content_size.x / 1170.0, reference_rect.size.y * world_content_size.y / 3376.0))

func _camp_boundary_world() -> PackedVector2Array:
	if camp_layout_data != null and _town_level() == 0:
		var authored_boundary: PackedVector2Array = camp_layout_data.boundary_polygon(0)
		if authored_boundary.size() >= 3:
			var mapped_boundary := PackedVector2Array()
			for point: Vector2 in authored_boundary:
				mapped_boundary.append(_world_map_point(point))
			return mapped_boundary
	var bounds: Rect2 = _town_bounds_world()
	var gate_x: float = _camp_gate_position().x
	return PackedVector2Array([
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		bounds.end,
		Vector2(gate_x + CAMP_GATE_HALF_WIDTH, bounds.end.y),
		Vector2(gate_x - CAMP_GATE_HALF_WIDTH, bounds.end.y),
		Vector2(bounds.position.x, bounds.end.y)
	])

func _town_level() -> int:
	return clampi(int(save.get("profile", {}).get("hall_level", 0)), 0, TOWN_LEVELS.size() - 1)

func _town_definition() -> Dictionary:
	return TOWN_LEVELS[_town_level()]

func _town_capacity() -> int:
	return int(_town_definition().capacity)

func _town_bounds_world() -> Rect2:
	var level: int = _town_level()
	if cached_town_bounds_level == level and cached_town_bounds_world.size != Vector2.ZERO:
		return cached_town_bounds_world
	var source_bounds: Rect2 = Rect2(_town_definition().bounds)
	if camp_layout_data != null and camp_layout_data.has_bounds(level):
		source_bounds = camp_layout_data.bounds_for(level)
	cached_town_bounds_world = _world_map_rect(source_bounds)
	cached_town_bounds_level = level
	return cached_town_bounds_world

func _visible_camp_decor() -> Array[Dictionary]:
	# Dressing is anchored to the live palisade bounds, so it moves outward as
	# the Hall expands instead of occupying future construction plots. The small
	# ground footprints below are physical, while the middle lane stays clear.
	var bounds: Rect2 = _town_bounds_world()
	var center: Vector2 = bounds.get_center()
	if camp_layout_data != null:
		var authored_decor: Array[Dictionary] = camp_layout_data.decoration_entries(_town_level())
		if not authored_decor.is_empty():
			for entry: Dictionary in authored_decor:
				entry["anchor_reference"] = Vector2(entry.anchor)
				entry.anchor = _world_map_point(Vector2(entry.anchor))
			return authored_decor
	var decor: Array[Dictionary] = [
		{"id": "barrels", "anchor": Vector2(bounds.position.x + 48.0, bounds.position.y + 116.0)},
		{"id": "crates", "anchor": Vector2(bounds.end.x - 48.0, bounds.position.y + 116.0)},
		{"id": "firewood", "anchor": Vector2(bounds.position.x + 50.0, bounds.end.y - 100.0)},
		{"id": "drying_rack", "anchor": Vector2(bounds.end.x - 50.0, bounds.end.y - 90.0)},
		{"id": "banner", "anchor": Vector2(bounds.position.x + 34.0, center.y + 8.0)},
		{"id": "weapon_rack", "anchor": Vector2(bounds.end.x - 38.0, center.y + 10.0)}
	]
	if _town_level() >= 2:
		decor.append({"id": "handcart", "anchor": Vector2(center.x + 100.0, bounds.position.y + 100.0)})
		decor.append({"id": "brazier", "anchor": Vector2(center.x - 100.0, bounds.end.y - 46.0)})
		decor.append({"id": "brazier", "anchor": Vector2(center.x + 100.0, bounds.end.y - 46.0)})
	return decor

func _camp_decor_footprint(entry: Dictionary, clearance: float = 0.0) -> Rect2:
	var authored_polygon: PackedVector2Array = entry.get("footprint", PackedVector2Array())
	if authored_polygon.size() >= 3:
		var authored_bounds := Rect2(authored_polygon[0], Vector2.ZERO)
		for point_index: int in range(1, authored_polygon.size()):
			authored_bounds = authored_bounds.expand(authored_polygon[point_index])
		return Rect2(Vector2(entry.get("anchor", Vector2.ZERO)) + authored_bounds.position - Vector2.ONE * clearance, authored_bounds.size + Vector2.ONE * clearance * 2.0)
	var half_size: Vector2 = Vector2(CAMP_DECOR_FOOTPRINTS.get(String(entry.get("id", "")), Vector2(12.0, 8.0)))
	half_size += Vector2.ONE * clearance
	var anchor: Vector2 = Vector2(entry.get("anchor", Vector2.ZERO))
	return Rect2(anchor - half_size, half_size * 2.0)

func _point_hits_camp_decor(position: Vector2, clearance: float = 0.0) -> bool:
	for entry: Dictionary in _visible_camp_decor():
		var authored_polygon: PackedVector2Array = entry.get("footprint", PackedVector2Array())
		if authored_polygon.size() >= 3:
			var authored_world := PackedVector2Array()
			for point: Vector2 in authored_polygon:
				authored_world.append(Vector2(entry.get("anchor", Vector2.ZERO)) + point)
			if Geometry2D.is_point_in_polygon(position, authored_world):
				return true
		if _camp_decor_footprint(entry, clearance).has_point(position):
			return true
	return false

func _draw_camp_decor() -> void:
	for entry: Dictionary in _visible_camp_decor():
		var texture: Texture2D = camp_decor_textures.get(String(entry.id)) as Texture2D
		if texture == null:
			continue
		var anchor: Vector2 = Vector2(entry.anchor)
		var texture_size: Vector2 = texture.get_size()
		draw_texture_rect(texture, Rect2(anchor - Vector2(texture_size.x * 0.5, texture_size.y), texture_size), false)

func _constructed_buildings() -> Array:
	return save.get("profile", {}).get("constructed_buildings", ["veterans_hall", "campfire"])

func _is_constructed(structure_id: String) -> bool:
	return structure_id in _constructed_buildings()

func _constructed_count() -> int:
	return _constructed_buildings().size()

func _has_open_building_slot() -> bool:
	return not _first_open_plot().is_empty()

func _building_plots() -> Dictionary:
	return save.get("profile", {}).get("building_plots", {})

func _revealed_plot_ids() -> Array[String]:
	var revealed: Array[String] = []
	for index: int in mini(_town_level(), CAMP_PLOT_ORDER.size()):
		revealed.append(CAMP_PLOT_ORDER[index])
	return revealed

func _plot_anchor(plot_id: String) -> Vector2:
	if not CAMP_PLOT_LAYOUT.has(plot_id):
		return Vector2.ZERO
	if camp_layout_data != null and camp_layout_data.has_plot(0, plot_id):
		return _world_map_point(camp_layout_data.plot_anchor(0, plot_id))
	return _world_map_point(Vector2(CAMP_PLOT_LAYOUT[plot_id].anchor))

func _plot_interaction_polygon_world(plot_id: String) -> PackedVector2Array:
	if camp_layout_data == null or not camp_layout_data.has_plot(0, plot_id):
		return PackedVector2Array()
	var local_polygon: PackedVector2Array = camp_layout_data.plot_polygon(0, plot_id, "Interaction")
	if local_polygon.size() < 3:
		return PackedVector2Array()
	var anchor_reference: Vector2 = camp_layout_data.plot_anchor(0, plot_id)
	var world_polygon := PackedVector2Array()
	for point: Vector2 in local_polygon:
		world_polygon.append(_world_map_point(anchor_reference + point))
	return world_polygon

func _building_for_plot(plot_id: String) -> String:
	return String(_building_plots().get(plot_id, ""))

func _plot_for_building(building: String) -> String:
	for plot_id: String in _building_plots():
		if String(_building_plots()[plot_id]) == building:
			return plot_id
	return ""

func _is_plot_visible(plot_id: String) -> bool:
	return plot_id in _revealed_plot_ids() and _building_for_plot(plot_id).is_empty()

func _first_open_plot() -> String:
	for plot_id: String in _revealed_plot_ids():
		if _building_for_plot(plot_id).is_empty():
			return plot_id
	return ""

func _sync_structure_anchors() -> void:
	# The safe-town center can change with viewport scaling and Hall expansion.
	# Re-resolve the two original landmarks whenever the camp UI is rebuilt.
	for centered_building: String in ["veterans_hall", "campfire"]:
		if camp_structure_definitions.has(centered_building):
			(camp_structure_definitions[centered_building] as StructureDefinition).anchor = _centered_camp_anchor(centered_building)
	for building: String in ["armory", "blacksmith", "quartermaster", "training"]:
		if not camp_structure_definitions.has(building):
			continue
		var plot_id: String = _plot_for_building(building)
		if not plot_id.is_empty():
			(camp_structure_definitions[building] as StructureDefinition).anchor = _plot_anchor(plot_id)

func _visible_world_rect() -> Rect2:
	return Rect2(camera_offset, size)

func _update_world_camera(focus: Vector2, safe_town: bool, instant: bool = false) -> void:
	var desired: Vector2
	# In town the hero sits low in the portrait frame so the Hall, plots and
	# paths ahead remain visible while walking toward the gate. Leaving through
	# the gate eases toward the expedition framing instead of snapping anchors.
	var vertical_anchor: float = 0.72
	var horizontal_anchor: float = 0.5
	if camp_uses_field_camera and screen == Screen.CAMP:
		horizontal_anchor = camp_camera_anchor_x
		vertical_anchor = camp_camera_anchor_y
	elif not safe_town:
		var blend: float = run_camera_transition * run_camera_transition * (3.0 - 2.0 * run_camera_transition)
		vertical_anchor = lerpf(0.72, 0.52, blend)
	desired = focus - Vector2(size.x * horizontal_anchor, size.y * vertical_anchor)
	desired.x = clampf(desired.x, 0.0, maxf(0.0, world_size.x - size.x))
	desired.y = clampf(desired.y, 0.0, maxf(0.0, world_size.y - size.y))
	camera_offset = desired if instant else camera_offset.lerp(desired, 0.16)

func _camp_gate_position() -> Vector2:
	var bounds: Rect2 = _town_bounds_world()
	var authored_gate_x: float = 585.0
	if camp_layout_data != null and (camp_layout_data.layout_tier == 0 or camp_layout_data.has_explicit_tier(_town_level())) and camp_layout_data.wall_segments(_town_level()).size() > 0:
		var authored_gate: Vector2 = camp_layout_data.gate_anchor(_town_level())
		if authored_gate != Vector2.ZERO:
			return _world_map_point(authored_gate)
	return Vector2(_world_map_point(Vector2(authored_gate_x, 0.0)).x, bounds.end.y)

func _centered_camp_anchor(structure_id: String) -> Vector2:
	var authored_anchor: Vector2 = Vector2(CAMP_STRUCTURE_LAYOUT[structure_id].anchor)
	if camp_layout_data != null and (camp_layout_data.layout_tier == 0 or camp_layout_data.has_explicit_tier(_town_level())) and camp_layout_data.has_anchor(_town_level(), structure_id):
		authored_anchor = camp_layout_data.anchor_for(_town_level(), structure_id)
	var anchor: Vector2 = _world_map_point(authored_anchor)
	if camp_layout_data != null and (camp_layout_data.layout_tier == 0 or camp_layout_data.has_explicit_tier(_town_level())) and camp_layout_data.has_anchor(_town_level(), structure_id):
		return anchor
	if structure_id == "veterans_hall" or structure_id == "campfire":
		var bounds: Rect2 = _town_bounds_world()
		anchor.x = bounds.get_center().x
		if _town_level() == 0:
			anchor.y = bounds.position.y + 130.0 if structure_id == "veterans_hall" else bounds.end.y - 175.0
	return anchor

func _input(event: InputEvent) -> void:
	if screen == Screen.CAMP:
		if not _camp_hub_active():
			return
		if _gate_confirmation_open():
			_reset_movement_input()
			return
		if event is InputEventScreenTouch:
			var camp_touch: InputEventScreenTouch = event
			if camp_touch.pressed and joystick_touch_id < 0 and camp_touch.position.y > size.y * 0.20 and not _point_over_camp_action_button(camp_touch.position):
				joystick_touch_id = camp_touch.index
				joystick_origin = camp_touch.position
				joystick_position = camp_touch.position
				joystick_vector = Vector2.ZERO
			elif not camp_touch.pressed and camp_touch.index == joystick_touch_id:
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
		elif event is InputEventScreenDrag:
			var camp_drag: InputEventScreenDrag = event
			if camp_drag.index == joystick_touch_id:
				joystick_position = camp_drag.position
				joystick_vector = (camp_drag.position - joystick_origin).limit_length(46.0) / 46.0
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
	_update_camp_wanderers(delta)
	if _gate_confirmation_open():
		camp_move_vector = Vector2.ZERO
		return
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
	var gate: Vector2 = _camp_gate_position()
	camp_player_position.x = clampf(camp_player_position.x, 16.0, world_size.x - 16.0)
	camp_player_position.y = clampf(camp_player_position.y, 24.0, gate.y + 34.0)
	if camp_player_position.y >= gate.y:
		if absf(camp_player_position.x - gate.x) <= CAMP_GATE_HALF_WIDTH:
			_begin_expedition_from_gate()
			return
		camp_player_position.y = gate.y - 1.0
	_update_world_camera(camp_player_position, not camp_uses_field_camera)
	camp_interaction_target = _nearest_camp_interaction()
	_update_camp_hotspot_positions()
	if camp_interaction_target in CAMP_STRUCTURE_LAYOUT or camp_interaction_target in CAMP_PLOT_LAYOUT:
		camp_highlighted_structure = camp_interaction_target
	elif not camp_highlighted_structure.is_empty():
		camp_highlighted_structure = ""
	_update_camp_interact_button()

func _camp_position_blocked(position: Vector2) -> bool:
	var gate: Vector2 = _camp_gate_position()
	var in_gate_corridor: bool = absf(position.x - gate.x) <= CAMP_GATE_HALF_WIDTH and position.y >= gate.y - 54.0 and position.y <= gate.y + 40.0
	if _point_hits_camp_fence(position):
		return true
	if not in_gate_corridor and not Geometry2D.is_point_in_polygon(position, _camp_boundary_world()):
		return true
	for structure_id: String in camp_structure_definitions:
		if not _is_constructed(structure_id):
			continue
		var definition: StructureDefinition = camp_structure_definitions[structure_id]
		if definition.contains_ground_point_for_tier(position, 9.0, _structure_tier(structure_id)):
			return true
	if _point_hits_camp_decor(position, 9.0):
		return true
	return false

func _safe_camp_spawn_position() -> Vector2:
	var gate: Vector2 = _camp_gate_position()
	var candidates: Array[Vector2] = [
		gate + Vector2(0.0, -42.0),
		_world_map_point(Vector2(600.0, 585.0)),
		_world_map_point(Vector2(585.0, 610.0)),
		_world_map_point(Vector2(520.0, 610.0)),
		_world_map_point(Vector2(650.0, 610.0))
	]
	for candidate: Vector2 in candidates:
		if not _camp_position_blocked(candidate):
			return candidate
	return gate + Vector2(0.0, -34.0)

func _structure_tier(structure_id: String) -> int:
	if structure_id == "veterans_hall":
		return _town_level()
	if structure_id in ["armory", "blacksmith", "quartermaster", "training"]:
		return int(save.get("profile", {}).get("%s_level" % structure_id, 0))
	return 0

func _point_hits_camp_fence(position: Vector2) -> bool:
	# Tier-zero wall strips are authored as editable Polygon2D nodes in
	# CampLayout. They are transformed through the same world mapping as the
	# artwork, so moving or reshaping a strip updates collision with it.
	if camp_layout_data != null and camp_layout_data.wall_segments(0).size() > 0 and _town_level() == 0:
		for segment: Dictionary in camp_layout_data.wall_segments(0):
			var authored_polygon: PackedVector2Array = segment.get("polygon", PackedVector2Array())
			if authored_polygon.size() < 3:
				continue
			var world_polygon := PackedVector2Array()
			for point: Vector2 in authored_polygon:
				world_polygon.append(_world_map_point(point))
			if Geometry2D.is_point_in_polygon(position, world_polygon):
				return true
		return false
	var boundary: PackedVector2Array = _camp_boundary_world()
	for index: int in boundary.size():
		if index == CAMP_GATE_EDGE_INDEX:
			continue
		var next_index: int = (index + 1) % boundary.size()
		# The southern poles are tall sprites whose visual weight extends inward.
		# Their actual ground footprint is narrow, so do not block the player well
		# before the visible base as the side and rear walls intentionally do.
		var collision_radius: float = 8.0 if index == 2 or index == 4 else CAMP_FENCE_COLLISION_RADIUS
		if _distance_to_segment(position, boundary[index], boundary[next_index]) <= collision_radius:
			return true
	return false

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment: Vector2 = finish - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start)
	var progress: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * progress)

func _camp_interaction_position(target: String) -> Vector2:
	if target == "gate":
		return _camp_gate_position() + Vector2(0.0, -16.0)
	if CAMP_PLOT_LAYOUT.has(target):
		return _plot_anchor(target)
	if camp_structure_definitions.has(target):
		return (camp_structure_definitions[target] as StructureDefinition).anchor
	return _world_map_point(Vector2(CAMP_INTERACTION_POINTS.get(target, Vector2.ZERO)))

func _camp_hit_rect_world(structure_id: String) -> Rect2:
	if CAMP_PLOT_LAYOUT.has(structure_id):
		var authored_polygon: PackedVector2Array = _plot_interaction_polygon_world(structure_id)
		if authored_polygon.size() >= 3:
			var authored_bounds := Rect2(authored_polygon[0], Vector2.ZERO)
			for point: Vector2 in authored_polygon:
				authored_bounds = authored_bounds.expand(point)
			return authored_bounds
		return Rect2(_plot_anchor(structure_id) - Vector2(70.0, 48.0), Vector2(140.0, 96.0))
	if camp_structure_definitions.has(structure_id):
		var definition: StructureDefinition = camp_structure_definitions[structure_id]
		var points: PackedVector2Array = definition.world_interaction_polygon()
		if not points.is_empty():
			var bounds := Rect2(points[0], Vector2.ZERO)
			for point: Vector2 in points:
				bounds = bounds.expand(point)
			return bounds
	return _world_map_rect(Rect2(CAMP_STRUCTURE_HIT_RECTS.get(structure_id, Rect2())))

func _update_camp_hotspot_positions() -> void:
	for structure_id: String in camp_hotspot_buttons:
		var button: Button = camp_hotspot_buttons[structure_id] as Button
		if not is_instance_valid(button):
			continue
		var screen_rect: Rect2 = _camp_hit_rect_world(structure_id)
		screen_rect.position -= camera_offset
		button.position = screen_rect.position
		button.size = screen_rect.size
		button.visible = structure_id == camp_interaction_target and screen_rect.intersects(Rect2(Vector2.ZERO, size))

func _nearest_camp_interaction() -> String:
	var nearest: String = ""
	var nearest_distance: float = CAMP_INTERACTION_RADIUS
	for target: String in camp_structure_definitions:
		if not _is_constructed(target):
			continue
		var definition: StructureDefinition = camp_structure_definitions[target]
		var distance: float = camp_player_position.distance_to(definition.anchor)
		if definition.can_interact(camp_player_position) and distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	for plot_id: String in _revealed_plot_ids():
		if not _is_plot_visible(plot_id):
			continue
		var plot_distance: float = camp_player_position.distance_to(_plot_anchor(plot_id))
		var authored_polygon: PackedVector2Array = _plot_interaction_polygon_world(plot_id)
		var plot_in_range: bool = Geometry2D.is_point_in_polygon(camp_player_position, authored_polygon) if authored_polygon.size() >= 3 else plot_distance < CAMP_INTERACTION_RADIUS
		if plot_in_range and plot_distance < nearest_distance:
			nearest_distance = plot_distance
			nearest = plot_id
	var gate_distance: float = camp_player_position.distance_to(_camp_interaction_position("gate"))
	if camp_player_position.y >= _camp_gate_position().y - 34.0 and gate_distance < nearest_distance:
		nearest = "gate"
	return nearest

func _camp_interaction_text(target: String) -> String:
	if CAMP_PLOT_LAYOUT.has(target) and _is_plot_visible(target):
		return "PLAN NEW BUILDING"
	match target:
		"veterans_hall": return "ENTER VETERANS' HALL"
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
	if CAMP_PLOT_LAYOUT.has(camp_interaction_target):
		_show_construction_menu(camp_interaction_target)
		return
	match camp_interaction_target:
		"veterans_hall": _show_hall_detail()
		"armory", "quartermaster", "blacksmith", "training":
			_show_building_detail(camp_interaction_target)
		"campfire": _show_weapon_picker()

func _begin_expedition_from_gate() -> void:
	if screen != Screen.CAMP or _gate_confirmation_open():
		return
	_reset_movement_input()
	camp_player_position.y = _camp_gate_position().y - 1.0
	if _gate_confirmations_enabled():
		_show_gate_confirmation(true)
	else:
		_confirm_begin_expedition(null)

func _confirm_begin_expedition(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	if not save.active_run.is_empty():
		_resume_run()
		return
	_show_arsenal_screen(true)

func _gate_confirmation_open() -> bool:
	return is_instance_valid(ui_root) and ui_root.get_node_or_null("GateConfirmationOverlay") != null

func _gate_confirmations_enabled() -> bool:
	return bool(save.get("settings", {}).get("gate_confirmations", true))

func _show_gate_confirmation(departing: bool) -> void:
	if not is_instance_valid(ui_root) or _gate_confirmation_open():
		return
	_reset_movement_input()
	if not departing:
		run_paused = true
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "GateConfirmationOverlay"
	overlay.color = Color(0.01, 0.012, 0.014, 0.68)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	var panel := _make_authored_panel("Modal/GateConfirmation", Rect2(30.0, size.y * 0.5 - 104.0, size.x - 60.0, 208.0), "GateConfirmationPanel")
	overlay.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, column)
	var heading: String = "READY FOR BATTLE?" if departing else "FINISH THIS RUN?"
	var detail: String = "Cross into Blackthorn Moor and begin the expedition?" if departing else "Return to camp, bank your findings and end this expedition?"
	column.add_child(_make_label(heading, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label(detail, 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	var no_button: Button = _make_button("NO", 54.0, IRON.darkened(0.28))
	no_button.name = "GateNoButton"
	no_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no_button.pressed.connect(_cancel_gate_confirmation.bind(overlay, departing))
	actions.add_child(no_button)
	var yes_button: Button = _make_button("YES", 54.0, BURGUNDY)
	yes_button.name = "GateYesButton"
	yes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if departing:
		yes_button.pressed.connect(_confirm_begin_expedition.bind(overlay))
	else:
		yes_button.pressed.connect(_confirm_finish_run.bind(overlay))
	actions.add_child(yes_button)

func _cancel_gate_confirmation(overlay: Control, departing: bool) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_reset_movement_input()
	var gate: Vector2 = _camp_gate_position()
	if departing:
		camp_player_position = Vector2(gate.x, gate.y - 2.0)
	else:
		player_position = Vector2(gate.x, gate.y + 2.0)
		run_paused = false
	queue_redraw()

func _confirm_finish_run(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_reset_movement_input()
	_finish_run(false, true)

func _draw_camp_ambience() -> void:
	var animation_time: float = camp_elapsed + run_elapsed
	var ambience_density: float = clampf(float(save.settings.effect_density), 0.0, 1.0)
	var refuge_bounds: Rect2 = _town_bounds_world()
	# Only the leaf tips move, by a single native pixel. The retained trees and
	# every collision edge remain perfectly still.
	for leaf_index: int in ceili(12.0 * ambience_density):
		var leaf_hash: int = absi(tile_hash(Vector2i(leaf_index * 17, _town_level() * 31 + 9)))
		var leaf_x: float = refuge_bounds.position.x - 42.0 - float(leaf_hash % 72) if leaf_index % 2 == 0 else refuge_bounds.end.x + 34.0 + float(leaf_hash % 72)
		var leaf_y: float = refuge_bounds.position.y - 22.0 + float((leaf_hash / 7) % int(refuge_bounds.size.y + 24.0))
		var leaf_shift: float = roundf(sin(animation_time * 1.3 + float(leaf_index) * 0.71))
		draw_rect(Rect2(Vector2(leaf_x + leaf_shift, leaf_y).round(), Vector2(2.0, 2.0)), Color("66743e", 0.62))
	var fire_position: Vector2 = (camp_structure_definitions["campfire"] as StructureDefinition).anchor
	# The campfire is one complete authored sprite per frame: stones, benches,
	# and flame are never composed from separate moving pieces. This keeps the
	# base locked in place while the generated six-frame strip supplies all fire
	# motion. The legacy flame-only asset is intentionally not used here.
	if campfire_animation_texture != null:
		var campfire_frame: int = floori(animation_time * 10.0) % 6
		var campfire_frame_rect := _camp_structure_rect("campfire", camp_landmark_textures.get("campfire") as Texture2D)
		if campfire_frame_rect.size == Vector2.ZERO:
			campfire_frame_rect = Rect2(fire_position - Vector2(56.0, 96.0), Vector2(112.0, 96.0))
		draw_texture_rect_region(
			campfire_animation_texture,
			campfire_frame_rect,
			Rect2(Vector2(campfire_frame * 112.0, 0.0), Vector2(112.0, 96.0))
		)
	else:
		# Keep the scene usable if an import is temporarily unavailable, but use
		# the complete static campfire rather than overlaying a flame-only strip.
		var static_campfire: Texture2D = camp_landmark_textures.get("campfire") as Texture2D
		if static_campfire != null:
			draw_texture_rect(static_campfire, _camp_structure_rect("campfire", static_campfire), false)
	var hall_anchor: Vector2 = (camp_structure_definitions["veterans_hall"] as StructureDefinition).anchor
	for lantern_side: float in [-1.0, 1.0]:
		var lantern_position := (hall_anchor + Vector2(lantern_side * 30.0, -44.0)).round()
		var lantern_alpha: float = 0.46 + (sin(animation_time * 4.0 + lantern_side * 1.7) + 1.0) * 0.10
		draw_rect(Rect2(lantern_position - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(AMBER, lantern_alpha))
	for ember_index: int in ceili(8.0 * ambience_density):
		var ember_time: float = fmod(animation_time * (13.0 + ember_index % 3) + float(ember_index) * 9.0, 46.0)
		var ember_position := fire_position + Vector2(sin(animation_time * 2.2 + ember_index * 1.7) * (4.0 + ember_index % 4), -15.0 - ember_time)
		var ember_alpha: float = maxf(0.0, 0.80 - ember_time * 0.018)
		draw_rect(Rect2(ember_position.round(), Vector2(2.0, 2.0)), Color(AMBER.lightened(0.28), ember_alpha))
	for smoke_index: int in ceili(4.0 * ambience_density):
		var smoke_time: float = fmod(animation_time * 12.0 + float(smoke_index) * 17.0, 64.0)
		var smoke_position := (fire_position + Vector2(sin(animation_time * 1.4 + smoke_index) * 6.0, -28.0 - smoke_time)).round()
		var smoke_alpha: float = maxf(0.0, 0.16 - smoke_time * 0.0024)
		draw_rect(Rect2(smoke_position, Vector2(3.0 + floorf(smoke_time / 24.0), 3.0 + floorf(smoke_time / 28.0))), Color(0.48, 0.47, 0.43, smoke_alpha))
	if _is_constructed("blacksmith"):
		var smith_position: Vector2 = (camp_structure_definitions["blacksmith"] as StructureDefinition).anchor
		for smoke_index: int in 2:
			var smith_smoke_time: float = fmod(animation_time * 10.0 + float(smoke_index) * 31.0, 58.0)
			var smith_smoke_position := smith_position + Vector2(sin(animation_time + smoke_index) * 5.0, -smith_smoke_time)
			var smith_smoke_size: float = 3.0 + floorf(smith_smoke_time * 0.045)
			draw_rect(Rect2(smith_smoke_position.round(), Vector2(smith_smoke_size, smith_smoke_size)), Color(0.34, 0.35, 0.34, maxf(0.0, 0.16 - smith_smoke_time * 0.0025)))
	for entry: Dictionary in _visible_camp_decor():
		if String(entry.id) != "brazier":
			continue
		var brazier_flame: Vector2 = Vector2(entry.anchor) - Vector2(0.0, 35.0)
		var brazier_pulse: float = (sin(animation_time * 10.0 + brazier_flame.x * 0.02) + 1.0) * 0.5
		draw_rect(Rect2(brazier_flame.round() - Vector2(3.0, 5.0), Vector2(6.0, 7.0)), Color(AMBER, 0.26 + brazier_pulse * 0.16))
		draw_rect(Rect2(brazier_flame.round() - Vector2(1.0, 4.0), Vector2(2.0, 5.0)), Color(AMBER.lightened(0.3), 0.72))
	var gate_position := _camp_interaction_position("gate")
	var gate_alpha: float = 0.42 + (sin(animation_time * 3.0) + 1.0) * 0.10
	draw_line(gate_position + Vector2(-18.0, -7.0), gate_position, Color(AMBER, gate_alpha), 2.0)
	draw_line(gate_position, gate_position + Vector2(18.0, -7.0), Color(AMBER, gate_alpha), 2.0)
	draw_string(theme_main.default_font, gate_position + Vector2(-52.0, -18.0), "CROSS TO BEGIN", HORIZONTAL_ALIGNMENT_CENTER, 104.0, 9, Color(PARCHMENT, 0.82))


func _draw_camp_highlights() -> void:
	if camp_highlighted_structure.is_empty():
		return
	if camp_highlighted_structure in CAMP_PLOT_LAYOUT:
		if camp_construction_plot_outline == null or not _is_plot_visible(camp_highlighted_structure):
			return
		var plot_size: Vector2 = camp_construction_plot_texture.get_size()
		var plot_height: float = minf(76.0, plot_size.y)
		var plot_width: float = plot_height * plot_size.x / maxf(1.0, plot_size.y)
		draw_texture_rect(camp_construction_plot_outline, Rect2(_plot_anchor(camp_highlighted_structure) - Vector2(plot_width * 0.5, plot_height), Vector2(plot_width, plot_height)), false)
		return
	var texture: Texture2D
	var outline: Texture2D
	if camp_highlighted_structure == "campfire":
		texture = camp_landmark_textures.get("campfire") as Texture2D
		outline = camp_landmark_outline_textures.get("campfire") as Texture2D
	elif camp_highlighted_structure == "veterans_hall":
		texture = _camp_tier_texture("veterans_hall", _town_level())
		outline = _camp_tier_outline_texture("veterans_hall", _town_level())
	elif _is_constructed(camp_highlighted_structure):
		texture = _camp_tier_texture(camp_highlighted_structure, _structure_tier(camp_highlighted_structure))
		outline = _camp_tier_outline_texture(camp_highlighted_structure, _structure_tier(camp_highlighted_structure))
	if texture != null and outline != null:
		draw_texture_rect(outline, _camp_structure_rect(camp_highlighted_structure, texture), false)
func _draw_camp_life() -> void:
	for enemy: EnemyState in camp_wanderers:
		_draw_enemy(enemy, Vector2.ZERO)
	_draw_camp_player(camp_player_position)

func _draw_camp_controls() -> void:
	# Movement is a floating drag gesture. It intentionally has no visible
	# joystick so the town and expedition remain unobstructed on a phone.
	pass

func _draw_camp_player(position: Vector2) -> void:
	var moving: bool = camp_move_vector.length_squared() > 0.01
	var gait: float = sin(camp_elapsed * 8.0) if moving else sin(camp_elapsed * 2.5) * 0.18
	_draw_actor_shadow(position + Vector2(0.0, 7.0), 11.0, 0.52)
	var class_id: String = String(save.profile.get("starting_class", "warrior"))
	var direction: String = _hero_facing_direction(last_move_vector)
	var texture_key: String = "%s_%s" % [class_id, direction]
	var texture: Texture2D = hero_animation_textures.get(texture_key) as Texture2D
	if texture != null:
		var frame_size := Vector2(texture.get_width() / 6.0, texture.get_height())
		var frame: int = 2 + int(floor(camp_elapsed * 8.0)) % 4 if moving else int(floor(camp_elapsed * 2.0)) % 2
		var target := Rect2(Vector2(position.x - frame_size.x * 0.5, position.y - frame_size.y + 7.0).round(), frame_size)
		draw_texture_rect_region(texture, target, Rect2(frame * frame_size.x, 0.0, frame_size.x, frame_size.y))
	else:
		texture = foundation_hero_textures.get(texture_key) as Texture2D
		if texture != null:
			var draw_size: Vector2 = texture.get_size()
			var bob: float = roundf(gait * (2.2 if moving else 0.5))
			draw_texture_rect(texture, Rect2(Vector2(position.x - draw_size.x * 0.5, position.y - draw_size.y + 7.0 + bob).round(), draw_size), false)

func _hero_facing_direction(vector: Vector2) -> String:
	if absf(vector.x) > absf(vector.y):
		return "left" if vector.x < 0.0 else "right"
	return "up" if vector.y < 0.0 else "down"

func _process_run(delta: float) -> void:
	sfx_throttle = maxf(0.0, sfx_throttle - delta)
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
	if run_gate_entry_armed and gate_band and moving_into_gate and absf(player_position.x - gate.x) <= CAMP_GATE_HALF_WIDTH:
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

func _draw_collision_debug() -> void:
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
				draw_polyline(closed_footprint, Color(0.95, 0.25, 0.20, 0.95), 2.0)
		var interaction_shape: PackedVector2Array = structure.world_interaction_polygon()
		if interaction_shape.size() > 1:
			var closed_interaction: PackedVector2Array = interaction_shape.duplicate()
			closed_interaction.append(interaction_shape[0])
			draw_polyline(closed_interaction, Color(0.95, 0.72, 0.20, 0.78), 1.0)
	var camp_boundary: PackedVector2Array = _camp_boundary_world()
	for edge_index: int in camp_boundary.size():
		if edge_index == CAMP_GATE_EDGE_INDEX:
			continue
		draw_line(camp_boundary[edge_index], camp_boundary[(edge_index + 1) % camp_boundary.size()], Color(0.92, 0.18, 0.20, 0.92), 2.0)
	for decor_entry: Dictionary in _visible_camp_decor():
		var authored_polygon: PackedVector2Array = decor_entry.get("footprint", PackedVector2Array())
		if authored_polygon.size() >= 3:
			var authored_world := PackedVector2Array()
			for point: Vector2 in authored_polygon:
				authored_world.append(Vector2(decor_entry.get("anchor", Vector2.ZERO)) + point)
			authored_world.append(authored_world[0])
			draw_polyline(authored_world, Color(0.30, 0.75, 0.95, 0.90), 1.0)
		else:
			draw_rect(_camp_decor_footprint(decor_entry), Color(0.30, 0.75, 0.95, 0.90), false, 1.0)
	for blocker_value: Variant in generated_region.get("blockers", []):
		if blocker_value is Rect2:
			var blocker: Rect2 = blocker_value
			blocker.position += region_origin
			draw_rect(blocker, Color(0.92, 0.18, 0.20, 0.72), false, 1.0)

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
	enemy.route_waypoints.clear()
	enemy.route_target_cell = Vector2i(-9999, -9999)
	enemy.route_repath_timer = 0.0
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

func _update_enemies(delta: float) -> void:
	_update_enemy_flow_field(delta)
	for enemy: EnemyState in enemies.duplicate():
		_eject_enemy_from_town(enemy)
		enemy.touch_cooldown = maxf(0.0, enemy.touch_cooldown - delta)
		enemy.attack_cooldown -= delta
		enemy.stagger = maxf(0.0, enemy.stagger - delta)
		enemy.pin_timer = maxf(0.0, enemy.pin_timer - delta)
		enemy.path_check_timer -= delta
		var to_player: Vector2 = player_position - enemy.position
		var distance: float = to_player.length()
		var direction: Vector2 = to_player.normalized() if distance > 0.1 else Vector2.ZERO
		if enemy.path_check_timer <= 0.0:
			# Direct-path checks are deliberately staggered. Their result remains
			# stable between checks while movement and collision stay frame-based.
			# Long-distance enemies use the shared flow field instead of each doing
			# a full ray march to the player. This keeps dense waves bounded while
			# retaining exact obstacle checks in combat range.
			enemy.path_check_timer = 0.16 + float(enemy.uid % 7) * 0.018
			enemy.has_direct_path = distance <= 384.0 and _enemy_direct_path_clear(enemy.position, player_position, enemy.radius)
		if enemy.kind == "archer" and _enemy_inside_playable_bounds(enemy):
			var clear_shot: bool = enemy.has_direct_path
			if not clear_shot:
				# Archers do not fire through trees, ruins or walls. Search for a
				# nearby lateral step that opens a direct line to the player.
				_move_archer_toward_line_of_sight(enemy, direction, delta)
			elif distance > 220.0:
				_move_enemy_with_collision(enemy, direction * enemy.speed * delta)
			elif distance < 135.0:
				_move_enemy_with_collision(enemy, -direction * enemy.speed * 0.55 * delta)
			if clear_shot and distance < 235.0 and enemy.attack_cooldown <= 0.0:
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

func _eject_enemy_from_town(enemy: EnemyState) -> void:
	var exclusion: Rect2 = _enemy_town_exclusion_rect(enemy.radius)
	if exclusion.has_point(enemy.position):
		enemy.position.y = exclusion.end.y + 1.0

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
	for enemy: EnemyState in enemies:
		if not camp_wanderers.has(enemy):
			enemy_pool.append(enemy)
	enemies.clear()
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
		var preserved_position: Vector2 = enemy.position
		var preserved_id: String = enemy.id
		_configure_enemy_state(enemy, preserved_id, false, _current_dread())
		enemy.position = preserved_position
		enemy.attack_cooldown = rng.randf_range(0.6, 1.4)
		enemies.append(enemy)
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
	if enemy_flow_repath_timer > 0.0 and enemy_flow_target_cell == target_cell and not enemy_flow_distance.is_empty():
		return
	enemy_flow_repath_timer = 0.35
	enemy_flow_target_cell = target_cell
	enemy_flow_distance.clear()
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
		for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
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
	# Line of sight follows projectile blockers, not the rectangular hostile
	# no-spawn zone. The latter keeps enemies out of town but is not itself an
	# invisible wall that should block an archer's shot.
	return not _projectile_path_blocked(from_position, to_position, maxf(2.0, radius * 0.35))

func _enemy_flow_direction(enemy: EnemyState) -> Vector2:
	var current: Vector2i = _path_cell_for_position(enemy.position)
	if not enemy_flow_distance.has(current):
		return Vector2.ZERO
	var best_cell: Vector2i = current
	var best_distance: int = int(enemy_flow_distance[current])
	for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
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

func _enemy_route_direction(enemy: EnemyState, target: Vector2, delta: float) -> Vector2:
	var target_cell: Vector2i = _path_cell_for_position(target)
	enemy.route_repath_timer = maxf(0.0, enemy.route_repath_timer - delta)
	if enemy.route_repath_timer <= 0.0 or enemy.route_target_cell != target_cell or enemy.route_waypoints.is_empty():
		_build_enemy_route(enemy, target)
	if enemy.route_waypoints.is_empty():
		return Vector2.ZERO
	while not enemy.route_waypoints.is_empty() and enemy.position.distance_to(enemy.route_waypoints[0]) <= maxf(12.0, enemy.radius * 1.5):
		enemy.route_waypoints.pop_front()
	if enemy.route_waypoints.is_empty():
		return Vector2.ZERO
	return enemy.position.direction_to(enemy.route_waypoints[0])

func _path_cell_for_position(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))

func _path_cell_center(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 0.5) * 32.0)

func _path_cell_open(cell: Vector2i, radius: float) -> bool:
	var max_cell: Vector2i = Vector2i(ceili(world_size.x / 32.0) - 1, ceili(world_size.y / 32.0) - 1)
	if cell.x < 0 or cell.y < 0 or cell.x > max_cell.x or cell.y > max_cell.y:
		return false
	return not _enemy_position_blocked(_path_cell_center(cell), radius)

func _build_enemy_route(enemy: EnemyState, target: Vector2) -> void:
	enemy.route_waypoints.clear()
	enemy.route_target_cell = _path_cell_for_position(target)
	enemy.route_repath_timer = 0.35
	var start: Vector2i = _path_cell_for_position(enemy.position)
	var goal: Vector2i = enemy.route_target_cell
	if not _path_cell_open(goal, enemy.radius):
		var goal_candidates: Array[Vector2i] = []
		for radius: int in range(1, 4):
			for y: int in range(-radius, radius + 1):
				for x: int in range(-radius, radius + 1):
					goal_candidates.append(goal + Vector2i(x, y))
		var nearest_goal: Vector2i = start
		var nearest_distance: float = INF
		for candidate: Vector2i in goal_candidates:
			if _path_cell_open(candidate, enemy.radius) and _path_cell_center(candidate).distance_to(target) < nearest_distance:
				nearest_goal = candidate
				nearest_distance = _path_cell_center(candidate).distance_to(target)
		goal = nearest_goal
	if not _path_cell_open(start, enemy.radius) or not _path_cell_open(goal, enemy.radius):
		return

	var min_cell := Vector2i(maxi(0, mini(start.x, goal.x) - 10), maxi(0, mini(start.y, goal.y) - 10))
	var max_cell := Vector2i(mini(ceili(world_size.x / 32.0) - 1, maxi(start.x, goal.x) + 10), mini(ceili(world_size.y / 32.0) - 1, maxi(start.y, goal.y) + 10))
	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _path_heuristic(start, goal)}
	var found: bool = false
	var expansions: int = 0
	while not open.is_empty() and expansions < 1200:
		expansions += 1
		var best_index: int = 0
		for index: int in range(1, open.size()):
			if float(f_score.get(open[index], INF)) < float(f_score.get(open[best_index], INF)):
				best_index = index
		var current: Vector2i = open[best_index]
		open.remove_at(best_index)
		if current == goal:
			found = true
			break
		for neighbor: Vector2i in _path_neighbors(current, min_cell, max_cell, enemy.radius):
			var tentative: float = float(g_score.get(current, INF)) + current.distance_to(neighbor)
			if tentative >= float(g_score.get(neighbor, INF)):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative
			f_score[neighbor] = tentative + _path_heuristic(neighbor, goal)
			if not open.has(neighbor):
				open.append(neighbor)
	if not found:
		return
	var cells: Array[Vector2i] = []
	var cursor: Vector2i = goal
	while cursor != start:
		cells.push_front(cursor)
		if not came_from.has(cursor):
			return
		cursor = came_from[cursor]
	for cell: Vector2i in cells:
		enemy.route_waypoints.append(_path_cell_center(cell))

func _path_heuristic(from_cell: Vector2i, to_cell: Vector2i) -> float:
	return from_cell.distance_to(to_cell)

func _path_neighbors(cell: Vector2i, min_cell: Vector2i, max_cell: Vector2i, radius: float) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var candidate: Vector2i = cell + offset
		if candidate.x < min_cell.x or candidate.y < min_cell.y or candidate.x > max_cell.x or candidate.y > max_cell.y:
			continue
		if not _path_cell_open(candidate, radius):
			continue
		if offset.x != 0 and offset.y != 0 and (not _path_cell_open(cell + Vector2i(offset.x, 0), radius) or not _path_cell_open(cell + Vector2i(0, offset.y), radius)):
			continue
		result.append(candidate)
	return result

func _enemy_position_blocked(position: Vector2, radius: float) -> bool:
	# Hostile actors treat the complete safe-town footprint as solid. Player
	# collision keeps the painted gate open, but enemies never enter that lane.
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
	# The center cell plus ceil(radius / tile_size) neighbours covers every
	# rectangle that can overlap the query circle. The previous extra ring made
	# every ordinary enemy collision inspect 25 cells instead of 9.
	var search_radius: int = maxi(1, ceili(radius / 32.0))
	for cell_y: int in range(center_cell.y - search_radius, center_cell.y + search_radius + 1):
		for cell_x: int in range(center_cell.x - search_radius, center_cell.x + search_radius + 1):
			var cell := Vector2i(cell_x, cell_y)
			var temporary_state: Dictionary = environment_states.get(str(cell), {})
			if "broken" in Array(temporary_state.get("results", [])):
				continue
			if region_blocker_grid.has(cell) and Rect2(region_blocker_grid[cell]).grow(radius).has_point(local_position):
				return true
	return false

func _cache_region_blockers() -> void:
	region_blocker_grid.clear()
	enemy_flow_open_cache.clear()
	for blocker_value: Variant in generated_region.get("blockers", []):
		if blocker_value is Rect2:
			var blocker: Rect2 = blocker_value
			var cell := Vector2i(floori(blocker.get_center().x / 32.0), floori(blocker.get_center().y / 32.0))
			region_blocker_grid[cell] = blocker

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

func _load_actor_textures() -> void:
	# Foundation enemies deliberately use one readable three-quarter pose and
	# procedural gait animation, keeping every actor on the same pixel scale.
	for enemy_id: String in ["wolf", "raider", "archer", "reaver", "blighted", "crow", "houndmaster", "grave_guard", "barrow_knight"]:
		var foundation_enemy: Texture2D = load("res://assets/foundation/enemies/%s.png" % enemy_id) as Texture2D
		if foundation_enemy != null:
			actor_textures["%s_left" % enemy_id] = foundation_enemy
			actor_textures["%s_right" % enemy_id] = foundation_enemy
		var animated_enemy: Texture2D = load("res://assets/generated/reference_v2/enemies/%s.png" % enemy_id) as Texture2D
		if animated_enemy != null:
			enemy_animation_textures[enemy_id] = animated_enemy
	for class_id: String in ["warrior", "hunter", "mage", "rogue"]:
		for direction: String in ["down", "left", "right", "up"]:
			var hero_texture: Texture2D = load("res://assets/foundation/heroes_v2/%s_%s.png" % [class_id, direction]) as Texture2D
			if hero_texture != null:
				foundation_hero_textures["%s_%s" % [class_id, direction]] = hero_texture
			var animated_hero: Texture2D = load("res://assets/generated/reference_v2/heroes/%s_%s.png" % [class_id, direction]) as Texture2D
			if animated_hero != null:
				hero_animation_textures["%s_%s" % [class_id, direction]] = animated_hero

func _load_camp_layer_textures() -> void:
	var tier_counts: Dictionary = {"veterans_hall": 5, "armory": 4, "blacksmith": 4, "quartermaster": 4, "training": 6}
	for building: String in tier_counts:
		var tiers: Array[Texture2D] = []
		var outlines: Array[Texture2D] = []
		for tier: int in int(tier_counts[building]):
			var texture: Texture2D = load("res://assets/foundation/town/tiers/%s_%d.png" % [building, tier]) as Texture2D
			var outline: Texture2D = load("res://assets/foundation/town/outlines/tiers/%s_%d.png" % [building, tier]) as Texture2D
			if texture != null:
				tiers.append(texture)
			if outline != null:
				outlines.append(outline)
		camp_building_textures[building] = tiers
		camp_building_outline_textures[building] = outlines
	for landmark: String in ["campfire"]:
		var texture: Texture2D = load("res://assets/foundation/town/%s.png" % landmark) as Texture2D
		var outline: Texture2D = load("res://assets/foundation/town/outlines/%s.png" % landmark) as Texture2D
		if texture != null:
			camp_landmark_textures[landmark] = texture
		if outline != null:
			camp_landmark_outline_textures[landmark] = outline
	for decor_id: String in ["barrels", "crates", "firewood", "weapon_rack", "banner", "brazier", "handcart", "drying_rack"]:
		var decor_texture: Texture2D = load("res://assets/foundation/town/decor/%s.png" % decor_id) as Texture2D
		if decor_texture != null:
			camp_decor_textures[decor_id] = decor_texture
	camp_construction_plot_texture = load("res://assets/foundation/town/tiers/construction_plot.png") as Texture2D
	camp_construction_plot_outline = load("res://assets/foundation/town/outlines/tiers/construction_plot.png") as Texture2D

func _load_foundation_art() -> void:
	var pole: Texture2D = load("res://assets/foundation/town/palisade_simple/wall_pole.png") as Texture2D
	if pole != null:
		foundation_wall_textures["wall_pole"] = pole
	var gate: Texture2D = load("res://assets/foundation/town/town_gate.png") as Texture2D
	if gate != null:
		foundation_wall_textures["town_gate"] = gate
	_build_structure_definitions()


func _load_reference_modular_art() -> void:
	# Every Refuge visual is a separate runtime asset. The image-generation
	# master remains a style reference in the source folder and is never drawn.
	var terrain: Texture2D = load("res://assets/generated/reference_v3/terrain/blackthorn_tiles_modular.png") as Texture2D
	if terrain != null:
		foundation_terrain_atlas = terrain

	forest_cluster_textures.clear()
	forest_detail_textures.clear()
	for forest_id: String in ["tree_0", "tree_1", "tree_2"]:
		var forest_texture: Texture2D = load("res://assets/generated/reference_v3/forest/%s.png" % forest_id) as Texture2D
		if forest_texture != null:
			forest_cluster_textures.append(forest_texture)
	for detail_id: String in ["shrub", "stump", "rocks"]:
		var detail_texture: Texture2D = load("res://assets/generated/reference_v3/forest/%s.png" % detail_id) as Texture2D
		if detail_texture != null:
			forest_detail_textures.append(detail_texture)

	var pole: Texture2D = load("res://assets/generated/reference_v3/town/wall_pole.png") as Texture2D
	var gate: Texture2D = load("res://assets/generated/reference_v3/town/town_gate.png") as Texture2D
	if pole != null:
		foundation_wall_textures["wall_pole"] = pole
	if gate != null:
		foundation_wall_textures["town_gate"] = gate

	var hall: Texture2D = load("res://assets/generated/reference_v3/town/veterans_hall_0.png") as Texture2D
	var hall_outline: Texture2D = load("res://assets/generated/reference_v3/town/outlines/veterans_hall_0.png") as Texture2D
	var hall_tiers: Array = camp_building_textures.get("veterans_hall", [])
	var hall_outlines: Array = camp_building_outline_textures.get("veterans_hall", [])
	if hall != null:
		for tier_index: int in mini(2, hall_tiers.size()):
			hall_tiers[tier_index] = hall
		camp_building_textures["veterans_hall"] = hall_tiers
	if hall_outline != null:
		for tier_index: int in mini(2, hall_outlines.size()):
			hall_outlines[tier_index] = hall_outline
		camp_building_outline_textures["veterans_hall"] = hall_outlines

	var modular_campfire: Texture2D = load("res://assets/generated/reference_v3/town/campfire.png") as Texture2D
	var modular_campfire_outline: Texture2D = load("res://assets/generated/reference_v3/town/outlines/campfire.png") as Texture2D
	campfire_animation_texture = load("res://assets/generated/reference_v3/town/campfire_animation.png") as Texture2D
	if modular_campfire != null:
		camp_landmark_textures["campfire"] = modular_campfire
	if modular_campfire_outline != null:
		camp_landmark_outline_textures["campfire"] = modular_campfire_outline

	for decor_id: String in ["barrels", "crates", "weapon_rack", "banner", "firewood", "drying_rack"]:
		var decor_texture: Texture2D = load("res://assets/generated/reference_v3/town/decor/%s.png" % decor_id) as Texture2D
		if decor_texture != null:
			camp_decor_textures[decor_id] = decor_texture

	var plot: Texture2D = load("res://assets/generated/reference_v3/town/construction_plot.png") as Texture2D
	var plot_outline: Texture2D = load("res://assets/generated/reference_v3/town/outlines/construction_plot.png") as Texture2D
	if plot != null:
		camp_construction_plot_texture = plot
	if plot_outline != null:
		camp_construction_plot_outline = plot_outline

	# Structure definitions retain the existing footprints and interactions but
	# now point at the new independent sprites.
	_build_structure_definitions()

func _build_structure_definitions() -> void:
	camp_structure_definitions.clear()
	var footprints: Dictionary = {
		"veterans_hall": PackedVector2Array([Vector2(-42, -22), Vector2(42, -22), Vector2(42, 0), Vector2(-42, 0)]),
		"armory": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
		"quartermaster": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
		"blacksmith": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
		"training": PackedVector2Array([Vector2(-52, -70), Vector2(52, -70), Vector2(52, 0), Vector2(-52, 0)]),
		"campfire": PackedVector2Array([Vector2(-28, -18), Vector2(-18, -28), Vector2(18, -28), Vector2(28, -18), Vector2(28, 18), Vector2(18, 28), Vector2(-18, 28), Vector2(-28, 18)])
	}
	for structure_id: String in CAMP_STRUCTURE_LAYOUT:
		var definition: StructureDefinition = StructureDefinitionResource.new()
		definition.id = structure_id
		definition.display_name = structure_id.replace("_", " ").capitalize()
		definition.menu_id = structure_id
		definition.anchor = _centered_camp_anchor(structure_id)
		definition.draw_height = float(CAMP_STRUCTURE_LAYOUT[structure_id].height)
		definition.footprint = footprints[structure_id]
		definition.interaction_radius = 78.0 if structure_id == "campfire" else 72.0
		definition.interaction_polygon = PackedVector2Array([Vector2(-70, -45), Vector2(70, -45), Vector2(70, 44), Vector2(-70, 44)])
		var authored_footprint := PackedVector2Array()
		var authored_interaction := PackedVector2Array()
		# Refuge placement and collision authoring live in the same scene opened
		# in the Godot 2D editor. Higher Hall tiers retain their existing
		# footprint progression until their matching layout tier is authored.
		if camp_layout_data != null and camp_layout_data.has_anchor(0, structure_id):
			authored_footprint = camp_layout_data.structure_polygon(0, structure_id, "Footprint")
			authored_interaction = camp_layout_data.structure_polygon(0, structure_id, "Interaction")
		if structure_id == "veterans_hall":
			definition.tier_textures.assign(camp_building_textures.get("veterans_hall", []))
			definition.tier_outlines.assign(camp_building_outline_textures.get("veterans_hall", []))
			definition.tier_footprints = [
				PackedVector2Array([Vector2(-42, -22), Vector2(42, -22), Vector2(42, 0), Vector2(-42, 0)]),
				PackedVector2Array([Vector2(-48, -25), Vector2(48, -25), Vector2(48, 0), Vector2(-48, 0)]),
				PackedVector2Array([Vector2(-54, -28), Vector2(54, -28), Vector2(54, 0), Vector2(-54, 0)]),
				PackedVector2Array([Vector2(-60, -31), Vector2(60, -31), Vector2(60, 0), Vector2(-60, 0)]),
				PackedVector2Array([Vector2(-68, -34), Vector2(68, -34), Vector2(68, 0), Vector2(-68, 0)])
			]
		elif structure_id == "campfire":
			definition.tier_textures = [camp_landmark_textures.get("campfire")]
			definition.tier_outlines = [camp_landmark_outline_textures.get("campfire")]
		else:
			definition.tier_textures.assign(camp_building_textures.get(structure_id, []))
			definition.tier_outlines.assign(camp_building_outline_textures.get(structure_id, []))
		# Apply authored shapes after tier defaults. The old Hall tier array used
		# to overwrite a changed tier-zero Footprint, making editor edits appear
		# ineffective.
		if authored_footprint.size() >= 3:
			if definition.tier_footprints.is_empty():
				definition.footprint = authored_footprint
			else:
				var authored_tier_footprints: Array[PackedVector2Array] = definition.tier_footprints.duplicate()
				authored_tier_footprints[0] = authored_footprint
				definition.tier_footprints = authored_tier_footprints
		if authored_interaction.size() >= 3:
			definition.interaction_polygon = authored_interaction
		camp_structure_definitions[structure_id] = definition

func _active_hero() -> Dictionary:
	return Roster.active_hero(save.profile)

func _sync_active_hero_fields() -> void:
	var hero: Dictionary = _active_hero()
	if hero.is_empty():
		return
	save.profile.starting_class = String(hero.get("class_id", "warrior"))
	save.profile.equipped = hero.get("equipped", {}).duplicate(true)

func _sync_active_hero_equipment() -> void:
	var hero: Dictionary = _active_hero()
	if not hero.is_empty():
		hero.equipped = save.profile.get("equipped", {}).duplicate(true)

func _technique_total(stat: String) -> float:
	var total: float = 0.0
	for technique_id: String in techniques:
		if not runtime_techniques.has(technique_id):
			continue
		var definition: Dictionary = runtime_techniques[technique_id]
		var rank: int = clampi(int(techniques[technique_id]), 1, 5)
		var rank_stats: Array = definition.get("rank_stats", [])
		if not rank_stats.is_empty():
			# Canonical technique rank data belongs to that technique's cast. It is
			# consumed by _training_technique_progress() and must never leak into
			# every weapon or into the player's global projectile count.
			continue
		var stats: Dictionary = definition.get("stats", {})
		total += float(stats.get(stat, 0.0)) * rank
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
	var doctrine_ids: Array[String] = active_doctrines.duplicate()
	if doctrine_ids.is_empty() and not active_doctrine.is_empty():
		doctrine_ids.append(active_doctrine)
	var total: float = 0.0
	for doctrine_id: String in doctrine_ids:
		if TrainingContent.doctrines().has(doctrine_id):
			total += float(TrainingContent.doctrines()[doctrine_id].get("modifiers", {}).get(stat, 0.0))
		else:
			var doctrine: Dictionary = GameContent.DOCTRINES.get(doctrine_id, {})
			total += float(doctrine.get("stats", {}).get(stat, 0.0))
	return total

func _class_total(stat: String) -> float:
	var class_definition: Dictionary = GameContent.CLASSES.get(active_class, GameContent.CLASSES.warrior)
	var total: float = float(class_definition.get("stats", {}).get(stat, 0.0))
	var hero: Dictionary = _active_hero()
	var learned: Dictionary = hero.get("class_tree", {})
	for node_value: Variant in GameContent.CLASS_TREES.get(active_class, []):
		var node: Dictionary = node_value
		if bool(learned.get(String(node.id), false)):
			total += float(node.get("stats", {}).get(stat, 0.0))
	return total

func _relic_total(stat: String) -> float:
	var total: float = 0.0
	for relic_id: String in relics:
		var relic: Dictionary = GameContent.RELICS.get(relic_id, {})
		var stats: Dictionary = relic.get("stats", {})
		total += float(stats.get(stat, 0.0)) * int(relics[relic_id])
	return total

func _run_boon_total(stat: String) -> float:
	var total: float = 0.0
	for boon_id: String in run_boons:
		var rank: int = int(run_boons[boon_id])
		var per_rank: Dictionary = {"damage": 0.06, "attack_speed": 0.06, "health": 12.0, "armor": 5.0, "speed": 0.05, "area": 0.06, "duration": 0.06, "critical": 0.03, "critical_damage": 0.08, "projectile_speed": 0.08, "pickup": 12.0, "healing": 0.06}
		if boon_id == stat:
			total += float(per_rank.get(boon_id, 0.0)) * float(rank)
	return total

func _training_total(stat: String) -> float:
	return float(cached_training_modifiers.get(stat, 0.0))

func _refresh_training_modifier_cache() -> void:
	var training_service := TrainingGroundsService.new(save.profile)
	cached_training_modifiers = training_service.permanent_modifiers()

func _heal_player(amount: float, apply_modifiers: bool = true) -> void:
	if amount <= 0.0:
		return
	var multiplier: float = 1.0
	if apply_modifiers:
		multiplier += _training_total("healing") + _equipment_total("healing") + _run_boon_total("healing") + _doctrine_total("healing")
	player_hp = minf(player_max_hp, player_hp + amount * maxf(0.0, multiplier))

func _training_node_modifier(node_id: String, stat: String) -> float:
	if int(Dictionary(save.profile.get("training_nodes", {})).get(node_id, 0)) <= 0:
		return 0.0
	return float(Dictionary(TrainingContent.all_nodes().get(node_id, {}).get("stat_modifiers", {})).get(stat, 0.0))

func _curse_definition() -> Dictionary:
	return GameContent.CURSES.get(active_curse, GameContent.CURSES.none)

func _recalculate_player_stats() -> void:
	_refresh_training_modifier_cache()
	var training: int = int(save.profile.training_level)
	var training_fraction: float = float(training) / 5.0
	var doctrine_health: float = _doctrine_total("health")
	player_max_hp = 100.0 * (1.0 + training_fraction * 0.15 + doctrine_health + _training_total("health_multiplier")) + _technique_total("health") + _equipment_total("health") + _class_total("health") + _relic_total("health") + _run_boon_total("health") + _training_total("health")
	player_hp = minf(player_hp, player_max_hp)
	player_speed = 122.0 * (1.0 + training_fraction * 0.08 + _technique_total("speed") + _equipment_total("speed") + _class_total("speed") + _doctrine_total("speed") + _run_boon_total("speed") + _training_total("speed"))
	damage_multiplier = (1.0 + training_fraction * 0.15) * (1.0 + _technique_total("damage") + _equipment_total("damage") + _class_total("damage") + _run_boon_total("damage") + _training_total("damage"))
	cooldown_reduction = _technique_total("attack_speed") + _equipment_total("attack_speed") + _relic_total("attack_speed") + _run_boon_total("attack_speed") + _training_total("attack_speed")
	player_armor = _technique_total("armor") + _equipment_total("armor") + _run_boon_total("armor") + _doctrine_total("armor") + _training_total("armor")
	critical_chance = CombatStats.critical_chance(_technique_total("critical") + _equipment_total("critical") + _run_boon_total("critical") + _training_total("critical"))
	pickup_radius = 54.0 + _technique_total("pickup") + _equipment_total("pickup") + _run_boon_total("pickup")
	stagger_power = _technique_total("stagger") + _equipment_total("stagger")
	projectile_bonus = clampi(int(_technique_total("ranged_projectiles") + _relic_total("ranged_projectiles")), 0, 4)

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
	var panel := _make_authored_panel("Run/LevelUpPanel", Rect2(22.0, 120.0, size.x - 44.0, size.y - 210.0), "UpgradePanel")
	overlay.add_child(panel)
	_bind_authored_upgrade_panel(panel, overlay)
	return
	var content := panel.get_node("ContentRoot") as Control
	(content.get_node("UpgradeTitle") as Label).text = "CHOOSE YOUR TRAINING"
	(content.get_node("UpgradeLevel") as Label).text = "LEVEL %d" % run_level
	var choices: Array[Dictionary] = _build_upgrade_choices()
	for choice_index: int in range(4):
		var button := content.get_node("Choice%d" % (choice_index + 1)) as Button
		button.visible = choice_index < choices.size()
		if not button.visible:
			continue
		var choice: Dictionary = choices[choice_index]
		button.text = ""
		(button.get_node("CardDescription") as Label).text = "%s\n%s" % [choice.name, choice.description]
		(button.get_node("CardStats") as Label).text = _upgrade_summary(choice)
		button.pressed.connect(_apply_upgrade.bind(choice, overlay))

func _bind_authored_upgrade_panel(panel: PanelContainer, overlay: Control) -> void:
	var content := panel.get_node("ContentRoot") as Control
	(content.get_node("UpgradeTitle") as Label).text = "CHOOSE YOUR TRAINING"
	(content.get_node("UpgradeLevel") as Label).text = "LEVEL %d" % run_level
	var reroll_button := content.get_node_or_null("RerollButton") as Button
	if reroll_button != null:
		reroll_button.text = "REROLL  ·  %d REMAINING" % run_rerolls
		reroll_button.disabled = run_rerolls <= 0
		reroll_button.pressed.connect(_reroll_upgrade_choices.bind(overlay))
	var choices: Array[Dictionary] = _build_upgrade_choices()
	for choice_index: int in range(4):
		var button := content.get_node("Choice%d" % (choice_index + 1)) as Button
		button.visible = choice_index < choices.size()
		if not button.visible:
			continue
		var choice: Dictionary = choices[choice_index]
		button.text = ""
		(button.get_node("CardDescription") as Label).text = "%s\n%s" % [choice.name, choice.description]
		(button.get_node("CardStats") as Label).text = _upgrade_summary(choice)
		button.pressed.connect(_apply_upgrade.bind(choice, overlay))

func _reroll_upgrade_choices(overlay: Control) -> void:
	if run_rerolls <= 0 or not choosing_upgrade:
		return
	# Reject the complete visible set so the next deterministic offer applies
	# the reduced-weight memory rule to every card, not just the card under the
	# cursor. The service also advances the deterministic offer index.
	var current_choices: Array[Dictionary] = _build_upgrade_choices()
	for choice: Dictionary in current_choices:
		var choice_id: String = String(choice.get("canonical_id", choice.get("id", "")))
		if not choice_id.is_empty() and choice_id not in recently_rejected_choices:
			recently_rejected_choices.append(choice_id)
		if not choice_id.is_empty():
			rejected_choice_levels[choice_id] = run_level
	run_rerolls -= 1
	var run_state: Dictionary = _training_offer_run_state()
	var reroll_result: Dictionary = UpgradeOfferService.reroll(run_state, save.profile, prepared_arsenal, current_choices, upgrade_offer_index)
	upgrade_offer_index = int(reroll_result.get("offer_index", upgrade_offer_index + 1))
	if is_instance_valid(overlay):
		overlay.queue_free()
	# Recreate the same authored panel with the new offer. This keeps the
	# scene-owned layout authoritative and avoids stale card signal bindings.
	call_deferred("_show_upgrade_choices")

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
	var weapon: Dictionary = runtime_weapons[weapon_id]
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
	return GameContent.stats_text(GameContent.CLASSES.get(class_id, {}).get("stats", {}))

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

func _build_prepared_upgrade_choices() -> Array[Dictionary]:
	_prune_rejected_choice_memory()
	var run_state: Dictionary = _training_offer_run_state()
	var generated: Array[Dictionary] = UpgradeOfferService.generate(run_state, save.profile, prepared_arsenal, upgrade_offer_index)
	var result: Array[Dictionary] = []
	var seen_runtime_ids: Dictionary = {}
	var training_service := TrainingGroundsService.new(save.profile)
	for offer: Dictionary in generated:
		var offer_type: String = String(offer.get("type", "boon"))
		var canonical_id: String = String(offer.get("id", ""))
		var choice: Dictionary = offer.duplicate(true)
		if offer_type == "weapon":
			var runtime_id: String = _legacy_runtime_weapon_id(canonical_id)
			if seen_runtime_ids.has(runtime_id) or not runtime_weapons.has(runtime_id):
				continue
			seen_runtime_ids[runtime_id] = true
			var runtime_rank: int = int(weapons.get(runtime_id, 0))
			var weapon: Dictionary = runtime_weapons[runtime_id]
			if int(offer.get("rank", runtime_rank + 1)) >= 5:
				var school: String = TrainingContent.school_for_ability(canonical_id)
				if not training_service.mastery_unlocked(school):
					continue
				choice.type = "mastery"
				choice.name = String(weapon.get("mastery", "%s mastery" % weapon.name)).to_upper()
				choice.description = "School mastery transforms this weapon at rank five."
				choice.summary = _ability_rank_delta_text(canonical_id, 5)
			else:
				choice.id = runtime_id
				choice.canonical_id = canonical_id
				choice.name = "%s  %d > %d" % [String(weapon.name), runtime_rank, runtime_rank + 1]
				choice.description = String(TrainingContent.abilities().get(canonical_id, {}).get("ranks", [{}])[mini(runtime_rank, 4)].get("description", weapon.description))
				choice.summary = _ability_rank_delta_text(canonical_id, runtime_rank + 1)
		elif offer_type == "technique":
			var runtime_technique: String = _legacy_runtime_technique_id(canonical_id)
			if seen_runtime_ids.has(runtime_technique) or not runtime_techniques.has(runtime_technique):
				continue
			seen_runtime_ids[runtime_technique] = true
			var current_rank: int = int(techniques.get(runtime_technique, 0))
			choice.id = runtime_technique
			choice.canonical_id = canonical_id
			var canonical_definition: Dictionary = TrainingContent.abilities().get(canonical_id, {})
			if int(offer.get("rank", current_rank + 1)) >= 5:
				choice.type = "mastery"
				choice.mastery_kind = "technique"
				choice.name = "%s MASTERY" % String(canonical_definition.get("name", runtime_technique)).to_upper()
				choice.description = "School mastery transforms this technique at rank five."
				choice.summary = _ability_rank_delta_text(canonical_id, 5)
			else:
				choice.name = "%s  %d > %d" % [String(canonical_definition.get("name", runtime_technique)).to_upper(), current_rank, current_rank + 1]
				choice.description = String(canonical_definition.get("ranks", [{}])[mini(current_rank, 4)].get("description", runtime_techniques[runtime_technique].description))
				choice.summary = _ability_rank_delta_text(canonical_id, current_rank + 1)
		elif offer_type == "boon":
			choice.id = canonical_id
			choice.name = "BOON  ·  %s  %d > %d" % [canonical_id.replace("_", " ").to_upper(), int(run_boons.get(canonical_id, 0)), int(offer.get("rank", 1))]
			choice.description = "A temporary expedition bonus. Does not consume an Arsenal slot."
			choice.summary = _run_boon_summary(canonical_id)
		if not result.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(choice.get("id", "")) and String(existing.get("type", "")) == String(choice.get("type", ""))):
			result.append(choice)
	if result.size() < 3:
		for boon_id: String in ["damage", "attack_speed", "health", "armor", "speed", "area", "duration", "critical", "critical_damage", "projectile_speed", "pickup", "healing"]:
			if int(run_boons.get(boon_id, 0)) >= 5:
				continue
			var boon_choice: Dictionary = {"type": "boon", "id": boon_id, "rank": int(run_boons.get(boon_id, 0)) + 1, "name": "BOON  ·  %s" % boon_id.replace("_", " ").to_upper(), "description": "A temporary expedition bonus. Does not consume an Arsenal slot.", "summary": _run_boon_summary(boon_id)}
			if not result.any(func(existing: Dictionary) -> bool: return String(existing.id) == boon_id):
				result.append(boon_choice)
			if result.size() >= 3:
				break
	return result.slice(0, 3)

func _training_offer_run_state() -> Dictionary:
	var canonical_weapon_ranks: Dictionary = {}
	for canonical_id_value: Variant in prepared_arsenal.get("weapon_ids", []):
		var canonical_id: String = String(canonical_id_value)
		canonical_weapon_ranks[canonical_id] = int(weapons.get(_legacy_runtime_weapon_id(canonical_id), 0))
	var canonical_technique_ranks: Dictionary = {}
	for canonical_id_value: Variant in prepared_arsenal.get("technique_ids", []):
		var canonical_id: String = String(canonical_id_value)
		canonical_technique_ranks[canonical_id] = int(techniques.get(_legacy_runtime_technique_id(canonical_id), 0))
	return {
		"seed": run_seed,
		"level": run_level,
		"weapon_ranks": canonical_weapon_ranks,
		"technique_ranks": canonical_technique_ranks,
		"boon_ranks": run_boons,
		"recent_rejected_choices": recently_rejected_choices
	}

func _prune_rejected_choice_memory() -> void:
	for choice_id_value: Variant in rejected_choice_levels.keys().duplicate():
		var choice_id: String = String(choice_id_value)
		if run_level - int(rejected_choice_levels.get(choice_id, run_level)) > 2:
			rejected_choice_levels.erase(choice_id)
	recently_rejected_choices.assign(rejected_choice_levels.keys())

func _ability_rank_delta_text(ability_id: String, rank: int) -> String:
	var compiled: Dictionary = TrainingContent.compile_ability(ability_id, rank)
	var rank_stats: Dictionary = Dictionary(compiled.get("rank_stats", {}))
	if rank_stats.is_empty():
		return "RANK %d" % rank
	var cumulative_progress: Dictionary = _ability_progress(ability_id, rank)
	var cumulative_stats: Dictionary = Dictionary(cumulative_progress.get("stats", {}))
	var lines: Array[String] = ["RANK %d" % rank]
	var damage_multiplier: float = float(rank_stats.get("damage_multiplier", 1.0))
	if not is_equal_approx(damage_multiplier, 1.0):
		lines.append("DAMAGE  %+d%%" % roundi((damage_multiplier - 1.0) * 100.0))
	var interval: float = float(rank_stats.get("cooldown_or_interval", 0.0))
	if interval > 0.0:
		lines.append(("COOLDOWN  %.2fs" if String(compiled.get("category", "")) == "technique" else "ATTACK INTERVAL  %.2fs") % interval)
	var area_multiplier: float = float(rank_stats.get("area_multiplier", 1.0))
	if not is_equal_approx(area_multiplier, 1.0):
		lines.append("AREA  %+d%%" % roundi((area_multiplier - 1.0) * 100.0))
	var duration_multiplier: float = float(rank_stats.get("duration_multiplier", 1.0))
	if not is_equal_approx(duration_multiplier, 1.0):
		lines.append("DURATION  %+d%%" % roundi((duration_multiplier - 1.0) * 100.0))
	var projectile_count_value: int = int(cumulative_progress.get("projectile_count", rank_stats.get("projectile_count", 0)))
	var split_interval: int = int(cumulative_stats.get("split_interval", 0))
	var repeat_interval: int = int(cumulative_stats.get("repeat_interval", 0))
	var fork_interval: int = int(cumulative_stats.get("fork_interval", 0))
	var volley_interval: int = int(cumulative_stats.get("volley_interval", 0))
	var has_projectile_pattern: bool = split_interval > 0 or repeat_interval > 0 or fork_interval > 0 or volley_interval > 0
	if has_projectile_pattern:
		lines.append("NORMAL SHOT  1 PROJECTILE")
		if split_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [split_interval, projectile_count_value])
		if repeat_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [repeat_interval, projectile_count_value])
		if fork_interval > 0:
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [fork_interval, projectile_count_value])
		if volley_interval > 0:
			var volley_count: int = int(cumulative_stats.get("volley_projectile_count", maxi(5, projectile_count_value)))
			lines.append("EVERY %d ATTACKS  %d PROJECTILES" % [volley_interval, volley_count])
	elif projectile_count_value > 0:
		lines.append("PROJECTILES  %d" % projectile_count_value)
	var pierce_value: int = int(rank_stats.get("pierce", 0))
	if pierce_value > 0:
		lines.append("PIERCE  +%d" % pierce_value)
	for stat: String in Dictionary(rank_stats.get("stat_changes", {})):
		if stat in ["split_interval", "repeat_interval", "fork_interval", "volley_interval", "volley_projectile_count"]:
			continue
		var value: Variant = Dictionary(rank_stats.stat_changes)[stat]
		lines.append("%s  %s" % [stat.replace("_", " ").to_upper(), str(value)])
	return "  ·  ".join(lines)

func _legacy_runtime_technique_id(canonical_id: String) -> String:
	# Canonical Training Grounds IDs are also the runtime IDs. Keeping this
	# function as a compatibility shim lets old snapshots still be read without
	# collapsing new weapons or techniques into the retired v2 definitions.
	return {
		"riposte_drill": "ground_slam", "deep_quiver": "rain_of_arrows", "marked_prey": "hunters_mark",
		"long_stride": "windstep", "second_wind": "smoke_veil", "scavengers_reach": "poison_flask",
		"ember_lore": "fire_nova", "field_dressing": "frost_ring", "twin_cast": "chain_lightning"
	}.get(canonical_id, canonical_id)

func _run_boon_summary(boon_id: String) -> String:
	match boon_id:
		"damage": return "ALL DAMAGE  +6%"
		"attack_speed": return "ATTACK SPEED  +6%"
		"health": return "MAX HEALTH  +12"
		"armor": return "ARMOR  +5"
		"speed": return "MOVEMENT  +5%"
		"area": return "ABILITY AREA  +6%"
		"duration": return "ABILITY DURATION  +6%"
		"critical": return "CRITICAL CHANCE  +3%"
		"critical_damage": return "CRITICAL DAMAGE  +8%"
		"projectile_speed": return "PROJECTILE SPEED  +8%"
		"pickup": return "PICKUP REACH  +12"
		"healing": return "HEALING  +6%"
	return "TEMPORARY FIELD BONUS"

func _build_upgrade_choices() -> Array[Dictionary]:
	if not prepared_arsenal.is_empty():
		var prepared_choices: Array[Dictionary] = _build_prepared_upgrade_choices()
		if not prepared_choices.is_empty():
			return prepared_choices
		# A prepared Arsenal is authoritative. If every prepared ability and boon
		# is already at its cap, do not fall back to the retired v2 pools; offer a
		# harmless recovery choice instead of leaking Woodsman's Axe, Caltrops,
		# Witchfire, or legacy generic techniques into a v3 expedition.
		return [{"type": "heal", "id": "rations", "name": "FIELD RATIONS", "description": "Restore 30 health immediately.", "summary": "+30 CURRENT HEALTH"}]
	var candidates: Array[Dictionary] = []
	for weapon_id: String in weapons:
		var rank: int = int(weapons[weapon_id])
		if GameRules.mastery_available(weapon_id, rank, techniques, save.profile.get("skill_tree", {})) and not bool(mastered.get(weapon_id, false)):
			var weapon: Dictionary = runtime_weapons[weapon_id]
			candidates.append({"type": "mastery", "id": weapon_id, "name": String(weapon.mastery).to_upper(), "description": "Complete this weapon's proven final form.", "summary": GameContent.stats_text(weapon.mastery_stats)})
		elif rank < 5:
			var weapon: Dictionary = runtime_weapons[weapon_id]
			var rank_stats: Dictionary = weapon.rank_bonuses[rank - 1]
			candidates.append({"type": "weapon", "id": weapon_id, "name": "%s  %d > %d" % [weapon.name, rank, rank + 1], "description": weapon.description, "summary": GameContent.stats_text(rank_stats)})
	if weapons.size() < 4:
		for weapon_id: String in GameContent.unlocked_weapons(int(save.profile.armory_level), save.profile.get("skill_tree", {})):
			if not weapons.has(weapon_id):
				var weapon: Dictionary = runtime_weapons[weapon_id]
				candidates.append({"type": "weapon", "id": weapon_id, "name": "TAKE %s" % String(weapon.name).to_upper(), "description": weapon.description, "summary": _weapon_stats_text(weapon_id)})
	for technique_id: String in techniques:
		var rank: int = int(techniques[technique_id])
		if rank < 3:
			var technique: Dictionary = runtime_techniques[technique_id]
			candidates.append({"type": "technique", "id": technique_id, "name": "%s  %d > %d" % [technique.name, rank, rank + 1], "description": technique.description, "stats": technique.stats, "summary": GameContent.stats_text(technique.stats)})
	if techniques.size() < 4:
		for technique_id: String in GameContent.unlocked_techniques(save.profile.get("skill_tree", {})):
			if not techniques.has(technique_id):
				var technique: Dictionary = runtime_techniques[technique_id]
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
			var mastery_kind: String = String(choice.get("mastery_kind", "weapon"))
			var runtime_id: String = String(choice.id)
			var canonical_id: String = String(choice.get("canonical_id", runtime_id))
			# A mastery card is the rank-five acquisition, not only a cosmetic
			# flag. Persist the rank in the run build so the rank-five data and
			# transformation are immediately active and survive snapshots.
			if mastery_kind == "technique":
				techniques[runtime_id] = maxi(5, int(techniques.get(runtime_id, 0)))
				mastered[canonical_id] = true
			else:
				weapons[runtime_id] = maxi(5, int(weapons.get(runtime_id, 0)))
				mastered[canonical_id] = true
		"boon":
			var boon_id: String = String(choice.id)
			run_boons[boon_id] = int(run_boons.get(boon_id, 0)) + 1
		"heal":
			_heal_player(30.0)
	upgrade_offer_index += 1
	_prune_rejected_choice_memory()
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
	var continuous_departure: bool = camp_uses_field_camera
	_clear_run_state()
	run_camera_transition = 1.0 if continuous_departure else (0.0 if from_gate else 1.0)
	run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	rng.seed = run_seed
	save.profile.region_seed = run_seed
	generated_region = RegionGeneratorService.generate_blackthorn(run_seed)
	_cache_region_blockers()
	var hero: Dictionary = _active_hero()
	active_class = String(hero.get("class_id", save.profile.get("starting_class", "warrior")))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrines.clear()
	active_doctrine = ""
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
	var class_weapon: String = TrainingContent.starter_weapon_for_class(active_class)
	var chosen_weapon: String = starting_weapon if not starting_weapon.is_empty() else class_weapon
	if not TrainingContent.abilities().has(chosen_weapon):
		chosen_weapon = TrainingContent.starter_weapon_for_class(active_class)
	prepared_arsenal = _selected_arsenal()
	if prepared_arsenal.is_empty():
		prepared_arsenal = ArsenalService.default_arsenal(save.profile)
	if String(prepared_arsenal.get("starting_weapon", "")) != chosen_weapon:
		prepared_arsenal.starting_weapon = chosen_weapon
		var prepared_weapons: Array = Array(prepared_arsenal.get("weapon_ids", []))
		if chosen_weapon not in prepared_weapons:
			prepared_weapons.push_front(chosen_weapon)
		prepared_arsenal.weapon_ids = prepared_weapons.slice(0, ArsenalService.MAX_WEAPONS)
	for doctrine_value: Variant in Array(prepared_arsenal.get("doctrine_ids", [])):
		var doctrine_id: String = String(doctrine_value)
		if (GameContent.DOCTRINES.has(doctrine_id) or TrainingContent.doctrines().has(doctrine_id)) and doctrine_id not in active_doctrines:
			active_doctrines.append(doctrine_id)
	active_doctrine = active_doctrines[0] if not active_doctrines.is_empty() else String(save.profile.get("starting_doctrine", ""))
	if not GameContent.DOCTRINES.has(active_doctrine) and not TrainingContent.doctrines().has(active_doctrine):
		active_doctrine = ""
	run_rerolls = 1 if int(Dictionary(save.profile.get("training_nodes", {})).get("tactical_rethink", 0)) > 0 else 0
	upgrade_offer_index = 0
	recently_rejected_choices.clear()
	rejected_choice_levels.clear()
	var runtime_weapon: String = _legacy_runtime_weapon_id(chosen_weapon)
	if not runtime_weapons.has(runtime_weapon):
		runtime_weapon = class_weapon
	weapons[runtime_weapon] = 1
	weapon_timers[runtime_weapon] = 0.2
	_generate_exploration_points()
	_recalculate_player_stats()
	player_hp = player_max_hp
	var gate: Vector2 = _camp_gate_position()
	player_position = departure_position if from_gate else gate + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
	player_position.y = maxf(player_position.y, gate.y + (1.0 if from_gate else 14.0))
	# A run that starts at the painted gate may be reversed immediately. The
	# narrow crossing band below still prevents any position elsewhere in camp
	# from being mistaken for extraction.
	run_gate_entry_armed = from_gate or player_position.y > gate.y + 26.0
	_activate_camp_wanderers_for_run()
	camp_uses_field_camera = false
	save.active_run = {}
	SaveService.save_data(save)
	screen = Screen.RUN
	_play_music("moor")
	_build_run_ui()
	queue_redraw()

func _show_weapon_picker(category_index: int = -1) -> void:
	_show_arsenal_screen(false)
	return

func _show_arsenal_screen(from_gate: bool = false) -> void:
	if not is_instance_valid(ui_root):
		_show_camp()
		return
	_reset_movement_input()
	run_paused = true
	var existing: Node = ui_root.get_node_or_null("ArsenalScreen")
	if existing != null:
		existing.queue_free()
	var arsenal_screen := ArsenalScreenScene.instantiate() as AshenArsenalScreen
	arsenal_screen.name = "ArsenalScreen"
	arsenal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arsenal_screen.z_index = 600
	arsenal_screen.closed.connect(_show_camp)
	arsenal_screen.expedition_requested.connect(_on_arsenal_expedition_requested.bind(from_gate))
	ui_root.add_child(arsenal_screen)
	arsenal_screen.apply_safe_area(safe_area_top)
	arsenal_screen.bind_profile(save.profile)

func _on_arsenal_expedition_requested(arsenal: Dictionary, from_gate: bool = false) -> void:
	var validation: Dictionary = ArsenalService.validate(save.profile, arsenal)
	if not bool(validation.get("valid", false)):
		return
	save.profile.starting_class = String(arsenal.get("class_id", save.profile.get("starting_class", "warrior")))
	Roster.set_active_hero(save.profile, String(save.profile.starting_class))
	_sync_active_hero_fields()
	save.profile.starting_weapon = String(arsenal.get("starting_weapon", "sword"))
	var doctrine_ids: Array = arsenal.get("doctrine_ids", [])
	save.profile.starting_doctrine = String(doctrine_ids[0]) if not doctrine_ids.is_empty() else ""
	save.profile.expedition_arsenals = [arsenal.duplicate(true)]
	save.profile.selected_arsenal_id = String(arsenal.get("id", "arsenal_company_standard"))
	SaveService.save_data(save)
	var screen_to_remove: Node = ui_root.get_node_or_null("ArsenalScreen")
	if screen_to_remove != null:
		screen_to_remove.queue_free()
	_start_new_run(String(save.profile.starting_weapon), from_gate)

func _selected_arsenal() -> Dictionary:
	var selected_id: String = String(save.profile.get("selected_arsenal_id", ""))
	for arsenal_value: Variant in save.profile.get("expedition_arsenals", []):
		if arsenal_value is Dictionary and (selected_id.is_empty() or String(arsenal_value.get("id", "")) == selected_id):
			var candidate: Dictionary = arsenal_value.duplicate(true)
			var validation: Dictionary = ArsenalService.validate(save.profile, candidate)
			if bool(validation.get("valid", false)):
				return candidate
	return {}

func _legacy_runtime_weapon_id(canonical_id: String) -> String:
	match canonical_id:
		"axe": return "greatsword"
		"knives": return "daggers"
		"witchfire": return "staff"
		_: return canonical_id

func _register_training_runtime_content() -> void:
	# The legacy controller still owns pooling, collision, and drawing. These
	# definitions adapt the new data-driven registry to that stable runtime
	# contract while preserving one distinct ID per weapon and technique.
	for ability_id: String in TrainingContent.abilities():
		var data: Dictionary = TrainingContent.abilities()[ability_id]
		if String(data.get("category", "")) == "technique":
			# Replace legacy collisions (for example shield_wall) with the
			# canonical five-rank Training Grounds definition.
			runtime_techniques[ability_id] = _training_runtime_technique(data)
		else:
			# The old table contains spear, bow, and sling under the same IDs;
			# canonical data must win so their Bible stats are used at runtime.
			runtime_weapons[ability_id] = _training_runtime_weapon(data)

func _training_runtime_weapon(data: Dictionary) -> Dictionary:
	var ability_id: String = String(data.get("id", ""))
	var tags: Array = Array(data.get("tags", []))
	var base: Dictionary = Dictionary(data.get("base_stats", {}))
	var category: String = "ARCANE" if "arcane" in tags else ("MELEE" if "melee" in tags else "RANGED")
	var behavior: String = "line"
	if ability_id == "spear":
		behavior = "thrust"
	elif ability_id in ["sword", "greatsword", "daggers"]:
		behavior = "sweep"
	elif ability_id == "sling":
		behavior = "splash"
	elif ability_id == "throwing_knives":
		behavior = "fan"
	elif ability_id == "staff":
		behavior = "hex"
	elif ability_id in ["throwing_knives", "chakrams"]:
		behavior = "returning" if ability_id == "chakrams" else "fan"
	elif ability_id == "runic_orb":
		behavior = "orbit"
	var radius: float = 58.0 if category == "MELEE" else 5.0
	if ability_id == "spear":
		radius = 120.0
	elif ability_id == "greatsword":
		radius = 92.0
	elif ability_id == "daggers":
		radius = 54.0
	var rank_bonuses: Array[Dictionary] = []
	var ranks: Array = data.get("ranks", [])
	for rank_index: int in range(1, 5):
		var rank: Dictionary = Dictionary(ranks[rank_index]) if rank_index < ranks.size() else {}
		var changes: Dictionary = Dictionary(rank.get("stat_changes", {}))
		var bonus: Dictionary = {}
		var damage_multiplier: float = float(rank.get("damage_multiplier", 1.0))
		if not is_equal_approx(damage_multiplier, 1.0):
			bonus.damage = damage_multiplier - 1.0
		if int(rank.get("pierce", 0)) > 0:
			bonus.pierce = int(rank.get("pierce", 0))
		if float(rank.get("area_multiplier", 1.0)) != 1.0:
			bonus.melee_area = float(rank.get("area_multiplier", 1.0)) - 1.0 if category == "MELEE" else float(rank.get("area_multiplier", 1.0)) - 1.0
		for stat: String in ["attack_speed", "projectile_speed", "melee_range", "knockback", "bleed_damage"]:
			if changes.has(stat):
				bonus[stat] = float(changes[stat])
		if category == "MELEE" and changes.has("reach"):
			bonus.melee_range = float(changes.reach) * radius
		# Pattern projectile counts are cadence rules (every third/fifth attack),
		# not permanent global projectile bonuses. _fire_weapon consumes them with
		# the behavior flags and the per-weapon attack counter.
		rank_bonuses.append(bonus)
	var rank_five: Dictionary = Dictionary(ranks[4]) if ranks.size() > 4 else {}
	var mastery_stats: Dictionary = {}
	var mastery_changes: Dictionary = Dictionary(rank_five.get("stat_changes", {}))
	if float(rank_five.get("damage_multiplier", 1.0)) != 1.0:
		mastery_stats.damage = float(rank_five.get("damage_multiplier", 1.0)) - 1.0
	if category == "MELEE" and float(rank_five.get("area_multiplier", 1.0)) != 1.0:
		mastery_stats.melee_area = float(rank_five.get("area_multiplier", 1.0)) - 1.0
	return {
		"name": String(data.get("name", ability_id)), "category": category,
		"description": String(Dictionary(ranks[0]).get("description", "")) if not ranks.is_empty() else "",
		"cooldown": float(base.get("interval", 1.0)), "damage": float(base.get("normalized_power", 1.0)) * 20.0,
		"speed": 0.0 if category == "MELEE" else float(base.get("range", 300.0)), "radius": radius,
		"pierce": 2 if ability_id == "spear" else 0, "behavior": behavior,
		"color": TrainingContent.SCHOOL_COLORS.get(String(data.get("school", "vanguard")), Color.WHITE),
		"technique": "", "mastery": "%s Mastery" % String(data.get("name", ability_id)),
		"mastery_description": "Rank-five transformation unlocked by school mastery.", "mastery_stats": mastery_stats,
		"rank_bonuses": rank_bonuses, "homing": behavior == "hex"
	}

func _training_runtime_technique(data: Dictionary) -> Dictionary:
	var ranks: Array = data.get("ranks", [])
	var base: Dictionary = Dictionary(data.get("base_stats", {}))
	return {
		"name": String(data.get("name", data.get("id", "Technique"))),
		"description": String(Dictionary(ranks[0]).get("description", "")) if not ranks.is_empty() else "",
		# Canonical techniques are cast-scoped. Their rank data is consumed when
		# that specific technique fires and must never become a global player stat.
		"stats": {}, "cooldown": float(base.get("cooldown", 8.0)),
		"school": String(data.get("school", "")), "automatic": true,
		"rank_stats": ranks.duplicate(true)
	}

func _legacy_show_weapon_picker(category_index: int = -1) -> void:
	if not is_instance_valid(ui_root):
		_show_camp()
		return
	if category_index >= 0:
		weapon_picker_category = category_index
	var existing_picker: Node = ui_root.get_node_or_null("WeaponPickerOverlay") if is_instance_valid(ui_root) else null
	if existing_picker != null:
		existing_picker.name = "ClosingWeaponPicker"
		existing_picker.queue_free()
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "WeaponPickerOverlay"
	overlay.color = Color(0.03, 0.035, 0.038, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	# The picker belongs to the screen-space UI layer. Adding it to the world
	# root leaves it underneath the camp art and causes the fire/structures to
	# bleed through the menu. Keep it above every camp visual and HUD element.
	overlay.z_index = 500
	ui_root.add_child(overlay)
	var panel := _make_authored_panel("Run/LevelUpPanel", Rect2(12.0, 42.0, maxf(260.0, size.x - 24.0), maxf(420.0, size.y - 78.0)), "WeaponPickerPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_attach_panel_content(panel, box)
	box.add_child(_make_label("CHOOSE YOUR ARMS", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("One weapon begins the expedition. You can build to four.", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("CHOOSE YOUR COMPANY ROLE", 13, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_LEFT))
	var class_grid: GridContainer = GridContainer.new()
	class_grid.columns = 1 if size.x < 340.0 else 2
	class_grid.add_theme_constant_override("h_separation", 7)
	class_grid.add_theme_constant_override("v_separation", 7)
	for class_id: String in ["warrior", "hunter", "mage", "rogue"]:
		var class_definition: Dictionary = GameContent.CLASSES[class_id]
		var roster_hero: Dictionary = Roster.hero_by_id(save.profile.get("heroes", []), class_id)
		var class_button: Button = _make_button("%s · LV %d" % [String(roster_hero.get("name", class_definition.name)).to_upper(), int(roster_hero.get("level", 1))], 34.0, BURGUNDY if class_id == String(save.profile.get("active_hero_id", "warrior")) else IRON.darkened(0.35))
		class_button.name = "Class%sButton" % class_id.capitalize()
		class_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		class_button.pressed.connect(_select_class.bind(class_id, overlay))
		class_grid.add_child(class_button)
	box.add_child(class_grid)
	var selected_class_id: String = String(save.profile.get("active_hero_id", "warrior"))
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
			if String(runtime_weapons[weapon_id].category) == category:
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
			var weapon: Dictionary = runtime_weapons[weapon_id]
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
	Roster.set_active_hero(save.profile, class_id)
	_sync_active_hero_fields()
	save.profile.starting_weapon = String(GameContent.CLASSES[class_id].starting_weapon)
	weapon_picker_category = 2 if class_id == "mage" else (1 if class_id in ["hunter", "rogue"] else 0)
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
	var panel := _make_authored_panel("Run/ContractsPanel", Rect2(22.0, 180.0, size.x - 44.0, size.y - 320.0), "ContractPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
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
	var panel := _make_authored_panel("Run/RelicBox", Rect2(22.0, 170.0, size.x - 44.0, size.y - 300.0), "RelicPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
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
	run_boons.clear()
	combat_statuses.clear()
	environment_states.clear()
	weapon_attack_counts.clear()
	elemental_echo_cooldowns.clear()
	elemental_conduit_cooldowns.clear()
	volatile_mixture_cooldowns.clear()
	repeated_hit_counts.clear()
	prepared_arsenal.clear()
	run_rerolls = 0
	upgrade_offer_index = 0
	recently_rejected_choices.clear()
	rejected_choice_levels.clear()
	technique_timers.clear()
	run_loot.clear()
	weapon_timers.clear()
	exploration_points.clear()
	player_position = _camp_gate_position() + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
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
	active_doctrine = ""
	active_doctrines.clear()
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
	boss_cycle_spawned = 0
	run_bosses_defeated = 0
	run_boss_keys = 0
	run_paused = false
	choosing_upgrade = false
	run_gate_entry_armed = false
	autosave_timer = 0.0
	spawn_accumulator = 0.0
	guard_cooldown = 0.0
	guard_timer = 0.0
	guard_empowered = false
	player_barrier = 0.0
	time_since_player_damage = 0.0
	stationary_time = 0.0
	stationary_anchor = Vector2.ZERO
	recent_movement_distance = 0.0
	post_mobility_timer = 0.0
	war_cry_timer = 0.0
	war_cry_attack_speed = 0.0
	movement_burst_timer = 0.0
	vanishing_step_cooldown = 0.0
	running_shot_cooldown = 0.0
	toxic_blood_cooldown = 0.0
	resonant_guard_cooldown = 0.0
	technique_damage_reduction_timer = 0.0
	static_field_timer = 1.0
	blade_hit_count = 0
	bloodbound_heal_window = 0.0
	bloodbound_healed = 0.0
	duelist_momentum = 0
	duelist_last_category = ""
	next_ranged_projectiles = 0
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
	run_camera_transition = 1.0

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
	var banked: bool = victory or extracted
	var loot_result: Dictionary = _store_run_loot() if banked else {"stored": 0, "salvaged": 0, "salvaged_silver": 0}
	silver = silver + int(loot_result.salvaged_silver) if banked else 0
	provisions = provisions if banked else 0
	var rating: float = GameRules.veteran_rating(run_elapsed, run_kills, run_elites, victory)
	var hero: Dictionary = _active_hero()
	var hero_xp: int = maxi(1, floori(float(run_kills) * 0.35 + float(run_elites) * 8.0 + float(run_bosses_defeated) * 35.0))
	var hero_levels: int = Roster.grant_xp(hero, hero_xp)
	var training_service := TrainingGroundsService.new(save.profile)
	var training_xp: int = training_service.expedition_training_xp(_current_dread(), run_elites, run_bosses_defeated, 1 if objective_complete else 0, run_elapsed, banked)
	var training_reward: Dictionary = training_service.grant_training_xp(training_xp, "victory" if victory else ("extraction" if extracted else "defeat"))
	var one_time_training_points: int = 0
	if victory:
		one_time_training_points += int(training_service.grant_one_time_points("blackthorn_moor_boss_first", 5, "boss").get("points", 0))
	if objective_complete:
		one_time_training_points += int(training_service.grant_one_time_points("blackthorn_moor_objective_%s" % objective_id, 3, "objective").get("points", 0))
	var keys_banked: int = run_boss_keys if banked else 0
	result_data = {"victory": victory, "extracted": extracted, "banked": banked, "silver": silver, "provisions": provisions, "rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "discoveries": run_discoveries, "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete, "class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true), "loot": run_loot.duplicate(true), "stored_loot": int(loot_result.stored), "salvaged_loot": int(loot_result.salvaged), "lost_loot": 0 if banked else run_loot.size(), "boss_keys": keys_banked, "hero_xp": hero_xp, "hero_levels": hero_levels, "training_xp": training_xp, "training_points_gained": int(training_reward.get("points", 0)) + one_time_training_points, "training_xp_remaining": int(training_reward.get("remaining_xp", 0))}
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	if keys_banked > 0:
		var biome_keys: Dictionary = save.profile.get("biome_keys", {})
		biome_keys.barrows_key = int(biome_keys.get("barrows_key", 0)) + keys_banked
		save.profile.biome_keys = biome_keys
	var current_veteran: Dictionary = save.profile.veteran
	if current_veteran.is_empty() or rating > float(current_veteran.get("rating", 0.0)):
		save.profile.veteran = {"rating": rating, "time": run_elapsed, "kills": run_kills, "elites": run_elites, "boss": victory, "weapons": weapons.duplicate(true), "techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true), "objective": objective_id, "objective_complete": objective_complete, "contract": contract_id, "contract_complete": contract_complete}
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
	camp_player_position = _camp_gate_position() + Vector2(0.0, -2.0)
	_update_last_seen()
	SaveService.save_data(save)
	if extracted:
		_handoff_run_enemies_to_camp()
		# Preserve the exact field framing for the first camp frame. The anchor
		# is a camera continuity value, not a UI coordinate, so allowing it to be
		# slightly beyond the usual portrait comfort range prevents a visible
		# snap when the town HUD takes over.
		camp_camera_anchor_x = (camp_player_position.x - camera_offset.x) / maxf(1.0, size.x)
		camp_camera_anchor_y = (camp_player_position.y - camera_offset.y) / maxf(1.0, size.y)
		var return_message: String = "Banked %d silver, %d provisions and %d equipment." % [silver, provisions, int(loot_result.stored)]
		_show_camp(return_message, true)
		return
	camera_offset = camp_world_origin
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
		"class": active_class, "doctrine": active_doctrine, "doctrines": active_doctrines.duplicate(), "curse": active_curse, "relics": relics.duplicate(true),
		"prepared_arsenal": prepared_arsenal.duplicate(true), "run_boons": run_boons.duplicate(true), "rerolls_remaining": run_rerolls,
		"upgrade_offer_index": upgrade_offer_index, "recently_rejected_choices": recently_rejected_choices.duplicate(), "rejected_choice_levels": rejected_choice_levels.duplicate(true),
		"position": [player_position.x, player_position.y], "level": run_level, "xp": run_xp, "next_xp": next_xp,
		"kills": run_kills, "elites": run_elites, "score": run_score, "weapons": weapons.duplicate(true),
		"techniques": techniques.duplicate(true), "mastered": mastered.duplicate(true), "boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated, "elite_one": elite_one_spawned, "elite_two": elite_two_spawned, "boss_phase": boss_phase,
		"boss_cycle_spawned": boss_cycle_spawned, "bosses_defeated": run_bosses_defeated, "boss_keys": run_boss_keys,
		"hero_id": String(save.profile.get("active_hero_id", "warrior")), "biome": "blackthorn_moor",
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
	generated_region = RegionGeneratorService.generate_blackthorn(run_seed)
	_cache_region_blockers()
	Roster.set_active_hero(save.profile, String(snapshot.get("hero_id", save.profile.get("active_hero_id", "warrior"))))
	_sync_active_hero_fields()
	active_class = String(snapshot.get("class", save.profile.get("starting_class", "warrior")))
	if not GameContent.CLASSES.has(active_class):
		active_class = "warrior"
	active_doctrines.clear()
	for doctrine_value: Variant in Array(snapshot.get("doctrines", [])):
		var doctrine_id: String = String(doctrine_value)
		if (GameContent.DOCTRINES.has(doctrine_id) or TrainingContent.doctrines().has(doctrine_id)) and doctrine_id not in active_doctrines:
			active_doctrines.append(doctrine_id)
	active_doctrine = String(snapshot.get("doctrine", active_doctrines[0] if not active_doctrines.is_empty() else save.profile.get("starting_doctrine", "")))
	if active_doctrines.is_empty() and not active_doctrine.is_empty():
		active_doctrines.append(active_doctrine)
	if not GameContent.DOCTRINES.has(active_doctrine) and not TrainingContent.doctrines().has(active_doctrine):
		active_doctrine = ""
	active_curse = String(snapshot.get("curse", save.profile.get("starting_curse", "none")))
	if not GameContent.CURSES.has(active_curse):
		active_curse = "none"
	relics = snapshot.get("relics", {}).duplicate(true)
	run_elapsed = maxf(0.0, float(snapshot.get("elapsed", 0.0)))
	player_hp = float(snapshot.get("hp", 100.0))
	var position_data: Array = snapshot.get("position", [_camp_gate_position().x, _camp_gate_position().y + FIELD_START_DISTANCE + 12.0])
	if bool(snapshot.get("world_map", false)):
		player_position = Vector2(float(position_data[0]), float(position_data[1]))
	else:
		# Old snapshots used screen coordinates. Resume them just beyond the same
		# physical gate instead of placing the player inside the rebuilt town.
		player_position = _camp_gate_position() + Vector2(0.0, FIELD_START_DISTANCE + 12.0)
	run_level = int(snapshot.get("level", 1))
	run_xp = int(snapshot.get("xp", 0))
	next_xp = int(snapshot.get("next_xp", 14))
	run_kills = int(snapshot.get("kills", 0))
	run_elites = int(snapshot.get("elites", 0))
	run_score = int(snapshot.get("score", 0))
	weapons = snapshot.get("weapons", {"spear": 1}).duplicate(true)
	techniques = snapshot.get("techniques", {}).duplicate(true)
	mastered = snapshot.get("mastered", {}).duplicate(true)
	prepared_arsenal = snapshot.get("prepared_arsenal", _selected_arsenal()).duplicate(true)
	run_boons = snapshot.get("run_boons", {}).duplicate(true)
	run_rerolls = int(snapshot.get("rerolls_remaining", 0))
	upgrade_offer_index = int(snapshot.get("upgrade_offer_index", 0))
	recently_rejected_choices.assign(snapshot.get("recently_rejected_choices", []))
	rejected_choice_levels = Dictionary(snapshot.get("rejected_choice_levels", {})).duplicate(true)
	if rejected_choice_levels.is_empty():
		for rejected_id: String in recently_rejected_choices:
			rejected_choice_levels[rejected_id] = run_level
	boss_spawned = bool(snapshot.get("boss_spawned", false))
	boss_defeated = bool(snapshot.get("boss_defeated", false))
	elite_one_spawned = bool(snapshot.get("elite_one", run_elapsed >= 120.0))
	elite_two_spawned = bool(snapshot.get("elite_two", run_elapsed >= 300.0))
	boss_phase = int(snapshot.get("boss_phase", 0))
	boss_cycle_spawned = int(snapshot.get("boss_cycle_spawned", Expedition.boss_cycle_for_dread(_current_dread())))
	run_bosses_defeated = int(snapshot.get("bosses_defeated", 0))
	run_boss_keys = int(snapshot.get("boss_keys", 0))
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
	# Resumed runs also begin at a valid field position, so returning straight
	# to the gate remains an intentional, immediate crossing.
	run_gate_entry_armed = true
	run_camera_transition = 1.0
	_update_world_camera(player_position, false, true)
	for index: int in mini(24, 6 + floori(run_elapsed / 25.0)):
		_spawn_enemy(_choose_wave_enemy(), false)
	_activate_camp_wanderers_for_run()
	if boss_spawned and not boss_defeated:
		_spawn_enemy("barrow_knight", true)
	screen = Screen.RUN
	run_paused = false
	_build_run_ui()

func _apply_offline_progress() -> void:
	var now: float = Time.get_unix_time_from_system()
	Roster.apply_offline(save.profile, now)
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
	var training_service := TrainingGroundsService.new(save.profile)
	training_service.training_points_from_building_upgrade(building, level + 1)
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

func _show_camp(message: String = "", preserve_world: bool = false) -> void:
	# Only play the location card on a genuine arrival. Rebuilding the camp UI
	# after closing a menu must not restart it.
	var show_location_title: bool = not is_instance_valid(ui_root) or screen == Screen.RUN or screen == Screen.RESULTS
	var keep_camera: bool = preserve_world or camp_uses_field_camera
	screen = Screen.CAMP
	run_paused = true
	camp_uses_field_camera = keep_camera
	_load_camp_layout_for_tier(_town_level())
	_build_structure_definitions()
	camp_highlighted_structure = ""
	_sync_structure_anchors()
	if not keep_camera:
		_update_world_camera(camp_player_position, true, true)
	_ensure_camp_wanderers()
	_apply_offline_progress()
	_play_music("camp")
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100

	var locations: Control = Control.new()
	locations.name = "CampLocations"
	locations.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	locations.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(locations)
	_add_safe_area_band(ui_root)
	camp_hotspot_buttons.clear()

	var expedition: Dictionary = save.profile.expedition
	var current_operation: String = String(expedition.get("operation", "forage"))
	var pending_silver: int = int(expedition.get("pending_silver", 0))
	var pending_provisions: int = int(expedition.get("pending_provisions", 0))
	var operation_name: String = "PATROL" if current_operation == "patrol" else "FORAGING"
	var pending_text: String = "%dS / %dP READY  ·  %d/%d BUILT" % [pending_silver, pending_provisions, _constructed_count(), _town_capacity()] if pending_silver + pending_provisions > 0 else "%s  ·  %d/%d BUILT" % [operation_name, _constructed_count(), _town_capacity()]
	var veterans_button: Button = _make_camp_hotspot("VeteranTentButton", "%s  -  HALL TIER %d" % [String(_town_definition().name), _town_level()], pending_text, _camp_hit_rect_world("veterans_hall"), AMBER)
	camp_hotspot_buttons["veterans_hall"] = veterans_button
	_wire_camp_highlight(veterans_button, "veterans_hall")
	# Open on touch-down so a tiny finger drift during release cannot cancel this
	# central hotspot on mobile Safari.
	veterans_button.button_down.connect(_show_hall_detail)

	var buildings: Control = Control.new()
	buildings.name = "CampBuildings"
	buildings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buildings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locations.add_child(buildings)
	for building: String in ["armory", "quartermaster", "blacksmith", "training"]:
		if not _is_constructed(building):
			continue
		var level: int = int(save.profile[building + "_level"])
		var building_costs: Array[Dictionary]
		match building:
			"armory": building_costs = GameContent.ARMORY_COSTS
			"blacksmith": building_costs = GameContent.BLACKSMITH_COSTS
			"training": building_costs = GameContent.TRAINING_COSTS
			_: building_costs = GameContent.QUARTERMASTER_COSTS
		var building_name: String = "QUARTERMASTER" if building == "quartermaster" else building.to_upper()
		var tier_text: String = "RESTORED" if level >= building_costs.size() else "TIER %d / %d" % [level, building_costs.size()]
		var button: Button = _make_camp_hotspot("CampBuilding_%s" % building, building_name, tier_text, _camp_hit_rect_world(building), Color("91a985") if level >= building_costs.size() else AMBER)
		camp_hotspot_buttons[building] = button
		_wire_camp_highlight(button, building)
		button.pressed.connect(_show_building_detail.bind(building))
		buildings.add_child(button)
	for plot_id: String in _revealed_plot_ids():
		if not _is_plot_visible(plot_id):
			continue
		var plot_button: Button = _make_camp_hotspot("CampPlot_%s" % plot_id, "EMPTY BUILDING PLOT", "CHOOSE A TOWN SERVICE", _camp_hit_rect_world(plot_id), PARCHMENT_DARK)
		camp_hotspot_buttons[plot_id] = plot_button
		_wire_camp_highlight(plot_button, plot_id)
		plot_button.pressed.connect(_show_construction_menu.bind(plot_id))
		buildings.add_child(plot_button)

	var march_title: String = "EXPEDITION TABLE" if not save.active_run.is_empty() else "CAMPFIRE"
	var march_stats: String = "RESUME OR RE-EQUIP" if not save.active_run.is_empty() else "PREPARE YOUR COMPANY"
	var march_button: Button = _make_camp_hotspot("CampfireButton", march_title, march_stats, _camp_hit_rect_world("campfire"), BURGUNDY.lightened(0.18))
	camp_hotspot_buttons["campfire"] = march_button
	_wire_camp_highlight(march_button, "campfire")
	march_button.pressed.connect(_show_weapon_picker)
	locations.add_child(march_button)

	var live_hud := _add_live_hud("camp")
	var title_crest := live_hud.get_node("SafeAreaTop/CampTitleCrest") as TextureRect
	title_crest.visible = show_location_title
	camp_arrival_crest = title_crest
	camp_arrival_crest_elapsed = 0.0
	if show_location_title:
		title_crest.modulate.a = 1.0
	live_hud.bind_profile(save.profile, _active_hero(), _camp_display_max_health())
	silver_value_label = live_hud.get_node("SafeAreaTop/ResourceRail/SilverCell/SilverValueLabel") as Label
	provisions_value_label = live_hud.get_node("SafeAreaTop/ResourceRail/ProvisionsCell/ProvisionsValueLabel") as Label
	health_bar = live_hud.get_node("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	var settings_button_top := live_hud.get_node("SafeAreaTop/SettingsCogButton") as Button
	settings_button_top.tooltip_text = "Settings"
	settings_button_top.pressed.connect(_show_settings)
	camp_interact_button = live_hud.get_node("Camp/CampInteractButton") as Button
	camp_interact_button.disabled = true
	camp_interact_button.pressed.connect(_interact_with_camp_target)
	if not Geometry2D.is_point_in_polygon(camp_player_position, _camp_boundary_world()) or _camp_position_blocked(camp_player_position):
		camp_player_position = _safe_camp_spawn_position()
	camp_interaction_target = _nearest_camp_interaction()
	_update_camp_interact_button()
	_update_camp_hotspot_positions()
	status_label = live_hud.get_node("Camp/CampStatusLabel") as Label
	status_label.text = message
	status_label.visible = not message.is_empty()
	# Add this central hotspot last so the compact header cannot win Godot's
	# hit test in the narrow gap beneath it on mobile web.
	ui_root.add_child(veterans_button)
	queue_redraw()

func _show_hall_detail() -> void:
	var overlay: ColorRect = _make_camp_overlay("HallOverlay")
	var panel := _make_authored_panel("Camp/HallPanel", Rect2(20.0, 146.0, size.x - 40.0, minf(560.0, size.y - 176.0)), "HallPanel")
	overlay.add_child(panel)
	_bind_authored_hall_panel(panel, overlay)
	return
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	_attach_panel_content(panel, box)
	var hall_level: int = _town_level()
	var town: Dictionary = _town_definition()
	box.add_child(_make_label("VETERANS' HALL", 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("%s  ·  HALL TIER %d" % [String(town.name), hall_level], 12, AMBER.lightened(0.18), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("BUILDING CAPACITY  %d / %d" % [_constructed_count(), _town_capacity()], 14, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	var explanation: Label = _make_label("Expand the Hall to push back the palisade and open one permanent building slot. Choose which service the settlement needs first.", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size.y = 42.0
	box.add_child(explanation)
	if hall_level < GameContent.HALL_COSTS.size():
		var cost: Dictionary = GameContent.HALL_COSTS[hall_level]
		var can_afford: bool = int(save.profile.silver) >= int(cost.silver) and int(save.profile.provisions) >= int(cost.provisions)
		var next_town: Dictionary = TOWN_LEVELS[hall_level + 1]
		var expand: Button = _make_button("EXPAND TO %s\n+1 BUILDING SLOT  ·  %d SILVER / %d PROVISIONS" % [String(next_town.name), int(cost.silver), int(cost.provisions)], 68.0, BURGUNDY if can_afford else IRON.darkened(0.42))
		expand.name = "HallUpgradeButton"
		expand.disabled = not can_afford
		expand.pressed.connect(_buy_hall_upgrade)
		box.add_child(expand)
	else:
		box.add_child(_make_label("THE SETTLEMENT HAS REACHED ITS CURRENT LIMIT", 11, Color("91a985"), HORIZONTAL_ALIGNMENT_CENTER))
	if _has_open_building_slot():
		box.add_child(_make_label("A MARKED FOUNDATION IS READY\nWalk to the empty plot to choose its service.", 11, AMBER.lightened(0.18), HORIZONTAL_ALIGNMENT_CENTER))
	else:
		box.add_child(_make_label("ALL CURRENT SLOTS ARE OCCUPIED", 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var roster: Button = _make_button("MANAGE COMPANY & OFFLINE WORK", 50.0, Color("4d5b55"))
	roster.name = "HallRosterButton"
	roster.pressed.connect(_show_camp_expeditions)
	box.add_child(roster)
	var close: Button = _make_button("RETURN TO TOWN", 46.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _bind_authored_hall_panel(panel: PanelContainer, overlay: Control) -> void:
	var content := panel.get_node("ContentRoot") as Control
	var hall_level: int = _town_level()
	var town: Dictionary = _town_definition()
	(content.get_node("HallTitle") as Label).text = "VETERANS' HALL"
	(content.get_node("HallTier") as Label).text = "%s - HALL TIER %d" % [String(town.name), hall_level]
	(content.get_node("HallCapacity") as Label).text = "BUILDING CAPACITY  %d / %d" % [_constructed_count(), _town_capacity()]
	(content.get_node("HallExplanation") as Label).text = "Expand the Hall to push back the palisade and open one permanent building slot. Choose which service the settlement needs first."
	var expand := content.get_node("HallUpgradeButton") as Button
	if hall_level < GameContent.HALL_COSTS.size():
		var cost: Dictionary = GameContent.HALL_COSTS[hall_level]
		var can_afford: bool = int(save.profile.silver) >= int(cost.silver) and int(save.profile.provisions) >= int(cost.provisions)
		var next_town: Dictionary = TOWN_LEVELS[hall_level + 1]
		expand.visible = true
		expand.text = "EXPAND TO %s\n+1 BUILDING SLOT - %d SILVER / %d PROVISIONS" % [String(next_town.name), int(cost.silver), int(cost.provisions)]
		expand.disabled = not can_afford
		expand.pressed.connect(_buy_hall_upgrade)
	else:
		expand.visible = false
	var slot_status := content.get_node("HallSlotStatus") as Label
	slot_status.text = "A MARKED FOUNDATION IS READY\nWalk to the empty plot to choose its service." if _has_open_building_slot() else "ALL CURRENT SLOTS ARE OCCUPIED"
	var roster := content.get_node("HallRosterButton") as Button
	roster.pressed.connect(_show_camp_expeditions)
	var close := content.get_node("HallCloseButton") as Button
	close.pressed.connect(overlay.queue_free)

func _buy_hall_upgrade() -> void:
	var hall_level: int = _town_level()
	if hall_level >= GameContent.HALL_COSTS.size():
		return
	var cost: Dictionary = GameContent.HALL_COSTS[hall_level]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	save.profile.hall_level = hall_level + 1
	var training_service := TrainingGroundsService.new(save.profile)
	training_service.training_points_from_building_upgrade("veterans_hall", hall_level + 1)
	SaveService.save_data(save)
	_show_camp("The palisade expands. Find the new marked foundation in town.")

func _show_construction_menu(plot_id: String = "") -> void:
	if plot_id.is_empty():
		plot_id = _first_open_plot()
	if plot_id.is_empty() or not _is_plot_visible(plot_id):
		return
	var overlay: ColorRect = _make_camp_overlay("ConstructionMenuOverlay")
	var panel := _make_authored_panel("Camp/ConstructionPanel", Rect2(18.0, 140.0, size.x - 36.0, minf(600.0, size.y - 168.0)), "ConstructionPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	_attach_panel_content(panel, box)
	box.add_child(_make_label("CHOOSE A TOWN SERVICE", 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("FOUNDATION %d  ·  THIS CHOICE IS PERMANENT" % (CAMP_PLOT_ORDER.find(plot_id) + 1), 11, AMBER.lightened(0.18), HORIZONTAL_ALIGNMENT_CENTER))
	for building: String in ["armory", "blacksmith", "quartermaster", "training"]:
		if _is_constructed(building):
			continue
		var cost: Dictionary = GameContent.BUILDING_CONSTRUCTION_COSTS[building]
		var label: String = "TRAINING YARD" if building == "training" else building.replace("_", " ").to_upper()
		var effect: String = _building_construction_effect(building)
		var can_build: bool = _is_plot_visible(plot_id) and int(save.profile.silver) >= int(cost.silver) and int(save.profile.provisions) >= int(cost.provisions)
		var choice: Button = _make_button("%s  ·  %dS / %dP\n%s" % [label, int(cost.silver), int(cost.provisions), effect], 70.0, BURGUNDY if can_build else IRON.darkened(0.42))
		choice.name = "Construct_%s" % building
		choice.disabled = not can_build
		choice.pressed.connect(_construct_building.bind(building, plot_id))
		box.add_child(choice)
	var close: Button = _make_button("LEAVE FOUNDATION", 44.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _show_construction_detail(building: String) -> void:
	if _is_constructed(building):
		_show_building_detail(building)
		return
	var overlay: ColorRect = _make_camp_overlay("ConstructionDetailOverlay")
	var panel := _make_authored_panel("Camp/ConstructionDetailPanel", Rect2(24.0, 205.0, size.x - 48.0, 340.0), "ConstructionDetailPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
	var label: String = "TRAINING YARD" if building == "training" else building.replace("_", " ").to_upper()
	box.add_child(_make_label("EMPTY BUILDING PLOT", 11, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label(label, 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var effect: Label = _make_label(_building_construction_effect(building), 12, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.custom_minimum_size.y = 42.0
	box.add_child(effect)
	var cost: Dictionary = GameContent.BUILDING_CONSTRUCTION_COSTS[building]
	var can_build: bool = _has_open_building_slot() and int(save.profile.silver) >= int(cost.silver) and int(save.profile.provisions) >= int(cost.provisions)
	var construct: Button = _make_button("CONSTRUCT\n%d SILVER / %d PROVISIONS" % [int(cost.silver), int(cost.provisions)], 64.0, BURGUNDY if can_build else IRON.darkened(0.42))
	construct.name = "ConstructionConfirmButton"
	construct.disabled = not can_build
	construct.pressed.connect(_construct_building.bind(building))
	box.add_child(construct)
	var close: Button = _make_button("LEAVE PLOT", 44.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _building_construction_effect(building: String) -> String:
	match building:
		"armory": return "Unlocks weapon loadouts and martial weapon restoration."
		"blacksmith": return "Unlocks equipment inspection and improves positive item stats."
		"quartermaster": return "Unlocks expedition logistics, idle yield and frontier work."
		"training": return "Unlocks the company skill tree and permanent hero training."
	return "Adds a new service to the settlement."

func _construct_building(building: String, plot_id: String = "") -> void:
	if plot_id.is_empty():
		plot_id = _first_open_plot()
	if _is_constructed(building) or not _is_plot_visible(plot_id) or not GameContent.BUILDING_CONSTRUCTION_COSTS.has(building):
		return
	var cost: Dictionary = GameContent.BUILDING_CONSTRUCTION_COSTS[building]
	if int(save.profile.silver) < int(cost.silver) or int(save.profile.provisions) < int(cost.provisions):
		return
	save.profile.silver = int(save.profile.silver) - int(cost.silver)
	save.profile.provisions = int(save.profile.provisions) - int(cost.provisions)
	var buildings: Array = _constructed_buildings().duplicate()
	buildings.append(building)
	save.profile.constructed_buildings = buildings
	var plots: Dictionary = _building_plots().duplicate(true)
	plots[plot_id] = building
	save.profile.building_plots = plots
	# Constructing the Training Grounds is its own one-time reward. Later
	# restorations (tiers 2–5) are handled by _buy_building below.
	if building == "training":
		var training_service := TrainingGroundsService.new(save.profile)
		training_service.grant_one_time_points("training_grounds_constructed", 4, "training_grounds")
	_sync_structure_anchors()
	SaveService.save_data(save)
	_show_camp("The %s is ready for service." % ("training yard" if building == "training" else building.replace("_", " ")))

func _show_building_detail(building: String) -> void:
	if not _is_constructed(building):
		_show_construction_menu(_first_open_plot())
		return
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
	var panel := _make_authored_panel("Camp/BuildingDetailPanel", Rect2(24.0, 202.0, size.x - 48.0, 390.0), "BuildingDetailPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
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
	if building == "training":
		var class_tree_button: Button = _make_button("ACTIVE HERO TRAINING", 44.0, Color("4d5b55"))
		class_tree_button.pressed.connect(_replace_overlay_with_class_tree.bind(overlay))
		box.add_child(class_tree_button)
	if building == "quartermaster" and not save.profile.get("unlocked_biomes", []).has("gloamwood"):
		var key_count: int = int(save.profile.get("biome_keys", {}).get("barrows_key", 0))
		var frontier_ready: bool = level >= 1 and key_count >= 1
		var frontier: Button = _make_button("RESTORE GLOAMWOOD GATE\nNEEDS TIER 1 + 1 BARROW KEY  ·  OWNED %d" % key_count, 54.0, Color("4d5b55") if frontier_ready else IRON.darkened(0.42))
		frontier.disabled = not frontier_ready
		frontier.pressed.connect(_unlock_frontier.bind(overlay))
		box.add_child(frontier)
	var close: Button = _make_button("RETURN TO CAMP", 46.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _replace_overlay_with_class_tree(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_class_tree()

func _show_class_tree(message: String = "") -> void:
	var overlay: ColorRect = _make_camp_overlay("HeroClassTreeOverlay")
	var panel := _make_authored_panel("Camp/ClassTreePanel", Rect2(20.0, 150.0, size.x - 40.0, minf(540.0, size.y - 180.0)), "HeroClassTreePanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_attach_panel_content(panel, box)
	var hero: Dictionary = _active_hero()
	var class_id: String = String(hero.get("class_id", "warrior"))
	var learned: Dictionary = hero.get("class_tree", {})
	var points_available: int = maxi(0, int(hero.get("level", 1)) - 1 - learned.size())
	box.add_child(_make_label("%s · %s" % [String(hero.get("name", "HERO")).to_upper(), String(GameContent.CLASSES[class_id].name).to_upper()], 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("HERO LEVEL %d  ·  %d TRAINING POINTS" % [int(hero.get("level", 1)), points_available], 11, AMBER.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
	if not message.is_empty():
		box.add_child(_make_label(message, 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var nodes: Array = GameContent.CLASS_TREES.get(class_id, [])
	for node_index: int in nodes.size():
		var node: Dictionary = nodes[node_index]
		var learned_node: bool = bool(learned.get(String(node.id), false))
		var prior_met: bool = node_index == 0 or bool(learned.get(String(nodes[node_index - 1].id), false))
		var node_text: String = "%s\n%s\n%s" % [String(node.name).to_upper(), String(node.description), GameContent.stats_text(node.stats)]
		var node_button: Button = _make_button(node_text, 72.0, Color("4d5b55") if learned_node else (BURGUNDY if prior_met and points_available > 0 else IRON.darkened(0.48)))
		node_button.name = "ClassNode_%s" % String(node.id)
		node_button.disabled = learned_node or not prior_met or points_available <= 0
		node_button.pressed.connect(_buy_class_node.bind(String(node.id)))
		box.add_child(node_button)
	var close: Button = _make_button("RETURN TO TRAINING YARD", 46.0, BURGUNDY)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _buy_class_node(node_id: String) -> void:
	var hero: Dictionary = _active_hero()
	var class_id: String = String(hero.get("class_id", "warrior"))
	var nodes: Array = GameContent.CLASS_TREES.get(class_id, [])
	var learned: Dictionary = hero.get("class_tree", {})
	if maxi(0, int(hero.get("level", 1)) - 1 - learned.size()) <= 0:
		_show_class_tree("Gain a hero level to earn another training point.")
		return
	for node_index: int in nodes.size():
		var node: Dictionary = nodes[node_index]
		if String(node.id) != node_id:
			continue
		if node_index > 0 and not bool(learned.get(String(nodes[node_index - 1].id), false)):
			return
		learned[node_id] = true
		hero.class_tree = learned
		SaveService.save_data(save)
		_show_class_tree("%s learned." % String(node.name))
		return

func _unlock_frontier(overlay: Control) -> void:
	if int(save.profile.get("quartermaster_level", 0)) < 1:
		return
	var keys: Dictionary = save.profile.get("biome_keys", {})
	if int(keys.get("barrows_key", 0)) < 1:
		return
	keys.barrows_key = int(keys.barrows_key) - 1
	save.profile.biome_keys = keys
	var unlocked: Array = save.profile.get("unlocked_biomes", ["blackthorn_moor"])
	if not unlocked.has("gloamwood"):
		unlocked.append("gloamwood")
	save.profile.unlocked_biomes = unlocked
	save.profile.frontier_upgrades.gloamwood_gate = true
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_camp("The Gloamwood frontier gate is restored. The road beyond is coming next.")

func _show_camp_expeditions() -> void:
	_apply_offline_progress()
	var overlay: ColorRect = _make_camp_overlay("CampExpeditionOverlay")
	var panel := _make_authored_panel("Camp/ExpeditionsPanel", Rect2(18.0, 108.0, size.x - 36.0, minf(650.0, size.y - 136.0)), "ExpeditionsPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_attach_panel_content(panel, box)
	box.add_child(_make_label("COMPANY ROSTER", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Choose one field hero. Send the others to work while you are away.", 10, PARCHMENT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var hero_grid: GridContainer = GridContainer.new()
	hero_grid.columns = 2
	hero_grid.add_theme_constant_override("h_separation", 6)
	hero_grid.add_theme_constant_override("v_separation", 6)
	var total_pending: int = 0
	for hero_value: Variant in save.profile.get("heroes", []):
		var hero: Dictionary = hero_value
		var hero_id: String = String(hero.id)
		var assignment_name: String = String(hero.get("assignment", "idle")).replace("_", " ").to_upper()
		var pending: int = int(hero.get("pending_silver", 0)) + int(hero.get("pending_provisions", 0)) + int(hero.get("pending_xp", 0))
		total_pending += pending
		var hero_button: Button = _make_stat_button("%s · %s" % [String(hero.name).to_upper(), String(GameContent.CLASSES[hero.class_id].name).to_upper()], "LV %d  ·  %s%s" % [int(hero.level), assignment_name, "  ·  READY" if pending > 0 else ""], 58.0, BURGUNDY if hero_id == selected_roster_hero_id else (Color("4d5b55") if assignment_name == "ACTIVE" else IRON.darkened(0.35)), 18.0)
		hero_button.name = "RosterHero_%s" % hero_id
		hero_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hero_button.pressed.connect(_select_roster_hero.bind(hero_id))
		hero_grid.add_child(hero_button)
	box.add_child(hero_grid)
	var selected: Dictionary = Roster.hero_by_id(save.profile.get("heroes", []), selected_roster_hero_id)
	if selected.is_empty():
		selected_roster_hero_id = "hunter"
		selected = Roster.hero_by_id(save.profile.get("heroes", []), selected_roster_hero_id)
	var class_id: String = String(selected.get("class_id", "hunter"))
	var xp_needed: int = Roster.xp_for_next_level(int(selected.get("level", 1)))
	var selected_status: String = "%s · LV %d · XP %d/%d\n%s" % [String(selected.get("name", "Recruit")).to_upper(), int(selected.get("level", 1)), int(selected.get("xp", 0)), xp_needed, String(GameContent.CLASSES[class_id].description)]
	box.add_child(_make_label(selected_status, 11, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	var assignments: GridContainer = GridContainer.new()
	assignments.columns = 3
	assignments.add_theme_constant_override("h_separation", 5)
	for assignment_data: Dictionary in [{"id": "patrol", "label": "PATROL", "rate": "9S/H"}, {"id": "forage", "label": "FORAGE", "rate": "2.5P/H"}, {"id": "training", "label": "TRAIN", "rate": "6XP/H"}]:
		var assignment_id: String = String(assignment_data.id)
		var assignment_button: Button = _make_stat_button(String(assignment_data.label), String(assignment_data.rate), 50.0, BURGUNDY if String(selected.get("assignment", "idle")) == assignment_id else IRON.darkened(0.35), 16.0)
		assignment_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		assignment_button.disabled = String(selected.get("assignment", "idle")) == "active"
		assignment_button.pressed.connect(_set_hero_assignment.bind(selected_roster_hero_id, assignment_id))
		assignments.add_child(assignment_button)
	box.add_child(assignments)
	if String(selected.get("assignment", "idle")) != "active":
		var make_active: Button = _make_button("TAKE %s INTO THE MOOR" % String(selected.get("name", "HERO")).to_upper(), 44.0, Color("4d5b55"))
		make_active.pressed.connect(_make_roster_hero_active.bind(selected_roster_hero_id))
		box.add_child(make_active)
	if total_pending > 0:
		var claim: Button = _make_button("COLLECT ALL COMPLETED WORK", 44.0, AMBER.darkened(0.35))
		claim.pressed.connect(_claim_roster_rewards)
		box.add_child(claim)
	var close: Button = _make_button("RETURN TO CAMP", 46.0)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)

func _select_roster_hero(hero_id: String) -> void:
	selected_roster_hero_id = hero_id
	_show_camp_expeditions()

func _set_hero_assignment(hero_id: String, assignment: String) -> void:
	_apply_offline_progress()
	var hero: Dictionary = Roster.hero_by_id(save.profile.get("heroes", []), hero_id)
	if hero.is_empty() or String(hero.get("assignment", "idle")) == "active":
		return
	hero.assignment = assignment
	hero.assignment_started = Time.get_unix_time_from_system()
	hero.last_seen = hero.assignment_started
	SaveService.save_data(save)
	_show_camp_expeditions()

func _make_roster_hero_active(hero_id: String) -> void:
	_apply_offline_progress()
	if Roster.set_active_hero(save.profile, hero_id):
		_sync_active_hero_fields()
		SaveService.save_data(save)
	_show_camp_expeditions()

func _claim_roster_rewards() -> void:
	_apply_offline_progress()
	var silver: int = 0
	var provisions: int = 0
	var xp: int = 0
	for hero_value: Variant in save.profile.get("heroes", []):
		var result: Dictionary = Roster.claim_hero(hero_value)
		silver += int(result.silver)
		provisions += int(result.provisions)
		xp += int(result.xp)
	save.profile.silver = int(save.profile.silver) + silver
	save.profile.provisions = int(save.profile.provisions) + provisions
	SaveService.save_data(save)
	_show_camp("Company work collected: %d silver, %d provisions, %d hero XP." % [silver, provisions, xp])

func _replace_camp_overlay_with_expeditions(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_camp_expeditions()

func _show_march_detail() -> void:
	if save.active_run.is_empty():
		_show_weapon_picker()
		return
	var overlay: ColorRect = _make_camp_overlay("CampMarchOverlay")
	var panel := _make_authored_panel("Camp/MarchPanel", Rect2(32.0, 256.0, size.x - 64.0, 280.0), "MarchPanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
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
	_reset_movement_input()
	var existing: Node = ui_root.get_node_or_null(node_name) if ui_root != null else null
	if existing != null:
		existing.queue_free()
	var overlay: ColorRect = ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0.025, 0.028, 0.03, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	_add_safe_area_band(overlay)
	return overlay

func _show_inventory(message: String = "", requested_uid: String = "") -> void:
	screen = Screen.CAMP
	run_paused = true
	_play_music("camp")
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	var panel := _make_authored_panel("Camp/EquipmentPanel", Rect2(18.0, 108.0, size.x - 36.0, minf(650.0, size.y - 136.0)), "InventoryPanel")
	ui_root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_panel_content(panel, column)
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
	_sync_active_hero_equipment()
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
	var panel := _make_authored_panel("Camp/DismantleBox", Rect2(20.0, 250.0, size.x - 40.0, 250.0), "DismantlePanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
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
	_sync_active_hero_equipment()
	save.profile.silver = int(save.profile.silver) + salvage_value
	selected_item_uid = ""
	SaveService.save_data(save)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_inventory("Equipment dismantled for %d silver." % salvage_value)

func _skill_cost(rank: int) -> Dictionary:
	return {"silver": 18 + rank * 14, "provisions": 6 + rank * 5}

func _show_skill_tree(message: String = "", branch_index: int = -1) -> void:
	_show_training_tree_screen()
	return

func _show_training_tree_screen() -> void:
	var training_service := TrainingGroundsService.new(save.profile)
	if not training_service.tree_available():
		_show_camp("Construct the Training Grounds before opening the skill tree.")
		return
	screen = Screen.CAMP
	run_paused = true
	_reset_movement_input()
	_play_music("camp")
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	_add_safe_area_band(ui_root)
	var tree_screen := TrainingTreeScreenScene.instantiate() as AshenTrainingTreeScreen
	tree_screen.name = "TrainingGroundsScreen"
	tree_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree_screen.profile_changed.connect(func() -> void:
		SaveService.save_data(save)
		_sync_active_hero_fields()
	)
	tree_screen.closed.connect(_show_camp)
	ui_root.add_child(tree_screen)
	tree_screen.apply_safe_area(safe_area_top)
	tree_screen.bind_profile(save.profile)

func _legacy_show_skill_tree(message: String = "", branch_index: int = -1) -> void:
	screen = Screen.CAMP
	run_paused = true
	if branch_index >= 0:
		skill_tree_branch = branch_index
	var picker_overlay: Node = get_node_or_null("WeaponPickerOverlay")
	if picker_overlay != null:
		picker_overlay.queue_free()
	_play_music("camp")
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	var panel := _make_authored_panel("Camp/ClassTreePanel", Rect2(18.0, 34.0, size.x - 36.0, size.y - 58.0), "SkillTreePanel")
	ui_root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_attach_panel_content(panel, column)
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
			var technique: Dictionary = runtime_techniques[technique_id]
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
	save.profile.company_tree = tree.duplicate(true)
	SaveService.save_data(save)
	_show_skill_tree("%s is now part of company training." % String(node.name))

func _build_run_ui() -> void:
	_clear_ui()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	_add_safe_area_band(ui_root)
	if run_camera_transition < 1.0:
		ui_root.modulate.a = 0.0
		var hud_fade: Tween = ui_root.create_tween()
		hud_fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hud_fade.tween_interval(0.12)
		hud_fade.tween_property(ui_root, "modulate:a", 1.0, 0.38)
	var live_hud := _add_live_hud("run")
	live_hud.bind_run(run_level, player_hp, player_max_hp, run_exploration_silver, run_exploration_provisions, floori(_current_dread()))
	health_bar = live_hud.get_node("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	hud_label = live_hud.get_node("SafeAreaTop/RunTop/HudLabel") as Label
	boss_label = live_hud.get_node("SafeAreaTop/RunTop/BossLabel") as Label
	objective_label = live_hud.get_node("SafeAreaTop/RunTop/ObjectiveLabel") as Label
	pause_button = live_hud.get_node("SafeAreaTop/RunTop/PauseButton") as Button
	pause_button.pressed.connect(_toggle_pause)
	skill_button = live_hud.get_node("RunActions/GuardStepButton") as Button
	skill_button.pressed.connect(_guard_step)
	expedition_interact_button = live_hud.get_node("RunActions/ExpeditionInteractButton") as Button
	expedition_interact_button.visible = false
	expedition_interact_button.disabled = true
	expedition_interact_button.pressed.connect(_interact_with_expedition)
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
	var field_phase: String = "BLACKTHORN MOOR  %s" % _format_time(run_elapsed)
	hud_label.text = "%s  ·  SITES %d/%d  ·  XP %d/%d  ·  %d KILLS" % [field_phase, run_discoveries, exploration_points.size(), run_xp, next_xp, run_kills]
	if is_instance_valid(active_hud_layout):
		active_hud_layout.bind_run(run_level, player_hp, player_max_hp, run_exploration_silver, run_exploration_provisions, floori(_current_dread()))
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
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	var panel := _make_authored_panel("Results/Panel", Rect2(28.0, 130.0, size.x - 56.0, size.y - 230.0), "ResultsPanel")
	ui_root.add_child(panel)
	_bind_authored_results_panel(panel)
	return
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_panel_content(panel, box)
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
	var banked: bool = bool(result_data.get("banked", false))
	var loot_text: String = "EQUIPMENT BANKED: %d%s" % [loot_count, "  ·  %d DISMANTLED" % salvaged_count if salvaged_count > 0 else ""] if banked else "UNSECURED EQUIPMENT LOST: %d" % int(result_data.get("lost_loot", 0))
	box.add_child(_make_label(loot_text, 12, FOLKLORE.lightened(0.15) if banked else BLOOD.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("+%d SILVER     +%d PROVISIONS     +%d HERO XP\nBARROW KEYS BANKED: %d" % [int(result_data.silver), int(result_data.provisions), int(result_data.get("hero_xp", 0)), int(result_data.get("boss_keys", 0))], 14, AMBER.lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER))
	var again: Button = _make_button("MARCH AGAIN", 58.0, BURGUNDY)
	again.pressed.connect(_show_weapon_picker)
	box.add_child(again)
	var camp: Button = _make_button("RETURN TO CAMP", 52.0)
	camp.pressed.connect(_show_camp)
	box.add_child(camp)

func _bind_authored_results_panel(panel: PanelContainer) -> void:
	var content := panel.get_node("ContentRoot") as Control
	var result_heading: String = "THE BARROW IS QUIET" if bool(result_data.victory) else ("THE COMPANY RETURNS" if bool(result_data.get("extracted", false)) else "THE COMPANY WITHDRAWS")
	(content.get_node("ResultHeading") as Label).text = result_heading
	(content.get_node("ResultStats") as Label).text = "Time %s\n%d enemies / %d elites / %d discoveries\nVeteran rating %d%%" % [_format_time(float(result_data.time)), int(result_data.kills), int(result_data.elites), int(result_data.get("discoveries", 0)), roundi(float(result_data.rating) * 100.0)]
	var objective_result: Dictionary = GameContent.OBJECTIVES.get(String(result_data.get("objective", "")), {})
	var contract_result: Dictionary = GameContent.CONTRACTS.get(String(result_data.get("contract", "")), {})
	var objective_text: String = "OBJECTIVE: %s" % GameContent.reward_text(objective_result) if bool(result_data.get("objective_complete", false)) else "OBJECTIVE INCOMPLETE"
	var contract_text: String = "CONTRACT: %s" % GameContent.reward_text(contract_result) if bool(result_data.get("contract_complete", false)) else "NO CONTRACT REWARD"
	(content.get_node("ObjectiveResult") as Label).text = "%s\n%s" % [objective_text, contract_text]
	var doctrine_name: String = String(GameContent.DOCTRINES.get(String(result_data.get("doctrine", active_doctrine)), {}).get("name", active_doctrine))
	var curse_name: String = String(GameContent.CURSES.get(String(result_data.get("curse", active_curse)), {}).get("name", active_curse))
	(content.get_node("DoctrineResult") as Label).text = "%s / %s\nRelics carried: %d" % [doctrine_name.to_upper(), curse_name.to_upper(), relics.size()]
	var loot_count: int = int(result_data.get("stored_loot", 0))
	var salvaged_count: int = int(result_data.get("salvaged_loot", 0))
	var banked: bool = bool(result_data.get("banked", false))
	(content.get_node("LootResult") as Label).text = "EQUIPMENT BANKED: %d%s" % [loot_count, " - %d DISMANTLED" % salvaged_count if salvaged_count > 0 else ""] if banked else "UNSECURED EQUIPMENT LOST: %d" % int(result_data.get("lost_loot", 0))
	(content.get_node("RewardResult") as Label).text = "+%d SILVER     +%d PROVISIONS     +%d HERO XP\nBARROW KEYS BANKED: %d" % [int(result_data.silver), int(result_data.provisions), int(result_data.get("hero_xp", 0)), int(result_data.get("boss_keys", 0))]
	var again := content.get_node("MarchAgainButton") as Button
	again.pressed.connect(_show_weapon_picker)
	var camp := content.get_node("ReturnToCampButton") as Button
	camp.pressed.connect(_show_camp)

func _show_settings() -> void:
	screen = Screen.SETTINGS
	_clear_ui()
	# Use explicit anchors here instead of a MarginContainer. On the web
	# renderer, this long form can otherwise retain the panel's tiny minimum
	# size after its children are added, leaving only the black scene overlay.
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = theme_main
	add_child(ui_root)
	ui_root.z_index = 100
	_add_safe_area_band(ui_root)
	var panel := _make_authored_panel("Settings/Panel", Rect2(22.0, 52.0, size.x - 44.0, size.y - safe_area_top - 84.0), "SettingsPanel")
	panel.position.y += safe_area_top
	ui_root.add_child(panel)
	# These are the nodes authored in settings_menu_layout.tscn.  The running
	# game binds values and signals to them; it does not create a second menu.
	var content := panel.get_node("ContentRoot") as Control
	var music: HSlider = content.get_node("MusicSlider") as HSlider
	var sfx: HSlider = content.get_node("SfxSlider") as HSlider
	var effects: HSlider = content.get_node("EffectsSlider") as HSlider
	for slider: HSlider in [music, sfx, effects]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
	music.value = float(save.settings.music)
	sfx.value = float(save.settings.sfx)
	effects.value = float(save.settings.effect_density)
	music.value_changed.connect(_setting_slider_changed.bind("music"))
	sfx.value_changed.connect(_setting_slider_changed.bind("sfx"))
	effects.value_changed.connect(_setting_slider_changed.bind("effect_density"))
	var shake := content.get_node("ScreenShakeToggle") as CheckButton
	shake.button_pressed = bool(save.settings.screen_shake)
	shake.toggled.connect(_setting_toggle_changed.bind("screen_shake"))
	var handed := content.get_node("LeftHandedToggle") as CheckButton
	handed.button_pressed = bool(save.settings.left_handed)
	handed.toggled.connect(_setting_toggle_changed.bind("left_handed"))
	var collision_debug := content.get_node("CollisionDebugToggle") as CheckButton
	collision_debug.button_pressed = bool(save.settings.get("collision_debug", false))
	collision_debug.toggled.connect(_setting_toggle_changed.bind("collision_debug"))
	var gate_confirmations := content.get_node("GateConfirmationsToggle") as CheckButton
	gate_confirmations.button_pressed = _gate_confirmations_enabled()
	gate_confirmations.toggled.connect(_setting_toggle_changed.bind("gate_confirmations"))
	var save_text := content.get_node("SaveText") as TextEdit
	var export_button := content.get_node("ExportButton") as Button
	export_button.pressed.connect(_export_save.bind(save_text))
	var import_button := content.get_node("ImportButton") as Button
	import_button.pressed.connect(_import_save.bind(save_text))
	var reload_button := content.get_node("ReloadAppButton") as Button
	reload_button.pressed.connect(_reload_app)
	var reset_button := content.get_node("ResetSaveButton") as Button
	reset_button.pressed.connect(_show_reset_save_confirmation)
	status_label = content.get_node("SettingsStatus") as Label
	var back := content.get_node("BackButton") as Button
	back.pressed.connect(_show_camp)
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

func _show_reset_save_confirmation() -> void:
	var overlay: ColorRect = _make_camp_overlay("ResetSaveOverlay")
	var panel := _make_authored_panel("Modal/ResetConfirmation", Rect2(30.0, 286.0, 330.0, 272.0), "ResetSavePanel")
	overlay.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_attach_panel_content(panel, box)
	box.add_child(_make_label("RESET ALL PROGRESS?", 22, BLOOD.lightened(0.28), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("This permanently removes currencies, buildings, heroes, equipment, skills and active expedition data.\n\nYour audio, controls and accessibility settings will be kept.", 12, PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var cancel: Button = _make_button("NO, KEEP SAVE", 52.0)
	cancel.name = "CancelResetSaveButton"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(overlay.queue_free)
	row.add_child(cancel)
	var confirm: Button = _make_button("YES, RESET", 52.0, BLOOD.darkened(0.18))
	confirm.name = "ConfirmResetSaveButton"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_reset_game_progress.bind(overlay))
	row.add_child(confirm)
	box.add_child(row)

func _reset_game_progress(overlay: Control) -> void:
	var preserved_settings: Dictionary = save.get("settings", {}).duplicate(true)
	var fresh_save: Dictionary = SaveService.reset_data(preserved_settings)
	if fresh_save.is_empty():
		if is_instance_valid(overlay):
			overlay.queue_free()
		if is_instance_valid(status_label):
			status_label.text = "The save could not be reset."
		return
	for enemy: EnemyState in camp_wanderers:
		enemy_pool.append(enemy)
	camp_wanderers.clear()
	if is_instance_valid(overlay):
		overlay.queue_free()
	save = fresh_save
	_clear_run_state()
	result_data.clear()
	_sync_active_hero_fields()
	generated_region = RegionGeneratorService.generate_blackthorn(int(save.profile.get("region_seed", 41041)))
	_cache_region_blockers()
	_sync_structure_anchors()
	_configure_world()
	camp_uses_field_camera = false
	_update_audio_volumes()
	_show_camp("A new company begins.")

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
	active_hud_layout = null
	hud_layout_data = null
	camp_interact_button = null
	expedition_interact_button = null
	camp_hotspot_buttons.clear()

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

func _exit_tree() -> void:
	# Explicitly release audio streams before the world tree is torn down. This
	# matters for repeated headless sessions and PWA reloads, where the audio
	# backend may otherwise retain the last decoded stream until process exit.
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for player: AudioStreamPlayer in sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	sfx_players.clear()
	sfx_streams.clear()

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


func _camp_display_max_health() -> float:
	var training: int = int(save.get("profile", {}).get("training_level", 0))
	var result: float = 100.0 * (1.0 + float(training) / 5.0 * 0.15)
	result += _equipment_total("health") + _class_total("health")
	return maxf(1.0, result)


func _apply_reference_button_frame(button: Button) -> void:
	if reference_action_button_texture == null:
		return
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var frame := StyleBoxTexture.new()
		frame.texture = reference_action_button_texture
		frame.texture_margin_left = 8.0
		frame.texture_margin_right = 8.0
		frame.texture_margin_top = 8.0
		frame.texture_margin_bottom = 8.0
		frame.modulate_color = Color(1.0, 1.0, 1.0, 0.48) if state == "disabled" else (Color(0.88, 0.76, 0.72, 1.0) if state == "pressed" else Color.WHITE)
		button.add_theme_stylebox_override(state, frame)

func _format_time(seconds: float) -> String:
	var safe: int = maxi(0, floori(seconds))
	return "%02d:%02d" % [safe / 60, safe % 60]

func _point_over_action_button(point: Vector2) -> bool:
	return (skill_button != null and skill_button.get_global_rect().has_point(point)) or (pause_button != null and pause_button.get_global_rect().has_point(point)) or (expedition_interact_button != null and expedition_interact_button.visible and expedition_interact_button.get_global_rect().has_point(point))

func _point_over_camp_action_button(point: Vector2) -> bool:
	if camp_interact_button != null and camp_interact_button.visible and camp_interact_button.get_global_rect().has_point(point):
		return true
	if is_instance_valid(active_hud_layout):
		var settings_button := active_hud_layout.get_node_or_null("SafeAreaTop/SettingsCogButton") as Button
		if settings_button != null and settings_button.visible and settings_button.get_global_rect().has_point(point):
			return true
	return false

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
	var draw_bounds: Rect2 = _visible_world_rect().grow(96.0)
	_draw_frontier_gate()
	for point: ExplorationPoint in exploration_points:
		if draw_bounds.has_point(point.position):
			_draw_exploration_point(point)
	for hazard: HazardState in hazards:
		if not draw_bounds.has_point(hazard.position):
			continue
		var hazard_color: Color = Color(FOLKLORE, 0.18 if not hazard.triggered else 0.32)
		draw_circle(hazard.position + shake_offset, hazard.radius, hazard_color)
		draw_arc(hazard.position + shake_offset, hazard.radius, 0.0, TAU, 28, FOLKLORE, 2.0)
	for trap: TrapState in traps:
		if not draw_bounds.has_point(trap.position):
			continue
		if trap.kind == "ember":
			draw_circle(trap.position + shake_offset, trap.radius, Color(FOLKLORE, 0.12))
			draw_arc(trap.position + shake_offset, trap.radius, 0.0, TAU, 18, Color(FOLKLORE, 0.65), 2.0)
		else:
			_draw_trap(trap.position + shake_offset, trap.radius)
	for pickup: PickupState in pickups:
		if not draw_bounds.has_point(pickup.position):
			continue
		var pos: Vector2 = pickup.position + shake_offset
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -5), pos + Vector2(4, 0), pos + Vector2(0, 5), pos + Vector2(-4, 0)]), AMBER)
	for projectile: ProjectileState in projectiles:
		if not draw_bounds.has_point(projectile.position):
			continue
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
		if draw_bounds.has_point(enemy.position):
			_draw_enemy(enemy, shake_offset)
	for effect: EffectState in effects:
		if not draw_bounds.has_point(effect.position):
			continue
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
		if draw_bounds.has_point(item.position):
			draw_string(font, item.position + shake_offset, item.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 13, Color(item.color, clampf(item.life / 0.7, 0.0, 1.0)))

func _draw_frontier_gate() -> void:
	var position: Vector2 = _frontier_gate_position()
	var gate: Texture2D = foundation_wall_textures.get("town_gate") as Texture2D
	if gate != null:
		draw_texture_rect(gate, Rect2(position - Vector2(64.0, 72.0), Vector2(128.0, 80.0)), false, Color(0.62, 0.68, 0.66))
	var unlocked: bool = save.profile.get("unlocked_biomes", []).has("gloamwood")
	var label: String = "GLOAMWOOD OPEN" if unlocked else "FRONTIER SEALED  -  BARROW KEY + RESTORATION"
	draw_string(theme_main.default_font, position + Vector2(-120.0, -82.0), label, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 10, FOLKLORE if unlocked else PARCHMENT_DARK)
	if not unlocked:
		draw_circle(position + Vector2(0.0, -32.0), 10.0, Color(0.08, 0.09, 0.10, 0.9))
		draw_arc(position + Vector2(0.0, -32.0), 10.0, 0.0, TAU, 16, AMBER, 2.0)

func _draw_run_controls() -> void:
	# The same invisible floating drag used in town drives expeditions.
	pass

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
	var direction: String = _hero_facing_direction(last_move_vector)
	var texture_key: String = "%s_%s" % [active_class, direction]
	var texture: Texture2D = hero_animation_textures.get(texture_key) as Texture2D
	if texture != null:
		var frame_size := Vector2(texture.get_width() / 6.0, texture.get_height())
		var frame: int = 2 + int(floor(run_elapsed * 8.0)) % 4 if moving else int(floor(run_elapsed * 2.0)) % 2
		var target := Rect2(Vector2(pos.x - frame_size.x * 0.5 + attack_push.x, pos.y - frame_size.y + 7.0 + attack_push.y).round(), frame_size)
		draw_texture_rect_region(texture, target, Rect2(frame * frame_size.x, 0.0, frame_size.x, frame_size.y))
	else:
		texture = foundation_hero_textures.get(texture_key) as Texture2D
		if texture != null:
			var texture_size: Vector2 = texture.get_size()
			var sprite_scale: Vector2 = Vector2(1.0 - gait * 0.035, 1.0 + gait * 0.035)
			var draw_size: Vector2 = texture_size * sprite_scale
			var sway: float = roundf(gait * 0.75) if moving else 0.0
			draw_texture_rect(texture, Rect2(Vector2(pos.x - draw_size.x * 0.5 + sway + attack_push.x, pos.y - draw_size.y + 7.0 + bob + attack_push.y).round(), draw_size), false)
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
	var animation_time: float = camp_elapsed if screen == Screen.CAMP else run_elapsed
	var gait: float = sin(animation_time * gait_rate + float(enemy.uid) * 0.73)
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
	var focus_position: Vector2 = camp_player_position if screen == Screen.CAMP else player_position
	var facing: String = "right" if focus_position.x >= enemy.position.x else "left"
	var texture: Texture2D = enemy_animation_textures.get(enemy.id) as Texture2D
	var health_bar_y: float = pos.y - enemy.radius - 11.0
	if texture != null:
		var frame_size := Vector2(texture.get_width() / 4.0, texture.get_height())
		var frame: int = int(floor(animation_time * gait_rate + float(enemy.uid) * 0.73)) % 4
		var bob: float = roundf(gait * (2.8 if enemy.kind == "crow" else 1.8))
		var sprite_scale: Vector2 = Vector2(1.0 - gait * 0.035, 1.0 + gait * 0.035)
		if enemy.kind == "crow":
			sprite_scale = Vector2(1.0 + absf(gait) * 0.05, 0.88 + (gait + 1.0) * 0.06)
		var draw_size: Vector2 = frame_size * sprite_scale
		var sway: float = roundf(gait * 0.65) if enemy.kind != "crow" else 0.0
		draw_texture_rect_region(texture, Rect2(Vector2(pos.x - draw_size.x * 0.5 + sway, pos.y - draw_size.y * 0.70 + bob).round(), draw_size), Rect2(frame * frame_size.x, 0.0, frame_size.x, frame_size.y))
		health_bar_y = pos.y - draw_size.y * 0.70 - 5.0
	else:
		texture = actor_textures.get("%s_%s" % [enemy.id, facing]) as Texture2D
		if texture != null:
			var texture_size: Vector2 = texture.get_size()
			var bob: float = roundf(gait * (2.8 if enemy.kind == "crow" else 1.8))
			var sprite_scale: Vector2 = Vector2(1.0 - gait * 0.035, 1.0 + gait * 0.035)
			var draw_size: Vector2 = texture_size * sprite_scale
			draw_texture_rect(texture, Rect2(Vector2(pos.x - draw_size.x * 0.5, pos.y - draw_size.y * 0.70 + bob).round(), draw_size), false)
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
	if camp_layout_data != null and camp_layout_data.has_anchor(0, structure_id):
		var authored_anchor: Vector2 = camp_layout_data.anchor_for(0, structure_id)
		var authored_sprite: Dictionary = camp_layout_data.structure_sprite_properties(0, structure_id)
		if not authored_sprite.is_empty():
			return _authored_sprite_rect(_world_map_point(authored_anchor), authored_anchor, texture, authored_sprite)
	var layout: Dictionary = CAMP_STRUCTURE_LAYOUT[structure_id]
	var anchor: Vector2 = _centered_camp_anchor(structure_id)
	var draw_height: float = float(layout.height)
	if camp_structure_definitions.has(structure_id):
		var definition: StructureDefinition = camp_structure_definitions[structure_id]
		anchor = definition.anchor
		draw_height = definition.draw_height
	var texture_size: Vector2 = texture.get_size()
	if structure_id == "veterans_hall":
		draw_height = texture_size.y
	var draw_width: float = draw_height * texture_size.x / maxf(1.0, texture_size.y)
	return Rect2(Vector2(anchor.x - draw_width * 0.5, anchor.y - draw_height), Vector2(draw_width, draw_height))

func _authored_sprite_rect(world_anchor: Vector2, reference_anchor: Vector2, texture: Texture2D, sprite: Dictionary) -> Rect2:
	var local_position: Vector2 = Vector2(sprite.get("position", Vector2.ZERO))
	var world_delta: Vector2 = _world_map_point(reference_anchor + local_position) - _world_map_point(reference_anchor)
	var sprite_scale: Vector2 = Vector2(sprite.get("scale", Vector2.ONE))
	var draw_size := texture.get_size() * Vector2(absf(sprite_scale.x), absf(sprite_scale.y))
	var offset: Vector2 = Vector2(sprite.get("offset", Vector2.ZERO)) * sprite_scale
	var top_left: Vector2 = world_anchor + world_delta + offset
	if bool(sprite.get("centered", true)):
		top_left -= draw_size * 0.5
	return Rect2(top_left, draw_size)

func _authored_flip_h(sprite: Dictionary) -> bool:
	return bool(sprite.get("flip_h", false)) or float(Vector2(sprite.get("scale", Vector2.ONE)).x) < 0.0

func _authored_flip_v(sprite: Dictionary) -> bool:
	return bool(sprite.get("flip_v", false)) or float(Vector2(sprite.get("scale", Vector2.ONE)).y) < 0.0

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

func _draw_construction_plot(plot_id: String) -> void:
	if camp_construction_plot_texture == null or not CAMP_PLOT_LAYOUT.has(plot_id):
		return
	var plot_sprite: Dictionary = camp_layout_data.plot_sprite_properties(0, plot_id) if camp_layout_data != null and camp_layout_data.has_plot(0, plot_id) else {}
	var rect: Rect2
	if not plot_sprite.is_empty():
		var plot_reference: Vector2 = camp_layout_data.plot_anchor(0, plot_id)
		rect = _authored_sprite_rect(_plot_anchor(plot_id), plot_reference, camp_construction_plot_texture, plot_sprite)
	else:
		var texture_size: Vector2 = camp_construction_plot_texture.get_size()
		var draw_height: float = minf(76.0, texture_size.y)
		var draw_width: float = draw_height * texture_size.x / maxf(1.0, texture_size.y)
		rect = Rect2(_plot_anchor(plot_id) - Vector2(draw_width * 0.5, draw_height), Vector2(draw_width, draw_height))
	if camp_highlighted_structure == plot_id and camp_construction_plot_outline != null:
		draw_texture_rect(camp_construction_plot_outline, rect, false)
	draw_texture_rect(camp_construction_plot_texture, rect, false, Color(0.88, 0.84, 0.72, 0.94))

func _draw_camp_buildings() -> void:
	var veterans: Texture2D = _camp_tier_texture("veterans_hall", _town_level())
	var campfire: Texture2D = camp_landmark_textures.get("campfire") as Texture2D
	var veterans_outline: Texture2D = _camp_tier_outline_texture("veterans_hall", _town_level())
	var campfire_outline: Texture2D = camp_landmark_outline_textures.get("campfire") as Texture2D
	# Draw from the far side of camp toward the gate so lower structures overlap
	# higher ones naturally in the three-quarter perspective.
	_draw_camp_structure("veterans_hall", veterans, veterans_outline)
	for plot_id: String in _revealed_plot_ids().slice(0, 2):
		var building: String = _building_for_plot(plot_id)
		if not building.is_empty() and _is_constructed(building):
			_draw_camp_structure(building, _camp_tier_texture(building, _structure_tier(building)), _camp_tier_outline_texture(building, _structure_tier(building)))
		elif _is_plot_visible(plot_id):
			_draw_construction_plot(plot_id)
	_draw_camp_structure("campfire", campfire, campfire_outline)
	for plot_id: String in _revealed_plot_ids().slice(2):
		var building: String = _building_for_plot(plot_id)
		if not building.is_empty() and _is_constructed(building):
			_draw_camp_structure(building, _camp_tier_texture(building, _structure_tier(building)), _camp_tier_outline_texture(building, _structure_tier(building)))
		elif _is_plot_visible(plot_id):
			_draw_construction_plot(plot_id)
