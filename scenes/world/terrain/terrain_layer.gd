class_name AshenTerrainLayer
extends Node2D

const TILE_SIZE: int = 32
const CHUNK_TILES: int = 8
const CHUNK_SIZE: int = TILE_SIZE * CHUNK_TILES
const TERRAIN_ROWS: Dictionary = {
	"earth": 0,
	"road": 1,
	"mud": 2,
	"moss": 3,
	"water": 4,
	"cobble": 5,
	"thorn": 6,
	"barrier": 7,
	"gate": 8,
}
const VARIANT_COUNTS: Dictionary = {
	"earth": 6,
	"road": 6,
	"mud": 4,
	"moss": 6,
	"water": 4,
	"cobble": 6,
	"thorn": 4,
	"barrier": 4,
	"gate": 4,
}

var chunks: Dictionary = {}
var rebuild_count: int = 0
var last_signature: String = ""

@onready var base_tiles: TileMapLayer = $BaseTiles
@onready var overlay_tiles: TileMapLayer = $OverlayTiles


func rebuild(region: Dictionary, origin: Vector2, seed: int, theme: Dictionary) -> void:
	var world_size: Vector2 = theme.get("world_size", Vector2.ZERO)
	var town_bounds: Rect2 = theme.get("town_bounds", Rect2())
	var signature := "%d:%s:%s:%s:%d" % [seed, world_size, town_bounds, region.get("size_tiles", Vector2i.ZERO), int(theme.get("version", 1))]
	if signature == last_signature and not chunks.is_empty():
		return
	last_signature = signature
	rebuild_count += 1
	base_tiles.clear()
	overlay_tiles.clear()
	chunks.clear()

	var region_size: Vector2i = region.get("size_tiles", Vector2i(36, 78))
	var region_cells: Array = region.get("cells", [])
	var tiles_x: int = ceili(world_size.x / float(TILE_SIZE))
	var tiles_y: int = ceili(world_size.y / float(TILE_SIZE))
	for tile_y: int in tiles_y:
		for tile_x: int in tiles_x:
			var tile := Vector2i(tile_x, tile_y)
			var world_position := Vector2(tile_x * TILE_SIZE, tile_y * TILE_SIZE)
			var kind: String = _terrain_kind(world_position, town_bounds, region, region_cells, region_size, origin, seed)
			var chunk_key := Vector2i(tile_x / CHUNK_TILES, tile_y / CHUNK_TILES)
			chunks[chunk_key] = true
			var variant: int = posmod(_stable_hash(tile, seed, int(TERRAIN_ROWS.get(kind, 0))), int(VARIANT_COUNTS.get(kind, 1)))
			base_tiles.set_cell(tile, 0, Vector2i(variant, int(TERRAIN_ROWS.get(kind, 0))))
			var overlay_index: int = _overlay_index(tile, kind, seed, town_bounds, world_position)
			if overlay_index >= 0:
				overlay_tiles.set_cell(tile, 1, Vector2i(overlay_index, 0))


func _terrain_kind(world_position: Vector2, town_bounds: Rect2, region: Dictionary, cells: Array, region_size: Vector2i, origin: Vector2, seed: int) -> String:
	var center := world_position + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	if town_bounds.has_point(center):
		return "cobble"
	# The underlying navigation and blockers remain untouched; this is only a
	# worn visual continuation of each painted town opening into the Moor.
	var town_center: Vector2 = town_bounds.get_center()
	var near_gate_road: bool = absf(center.x - town_center.x) <= 44.0 and center.y >= town_bounds.end.y and center.y <= town_bounds.end.y + 480.0
	if near_gate_road:
		return "road"
	if world_position.y >= origin.y:
		var local_tile := Vector2i(floori((world_position.x - origin.x) / TILE_SIZE), floori((world_position.y - origin.y) / TILE_SIZE))
		if local_tile.x >= 0 and local_tile.y >= 0 and local_tile.x < region_size.x and local_tile.y < region_size.y:
			var index: int = local_tile.y * region_size.x + local_tile.x
			if index >= 0 and index < cells.size():
				return String(cells[index].get("kind", "earth"))
	var outside_hash: int = absi(_stable_hash(Vector2i(floori(center.x / TILE_SIZE), floori(center.y / TILE_SIZE)), seed, 13))
	return "moss" if outside_hash % 3 == 0 else "earth"


func _overlay_index(tile: Vector2i, kind: String, seed: int, town_bounds: Rect2, world_position: Vector2) -> int:
	var overlay_hash: int = absi(_stable_hash(tile, seed, 41))
	var overlay_index: int = -1
	if kind == "cobble":
		var center := world_position + Vector2(16.0, 16.0)
		var edge_distance: float = minf(minf(center.x - town_bounds.position.x, town_bounds.end.x - center.x), minf(center.y - town_bounds.position.y, town_bounds.end.y - center.y))
		if edge_distance < 46.0 and overlay_hash % 3 == 0:
			overlay_index = 5
		elif overlay_hash % 11 == 0:
			overlay_index = 1
	elif kind == "earth" or kind == "road":
		if overlay_hash % 13 == 0:
			overlay_index = 0
		elif overlay_hash % 17 == 0:
			overlay_index = 2
	elif kind == "moss":
		if overlay_hash % 7 == 0:
			overlay_index = 3
		elif overlay_hash % 11 == 0:
			overlay_index = 4
	return overlay_index


func _stable_hash(tile: Vector2i, seed: int, salt: int) -> int:
	return tile.x * 73856093 ^ tile.y * 19349663 ^ seed * 83492791 ^ salt * 265443576
