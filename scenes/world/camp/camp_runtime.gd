class_name AshenCampRuntime
extends Node2D

signal structure_tapped(structure_id: String)
signal structure_hovered(structure_id: String, hovered: bool)

@export_range(0, 4, 1) var camp_tier: int = 0
@export var town_name: String = "REFUGE"
@export_range(2, 6, 1) var building_capacity: int = 2
@export var revealed_slot_ids: Array[String] = []

const HALL_SCENES: Array[PackedScene] = [
	preload("res://scenes/world/structures/veterans_hall_tier_0.tscn"),
	preload("res://scenes/world/structures/veterans_hall_tier_1.tscn"),
	preload("res://scenes/world/structures/veterans_hall_tier_2.tscn"),
	preload("res://scenes/world/structures/veterans_hall_tier_3.tscn"),
	preload("res://scenes/world/structures/veterans_hall_tier_4.tscn"),
]
const BUILDING_SCENES: Dictionary = {
	"armory": [preload("res://scenes/world/structures/armory_tier_0.tscn"), preload("res://scenes/world/structures/armory_tier_1.tscn"), preload("res://scenes/world/structures/armory_tier_2.tscn"), preload("res://scenes/world/structures/armory_tier_3.tscn")],
	"blacksmith": [preload("res://scenes/world/structures/blacksmith_tier_0.tscn"), preload("res://scenes/world/structures/blacksmith_tier_1.tscn"), preload("res://scenes/world/structures/blacksmith_tier_2.tscn"), preload("res://scenes/world/structures/blacksmith_tier_3.tscn")],
	"quartermaster": [preload("res://scenes/world/structures/quartermaster_tier_0.tscn"), preload("res://scenes/world/structures/quartermaster_tier_1.tscn"), preload("res://scenes/world/structures/quartermaster_tier_2.tscn"), preload("res://scenes/world/structures/quartermaster_tier_3.tscn")],
	"training": [preload("res://scenes/world/structures/training_tier_0.tscn"), preload("res://scenes/world/structures/training_tier_1.tscn"), preload("res://scenes/world/structures/training_tier_2.tscn"), preload("res://scenes/world/structures/training_tier_3.tscn"), preload("res://scenes/world/structures/training_tier_4.tscn"), preload("res://scenes/world/structures/training_tier_5.tscn")],
}

func bind_state(hall_tier: int, assignments: Dictionary, building_tiers: Dictionary) -> void:
	set_meta("assignments", assignments.duplicate(true))
	var structures: Node2D = get_node("Structures") as Node2D
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	var hall_anchor := structures.get_node_or_null("VeteransHallAnchor") as Node2D
	if hall_anchor != null:
		_replace_anchor_content(hall_anchor, HALL_SCENES[clampi(hall_tier, 0, HALL_SCENES.size() - 1)])
	for child: Node in slots.get_children():
		var slot := child as AshenBuildingSlot
		if slot == null:
			continue
		var revealed: bool = revealed_slot_ids.has(slot.slot_id)
		slot.visible = revealed
		if not revealed:
			continue
		var building_id: String = String(assignments.get(slot.slot_id, ""))
		if building_id.is_empty():
			slot.show_empty_plot()
		elif BUILDING_SCENES.has(building_id):
			var candidates: Array = BUILDING_SCENES[building_id]
			var building_tier: int = clampi(int(building_tiers.get(building_id, 0)), 0, candidates.size() - 1)
			slot.show_content(candidates[building_tier] as PackedScene)
		else:
			push_error("Missing authored building scene for assigned building '%s'" % building_id)
	_wire_authored_touch_areas()


func structure_info(structure_id: String) -> Dictionary:
	var structures: Node2D = get_node("Structures") as Node2D
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	var root: Node2D
	if structure_id == "veterans_hall":
		root = structures.get_node_or_null("VeteransHallAnchor/Content") as Node2D
	elif structure_id == "campfire":
		root = structures.get_node_or_null("CampfireAnchor/Content") as Node2D
	else:
		var assignments: Dictionary = get_meta("assignments", {})
		for slot_id: String in assignments:
			if String(assignments[slot_id]) == structure_id:
				var slot_number: int = int(slot_id.trim_prefix("plot_"))
				root = slots.get_node_or_null("Slot%02d/Content" % slot_number) as Node2D
				break
	return _physical_info(root)


func plot_info(plot_id: String) -> Dictionary:
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	var slot_number: int = int(plot_id.trim_prefix("plot_"))
	return _physical_info(slots.get_node_or_null("Slot%02d/Content" % slot_number) as Node2D)


func plot_anchor(plot_id: String) -> Vector2:
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	var slot_number: int = int(plot_id.trim_prefix("plot_"))
	var slot := slots.get_node_or_null("Slot%02d" % slot_number) as Node2D
	return position + to_local(slot.global_position) if slot != null else Vector2.ZERO


func camp_bounds_world() -> Rect2:
	var bounds_node := get_node_or_null("CampBounds") as Polygon2D
	if bounds_node == null or bounds_node.polygon.is_empty():
		return Rect2()
	var local_bounds: Rect2 = _polygon_bounds(bounds_node.polygon)
	return Rect2(position + local_bounds.position, local_bounds.size)


