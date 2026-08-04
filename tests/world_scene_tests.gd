extends SceneTree

var failures: int = 0


func _init() -> void:
	for tier: int in 5:
		var path: String = "res://scenes/world/camp/camp_tier_%d.tscn" % tier
		var camp := (load(path) as PackedScene).instantiate() as AshenCampRuntime
		camp.bind_state(tier, {}, {})
		_check(camp.camp_bounds_world().has_area(), "%s owns authored bounds" % path)
		_check(camp.safe_zone_polygon_world().size() >= 3, "%s owns a gate safe zone" % path)
		_check(camp.no_spawn_polygon_world().size() >= 3, "%s owns a no-spawn zone" % path)
		_check(camp.gate_transition_polygon_world().size() >= 3, "%s owns a gate transition polygon" % path)
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
