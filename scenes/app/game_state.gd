extends Control

const GameContent = preload("res://src/content.gd")
const GameRules = preload("res://src/rules.gd")
const SaveService = preload("res://src/save_service.gd")
const StructureDefinitionResource = preload("res://src/foundation/structure_definition.gd")
const RegionGeneratorService = preload("res://src/services/region_generator.gd")
const Expedition = preload("res://src/services/expedition_service.gd")
const Roster = preload("res://src/services/roster_service.gd")
const TerrainLayerScene = preload("res://scenes/world/terrain/blackthorn_terrain.tscn")
const RenderTheme = preload("res://src/render/render_theme.gd")
const HudLayoutScene = preload("res://scenes/ui/hud/hud.tscn")
const ScreenHostScene = preload("res://scenes/ui/screen_host.tscn")
const CanonicalUiTheme = preload("res://scenes/ui/theme/ashen_ui_theme.tres")
const SafeAreaBandScene = preload("res://scenes/ui/components/safe_area_band.tscn")
const SettingsScreenScene = preload("res://scenes/ui/screens/settings_screen.tscn")
const TrainingTreeScreenScene = preload("res://scenes/ui/screens/training_tree_screen.tscn")
const ArsenalScreenScene = preload("res://scenes/ui/screens/arsenal_screen.tscn")
const ResultsScreenScene = preload("res://scenes/ui/screens/results_screen.tscn")
const GateConfirmationScene = preload("res://scenes/ui/overlays/gate_confirmation_overlay.tscn")
const ResetConfirmationScene = preload("res://scenes/ui/overlays/reset_confirmation_overlay.tscn")
const LevelUpOverlayScene = preload("res://scenes/ui/overlays/level_up_overlay.tscn")
const RelicChoiceOverlayScene = preload("res://scenes/ui/overlays/relic_choice_overlay.tscn")
const HallScreenScene = preload("res://scenes/ui/screens/hall_screen.tscn")
const BuildingDetailScreenScene = preload("res://scenes/ui/screens/building_detail_screen.tscn")
const ConstructionScreenScene = preload("res://scenes/ui/screens/construction_screen.tscn")
const ClassTrainingScreenScene = preload("res://scenes/ui/screens/class_training_screen.tscn")
const ExpeditionAssignmentsScreenScene = preload("res://scenes/ui/screens/expedition_assignments_screen.tscn")
const InventoryScreenScene = preload("res://scenes/ui/screens/inventory_screen.tscn")
const ContractChoiceOverlayScene = preload("res://scenes/ui/overlays/contract_choice_overlay.tscn")
const DismantleConfirmationScene = preload("res://scenes/ui/overlays/dismantle_confirmation_overlay.tscn")
const ActorPresentationScene = preload("res://scenes/actors/actor_presentation_controller.tscn")
const CombatPresentationScene = preload("res://scenes/combat/combat_presentation_controller.tscn")
const WorldPresentationScene = preload("res://scenes/world/world_presentation_controller.tscn")
const CollisionDebugScene = preload("res://scenes/world/debug/collision_debug.tscn")
const TrainingContent = preload("res://src/content/training_grounds_content.gd")
const ArsenalService = preload("res://src/services/arsenal_service.gd")
const TrainingGroundsService = preload("res://src/services/training_grounds_service.gd")
const UpgradeOfferService = preload("res://src/services/upgrade_offer_service.gd")
const CombatStats = preload("res://src/services/combat_stat_service.gd")
const CombatStatusService = preload("res://src/services/status_service.gd")
const EnvironmentInteractions = preload("res://src/services/environment_interaction_service.gd")
const EnemyState = preload("res://src/state/enemy_state.gd")
const ProjectileState = preload("res://src/state/projectile_state.gd")
const PickupState = preload("res://src/state/pickup_state.gd")
const TrapState = preload("res://src/state/trap_state.gd")
const HazardState = preload("res://src/state/hazard_state.gd")
const FloatTextState = preload("res://src/state/float_text_state.gd")
const EffectState = preload("res://src/state/effect_state.gd")
const ExplorationPoint = preload("res://src/state/exploration_point.gd")
const AuthoredCampTierScenes: Array[PackedScene] = [
	preload("res://scenes/world/camp/camp_tier_0.tscn"),
	preload("res://scenes/world/camp/camp_tier_1.tscn"),
	preload("res://scenes/world/camp/camp_tier_2.tscn"),
	preload("res://scenes/world/camp/camp_tier_3.tscn"),
	preload("res://scenes/world/camp/camp_tier_4.tscn"),
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

const CAMP_INTERACTION_RADIUS: float = 74.0
const CAMP_WALK_SPEED: float = 104.0
# The original content occupies a three-by-four screen field. Keep that
# authored area at its native scale, then add one full screen of moor on every
# side so the camp is a true four-direction starting hub.
const WORLD_CONTENT_WIDTH_SCREENS: float = 3.0
const WORLD_CONTENT_HEIGHT_SCREENS: float = 4.0
const WORLD_WIDTH_SCREENS: float = 5.0
const WORLD_HEIGHT_SCREENS: float = 6.0
const FIELD_START_DISTANCE: float = 72.0
const RUN_CAMERA_TRANSITION_SECONDS: float = 1.0
const ENEMY_SPAWN_VIEW_MARGIN: float = 96.0
const MAX_CAMP_WANDERERS: int = 10
const MIN_CAMP_WANDERERS: int = 4

var screen: Screen = Screen.CAMP
var save: Dictionary = {}
var result_data: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var theme_main: Theme = CanonicalUiTheme
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
var audio_controller: AshenAudioController
var ui_controller: AshenUiController

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
## Web/PWA pages are often suspended instead of being destroyed when the
## user closes the installed app.  Keep a small amount of lifecycle state so
## the first frame after returning can rebuild the interactive state rather
## than leaving a stale, paused camera/UI at the camp gate.
var app_suspended_for_focus: bool = false
var resume_run_after_focus: bool = false
var recover_camp_after_focus: bool = false
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
var safe_area_top: float = 0.0
var world_root: Node2D
var terrain_layer: AshenTerrainLayer
var actor_presentation: Node2D
var combat_presentation: Node2D
var world_presentation: Node2D
var world_tint: ColorRect
var collision_debug_scene: Node2D
var active_camp_scene: AshenCampRuntime
var static_visual_signature: String = ""
var cached_town_bounds_world: Rect2 = Rect2()
var cached_town_bounds_level: int = -1
var hud_layout_data: AshenHudLayout
# GameContent keeps the original catalogue as immutable constants for legacy
# compatibility.  The rebuilt Training Grounds adds canonical IDs to these
# private mutable copies instead of attempting to mutate the constants.
var runtime_weapons: Dictionary = GameContent.WEAPONS.duplicate(true)
var runtime_techniques: Dictionary = GameContent.TECHNIQUES.duplicate(true)


# Virtual compatibility surface. Implementations live in the responsibility scripts
# that derive from this state container. These stubs keep cross-controller calls typed
# while the foundation is migrated without changing gameplay behavior.

func _ready() -> void:
	pass

func _notification(what: int) -> void:
	pass

func _recover_after_focus() -> void:
	pass

func _recover_camp_arrival() -> void:
	pass

func _refresh_safe_area_inset() -> void:
	pass

func _add_safe_area_band(parent: Control) -> void:
	pass

func _add_live_hud(mode: String) -> AshenHudLayout:
	return null

func _process(delta: float) -> void:
	pass

func _sync_actor_presentation() -> void:
	pass

func _sync_camp_authored_state() -> void:
	pass

func _update_arrival_crest(delta: float) -> void:
	pass

func _configure_world() -> void:
	pass

func _setup_visual_layers() -> void:
	pass

func _visual_state_signature() -> String:
	return ""

func _sync_visual_layers(force: bool = false) -> void:
	pass

func _sync_authored_camp_scene(force: bool = false) -> void:
	pass

func _sync_structure_definitions_from_authored_camp() -> void:
	pass

func _point_hits_refuge_forest(position: Vector2, clearance: float = 0.0) -> bool:
	return false

func _town_tile_kind(world_position: Vector2) -> String:
	return ""

func tile_hash(tile: Vector2i) -> int:
	return 0

func _world_map_point(reference_point: Vector2) -> Vector2:
	return Vector2.ZERO

func _camp_boundary_world() -> PackedVector2Array:
	return PackedVector2Array()

func _town_level() -> int:
	return 0

func _town_definition() -> Dictionary:
	return {}

func _camp_tier_metadata(tier: int) -> Dictionary:
	return {}

func _town_capacity() -> int:
	return 0

func _town_bounds_world() -> Rect2:
	return Rect2()

func _visible_camp_decor() -> Array[Dictionary]:
	return []

func _camp_decor_footprint(entry: Dictionary, clearance: float = 0.0) -> Rect2:
	return Rect2()

func _point_hits_camp_decor(position: Vector2, clearance: float = 0.0) -> bool:
	return false

func _constructed_buildings() -> Array:
	return []

func _is_constructed(structure_id: String) -> bool:
	return false

func _constructed_count() -> int:
	return 0

func _has_open_building_slot() -> bool:
	return false

func _building_plots() -> Dictionary:
	return {}

func _revealed_plot_ids() -> Array[String]:
	return []

func _plot_anchor(plot_id: String) -> Vector2:
	return Vector2.ZERO

func _plot_interaction_polygon_world(plot_id: String) -> PackedVector2Array:
	return PackedVector2Array()

func _building_for_plot(plot_id: String) -> String:
	return ""

func _plot_for_building(building: String) -> String:
	return ""

func _is_plot_visible(plot_id: String) -> bool:
	return false

func _first_open_plot() -> String:
	return ""

func _sync_structure_anchors() -> void:
	pass

func _visible_world_rect() -> Rect2:
	return Rect2()

func _update_world_camera(focus: Vector2, safe_town: bool, instant: bool = false) -> void:
	pass

func _camp_gate_position() -> Vector2:
	return Vector2.ZERO

func _camp_gate_safe_center() -> Vector2:
	return Vector2.ZERO

func _camp_gate_safe_zone_contains(position: Vector2, radius: float = 0.0) -> bool:
	return false

func _camp_gate_safe_exit_position(position: Vector2, radius: float) -> Vector2:
	return Vector2.ZERO

func _centered_camp_anchor(structure_id: String) -> Vector2:
	return Vector2.ZERO

func _input(event: InputEvent) -> void:
	pass

func _camp_hub_active() -> bool:
	return false

func _process_camp(delta: float) -> void:
	pass

func _camp_position_blocked(position: Vector2) -> bool:
	return false

func _safe_camp_spawn_position() -> Vector2:
	return Vector2.ZERO

func _structure_tier(structure_id: String) -> int:
	return 0

func _point_hits_camp_fence(position: Vector2) -> bool:
	return false

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	return 0.0

func _camp_interaction_position(target: String) -> Vector2:
	return Vector2.ZERO

func _camp_hit_rect_world(structure_id: String) -> Rect2:
	return Rect2()

func _nearest_camp_interaction() -> String:
	return ""

func _camp_interaction_text(target: String) -> String:
	return ""

func _update_camp_interact_button() -> void:
	pass

func _interact_with_camp_target() -> void:
	pass

func _on_authored_camp_structure_tapped(structure_id: String) -> void:
	pass

func _on_authored_camp_structure_hovered(structure_id: String, hovered: bool) -> void:
	pass

func _begin_expedition_from_gate() -> void:
	pass

func _confirm_begin_expedition(overlay: Control) -> void:
	pass

func _gate_confirmation_open() -> bool:
	return false

func _gate_confirmations_enabled() -> bool:
	return false

func _show_gate_confirmation(departing: bool) -> void:
	pass

func _cancel_gate_confirmation(overlay: Control, departing: bool) -> void:
	pass

func _confirm_finish_run(overlay: Control) -> void:
	pass

func _process_run(delta: float) -> void:
	pass

func _update_player(delta: float) -> void:
	pass

func _run_position_blocked(position: Vector2) -> bool:
	return false

func _sync_collision_debug_scene() -> void:
	pass

func _frontier_gate_position() -> Vector2:
	return Vector2.ZERO

func _current_dread() -> float:
	return 0.0

func _generate_exploration_points() -> void:
	pass

func _update_exploration() -> void:
	pass

func _interact_with_expedition() -> void:
	pass

func _update_wave(delta: float) -> void:
	pass

func _choose_wave_enemy() -> String:
	return ""

func _choose_objective() -> String:
	return ""

func _update_objective(delta: float) -> void:
	pass

func _spawn_enemy(enemy_id: String, special: bool) -> void:
	pass

func _configure_enemy_state(enemy: EnemyState, enemy_id: String, special: bool, dread: float) -> void:
	pass

func _random_edge_position(radius: float = 10.0) -> Vector2:
	return Vector2.ZERO

func _edge_spawn_candidate(side: int, spawn_bounds: Rect2, town_exclusion: Rect2, edge_ratio: float) -> Vector2:
	return Vector2.ZERO

func _update_weapons(delta: float) -> void:
	pass

func _update_techniques(delta: float) -> void:
	pass

func _fire_training_technique(technique_id: String, rank: int) -> void:
	pass

func _damage_training_area(center: Vector2, radius: float, damage: float, melee: bool, status: String, source: String) -> void:
	pass

func _spawn_training_zone(position: Vector2, radius: float, damage: float, duration: float, kind: String, source_ability: String = "") -> void:
	pass

func _apply_environment_ability(ability_id: String, center: Vector2, radius: float) -> void:
	pass

func _region_cell_at(world_position: Vector2) -> Vector2i:
	return Vector2i.ZERO

func _environment_tags_at(world_position: Vector2) -> Array[String]:
	return []

func _weapon_rank_total(weapon_id: String, stat: String) -> float:
	return 0.0

func _weapon_mastery_total(weapon_id: String, stat: String) -> float:
	return 0.0

func _fire_weapon(weapon_id: String) -> void:
	pass

func _fire_spectral_thrust(weapon_id: String, direction: Vector2, damage: float, reach: float, status: String) -> void:
	pass

func _configure_ranked_projectile(projectile: ProjectileState, weapon_id: String, progress: Dictionary, attack_number: int, index: int, count: int) -> void:
	pass

func _update_duelist_momentum(tags: Array) -> void:
	pass

func _spawn_player_projectile(weapon_id: String, direction: Vector2, damage: float, pierce: int, splash_radius: float, status: String = "", target_uid: int = -1) -> ProjectileState:
	return null

func _update_training_movement_state(delta: float) -> void:
	pass

func _update_combat_statuses(delta: float) -> void:
	pass

func _tick_target_cooldowns(cooldowns: Dictionary, delta: float) -> void:
	pass

func _update_static_field() -> void:
	pass

func _ability_progress(ability_id: String, rank: int) -> Dictionary:
	return {}

func _apply_combat_status(enemy: EnemyState, requested_status: String, source_ability: String, hit_damage: float) -> void:
	pass

func _update_environment_states(delta: float) -> void:
	pass

func _update_enemies(delta: float) -> void:
	pass

func _eject_enemy_from_town(enemy: EnemyState) -> void:
	pass

func _disperse_enemy_from_camp_gate(enemy: EnemyState) -> void:
	pass

func _enemy_town_exclusion_rect(radius: float = 0.0) -> Rect2:
	return Rect2()

func _handoff_run_enemies_to_camp() -> void:
	pass

func _ensure_camp_wanderers() -> void:
	pass

func _update_camp_wanderers(delta: float) -> void:
	pass

func _activate_camp_wanderers_for_run() -> void:
	pass

func _move_enemy_with_collision(enemy: EnemyState, movement: Vector2) -> void:
	pass

func _move_archer_toward_line_of_sight(enemy: EnemyState, direction: Vector2, delta: float) -> void:
	pass

func _update_enemy_flow_field(delta: float) -> void:
	pass

func _flow_cell_open(cell: Vector2i) -> bool:
	return false

func _enemy_direct_path_clear(from_position: Vector2, to_position: Vector2, radius: float) -> bool:
	return false

func _enemy_flow_direction(enemy: EnemyState) -> Vector2:
	return Vector2.ZERO

func _path_cell_for_position(position: Vector2) -> Vector2i:
	return Vector2i.ZERO

func _path_cell_center(cell: Vector2i) -> Vector2:
	return Vector2.ZERO

func _path_cell_open(cell: Vector2i, radius: float) -> bool:
	return false

func _enemy_position_blocked(position: Vector2, radius: float) -> bool:
	return false

func _region_position_blocked(position: Vector2, radius: float) -> bool:
	return false

func _cache_region_blockers() -> void:
	pass

func _enemy_inside_playable_bounds(enemy: EnemyState) -> bool:
	return false

func _spawn_enemy_bolt(origin: Vector2, direction: Vector2, damage: float) -> void:
	pass

func _rebuild_spatial_grid() -> void:
	pass

func _nearby_enemies(position: Vector2) -> Array[EnemyState]:
	return []

func _update_projectiles(delta: float) -> void:
	pass

func _projectile_path_blocked(from_position: Vector2, to_position: Vector2, radius: float) -> bool:
	return false

func _projectile_block_point(from_position: Vector2, to_position: Vector2, radius: float) -> Vector2:
	return Vector2.ZERO

func _resolve_projectile_environment_hit(projectile: ProjectileState, previous_position: Vector2, block_point: Vector2) -> bool:
	return false

func _update_traps(delta: float) -> void:
	pass

func _spawn_ember_zone(position: Vector2, damage: float) -> void:
	pass

func _update_hazards(delta: float) -> void:
	pass

func _update_pickups(delta: float) -> void:
	pass

func _update_feedback(delta: float) -> void:
	pass

func _damage_enemy(enemy: EnemyState, raw_damage: float, melee: bool, status: String = "", source_weapon: String = "") -> void:
	pass

func _damage_player(raw_damage: float) -> void:
	pass

func _kill_enemy(enemy: EnemyState) -> void:
	pass

func _roll_equipment_drop(boss_drop: bool) -> void:
	pass

func _spawn_pickup(position: Vector2, value: int) -> void:
	pass

func _recycle_projectile(projectile: ProjectileState) -> void:
	pass

func _recycle_pickup(pickup: PickupState) -> void:
	pass

func _find_nearest_enemy(from: Vector2) -> EnemyState:
	return null

func _find_nearest_enemies(from: Vector2, count: int) -> Array[EnemyState]:
	return []

func _find_enemy_by_uid(uid: int) -> EnemyState:
	return null

func _guard_step() -> void:
	pass

func _build_structure_definitions() -> void:
	pass

func _active_hero() -> Dictionary:
	return {}

func _sync_active_hero_fields() -> void:
	pass

func _sync_active_hero_equipment() -> void:
	pass

func _technique_total(stat: String) -> float:
	return 0.0

func _equipment_total(stat: String) -> float:
	return 0.0

func _doctrine_total(stat: String) -> float:
	return 0.0

func _class_total(stat: String) -> float:
	return 0.0

func _relic_total(stat: String) -> float:
	return 0.0

func _run_boon_total(stat: String) -> float:
	return 0.0

func _training_total(stat: String) -> float:
	return 0.0

func _refresh_training_modifier_cache() -> void:
	pass

func _heal_player(amount: float, apply_modifiers: bool = true) -> void:
	pass

func _training_node_modifier(node_id: String, stat: String) -> float:
	return 0.0

func _curse_definition() -> Dictionary:
	return {}

func _recalculate_player_stats() -> void:
	pass

func _show_upgrade_choices() -> void:
	pass

func _reroll_upgrade_choices(overlay: Control) -> void:
	pass

func _upgrade_summary(choice: Dictionary) -> String:
	return ""

func _weapon_stats_text(weapon_id: String) -> String:
	return ""

func _build_prepared_upgrade_choices() -> Array[Dictionary]:
	return []

func _training_offer_run_state() -> Dictionary:
	return {}

func _prune_rejected_choice_memory() -> void:
	pass

func _ability_rank_delta_text(ability_id: String, rank: int) -> String:
	return ""

func _legacy_runtime_technique_id(canonical_id: String) -> String:
	return ""

func _run_boon_summary(boon_id: String) -> String:
	return ""

func _build_upgrade_choices() -> Array[Dictionary]:
	return []

func _apply_upgrade(choice: Dictionary, overlay: Control) -> void:
	pass

func _reset_movement_input() -> void:
	pass

func _start_new_run(starting_weapon: String = "", from_gate: bool = false) -> void:
	pass

func _show_weapon_picker(category_index: int = -1) -> void:
	pass

func _show_arsenal_screen(from_gate: bool = false) -> void:
	pass

func _on_arsenal_expedition_requested(arsenal: Dictionary, from_gate: bool = false) -> void:
	pass

func _selected_arsenal() -> Dictionary:
	return {}

func _legacy_runtime_weapon_id(canonical_id: String) -> String:
	return ""

func _register_training_runtime_content() -> void:
	pass

func _training_runtime_weapon(data: Dictionary) -> Dictionary:
	return {}

func _training_runtime_technique(data: Dictionary) -> Dictionary:
	return {}

func _select_class(class_id: String, overlay: Control) -> void:
	pass

func _offer_contract() -> void:
	pass

func _accept_contract(selected_id: String, overlay: Control) -> void:
	pass

func _decline_contract(overlay: Control) -> void:
	pass

func _show_relic_choices() -> void:
	pass

func _claim_relic(relic_id: String, overlay: Control) -> void:
	pass

func _clear_run_state() -> void:
	pass

func _finish_run(victory: bool, extracted: bool = false) -> void:
	pass

func _store_run_loot() -> Dictionary:
	return {}

func _snapshot_run() -> void:
	pass

func _resume_run() -> void:
	pass

func _apply_offline_progress() -> void:
	pass

func _update_last_seen() -> void:
	pass

func _buy_building(building: String) -> void:
	pass

func _building_effect_text(building: String, level: int, maximum: int) -> String:
	return ""

func _show_camp(message: String = "", preserve_world: bool = false) -> void:
	pass

func _show_hall_detail() -> void:
	pass

func _buy_hall_upgrade() -> void:
	pass

func _on_hall_screen_action(action_id: String, overlay: Control) -> void:
	pass

func _show_construction_menu(plot_id: String = "") -> void:
	pass

func _on_construction_action(building: String, plot_id: String, overlay: Control) -> void:
	pass

func _building_construction_effect(building: String) -> String:
	return ""

func _construct_building(building: String, plot_id: String = "") -> void:
	pass

func _show_building_detail(building: String) -> void:
	pass

func _on_building_detail_action(action_id: String, building: String, overlay: Control) -> void:
	pass

func _replace_overlay_with_class_tree(overlay: Control) -> void:
	pass

func _show_class_tree(message: String = "") -> void:
	pass

func _buy_class_node(node_id: String) -> void:
	pass

func _on_class_training_action(action_id: String, overlay: Control) -> void:
	pass

func _unlock_frontier(overlay: Control) -> void:
	pass

func _show_camp_expeditions() -> void:
	pass

func _select_roster_hero(hero_id: String) -> void:
	pass

func _on_roster_screen_action(action_id: String, overlay: Control) -> void:
	pass

func _set_hero_assignment(hero_id: String, assignment: String) -> void:
	pass

func _make_roster_hero_active(hero_id: String) -> void:
	pass

func _claim_roster_rewards() -> void:
	pass

func _replace_camp_overlay_with_weapon_picker(overlay: Control) -> void:
	pass

func _show_inventory(message: String = "", requested_uid: String = "") -> void:
	pass

func _find_inventory_item(uid: String) -> Dictionary:
	return {}

func _equipment_modifier_text(item: Dictionary) -> String:
	return ""

func _equipment_stat_text(stat: String, amount: float) -> String:
	return ""

func _change_inventory_page(delta: int) -> void:
	pass

func _equip_item(uid: String) -> void:
	pass

func _show_dismantle_confirm(uid: String) -> void:
	pass

func _dismantle_item(uid: String, overlay: Control) -> void:
	pass

func _show_skill_tree(message: String = "", branch_index: int = -1) -> void:
	pass

func _show_training_tree_screen() -> void:
	pass

func _build_run_ui() -> void:
	pass

func _toggle_pause() -> void:
	pass

func _update_hud() -> void:
	pass

func _build_results_ui() -> void:
	pass

func _show_settings() -> void:
	pass

func _bind_inventory_screen(inventory_screen: Control, message: String, requested_uid: String) -> void:
	pass

func _on_inventory_screen_action(action_id: String) -> void:
	pass

func _setting_slider_changed(value: float, key: String) -> void:
	pass

func _setting_toggle_changed(value: bool, key: String) -> void:
	pass

func _reload_app() -> void:
	pass

func _show_reset_save_confirmation() -> void:
	pass

func _reset_game_progress(overlay: Control) -> void:
	pass

func _export_save(field: TextEdit) -> void:
	pass

func _import_save(field: TextEdit) -> void:
	pass

func _clear_ui() -> void:
	pass

func _exit_tree() -> void:
	pass

func _play_music(music_id: String) -> void:
	pass

func _play_sfx(sfx_id: String, throttle: float = 0.06) -> void:
	pass

func _update_audio_volumes() -> void:
	pass

func _camp_display_max_health() -> float:
	return 0.0

func _format_time(seconds: float) -> String:
	return ""

func _point_over_action_button(point: Vector2) -> bool:
	return false

func _point_over_camp_action_button(point: Vector2) -> bool:
	return false

func _add_float_text(position: Vector2, text: String, color: Color) -> void:
	pass

func _add_effect(position: Vector2, radius: float, color: Color, kind: String, direction: Vector2 = Vector2.RIGHT) -> void:
	pass
