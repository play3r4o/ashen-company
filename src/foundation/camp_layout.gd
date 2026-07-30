@tool
class_name CampLayout
extends Node2D

## Shared authoring layout for the refuge. The game reads the same placement
## nodes that are visible in the Godot 2D viewport, so moving a marker here
## changes the live camp without editing gameplay code.

@export var refuge_bounds: Rect2 = Rect2(415.0, 105.0, 340.0, 480.0)

const PREVIEW_INK := Color("171a1c")
const PREVIEW_COBBLE := Color("3c3b39")
const PREVIEW_EDGE := Color("bca77a")
const POLE_TEXTURE: Texture2D = preload("res://assets/generated/reference_v3/town/wall_pole.png")

func has_anchor(tier: int, structure_id: String) -> bool:
	return get_node_or_null("Tier%d/Structures/%s" % [tier, structure_id]) != null

func anchor_for(tier: int, structure_id: String) -> Vector2:
	var marker := get_node_or_null("Tier%d/Structures/%s" % [tier, structure_id]) as Node2D
	return marker.position if marker != null else Vector2.ZERO

func decoration_entries(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var decor_root := get_node_or_null("Tier%d/Decor" % tier)
	if decor_root == null:
		return result
	for child: Node in decor_root.get_children():
		if child is Node2D:
			result.append({"id": String(child.name), "anchor": (child as Node2D).position})
	return result

func has_bounds(tier: int) -> bool:
	return tier == 0

func bounds_for(tier: int) -> Rect2:
	return refuge_bounds if tier == 0 else Rect2()

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

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
