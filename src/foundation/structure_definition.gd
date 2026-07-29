class_name StructureDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var menu_id: String = ""
@export var anchor: Vector2 = Vector2.ZERO
@export var draw_height: float = 128.0
@export var footprint: PackedVector2Array = PackedVector2Array()
@export var interaction_polygon: PackedVector2Array = PackedVector2Array()
@export var interaction_radius: float = 58.0
@export var sort_origin_y: float = 0.0
@export var tier_textures: Array[Texture2D] = []
@export var tier_outlines: Array[Texture2D] = []

func texture_for_tier(tier: int) -> Texture2D:
	if tier_textures.is_empty():
		return null
	return tier_textures[clampi(tier, 0, tier_textures.size() - 1)]

func outline_for_tier(tier: int) -> Texture2D:
	if tier_outlines.is_empty():
		return null
	return tier_outlines[clampi(tier, 0, tier_outlines.size() - 1)]

func world_footprint() -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point: Vector2 in footprint:
		points.append(anchor + local_point)
	return points

func world_interaction_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point: Vector2 in interaction_polygon:
		points.append(anchor + local_point)
	return points

func contains_ground_point(point: Vector2, radius: float = 0.0) -> bool:
	var polygon: PackedVector2Array = world_footprint()
	if polygon.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(point, polygon):
		return true
	if radius <= 0.0:
		return false
	for index: int in polygon.size():
		if distance_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()]) <= radius:
			return true
	return false

func can_interact(point: Vector2) -> bool:
	var polygon: PackedVector2Array = world_interaction_polygon()
	if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
		return true
	return point.distance_to(anchor) <= interaction_radius

static func distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment: Vector2 = finish - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var progress: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * progress)
