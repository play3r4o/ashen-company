extends SceneTree

const TILESET_PATH := "res://scenes/world/terrain/blackthorn_tileset.tres"
const BLOCKING_ROWS: Array[int] = [6, 7]


func _init() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	if tile_set == null:
		push_error("Unable to load authored TileSet: %s" % TILESET_PATH)
		quit(1)
		return
	while tile_set.get_physics_layers_count() < 1:
		tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null:
		push_error("Blackthorn TileSet source 0 is not an atlas")
		quit(1)
		return
	var footprint := PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
	])
	for row: int in BLOCKING_ROWS:
		for column: int in 6:
			var tile_data := atlas.get_tile_data(Vector2i(column, row), 0)
			if tile_data == null:
				push_error("Missing blocking tile at %d,%d" % [column, row])
				quit(1)
				return
			while tile_data.get_collision_polygons_count(0) < 1:
				tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, footprint)
	var error := ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		push_error("Unable to save authored TileSet collision: %s" % error_string(error))
		quit(1)
		return
	quit()
