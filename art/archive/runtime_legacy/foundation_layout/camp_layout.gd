@tool
class_name CampLayout
extends Node2D

## Shared authoring layout for the refuge. The game reads the same placement
## nodes that are visible in the Godot 2D viewport, so moving a marker here
## changes the live camp without editing gameplay code.

@export var refuge_bounds: Rect2 = Rect2(415.0, 105.0, 340.0, 480.0)
@export_range(0, 4, 1) var layout_tier: int = 0
@export_range(0, 4, 1) var preview_tier: int = 0
@export var editor_show_building_library: bool = false
@export var show_hitboxes: bool = true
@export var show_interaction_areas: bool = true

const PREVIEW_INK := Color("171a1c")
const PREVIEW_COBBLE := Color("3c3b39")
const PREVIEW_EDGE := Color("bca77a")
const POLE_TEXTURE: Texture2D = preload("res://assets/generated/reference_v3/town/wall_pole.png")

func has_anchor(tier: int, structure_id: String) -> bool:
	return get_node_or_null("Tier%d/Structures/%s" % [_resolved_tier(tier), structure_id]) != null

func anchor_for(tier: int, structure_id: String) -> Vector2:
	var marker := get_node_or_null("Tier%d/Structures/%s" % [_resolved_tier(tier), structure_id]) as Node2D
	return marker.position if marker != null else Vector2.ZERO

func gate_anchor(tier: int) -> Vector2:
	var marker := get_node_or_null("Tier%d/Gate" % _resolved_tier(tier)) as Node2D
	return marker.position if marker != null else Vector2.ZERO

func boundary_polygon(tier: int) -> PackedVector2Array:
	"""Returns the authored walkable enclosure in layout/reference coordinates.

	The polygon is intentionally separate from the visible wall strips.  This
	lets the editor describe the actual ground that the player may occupy while
	wall artwork can retain its tall, overlapping sprite canvas.
	"""
	var polygon_node := get_node_or_null("Tier%d/Boundary" % _resolved_tier(tier)) as Polygon2D
	return _transformed_polygon(polygon_node)

func plot_anchor(tier: int, plot_id: String) -> Vector2:
	var marker := get_node_or_null("Tier%d/Plots/%s" % [_resolved_tier(tier), plot_id]) as Node2D
	return marker.position if marker != null else Vector2.ZERO

func has_plot(tier: int, plot_id: String) -> bool:
	return get_node_or_null("Tier%d/Plots/%s" % [_resolved_tier(tier), plot_id]) != null

func plot_polygon(tier: int, plot_id: String, polygon_name: String) -> PackedVector2Array:
	var polygon_node := get_node_or_null("Tier%d/Plots/%s/%s" % [_resolved_tier(tier), plot_id, polygon_name]) as Polygon2D
	if polygon_node == null:
		return PackedVector2Array()
	return _transformed_polygon(polygon_node)

func structure_polygon(tier: int, structure_id: String, polygon_name: String) -> PackedVector2Array:
	var polygon_node := get_node_or_null("Tier%d/Structures/%s/%s" % [_resolved_tier(tier), structure_id, polygon_name]) as Polygon2D
	if polygon_node == null:
		return PackedVector2Array()
	return _transformed_polygon(polygon_node)

func structure_sprite_properties(tier: int, structure_id: String) -> Dictionary:
	var root_path := "Tier%d/Structures/%s" % [_resolved_tier(tier), structure_id]
	var sprite := get_node_or_null(root_path + "/Sprite") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null(root_path + "/Visual/Base") as Sprite2D
	return _sprite_properties(sprite)

func plot_sprite_properties(tier: int, plot_id: String) -> Dictionary:
	return _sprite_properties(get_node_or_null("Tier%d/Plots/%s/Sprite" % [_resolved_tier(tier), plot_id]) as Sprite2D)

func gate_sprite_properties(tier: int) -> Dictionary:
	return _sprite_properties(get_node_or_null("Tier%d/Gate/Sprite" % _resolved_tier(tier)) as Sprite2D)

func wall_segments(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var wall_root := get_node_or_null("Tier%d/Walls" % _resolved_tier(tier))
	if wall_root == null:
		return result
	for child: Node in wall_root.get_children():
		if child is Polygon2D:
			result.append({"id": String(child.name), "polygon": _transformed_polygon(child as Polygon2D)})
	return result

func decoration_entries(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var decor_root := get_node_or_null("Tier%d/Decor" % _resolved_tier(tier))
	if decor_root == null:
		return result
	for child: Node in decor_root.get_children():
		if child is Node2D:
			var entry: Dictionary = {"id": String(child.name), "anchor": (child as Node2D).position}
			var footprint := child.get_node_or_null("Footprint") as Polygon2D
			if footprint != null and footprint.polygon.size() >= 3:
				entry["footprint"] = _transformed_polygon(footprint)
			entry["sprite"] = _sprite_properties(child.get_node_or_null("Sprite") as Sprite2D)
			result.append(entry)
	return result

func has_bounds(tier: int) -> bool:
	return tier == layout_tier

func has_explicit_tier(tier: int) -> bool:
	return get_node_or_null("Tier%d" % tier) != null

func bounds_for(tier: int) -> Rect2:
	return refuge_bounds if tier == layout_tier else Rect2()

func _resolved_tier(tier: int) -> int:
	if get_node_or_null("Tier%d" % tier) != null:
		return tier
	if get_node_or_null("Tier%d" % layout_tier) != null:
		return layout_tier
	return 0

func _transformed_polygon(polygon_node: Polygon2D) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon_node == null:
		return result
	for point: Vector2 in polygon_node.polygon:
		result.append(polygon_node.transform * point)
	return result

func _sprite_properties(sprite: Sprite2D) -> Dictionary:
	if sprite == null:
		return {}
	return {
		"position": sprite.position,
		"scale": sprite.scale,
		"flip_h": sprite.flip_h,
		"flip_v": sprite.flip_v,
		"centered": sprite.centered,
		"offset": sprite.offset,
	}

func _ready() -> void:
	if Engine.is_editor_hint():
		_sync_editor_preview()
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_editor_preview()
		queue_redraw()

func _sync_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var structures_root := get_node_or_null("Tier%d/Structures" % _resolved_tier(preview_tier))
	if structures_root != null:
		for structure: Node in structures_root.get_children():
			if String(structure.name) in ["armory", "quartermaster", "blacksmith", "training"]:
				var sprite := structure.get_node_or_null("Sprite") as CanvasItem
				if sprite != null:
					sprite.visible = editor_show_building_library
	var plots_root := get_node_or_null("Tier%d/Plots" % _resolved_tier(preview_tier))
	if plots_root != null:
		var plot_index: int = 0
		for plot: Node in plots_root.get_children():
			plot.visible = plot_index < preview_tier
			plot_index += 1
