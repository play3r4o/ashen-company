extends SceneTree

const OUTPUT := "res://scenes/world/terrain/blackthorn_tileset.tres"


func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	var base := TileSetAtlasSource.new()
	base.texture = load("res://assets/runtime/world/blackthorn_tiles_reference.png")
	base.texture_region_size = Vector2i(32, 32)
	for y: int in range(9):
		for x: int in range(6):
			base.create_tile(Vector2i(x, y))
	tile_set.add_source(base, 0)
	var overlays := TileSetAtlasSource.new()
	overlays.texture = load("res://assets/runtime/world/blackthorn_overlays_reference.png")
	overlays.texture_region_size = Vector2i(32, 32)
	for x: int in range(6):
		overlays.create_tile(Vector2i(x, 0))
	tile_set.add_source(overlays, 1)
	var error := ResourceSaver.save(tile_set, OUTPUT)
	if error != OK:
		push_error("Could not save Blackthorn TileSet: %s" % error_string(error))
		quit(1)
		return
	print("Saved authored Blackthorn TileSet to %s" % OUTPUT)
	quit()
