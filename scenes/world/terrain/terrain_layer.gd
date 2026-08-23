class_name AshenTerrainLayer
extends Node2D

const WorldMetrics = preload("res://src/world_metrics.gd")

## Native world presentation. Navigation and combat retain their own named
## 32px measurements; terrain is always authored and rendered at 64px.
@export var meadow_64_tileset: TileSet
@export var preserve_authored_meadow_grid: bool = true

const TILE_SIZE: int = WorldMetrics.TERRAIN_TILE_SIZE
const CHUNK_TILES: int = 8
const CHUNK_SIZE: int = TILE_SIZE * CHUNK_TILES
const GROUND_VARIANT_PATCH_TILES: int = 2
const TERRAIN_ROWS: Dictionary = {
	"earth": 0,
	"road": 1,
	"mud": 2,
	"moss": 3,
	"water": 4,
	"cobble": 5,
	"transition": 4,
	"thorn": 6,
	"barrier": 7,
	"gate": 8,
}
const VARIANT_COUNTS: Dictionary = {
	"earth": 6,
	"road": 6,
	"mud": 6,
	"moss": 6,
	"water": 6,
	"cobble": 6,
	"transition": 6,
	"thorn": 4,
	"barrier": 4,
	"gate": 4,
}
const GROUND_MATERIAL_KINDS: Array[String] = ["earth", "mud", "moss"]
const VISUAL_VARIANT_VERSION: int = 2

# The Tiny Swords meadow sheet is a 9x6 64px atlas.  Its large grass fields
# contain a few clean interior cells; using those cells for the generated
# ground keeps the new grid seamless while leaving the terrain semantics and
# the existing authored camp/landmark scenes unchanged.
const MEADOW_64_TILE_COORDS: Dictionary = {
	"earth": [Vector2i(1, 1), Vector2i(6, 1)],
	"road": [Vector2i(1, 1), Vector2i(6, 1)],
	"mud": [Vector2i(1, 1), Vector2i(6, 1)],
	"moss": [Vector2i(1, 1), Vector2i(6, 1)],
	"water": [Vector2i(1, 1), Vector2i(6, 1)],
	"cobble": [Vector2i(1, 1), Vector2i(6, 1)],
	"transition": [Vector2i(1, 1), Vector2i(6, 1)],
	"thorn": [Vector2i(1, 1), Vector2i(6, 1)],
	"barrier": [Vector2i(1, 1), Vector2i(6, 1)],
	"gate": [Vector2i(1, 1), Vector2i(6, 1)],
}

var chunks: Dictionary = {}
var rebuild_count: int = 0
var last_signature: String = ""
@onready var base_tiles: TileMapLayer = AshenSceneBindings.required(self, &"BaseTiles", "TerrainLayer") as TileMapLayer
@onready var water_fill: TileMapLayer = AshenSceneBindings.optional(self, &"WaterFill") as TileMapLayer
@onready var meadow_shadows: TileMapLayer = AshenSceneBindings.optional(self, &"MeadowShadows") as TileMapLayer
@onready var meadow_composition: TileMapLayer = AshenSceneBindings.optional(self, &"MeadowComposition") as TileMapLayer


