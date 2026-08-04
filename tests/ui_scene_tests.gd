extends SceneTree

const SCREEN_ROOTS: Array[String] = [
	"res://scenes/ui/screens",
	"res://scenes/ui/overlays",
]

var failures: int = 0


func _init() -> void:
	for root: String in SCREEN_ROOTS:
		for path: String in _scene_files(root):
			var scene := load(path) as PackedScene
			_check(scene != null, "%s loads" % path)
			if scene == null:
				continue
			var instance := scene.instantiate()
			_check(instance is Control, "%s has a Control root" % path)
			_check(_has_visible_authored_surface(instance), "%s owns an authored panel or background" % path)
			instance.free()
	print("UI scene guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _has_visible_authored_surface(root: Node) -> bool:
	if root is NinePatchRect or root is TextureRect or root is PanelContainer:
		return true
	for child: Node in root.get_children():
		if _has_visible_authored_surface(child):
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
	push_error("UI SCENE FAIL: %s" % message)
