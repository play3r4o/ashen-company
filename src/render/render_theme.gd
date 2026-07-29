class_name AshenRenderTheme
extends Resource

const VISUAL_VERSION: int = 2
const TILE_SIZE: int = 32
const CHUNK_TILES: int = 8

static func terrain_config(base_atlas: Texture2D, overlay_atlas: Texture2D, world_size: Vector2, town_bounds: Rect2) -> Dictionary:
	return {
		"version": VISUAL_VERSION,
		"base_atlas": base_atlas,
		"overlay_atlas": overlay_atlas,
		"world_size": world_size,
		"town_bounds": town_bounds,
	}
