extends "res://scenes/app/presentation_controller.gd"
func _point_hits_refuge_forest(position: Vector2, clearance: float = 0.0) -> bool:
	return is_instance_valid(active_camp_scene) and active_camp_scene.point_hits_vegetation(position, clearance)

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

func _world_map_point(reference_point: Vector2) -> Vector2:
	return world_content_origin + Vector2(reference_point.x * world_content_size.x / 1170.0, reference_point.y * world_content_size.y / 3376.0)

func _camp_boundary_world() -> PackedVector2Array:
	if is_instance_valid(active_camp_scene):
		return active_camp_scene.camp_boundary_polygon_world()
	push_error("No authored camp scene is active; camp boundary cannot be resolved")
	return PackedVector2Array()

func _town_level() -> int:
	return clampi(int(save.get("profile", {}).get("hall_level", 0)), 0, AuthoredCampTierScenes.size() - 1)

func _town_definition() -> Dictionary:
	return _camp_tier_metadata(_town_level())

func _camp_tier_metadata(tier: int) -> Dictionary:
	var safe_tier: int = clampi(tier, 0, AuthoredCampTierScenes.size() - 1)
	if is_instance_valid(active_camp_scene) and int(active_camp_scene.camp_tier) == safe_tier:
		return active_camp_scene.camp_metadata()
	var authored := AuthoredCampTierScenes[safe_tier].instantiate() as AshenCampRuntime
	authored.position = world_content_origin
	var metadata: Dictionary = authored.camp_metadata()
	authored.free()
	return metadata

func _town_capacity() -> int:
	return int(_town_definition().capacity)

func _town_bounds_world() -> Rect2:
	var level: int = _town_level()
	if is_instance_valid(active_camp_scene) and int(active_camp_scene.camp_tier) == level:
		var scene_bounds: Rect2 = active_camp_scene.camp_bounds_world()
		if scene_bounds.has_area():
			cached_town_bounds_world = scene_bounds
			cached_town_bounds_level = level
			return cached_town_bounds_world
	if cached_town_bounds_level == level and cached_town_bounds_world.size != Vector2.ZERO:
		return cached_town_bounds_world
	var metadata: Dictionary = _camp_tier_metadata(level)
	cached_town_bounds_world = Rect2(metadata.get("bounds", Rect2()))
	if not cached_town_bounds_world.has_area():
		push_error("Authored camp tier %d has no valid CampBounds polygon" % level)
	cached_town_bounds_level = level
	return cached_town_bounds_world

func _visible_camp_decor() -> Array[Dictionary]:
	if is_instance_valid(active_camp_scene):
		return active_camp_scene.prop_entries()
	push_error("No authored camp scene is active; camp props cannot be resolved")
	return []

func _camp_decor_footprint(entry: Dictionary, clearance: float = 0.0) -> Rect2:
	var authored_polygon: PackedVector2Array = entry.get("footprint", PackedVector2Array())
	if authored_polygon.size() >= 3:
		var authored_bounds := Rect2(authored_polygon[0], Vector2.ZERO)
		for point_index: int in range(1, authored_polygon.size()):
			authored_bounds = authored_bounds.expand(authored_polygon[point_index])
		return Rect2(Vector2(entry.get("anchor", Vector2.ZERO)) + authored_bounds.position - Vector2.ONE * clearance, authored_bounds.size + Vector2.ONE * clearance * 2.0)
	push_error("Authored camp prop '%s' is missing its collision footprint" % String(entry.get("id", "unknown")))
	return Rect2()

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
	if is_instance_valid(active_camp_scene):
		return active_camp_scene.revealed_plot_ids()
	var authored := AuthoredCampTierScenes[_town_level()].instantiate() as AshenCampRuntime
	var revealed: Array[String] = authored.revealed_plot_ids()
	authored.free()
	return revealed

func _plot_anchor(plot_id: String) -> Vector2:
	if is_instance_valid(active_camp_scene):
		var authored_anchor: Vector2 = active_camp_scene.plot_anchor(plot_id)
		if authored_anchor != Vector2.ZERO:
			return authored_anchor
	push_error("Authored camp tier %d has no anchor for plot '%s'" % [_town_level(), plot_id])
	return Vector2.ZERO

