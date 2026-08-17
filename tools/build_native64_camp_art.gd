extends SceneTree

## Builds native 64px versions of the approved authored camp terrain atlas.
## Nearest-neighbour enlargement preserves the source pixels while removing
## the old 0.5 presentation scale from camp TileMapLayers.

func _init() -> void:
	for pair: Array in [
		["res://assets/runtime/world/blackthorn_tiles_v02.png", "res://assets/runtime/world/blackthorn_tiles_64.png"],
		["res://assets/runtime/world/blackthorn_overlays_v02.png", "res://assets/runtime/world/blackthorn_overlays_64.png"],
	]:
		var source := Image.load_from_file(String(pair[0]))
		if source == null:
			push_error("Could not load %s" % String(pair[0]))
			continue
		source.resize(source.get_width() * 2, source.get_height() * 2, Image.INTERPOLATE_NEAREST)
		var result := source.save_png(String(pair[1]))
		if result != OK:
			push_error("Could not write %s" % String(pair[1]))
		else:
			print("Wrote ", pair[1])
	quit()