func rebuild(region: Dictionary, origin: Vector2, seed: int, theme: Dictionary) -> void:
	var world_size: Vector2 = theme.get("world_size", Vector2.ZERO)
	var town_bounds: Rect2 = theme.get("town_bounds", Rect2())
	var signature := "%d:%s:%s:%s:%d:64" % [seed, world_size, town_bounds, region.get("size_tiles", Vector2i.ZERO), int(theme.get("version", 1))]
	if signature == last_signature and not chunks.is_empty():
		return
	last_signature = signature
	rebuild_count += 1
	if meadow_64_tileset == null:
		push_error("Native 64 terrain requires an assigned meadow_64_tileset")
		return
	if base_tiles == null:
		return
	if base_tiles.tile_set == null or base_tiles.tile_set.tile_size != Vector2i(TILE_SIZE, TILE_SIZE):
		push_error("Native 64 terrain requires BaseTiles to own an authored 64x64 TileSet")
		return
	for layer: TileMapLayer in [water_fill, meadow_shadows, meadow_composition]:
		if layer == null:
			push_error("Native 64 terrain is missing an authored visual layer")
			return
		if layer.scale != Vector2.ONE:
			push_error("Native 64 terrain layer %s must remain at authored scale 1" % layer.name)
			return
	if meadow_shadows.position != Vector2(0, 4):
		push_error("Native 64 MeadowShadows must keep its authored 4px downward offset")
		return
	var keep_authored_meadow_grid := preserve_authored_meadow_grid and not base_tiles.get_used_cells().is_empty()
	if not keep_authored_meadow_grid:
		base_tiles.clear()
	chunks.clear()
	# The TileMap transforms, TileSet assignments, layer visibility, and shadow
	# offset are authored in the Meadow scene. Runtime only binds generated cell
	# state; it never repairs or overrides the presentation authored in Godot.

	var region_size: Vector2i = region.get("size_tiles", WorldMetrics.REGION_CELLS)
	var region_cells: Array = region.get("cells", [])
	var tiles_x: int = ceili(world_size.x / float(TILE_SIZE))
	var tiles_y: int = ceili(world_size.y / float(TILE_SIZE))
	if keep_authored_meadow_grid:
		# BaseTiles is the editable source of truth in Meadow 64 mode.  Do not
		# repaint or reinterpret the cells the user authored in the scene.
		for cell: Vector2i in base_tiles.get_used_cells():
			chunks[Vector2i(floori(float(cell.x) / CHUNK_TILES), floori(float(cell.y) / CHUNK_TILES))] = true
		return
	for tile_y: int in tiles_y:
		for tile_x: int in tiles_x:
			var tile := Vector2i(tile_x, tile_y)
			var world_position := Vector2(tile_x * TILE_SIZE, tile_y * TILE_SIZE)
			var kind: String = _terrain_kind(world_position, town_bounds, region, region_cells, region_size, origin, seed)
			var chunk_key := Vector2i(tile_x / CHUNK_TILES, tile_y / CHUNK_TILES)
			chunks[chunk_key] = true
			var visual_kind := _visual_ground_kind(tile, kind, town_bounds, region, region_cells, region_size, origin, seed)
			var variant_tile := tile
			if GROUND_MATERIAL_KINDS.has(visual_kind) or visual_kind == "road" or visual_kind == "transition":
				variant_tile = Vector2i(floori(float(tile.x) / GROUND_VARIANT_PATCH_TILES), floori(float(tile.y) / GROUND_VARIANT_PATCH_TILES))
			var variant: int = posmod(_stable_hash(variant_tile, seed, visual_kind), int(VARIANT_COUNTS.get(visual_kind, 1)))
			base_tiles.set_cell(tile, 0, _visual_tile_coords(visual_kind, variant))


func _visual_tile_coords(visual_kind: String, variant: int) -> Vector2i:
	var candidates: Array = MEADOW_64_TILE_COORDS.get(visual_kind, MEADOW_64_TILE_COORDS["earth"])
	if candidates.is_empty():
		return Vector2i(1, 1)
	return Vector2i(candidates[variant % candidates.size()])


func _terrain_kind(world_position: Vector2, town_bounds: Rect2, region: Dictionary, cells: Array, region_size: Vector2i, origin: Vector2, seed: int) -> String:
	var center := world_position + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	# The refuge is an open island: do not synthesize a second cobbled floor from
	# its bounds. Physical blocking
	# is owned by the region boundary and authored asset scenes; a worn visual
	# continuation of each painted town opening must never invent a blocker.
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
	# Keep the outer world varied without turning it into a per-cell checkerboard.
	var cluster_tile := Vector2i(floori(center.x / float(TILE_SIZE * 3)), floori(center.y / float(TILE_SIZE * 3)))
	var outside_hash: int = absi(_stable_hash(cluster_tile, seed, "outside"))
	if outside_hash % 7 == 0:
		return "mud"
	return "moss" if outside_hash % 3 == 0 else "earth"


func _visual_ground_kind(tile: Vector2i, kind: String, town_bounds: Rect2, region: Dictionary, region_cells: Array, region_size: Vector2i, origin: Vector2, seed: int) -> String:
	if not GROUND_MATERIAL_KINDS.has(kind):
		return kind
	var mixed_neighbors: int = 0
	for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_position := Vector2((tile + offset) * TILE_SIZE)
		var neighbor_kind := _terrain_kind(neighbor_position, town_bounds, region, region_cells, region_size, origin, seed)
		if GROUND_MATERIAL_KINDS.has(neighbor_kind) and neighbor_kind != kind:
			mixed_neighbors += 1
	if mixed_neighbors > 0:
		return "transition"
	return kind


func _stable_hash(tile: Vector2i, seed: int, terrain_category: String) -> int:
	# Keep visual variation stable while making the terrain category an explicit
	# input.  A custom string hash avoids relying on a generated atlas index and
	# means changing the visual category cannot silently reuse another category's
	# deterministic pattern.
	var category_hash: int = 17
	for codepoint: int in terrain_category.to_utf8_buffer():
		category_hash = int(category_hash * 31 + codepoint)
	return tile.x * 73856093 ^ tile.y * 19349663 ^ seed * 83492791 ^ category_hash * 265443576 ^ VISUAL_VARIANT_VERSION * 97531