func camp_metadata() -> Dictionary:
	return {"name": town_name, "capacity": building_capacity, "bounds": camp_bounds_world()}


func revealed_plot_ids() -> Array[String]:
	return revealed_slot_ids.duplicate()


func camp_boundary_polygon_world() -> PackedVector2Array:
	var bounds_node := get_node_or_null("CampBounds") as Polygon2D
	var mapped := PackedVector2Array()
	if bounds_node == null:
		return mapped
	for point: Vector2 in bounds_node.polygon:
		mapped.append(position + to_local(bounds_node.to_global(point)))
	return mapped


func point_hits_wall(world_point: Vector2, clearance: float = 0.0) -> bool:
	for layer_name: String in ["BackWall", "FrontWall"]:
		var layer := get_node_or_null(layer_name) as Node2D
		if layer == null:
			continue
		for segment: Node in layer.get_children():
			if segment is Node2D and _point_hits_collision_root(segment as Node2D, world_point, clearance):
				return true
	var gate := get_node_or_null("Gate") as Node2D
	return gate != null and _point_hits_collision_root(gate, world_point, clearance)


func wall_collision_polygons_world() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for layer_name: String in ["BackWall", "FrontWall"]:
		var layer := get_node_or_null(layer_name) as Node2D
		if layer != null:
			for segment: Node in layer.get_children():
				if segment is Node2D:
					result.append_array(_collision_polygons_world(segment as Node2D))
	var gate := get_node_or_null("Gate") as Node2D
	if gate != null:
		result.append_array(_collision_polygons_world(gate))
	return result


func gate_anchor_world() -> Vector2:
	var gate := get_node_or_null("Gate") as Node2D
	return position + gate.position if gate != null else Vector2.ZERO


func gate_transition_polygon_world() -> PackedVector2Array:
	var gate := get_node_or_null("Gate") as Node2D
	var shape := gate.get_node_or_null("TransitionArea/CollisionPolygon2D") as CollisionPolygon2D if gate != null else null
	var mapped := PackedVector2Array()
	if shape == null:
		return mapped
	for point: Vector2 in shape.polygon:
		mapped.append(position + to_local(shape.to_global(point)))
	return mapped


func gate_opening_contains_x(world_x: float, margin: float = 0.0) -> bool:
	var polygon: PackedVector2Array = gate_transition_polygon_world()
	if polygon.is_empty():
		return false
	var bounds: Rect2 = _polygon_bounds(polygon).grow(-maxf(0.0, margin))
	return world_x >= bounds.position.x and world_x <= bounds.end.x


func safe_zone_polygon_world() -> PackedVector2Array:
	return _area_polygon_world("SafeZone")


func no_spawn_polygon_world() -> PackedVector2Array:
	return _area_polygon_world("NoSpawnZone")


func prop_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for prop: Node in $Props.get_children():
		if not prop is Node2D:
			continue
		var info: Dictionary = _physical_info(prop as Node2D)
		if info.is_empty():
			continue
		info["id"] = String(prop.name).to_snake_case()
		entries.append(info)
	return entries


func vegetation_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for layer_name: String in ["BackVegetation", "FrontVegetation"]:
		var layer := get_node_or_null(layer_name) as Node2D
		if layer == null:
			continue
		for child: Node in layer.get_children():
			if not child is Node2D:
				continue
			var root := child as Node2D
			var collision := root.get_node_or_null("StaticBody2D/CollisionPolygon2D") as CollisionPolygon2D
			entries.append({
				"id": String(root.name),
				"anchor": position + root.position,
				"footprint": collision.polygon if collision != null else PackedVector2Array(),
				"layer": layer_name,
			})
	return entries


