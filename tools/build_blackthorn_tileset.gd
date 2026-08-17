extends SceneTree

## Retired 32px generator.  Keep its output in the archive so running this
## historical tool cannot overwrite the canonical native-64 TileSet.
const OUTPUT := "res://art/archive/runtime_legacy/foundation/terrain/blackthorn_tileset_32.tres"


func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	var base := TileSetAtlasSource.new()
	base.texture = load("res://assets/runtime/world/blackthorn_tiles_v02.png")
	base.texture_region_size = Vector2i(32, 32)
	for y: int in range(9):
		for x: int in range(6):
			base.create_tile(Vector2i(x, y))
	tile_set.add_source(base, 0)
	var overlays := TileSetAtlasSource.new()
	overlays.texture = load("res://assets/runtime/world/blackthorn_overlays_v02.png")
	overlays.texture_region_size = Vector2i(32, 32)
	for x: int in range(39):
		overlays.create_tile(Vector2i(x, 0))
	tile_set.add_source(overlays, 1)
	var error := ResourceSaver.save(tile_set, OUTPUT)
	if error != OK:
		push_error("Could not save Blackthorn TileSet: %s" % error_string(error))
		quit(1)
		return
	print("Saved authored Blackthorn TileSet to %s" % OUTPUT)
	quit()
