@tool
class_name AshenBlackthornMoorPreview
extends Node2D

## The single authored composition for Blackthorn Moor.
##
## Runtime supplies only generated state (seed, region cells, world origin and
## dynamic discovery state). Every meadow visual is a child of this scene, so
## opening this scene in Godot shows the same terrain, dressing, landmarks,
## and all five Refuge tier instances. The selected editor tier is visible in
## Godot; runtime adopts the matching child into CampHost on boot and frees the
## other previews, so the same authored node is used in the live game.

const RegionGeneratorService = preload("res://src/services/region_generator.gd")
const WORLD_CONTENT_SIZE := Vector2(1170.0, 3376.0)
const DEFAULT_REGION_ORIGIN := Vector2(-7.0, 800.0)
const EDITOR_REFERENCE_CONTENT_ORIGIN := Vector2(390.0, 844.0)

# The scene is authored at the 390x844 reference origin.  Runtime may place
# that same authored scene in a wider viewport, but it must never rewrite the
# positions of its decoration children.  Keep a single transform on this
# wrapper and compensate the world-coordinate layers underneath it.
var runtime_content_origin_delta: Vector2 = Vector2.ZERO
var _applying_runtime_origin: bool = false
var _authored_layer_positions_captured: bool = false
var _authored_preview_position: Vector2 = Vector2.ZERO
var _authored_terrain_position: Vector2 = Vector2.ZERO
var _authored_world_presentation_position: Vector2 = Vector2.ZERO
var _runtime_world_presentation_shake: Vector2 = Vector2.ZERO

@export var preview_seed: int = 41041:
	set(value):
		preview_seed = value
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@export var preview_content_origin: Vector2 = EDITOR_REFERENCE_CONTENT_ORIGIN:
	set(value):
		preview_content_origin = value
		if is_node_ready() and not Engine.is_editor_hint() and not _applying_runtime_origin:
			_apply_runtime_content_origin(value)

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

@export_range(0, 4, 1) var editor_camp_tier: int = 0:
	set(value):
		editor_camp_tier = clampi(value, 0, 4)
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@export var show_editor_camp: bool = true:
	set(value):
		show_editor_camp = value
		if is_node_ready() and Engine.is_editor_hint():
			_sync_editor_preview()

@onready var terrain: AshenTerrainLayer = AshenSceneBindings.required(self, &"Terrain", "BlackthornMoorPreview") as AshenTerrainLayer
@onready var authored_composition: Node2D = AshenSceneBindings.optional(self, &"AuthoredComposition") as Node2D
@onready var world_presentation: Node2D = AshenSceneBindings.optional(self, &"WorldPresentation") as Node2D


func _ready() -> void:
	_capture_authored_layer_positions()
	if Engine.is_editor_hint():
		_sync_editor_preview()
	else:
		_apply_runtime_content_origin(preview_content_origin)


## Called by the world controller when the expedition state is created or
## regenerated. This does not choose or create art; it binds generated terrain
## data into the authored Terrain scene already owned by this composition.
func configure_runtime(region: Dictionary, content_origin: Vector2, region_origin: Vector2, world_size: Vector2, town_bounds: Rect2, seed_value: int) -> void:
	_apply_runtime_content_origin(content_origin)
	preview_region_origin = region_origin
	if terrain == null:
		push_error("Blackthorn Moor preview is missing its authored Terrain child")
		return
	terrain.rebuild(region, region_origin, seed_value, {
		"world_size": world_size,
		"town_bounds": town_bounds,
		"version": 1,
	})


func authored_camp_local_position(camp: Node2D) -> Vector2:
	"""Return a camp instance position relative to the shared content origin.

	The preview scene is authored at a reference content origin, while runtime
	moves that origin for the actual viewport.  Subtracting the same origin here
	keeps a camp moved in the editor at the identical relative world position.
	"""
	var mount := AshenSceneBindings.optional(self, &"CampAuthoring") as Node2D
	if mount == null or camp == null:
		return Vector2.ZERO
	# Always subtract the authored reference origin.  `preview_content_origin`
	# is a runtime placement value and must not change the relative coordinates
	# authored in this scene.
	# Include the preview root as well.  If the complete Meadow scene is moved
	# in Godot, the selected camp must move by the same authored amount when it
	# is adopted into CampHost at runtime.
	return _authored_preview_position + mount.position + camp.position - EDITOR_REFERENCE_CONTENT_ORIGIN


func authored_composition_local_position() -> Vector2:
	"""Return the decoration root's authored offset from the shared origin.

	The preview and runtime both mount the complete meadow composition.  Keeping
	the root offset separate from the viewport origin means moving the whole
	decoration group in Godot is preserved at runtime, just like moving an
	individual tree, rock, shrub, or stump.
	"""
	if authored_composition == null:
		return Vector2.ZERO
	return _authored_preview_position + authored_composition.position - EDITOR_REFERENCE_CONTENT_ORIGIN


