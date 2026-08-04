extends SceneTree

var failures: int = 0


func _init() -> void:
	_check_directory("res://scenes/combat/projectiles", true)
	_check_directory("res://scenes/combat/effects", false)
	_check_directory("res://scenes/combat/pickups", false)
	_check_directory("res://scenes/combat/attacks", false)
	for path: String in _scene_files("res://scenes/actors/enemies"):
		var actor := (load(path) as PackedScene).instantiate()
		_check(actor.get_node_or_null("BodyVisual") is AnimatedSprite2D, "%s owns BodyVisual" % path)
		_check(actor.get_node_or_null("Body/CollisionShape2D") != null or actor.get_node_or_null("CharacterBody2D/CollisionShape2D") != null, "%s owns collision" % path)
		actor.free()
	print("Combat scene guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check_directory(root: String, require_area_root: bool) -> void:
	for path: String in _scene_files(root):
		var instance := (load(path) as PackedScene).instantiate()
		if require_area_root:
			_check(instance is Area2D, "%s uses Area2D root" % path)
		_check(_has_texture_art(instance), "%s owns explicitly assigned texture artwork" % path)
		_check(not _has_shape_art(instance), "%s does not expose fallback Line2D/Polygon2D production art" % path)
		instance.free()


func _has_texture_art(root: Node) -> bool:
	for child: Node in root.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			return true
		if child is AnimatedSprite2D and (child as AnimatedSprite2D).sprite_frames != null:
			return true
		if _has_texture_art(child):
			return true
	return false


func _has_shape_art(root: Node) -> bool:
	for child: Node in root.get_children():
		if child is Line2D or child is Polygon2D:
			return true
		if _has_shape_art(child):
			return true
	return false


func _scene_files(root: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		if not directory.current_is_dir() and name.ends_with(".tscn"):
			result.append(root.path_join(name))
		name = directory.get_next()
	directory.list_dir_end()
	return result


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("COMBAT SCENE FAIL: %s" % message)
