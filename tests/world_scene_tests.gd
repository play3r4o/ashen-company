extends SceneTree

var failures: int = 0


func _init() -> void:
	var tile_set := load("res://scenes/world/terrain/blackthorn_tileset.tres") as TileSet
	_check(tile_set != null and tile_set.get_physics_layers_count() == 1, "Blackthorn TileSet owns its authored blocker physics layer")
	if tile_set != null:
		var atlas := tile_set.get_source(0) as TileSetAtlasSource
		for row: int in [6, 7]:
			for column: int in 6:
				var tile_data := atlas.get_tile_data(Vector2i(column, row), 0)
				_check(tile_data != null and tile_data.get_collision_polygons_count(0) == 1, "blocking tile %d,%d owns collision" % [column, row])
	for tier: int in 5:
		var path: String = "res://scenes/world/camp/camp_tier_%d.tscn" % tier
		var camp := (load(path) as PackedScene).instantiate() as AshenCampRuntime
		camp.bind_state(tier, {}, {})
		_check(camp.camp_bounds_world().has_area(), "%s owns authored bounds" % path)
		_check(camp.safe_zone_polygon_world().size() >= 3, "%s owns a gate safe zone" % path)
		_check(camp.no_spawn_polygon_world().size() >= 3, "%s owns a no-spawn zone" % path)
		_check(camp.gate_transition_polygon_world().size() >= 3, "%s owns a gate transition polygon" % path)
		var gate := camp.get_node_or_null("Gate")
		_check(gate != null and gate.get_node_or_null("Prompt") != null, "%s gate owns its visual transition prompt" % path)
		for id: String in ["veterans_hall", "campfire"]:
			var info: Dictionary = camp.structure_info(id)
			_check(PackedVector2Array(info.get("footprint", PackedVector2Array())).size() >= 3, "%s %s owns collision" % [path, id])
			_check(PackedVector2Array(info.get("interaction", PackedVector2Array())).size() >= 3, "%s %s owns interaction" % [path, id])
		camp.free()
	print("World scene guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("WORLD SCENE FAIL: %s" % message)
