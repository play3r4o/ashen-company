class_name RegionGenerator
extends RefCounted

const TILE_SIZE: int = 32
const REGION_TILES: Vector2i = Vector2i(36, 78)
const GATE_TILE_X: int = 18
const SIDE_GATE_TILE_Y: int = 39

static func generate_blackthorn(seed_value: int) -> Dictionary:
	var roll := RandomNumberGenerator.new()
	roll.seed = seed_value
	var cells: Array[Dictionary] = []
	var blockers: Array[Rect2] = []
	var landmarks: Array[Dictionary] = []
	var chunks: Array[Dictionary] = []
	var road_centers: Array[int] = []
	var road_x: int = GATE_TILE_X
	for y: int in REGION_TILES.y:
		if y % 8 == 0 and y > 0:
			road_x = clampi(road_x + roll.randi_range(-5, 5), 12, REGION_TILES.x - 13)
		if y >= REGION_TILES.y - 8:
			road_x += signi(GATE_TILE_X - road_x)
		road_centers.append(road_x)
	for chunk_y: int in ceili(float(REGION_TILES.y) / 12.0):
		for chunk_x: int in ceili(float(REGION_TILES.x) / 12.0):
			chunks.append({"coord": Vector2i(chunk_x, chunk_y), "seed": seed_value ^ (chunk_x * 73856093) ^ (chunk_y * 19349663)})
	for y: int in REGION_TILES.y:
		road_x = road_centers[y]
		for x: int in REGION_TILES.x:
			var edge: bool = x < 2 or y < 2 or x >= REGION_TILES.x - 2 or y >= REGION_TILES.y - 2
			var cardinal_opening: bool = (y < 3 and absi(x - GATE_TILE_X) <= 2) or (y >= REGION_TILES.y - 3 and absi(x - GATE_TILE_X) <= 2) or (x < 3 and absi(y - SIDE_GATE_TILE_Y) <= 2) or (x >= REGION_TILES.x - 3 and absi(y - SIDE_GATE_TILE_Y) <= 2)
			var road: bool = absi(x - road_x) <= 2
			var noise: float = roll.randf()
			var kind: String = "road" if road else ("mud" if noise < 0.16 else ("moss" if noise < 0.54 else "earth"))
			var interior_barrier: bool = not road and y > 5 and y < REGION_TILES.y - 6 and absi(x - road_x) > 5 and noise > 0.91
			if interior_barrier:
				kind = "thorn" if ((x + y) & 1) == 0 else "barrier"
			if edge and not cardinal_opening:
				kind = "barrier"
			cells.append({"position": Vector2i(x, y), "kind": kind})
			if edge and not cardinal_opening:
				blockers.append(Rect2(Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE)))
			elif interior_barrier:
				blockers.append(Rect2(Vector2(x * TILE_SIZE + 3, y * TILE_SIZE + 3), Vector2(TILE_SIZE - 6, TILE_SIZE - 6)))
	# Keep the four painted frontier approaches authoritative even if a future
	# terrain rule changes the edge test above. These are the same centers used by
	# the traversal and smoke tests, so a generated biome can never seal itself.
	for opening: Vector2i in [
		Vector2i(GATE_TILE_X, 0),
		Vector2i(REGION_TILES.x - 1, SIDE_GATE_TILE_Y),
		Vector2i(0, SIDE_GATE_TILE_Y),
		Vector2i(GATE_TILE_X, REGION_TILES.y - 1)
		]:
		var opening_index: int = opening.y * REGION_TILES.x + opening.x
		cells[opening_index]["kind"] = "road"
		var opening_rect := Rect2(Vector2(opening * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
		for blocker_index: int in range(blockers.size() - 1, -1, -1):
			var blocker: Rect2 = blockers[blocker_index]
			if opening_rect.has_point(blocker.get_center()):
				blockers.remove_at(blocker_index)
	for index: int in 10:
		var landmark_y: int = 10 + index * 6
		var tile := Vector2i(clampi(road_centers[landmark_y] + (-4 if index % 2 == 0 else 4), 4, REGION_TILES.x - 5), landmark_y)
		landmarks.append({
			"id": "site_%02d" % index,
			"kind": ["cache", "shrine", "danger", "barrow"][index % 4],
			"position": Vector2(tile.x * TILE_SIZE + 16, tile.y * TILE_SIZE + 16),
			"dread": 3.0 + float(index % 4) * 2.0
		})
	return {
		"seed": seed_value,
		"tile_size": TILE_SIZE,
		"size_tiles": REGION_TILES,
		"cells": cells,
		"chunks": chunks,
		"blockers": blockers,
		"landmarks": landmarks,
		"entry": Vector2(GATE_TILE_X * TILE_SIZE + 16, 3 * TILE_SIZE + 16),
		"frontier_gate": Vector2(GATE_TILE_X * TILE_SIZE + 16, (REGION_TILES.y - 4) * TILE_SIZE + 16)
	}

static func signature(region: Dictionary) -> int:
	var result: int = int(region.get("seed", 0))
	for landmark_value: Variant in region.get("landmarks", []):
		if landmark_value is Dictionary:
			var point: Vector2 = landmark_value.get("position", Vector2.ZERO)
			result = result ^ int(point.x * 31.0 + point.y * 17.0)
	return result
