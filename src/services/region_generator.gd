class_name RegionGenerator
extends RefCounted

const WorldMetrics = preload("res://src/world_metrics.gd")

const TILE_SIZE: int = WorldMetrics.TERRAIN_TILE_SIZE
const REGION_TILES: Vector2i = WorldMetrics.REGION_CELLS
const REGION_PIXEL_SIZE: Vector2i = WorldMetrics.REGION_PIXEL_SIZE
## The north/south openings sit between columns 8 and 9.  The east/west
## openings sit between rows 19 and 20.  Keep these indices separate from
## navigation cells: this is the 64px terrain grid only.
const GATE_TILE_X: int = 9
const SIDE_GATE_TILE_Y: int = 20

static func generate_blackthorn(seed_value: int) -> Dictionary:
	var cells: Array[Dictionary] = []
	var landmarks: Array[Dictionary] = []
	var chunks: Array[Dictionary] = []
	var road_centers: Array[int] = []
	var road_x: int = GATE_TILE_X
	for y: int in REGION_TILES.y:
		if y % 8 == 0 and y > 0:
			road_x = clampi(road_x + _stable_noise(Vector2i(road_x, y), seed_value, 7, 3) - 1, 2, REGION_TILES.x - 3)
		if y >= REGION_TILES.y - 8:
			road_x += signi(GATE_TILE_X - road_x)
		road_centers.append(road_x)
	for chunk_y: int in ceili(float(REGION_TILES.y) / 12.0):
		for chunk_x: int in ceili(float(REGION_TILES.x) / 12.0):
			chunks.append({"coord": Vector2i(chunk_x, chunk_y), "seed": seed_value ^ (chunk_x * 73856093) ^ (chunk_y * 19349663)})
	for y: int in REGION_TILES.y:
		road_x = road_centers[y]
		for x: int in REGION_TILES.x:
			# Roads occupy exactly two native 64px cells.  `road_x` is the
			# right-hand cell of the corridor, so the corridor remains centered
			# around the same authored gate axis without accidentally becoming a
			# three-cell-wide gameplay/material band.
			var road: bool = x == road_x or x == road_x - 1
			var noise: float = float(_stable_noise(Vector2i(x, y), seed_value, 17, 1000)) / 1000.0
			var kind: String = "road" if road else ("mud" if noise < 0.16 else ("moss" if noise < 0.54 else "earth"))
			# Blackthorn Moor is an open exploration surface. Physical obstacles
			# belong to authored assets (camp structures, props and the ruined-city
			# district), not to the old 32px terrain grid. World-size clamping keeps
			# actors inside the playable map; there is no hidden procedural wall.
			cells.append({"position": Vector2i(x, y), "kind": kind})
	# Keep the four painted frontier approaches authoritative. These are the same
	# centers used by traversal and smoke tests, so a generated biome always has
	# four open directions even when the road generator changes later.
	for x: int in [8, 9]:
		cells[x]["kind"] = "road"
		cells[(REGION_TILES.y - 1) * REGION_TILES.x + x]["kind"] = "road"
	for y: int in [19, 20]:
		cells[y * REGION_TILES.x]["kind"] = "road"
		cells[y * REGION_TILES.x + REGION_TILES.x - 1]["kind"] = "road"
	for index: int in 10:
		# Preserve the old pixel progression (320, 512, ...) instead of simply
		# halving old integer tile indices.  This keeps discovery order and route
		# spacing stable while moving to the native 64px terrain grid.
		var landmark_pixel_y: int = 320 + index * 192
		var landmark_y: int = clampi(floori(float(landmark_pixel_y) / float(TILE_SIZE)), 5, REGION_TILES.y - 5)
		var tile := Vector2i(clampi(road_centers[landmark_y] + (-2 if index % 2 == 0 else 2), 2, REGION_TILES.x - 3), landmark_y)
		landmarks.append({
			"id": "site_%02d" % index,
			"kind": ["cache", "shrine", "danger", "barrow"][index % 4],
			"position": Vector2(tile.x * TILE_SIZE + WorldMetrics.TERRAIN_HALF_TILE, tile.y * TILE_SIZE + WorldMetrics.TERRAIN_HALF_TILE),
			"dread": 3.0 + float(index % 4) * 2.0
		})
	# The Meadow's first authored discovery district.  Keep the city beside the
	# generated road so it is reachable from the gate, while reserving a clear
	# central approach through the ruined walls.  The matching prison point is
	# deliberately just south of the intact cell so the player can approach it
	# without entering the structure's blocker cells.
	# The expanded city needs a little room on both sides of the authored
	# district. Keep its south gate near the generated road, but bias the
	# anchor west so the new eastern quarter remains inside the playable field.
	# Preserve the authored city world-pixel progression while changing the
	# terrain grid. This is a world coordinate, not a grid-cell measurement.
	const AUTHORED_CITY_PIXEL_Y: float = 976.0
	var city_pixel_y: float = AUTHORED_CITY_PIXEL_Y
	var city_tile_y: int = clampi(floori(city_pixel_y / float(TILE_SIZE)), 6, REGION_TILES.y - 7)
	var city_tile := Vector2i(clampi(road_centers[city_tile_y] - 2, 3, REGION_TILES.x - 5), city_tile_y)
	var city_position := Vector2(city_tile.x * TILE_SIZE + WorldMetrics.TERRAIN_HALF_TILE, city_pixel_y)
	landmarks.append({
		"id": "ruined_city",
		"kind": "ruined_city",
		"position": city_position,
		"dread": 8.0
	})
	landmarks.append({
		"id": "meadow_prison",
		"kind": "prison",
		# The interaction point is authored against the prison wing's local
		# approach in ruined_city_site.tscn.  Keep it just south of the intact
		# cell, inside the scene's InteractionArea, so the visible lock and the
		# contextual action always agree after the city is expanded.
		"position": city_position + Vector2(510.0, 280.0),
		"dread": 2.0
	})
	return {
		"seed": seed_value,
		"tile_size": TILE_SIZE,
		"size_tiles": REGION_TILES,
		"grid_version": 64,
		"pixel_size": REGION_PIXEL_SIZE,
		"cells": cells,
		"chunks": chunks,
		# Physical blockers are read from the instantiated authored city and wall
		# scenes by the navigation cache. The generator owns semantic landmarks,
		# never a second hard-coded copy of their collision rectangles.
		"blockers": [],
		"landmarks": landmarks,
		"entry": Vector2(REGION_PIXEL_SIZE.x * 0.5, 3 * TILE_SIZE + WorldMetrics.TERRAIN_HALF_TILE),
		"frontier_gate": Vector2(REGION_PIXEL_SIZE.x * 0.5, (REGION_TILES.y - 4) * TILE_SIZE + WorldMetrics.TERRAIN_HALF_TILE)
	}

static func _stable_noise(cell: Vector2i, seed_value: int, salt: int, modulus: int) -> int:
	var value: int = seed_value ^ (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	value = int(value ^ (value >> 13))
	value = int(value * 1274126177)
	value = int(value ^ (value >> 16))
	return posmod(value, maxi(1, modulus))

static func signature(region: Dictionary) -> int:
	# Include the semantic grid contract in the deterministic signature.  A
	# future visual-version change must not accidentally reuse a cached region
	# generated under a different terrain-cell contract.
	var result: int = int(region.get("seed", 0))
	result = result ^ int(region.get("grid_version", 0)) * 83492791
	result = result ^ int(region.get("tile_size", 0)) * 19349663
	var size_tiles: Vector2i = Vector2i(region.get("size_tiles", Vector2i.ZERO))
	result = result ^ size_tiles.x * 73856093 ^ size_tiles.y * 19349663
	for landmark_value: Variant in region.get("landmarks", []):
		if landmark_value is Dictionary:
			var point: Vector2 = landmark_value.get("position", Vector2.ZERO)
			result = result ^ int(point.x * 31.0 + point.y * 17.0)
	return result
