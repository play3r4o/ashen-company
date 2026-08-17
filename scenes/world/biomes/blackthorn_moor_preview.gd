@tool
class_name AshenBlackthornMoorPreview
extends Node2D

## The single authored composition for Blackthorn Moor.
##
## Runtime supplies only generated state (seed, region cells, world origin and
## dynamic discovery state). Every meadow visual is a child of this scene, so
## opening this scene in Godot shows the same terrain, dressing and landmark
## scene instances that the game mounts at runtime. The camp is intentionally
## kept outside this scene and is mounted by the camp controller.

const RegionGeneratorService = preload("res://src/services/region_generator.gd")
const WORLD_CONTENT_SIZE := Vector2(1170.0, 3376.0)
const DEFAULT_REGION_ORIGIN := Vector2(-7.0, 800.0)
# The default landmark anchor is the position produced by the authored preview
# seed (41041) and DEFAULT_REGION_ORIGIN.  A position edited and saved on the
# RuinedCitySite child is treated as an authored offset from this anchor.  The
# same offset is applied to the runtime-generated landmark, so the editor scene
# and the live expedition stay in the same coordinate space.
const DEFAULT_AUTHORED_CITY_POSITION := Vector2(585.0, 1776.0)

var authored_ruined_city_offset: Vector2 = Vector2.ZERO

@export var preview_seed: int = 41041:
	set(value):
		preview_seed = value
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@export var preview_content_origin: Vector2 = Vector2.ZERO:
	set(value):
		preview_content_origin = value
		if is_node_ready():
			_sync_authored_positions(value)

@export var preview_region_origin: Vector2 = DEFAULT_REGION_ORIGIN:
	set(value):
		preview_region_origin = value
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@export var show_editor_landmarks: bool = true:
	set(value):
		show_editor_landmarks = value
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@onready var terrain: AshenTerrainLayer = $Terrain
@onready var authored_composition: Node2D = $AuthoredComposition
@onready var world_presentation: Node2D = $WorldPresentation


func _ready() -> void:
	_capture_authored_landmark_positions()
	_sync_authored_positions(preview_content_origin)
	if Engine.is_editor_hint():
		_sync_editor_preview()


## Called by the world controller when the expedition state is created or
## regenerated. This does not choose or create art; it binds generated terrain
## data into the authored Terrain scene already owned by this composition.
func configure_runtime(region: Dictionary, content_origin: Vector2, region_origin: Vector2, world_size: Vector2, town_bounds: Rect2, seed_value: int) -> void:
	preview_content_origin = content_origin
	preview_region_origin = region_origin
	_sync_authored_positions(content_origin)
	if terrain == null:
		push_error("Blackthorn Moor preview is missing its authored Terrain child")
		return
	terrain.rebuild(region, region_origin, seed_value, {
		"world_size": world_size,
		"town_bounds": town_bounds,
		"version": 1,
	})


func get_authored_ruined_city_offset() -> Vector2:
	return authored_ruined_city_offset


## Forward dynamic landmark state to the authored presentation child. The
## world controller never instantiates a second meadow presentation scene.
func sync_frame(run_active: bool, frontier_position: Vector2, frontier_unlocked: bool, points: Array, elapsed: float, prisoner_rescued: bool = false, prison_key_available: bool = false) -> void:
	if world_presentation == null or not world_presentation.has_method("sync_frame"):
		push_error("Blackthorn Moor preview is missing its authored WorldPresentation controller")
		return
	world_presentation.call("sync_frame", run_active, frontier_position, frontier_unlocked, points, elapsed, prisoner_rescued, prison_key_available)


func reset_dynamic_visuals() -> void:
	if world_presentation != null and world_presentation.has_method("sync_frame"):
		world_presentation.call("sync_frame", false, Vector2.ZERO, false, [], 0.0, false, false)


func _sync_authored_positions(content_origin: Vector2) -> void:
	# Terrain is authored in world coordinates. Static dressing is authored in
	# the 1170x3376 content field and therefore follows the same origin used by
	# the camp and camera, while dynamic landmarks stay in world coordinates.
	if authored_composition != null:
		authored_composition.position = content_origin
	if terrain != null:
		terrain.position = Vector2.ZERO
	if world_presentation != null:
		world_presentation.position = Vector2.ZERO


func _capture_authored_landmark_positions() -> void:
	# A zero position means the reusable landmark scene has no serialized
	# placement override.  In that case the generated anchor remains authoritative.
	# Non-zero values are overrides saved by moving the editable child in this
	# canonical preview scene.
	if world_presentation == null:
		return
	var city := world_presentation.get_node_or_null("RuinedCitySite") as Node2D
	if city == null or city.position == Vector2.ZERO:
		authored_ruined_city_offset = Vector2.ZERO
		return
	authored_ruined_city_offset = city.position - DEFAULT_AUTHORED_CITY_POSITION


func _sync_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	_sync_authored_positions(preview_content_origin)
	if world_presentation == null:
		return
	world_presentation.visible = show_editor_landmarks
	var region: Dictionary = RegionGeneratorService.generate_blackthorn(preview_seed)
	var city: Node2D = world_presentation.get_node_or_null("RuinedCitySite") as Node2D
	if city != null:
		city.position = _landmark_world_position(region, "ruined_city") + authored_ruined_city_offset
		city.visible = show_editor_landmarks
	var frontier: Node2D = world_presentation.get_node_or_null("FrontierGate") as Node2D
	if frontier != null:
		frontier.position = preview_region_origin + Vector2(region.get("frontier_gate", Vector2.ZERO))
		frontier.visible = show_editor_landmarks


func _landmark_world_position(region: Dictionary, landmark_id: String) -> Vector2:
	for point_value: Variant in Array(region.get("landmarks", [])):
		if point_value is Dictionary and String(point_value.get("id", "")) == landmark_id:
			return preview_region_origin + Vector2(point_value.get("position", Vector2.ZERO))
	return preview_region_origin