func _plot_interaction_polygon_world(plot_id: String) -> PackedVector2Array:
	if is_instance_valid(active_camp_scene):
		var info: Dictionary = active_camp_scene.plot_info(plot_id)
		var polygon: PackedVector2Array = info.get("interaction", PackedVector2Array())
		if polygon.size() >= 3:
			var authored_world := PackedVector2Array()
			for point: Vector2 in polygon:
				authored_world.append(Vector2(info.anchor) + point)
			return authored_world
	return PackedVector2Array()

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
	# Rebind on every camp-state refresh, not only when the Hall tier changes.
	# Plot assignments and individual building tiers can change while the camp
	# scene itself remains on the same expansion tier.
	if is_instance_valid(world_root):
		_sync_authored_camp_scene()
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
	if is_instance_valid(active_camp_scene):
		_sync_structure_definitions_from_authored_camp()

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
	if is_instance_valid(active_camp_scene) and int(active_camp_scene.camp_tier) == _town_level():
		var scene_gate: Vector2 = active_camp_scene.gate_anchor_world()
		if scene_gate != Vector2.ZERO:
			return scene_gate
	var bounds: Rect2 = _town_bounds_world()
	var authored_gate_x: float = 585.0
	return Vector2(_world_map_point(Vector2(authored_gate_x, 0.0)).x, bounds.end.y)

func _camp_gate_safe_center() -> Vector2:
	var polygon: PackedVector2Array = active_camp_scene.safe_zone_polygon_world() if is_instance_valid(active_camp_scene) else PackedVector2Array()
	if polygon.is_empty():
		return _camp_gate_position()
	var center := Vector2.ZERO
	for point: Vector2 in polygon:
		center += point
	return center / polygon.size()

func _camp_gate_safe_zone_contains(position: Vector2, radius: float = 0.0) -> bool:
	var polygon: PackedVector2Array = active_camp_scene.safe_zone_polygon_world() if is_instance_valid(active_camp_scene) else PackedVector2Array()
	if polygon.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(position, polygon):
		return true
	if radius <= 0.0:
		return false
	for index: int in polygon.size():
		if _distance_to_segment(position, polygon[index], polygon[(index + 1) % polygon.size()]) <= radius:
			return true
	return false

func _camp_gate_safe_exit_position(position: Vector2, radius: float) -> Vector2:
	"""Find a passable point beyond the camp gate's hostile-free radius."""
	var center: Vector2 = _camp_gate_safe_center()
	var gate: Vector2 = _camp_gate_position()
	var from_center: Vector2 = position - center
	var preferred: Vector2 = from_center.normalized() if from_center.length_squared() > 0.01 else Vector2.DOWN
	var directions: Array[Vector2] = [preferred, Vector2.DOWN, Vector2.DOWN + Vector2.LEFT * 0.72, Vector2.DOWN + Vector2.RIGHT * 0.72, Vector2.LEFT, Vector2.RIGHT]
	var safe_polygon: PackedVector2Array = active_camp_scene.safe_zone_polygon_world() if is_instance_valid(active_camp_scene) else PackedVector2Array()
	var safe_bounds: Rect2 = Rect2(_camp_gate_safe_center(), Vector2.ZERO)
	for point: Vector2 in safe_polygon:
		safe_bounds = safe_bounds.expand(point)
	var distance: float = maxf(safe_bounds.size.x, safe_bounds.size.y) * 0.6 + maxf(8.0, radius + 8.0)
	for direction: Vector2 in directions:
		var escape_direction: Vector2 = direction.normalized()
		var candidate: Vector2 = center + escape_direction * distance
		# The camp wall is closed everywhere except the painted gate. If a
		# diagonal would land back on the front wall, continue through the open
		# field below the gate instead of parking an enemy on a post.
		if candidate.y < gate.y + radius + 6.0:
			candidate.y = gate.y + radius + 6.0
		candidate.x = clampf(candidate.x, radius + 2.0, world_size.x - radius - 2.0)
		candidate.y = clampf(candidate.y, radius + 2.0, world_size.y - radius - 2.0)
		if not _camp_gate_safe_zone_contains(candidate, radius) and not _enemy_position_blocked(candidate, radius):
			return candidate
	var fallback: Vector2 = Vector2(center.x, gate.y + distance)
	fallback.x = clampf(fallback.x, radius + 2.0, world_size.x - radius - 2.0)
	fallback.y = clampf(fallback.y, radius + 2.0, world_size.y - radius - 2.0)
	return fallback

func _centered_camp_anchor(structure_id: String) -> Vector2:
	if is_instance_valid(active_camp_scene):
		var info: Dictionary = active_camp_scene.structure_info(structure_id)
		if not info.is_empty():
			return Vector2(info.anchor)
	push_error("Authored camp tier %d has no anchor for structure '%s'" % [_town_level(), structure_id])
	return Vector2.ZERO