func authored_preview_local_position() -> Vector2:
	"""Return the preview root's authored offset from the reference origin.

	The preview root is itself editable in Godot.  Runtime may add the viewport
	origin delta, but it must not replace a position the user authored on this
	scene.  Keeping this value explicit also gives parity checks a stable way to
	compare the editor composition with the live instance.
	"""
	return _authored_preview_position


func runtime_world_presentation_local_position() -> Vector2:
	# WorldPresentation children are authored in world coordinates.  When the
	# wrapper is shifted for a non-reference viewport, cancel that shift here so
	# generated landmarks remain at the same world position as in the editor.
	return _authored_world_presentation_position - runtime_content_origin_delta + _runtime_world_presentation_shake


func apply_runtime_content_origin(content_origin: Vector2) -> void:
	_apply_runtime_content_origin(content_origin)


func set_runtime_world_presentation_shake(offset: Vector2) -> void:
	# Camera shake is transient runtime state, not authored placement.  Keeping
	# it on the preview owner prevents the presentation controller from writing a
	# second, competing transform directly onto the authored child.
	var rounded_offset: Vector2 = offset.round()
	if rounded_offset == _runtime_world_presentation_shake:
		return
	_runtime_world_presentation_shake = rounded_offset
	if is_node_ready() and not Engine.is_editor_hint() and world_presentation != null:
		# Shake only affects the dynamic landmark branch. Reapplying the complete
		# content-origin transform here would dirty every authored terrain and
		# decoration child on every rendered frame.
		world_presentation.position = _authored_world_presentation_position - runtime_content_origin_delta + _runtime_world_presentation_shake


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
	# Kept as a compatibility entry point for older callers.  It is intentionally
	# a runtime-only transform; editor-authored node positions are never copied
	# into a second set of runtime coordinates.
	if not Engine.is_editor_hint():
		_apply_runtime_content_origin(content_origin)


func _apply_runtime_content_origin(content_origin: Vector2) -> void:
	_capture_authored_layer_positions()
	var next_delta: Vector2 = content_origin - EDITOR_REFERENCE_CONTENT_ORIGIN
	var next_preview_position: Vector2 = _authored_preview_position + next_delta
	var next_terrain_position: Vector2 = _authored_terrain_position - next_delta
	var next_world_presentation_position: Vector2 = _authored_world_presentation_position - next_delta + _runtime_world_presentation_shake
	if content_origin == preview_content_origin and runtime_content_origin_delta == next_delta and position == next_preview_position and (terrain == null or terrain.position == next_terrain_position) and (world_presentation == null or world_presentation.position == next_world_presentation_position):
		return
	_applying_runtime_origin = true
	preview_content_origin = content_origin
	_applying_runtime_origin = false
	runtime_content_origin_delta = next_delta
	# Shift the complete authored composition once.  This preserves every
	# decoration's scene-local position and fixes the old double-origin offset.
	position = next_preview_position
	# Terrain and dynamic landmarks are authored in world coordinates, so they
	# cancel the wrapper transform.  Their child positions remain untouched.
	if terrain != null:
		terrain.position = next_terrain_position
	if world_presentation != null:
		world_presentation.position = next_world_presentation_position


func _capture_authored_layer_positions() -> void:
	if _authored_layer_positions_captured:
		return
	_authored_preview_position = position
	if terrain != null:
		_authored_terrain_position = terrain.position
	if world_presentation != null:
		_authored_world_presentation_position = world_presentation.position
	_authored_layer_positions_captured = true


func _sync_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	_sync_editor_camp()
	if world_presentation == null:
		return
	world_presentation.visible = show_editor_landmarks
	var region: Dictionary = RegionGeneratorService.generate_blackthorn(preview_seed)
	var frontier: Node2D = AshenSceneBindings.optional(world_presentation, &"FrontierGate") as Node2D
	if frontier != null:
		frontier.position = preview_region_origin + Vector2(region.get("frontier_gate", Vector2.ZERO))
		frontier.visible = show_editor_landmarks


func _sync_editor_camp() -> void:
	var mount := AshenSceneBindings.optional(self, &"CampAuthoring") as Node2D
	if mount == null:
		return
	mount.visible = show_editor_camp
	for child: Node in mount.get_children():
		var camp := child as Node2D
		if camp == null:
			continue
		camp.visible = show_editor_camp and camp.name == "CampTier%d" % editor_camp_tier


func _landmark_world_position(region: Dictionary, landmark_id: String) -> Vector2:
	for point_value: Variant in Array(region.get("landmarks", [])):
		if point_value is Dictionary and String(point_value.get("id", "")) == landmark_id:
			return preview_region_origin + Vector2(point_value.get("position", Vector2.ZERO))
	return preview_region_origin
