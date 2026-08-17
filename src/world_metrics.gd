class_name WorldMetrics
extends RefCounted

## Shared world measurements for the native 64px migration.
##
## Terrain artwork and authored terrain cells use 64px. Gameplay navigation
## deliberately remains at 32px so narrow blockers and enemy routing keep their
## existing precision. Do not replace these values globally: attack ranges,
## movement distances, and UI dimensions are not grid measurements.

const TERRAIN_TILE_SIZE: int = 64
const TERRAIN_HALF_TILE: float = 32.0

const NAVIGATION_CELL_SIZE: int = 32
const BLOCKER_SAMPLE_SIZE: int = 32
const SPATIAL_HASH_CELL_SIZE: float = 48.0

const REGION_CELLS: Vector2i = Vector2i(18, 39)
const REGION_PIXEL_SIZE: Vector2i = Vector2i(1152, 2496)
const REFERENCE_VIEWPORT: Vector2i = Vector2i(390, 844)

static func terrain_cell_to_origin(cell: Vector2i) -> Vector2:
	return Vector2(cell) * float(TERRAIN_TILE_SIZE)

static func terrain_cell_to_center(cell: Vector2i) -> Vector2:
	return terrain_cell_to_origin(cell) + Vector2.ONE * TERRAIN_HALF_TILE

static func world_to_terrain_cell(position: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
	var local := position - origin
	return Vector2i(floori(local.x / float(TERRAIN_TILE_SIZE)), floori(local.y / float(TERRAIN_TILE_SIZE)))

static func world_to_navigation_cell(position: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
	var local := position - origin
	return Vector2i(floori(local.x / float(NAVIGATION_CELL_SIZE)), floori(local.y / float(NAVIGATION_CELL_SIZE)))

static func terrain_coverage_for_rect(rect: Rect2) -> Vector2i:
	return Vector2i(
		ceili(rect.size.x / float(TERRAIN_TILE_SIZE)),
		ceili(rect.size.y / float(TERRAIN_TILE_SIZE))
	)

static func snap_visual_to_pixel(position: Vector2) -> Vector2:
	return position.round()