func point_hits_vegetation(world_point: Vector2, clearance: float = 0.0) -> bool:
	for entry: Dictionary in vegetation_entries():
		var polygon: PackedVector2Array = entry.get("footprint", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var world_polygon := PackedVector2Array()
		for point: Vector2 in polygon:
			world_polygon.append(Vector2(entry.anchor) + point)
		if clearance <= 0.0 and Geometry2D.is_point_in_polygon(world_point, world_polygon):
			return true
		var bounds: Rect2 = _polygon_bounds(world_polygon).grow(clearance)
		if bounds.has_point(world_point):
			return true
	return false


func set_highlighted(structure_id: String) -> void:
	var structures: Node2D = get_node("Structures") as Node2D
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	for id: String in ["veterans_hall", "campfire", "armory", "blacksmith", "quartermaster", "training"]:
		var root: Node2D
		if id == "veterans_hall":
			root = structures.get_node_or_null("VeteransHallAnchor/Content") as Node2D
		elif id == "campfire":
			root = structures.get_node_or_null("CampfireAnchor/Content") as Node2D
		else:
			var assignments: Dictionary = get_meta("assignments", {})
			for slot_id: String in assignments:
				if String(assignments[slot_id]) == id:
					root = slots.get_node_or_null("Slot%02d/Content" % int(slot_id.trim_prefix("plot_"))) as Node2D
		if root != null and root.has_method("set_highlighted"):
			root.call("set_highlighted", id == structure_id)
	for plot_id: String in revealed_slot_ids:
		var slot_number: int = int(plot_id.trim_prefix("plot_"))
		var plot_root := slots.get_node_or_null("Slot%02d/Content" % slot_number) as Node2D
		if plot_root != null and plot_root.has_method("set_highlighted"):
			plot_root.call("set_highlighted", plot_id == structure_id)


func _wire_authored_touch_areas() -> void:
	var structures: Node2D = get_node("Structures") as Node2D
	_wire_touch_area(structures.get_node_or_null("VeteransHallAnchor/Content") as Node2D, "veterans_hall")
	_wire_touch_area(structures.get_node_or_null("CampfireAnchor/Content") as Node2D, "campfire")
	var slots: Node2D = get_node("BuildingSlots") as Node2D
	var assignments: Dictionary = get_meta("assignments", {})
	for slot_id: String in revealed_slot_ids:
		var slot_number: int = int(slot_id.trim_prefix("plot_"))
		var content := slots.get_node_or_null("Slot%02d/Content" % slot_number) as Node2D
		var building_id: String = String(assignments.get(slot_id, ""))
		_wire_touch_area(content, building_id if not building_id.is_empty() else slot_id)


func _wire_touch_area(root: Node2D, structure_id: String) -> void:
	if root == null or structure_id.is_empty():
		return
	var touch_area := root.get_node_or_null("TouchArea") as Area2D
	if touch_area == null:
		push_error("Authored camp object '%s' has no TouchArea" % structure_id)
		return
	var input_callable: Callable = _on_touch_input.bind(structure_id)
	var enter_callable: Callable = _on_touch_hover.bind(structure_id, true)
	var exit_callable: Callable = _on_touch_hover.bind(structure_id, false)
	if not touch_area.input_event.is_connected(input_callable):
		touch_area.input_event.connect(input_callable)
	if not touch_area.mouse_entered.is_connected(enter_callable):
		touch_area.mouse_entered.connect(enter_callable)
	if not touch_area.mouse_exited.is_connected(exit_callable):
		touch_area.mouse_exited.connect(exit_callable)


func _on_touch_input(_viewport: Node, event: InputEvent, _shape_index: int, structure_id: String) -> void:
	var activated: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if activated:
		structure_tapped.emit(structure_id)


func _on_touch_hover(structure_id: String, hovered: bool) -> void:
	structure_hovered.emit(structure_id, hovered)


func _physical_info(root: Node2D) -> Dictionary:
	if root == null:
		return {}
	var footprint := root.get_node_or_null("StaticBody2D/CollisionPolygon2D") as CollisionPolygon2D
	var interaction := root.get_node_or_null("InteractionArea/CollisionPolygon2D") as CollisionPolygon2D
	return {
		"anchor": position + to_local(root.global_position),
		"footprint": footprint.polygon if footprint != null else PackedVector2Array(),
		"interaction": interaction.polygon if interaction != null else PackedVector2Array(),
	}


func _point_hits_collision_root(root: Node2D, world_point: Vector2, clearance: float) -> bool:
	var body := root.get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null:
		return false
	for child: Node in body.get_children():
		var collision := child as CollisionPolygon2D
		if collision == null or collision.polygon.size() < 3:
			continue
		var world_polygon := PackedVector2Array()
		for point: Vector2 in collision.polygon:
			world_polygon.append(position + to_local(collision.to_global(point)))
		if Geometry2D.is_point_in_polygon(world_point, world_polygon):
			return true
		if clearance > 0.0 and _polygon_bounds(world_polygon).grow(clearance).has_point(world_point):
			return true
	return false


func _collision_polygons_world(root: Node2D) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var body := root.get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null:
		return result
	for child: Node in body.get_children():
		var collision := child as CollisionPolygon2D
		if collision == null or collision.polygon.size() < 3:
			continue
		var mapped := PackedVector2Array()
		for point: Vector2 in collision.polygon:
			mapped.append(position + to_local(collision.to_global(point)))
		result.append(mapped)
	return result


func _area_polygon_world(area_path: String) -> PackedVector2Array:
	var shape := get_node_or_null(area_path + "/CollisionPolygon2D") as CollisionPolygon2D
	var mapped := PackedVector2Array()
	if shape == null:
		return mapped
	for point: Vector2 in shape.polygon:
		mapped.append(position + shape.position + point)
	return mapped


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum: Vector2 = points[0]
	var maximum: Vector2 = points[0]
	for point: Vector2 in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _replace_anchor_content(anchor: Node2D, scene: PackedScene) -> void:
	var existing := anchor.get_node_or_null("Content") as Node
	var desired_path: String = scene.resource_path if scene != null else ""
	if existing != null and String(existing.get_meta("scene_path", "")) == desired_path:
		return
	if existing != null:
		existing.free()
	if scene == null:
		return
	var content := scene.instantiate() as Node2D
	content.name = "Content"
	content.set_meta("scene_path", desired_path)
	anchor.add_child(content)
