extends SceneTree

func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	var ground := TileSetAtlasSource.new()
	var ground_image := Image.load_from_file("assets/runtime/world/blackthorn_tiles_64.png")
	ground.texture = ImageTexture.create_from_image(ground_image)
	ground.texture_region_size = Vector2i(64, 64)
	for y: int in 9:
		for x: int in 6:
			var coordinate := Vector2i(x, y)
			ground.create_tile(coordinate)
	tile_set.add_source(ground, 0)
	for y: int in 9:
		if y != 6 and y != 7:
			continue
		for x: int in 6:
			var data := ground.get_tile_data(Vector2i(x, y), 0)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-32, -32), Vector2(32, -32), Vector2(32, 32), Vector2(-32, 32),
			]))
	var overlays := TileSetAtlasSource.new()
	var overlay_image := Image.load_from_file("assets/runtime/world/blackthorn_overlays_64.png")
	overlays.texture = ImageTexture.create_from_image(overlay_image)
	overlays.texture_region_size = Vector2i(64, 64)
	for x: int in 39:
		overlays.create_tile(Vector2i(x, 0))
	tile_set.add_source(overlays, 1)
	var result := ResourceSaver.save(tile_set, "res://scenes/world/terrain/blackthorn_tileset_64.tres")
	if result != OK:
		push_error("Could not write native camp TileSet: %s" % result)
	else:
		print("Wrote res://scenes/world/terrain/blackthorn_tileset_64.tres")
	quit()
