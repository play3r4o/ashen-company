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
	return _sprite_properties(get_node_or_null("Tier%d/Structures/%s/Sprite" % [_resolved_tier(tier), structure_id]) as Sprite2D)

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

func _draw() -> void:
	# A lightweight authoring backdrop keeps positions understandable in the
	# viewport without becoming a second runtime renderer.
	draw_rect(refuge_bounds.grow(80.0), Color("20221f"), true)
	draw_rect(refuge_bounds, PREVIEW_COBBLE, true)
	for x: float in range(int(refuge_bounds.position.x), int(refuge_bounds.end.x), 32):
		draw_line(Vector2(x, refuge_bounds.position.y), Vector2(x, refuge_bounds.end.y), Color(PREVIEW_INK, 0.16), 1.0)
	for y: float in range(int(refuge_bounds.position.y), int(refuge_bounds.end.y), 32):
		draw_line(Vector2(refuge_bounds.position.x, y), Vector2(refuge_bounds.end.x, y), Color(PREVIEW_INK, 0.16), 1.0)
	draw_rect(refuge_bounds, PREVIEW_EDGE, false, 3.0)
	if POLE_TEXTURE != null:
		var rear_y: float = refuge_bounds.position.y + 32.0
		for x: float in range(int(refuge_bounds.position.x), int(refuge_bounds.end.x) + 1, 16):
			draw_texture_rect(POLE_TEXTURE, Rect2(Vector2(x - 8.0, rear_y - 64.0), Vector2(16.0, 64.0)), false, Color(1.0, 1.0, 1.0, 0.72))
		for x: float in range(int(refuge_bounds.position.x), int(refuge_bounds.end.x) + 1, 16):
			draw_texture_rect(POLE_TEXTURE, Rect2(Vector2(x - 8.0, refuge_bounds.end.y - 32.0), Vector2(16.0, 64.0)), false, Color(1.0, 1.0, 1.0, 0.72))
		for y: float in range(int(refuge_bounds.position.y) + 32, int(refuge_bounds.end.y) + 33, 20):
			draw_texture_rect(POLE_TEXTURE, Rect2(Vector2(refuge_bounds.position.x - 8.0, y - 64.0), Vector2(16.0, 64.0)), false, Color(1.0, 1.0, 1.0, 0.72))
			draw_texture_rect(POLE_TEXTURE, Rect2(Vector2(refuge_bounds.end.x - 8.0, y - 64.0), Vector2(16.0, 64.0)), false, Color(1.0, 1.0, 1.0, 0.72))
	draw_string(ThemeDB.fallback_font, refuge_bounds.position + Vector2(8.0, -12.0), "REFUGE LAYOUT - DRAG PLACEMENT NODES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PREVIEW_EDGE)
	if show_hitboxes:
		_draw_editable_shapes()

func _draw_editable_shapes() -> void:
	var footprint_color := Color(0.94, 0.28, 0.22, 0.62)
	var interaction_color := Color(1.0, 0.72, 0.20, 0.46)
	var wall_color := Color(0.28, 0.78, 0.92, 0.54)
	var tier: int = _resolved_tier(preview_tier)
	if preview_tier > 0 and layout_tier == 0:
		# Tier wrapper scenes reuse the tier-zero authored node tree until a
		# later tier receives its own geometry overrides.
		tier = 0
	var boundary := boundary_polygon(tier)
	_draw_polygon_outline(boundary, Color(0.95, 0.28, 0.22, 0.72), 2.0)
	for segment: Dictionary in wall_segments(tier):
		_draw_polygon_outline(PackedVector2Array(segment.polygon), wall_color, 2.0)
	var structures_root := get_node_or_null("Tier%d/Structures" % tier)
	if structures_root != null:
		for structure: Node in structures_root.get_children():
			if not structure is Node2D:
				continue
			var footprint := structure_polygon(tier, String(structure.name), "Footprint")
			_draw_local_polygon(structure as Node2D, footprint, footprint_color)
			if show_interaction_areas:
				var interaction := structure_polygon(tier, String(structure.name), "Interaction")
				_draw_local_polygon(structure as Node2D, interaction, interaction_color)
	var decor_root := get_node_or_null("Tier%d/Decor" % tier)
	if decor_root != null:
		for decor: Node in decor_root.get_children():
			if not decor is Node2D:
				continue
			var footprint_node := decor.get_node_or_null("Footprint") as Polygon2D
			if footprint_node != null:
				_draw_local_polygon(decor as Node2D, _transformed_polygon(footprint_node), wall_color)
			if show_interaction_areas:
				var interaction_node := decor.get_node_or_null("Interaction") as Polygon2D
				if interaction_node != null:
					_draw_local_polygon(decor as Node2D, _transformed_polygon(interaction_node), interaction_color)
	var plots_root := get_node_or_null("Tier%d/Plots" % tier)
	if plots_root != null:
		for plot: Node in plots_root.get_children():
			if not plot is Node2D:
				continue
			var plot_footprint := plot.get_node_or_null("Footprint") as Polygon2D
			if plot_footprint != null:
				_draw_local_polygon(plot as Node2D, _transformed_polygon(plot_footprint), footprint_color)
			if show_interaction_areas:
				var plot_interaction := plot.get_node_or_null("Interaction") as Polygon2D
				if plot_interaction != null:
					_draw_local_polygon(plot as Node2D, _transformed_polygon(plot_interaction), interaction_color)

func _draw_local_polygon(parent: Node2D, polygon: PackedVector2Array, color: Color) -> void:
	if polygon.size() < 2:
		return
	var points := PackedVector2Array()
	for point: Vector2 in polygon:
		points.append(parent.position + point)
	points.append(points[0])
	draw_polyline(points, color, 2.0)

func _draw_polygon_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	if polygon.size() < 2:
		return
	var points := polygon.duplicate()
	points.append(points[0])
	draw_polyline(points, color, width)
