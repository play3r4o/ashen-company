extends SceneTree

## Loads every production script, scene, and resource once. This catches
## broken ext_resource paths and parse errors in content that an ordinary
## smoke test may not reach yet.

const ROOTS: Array[String] = ["res://scenes", "res://src"]
const EXTENSIONS: Array[String] = ["gd", "gdshader", "tscn", "tres"]

var failures: int = 0
var loaded_count: int = 0


func _init() -> void:
	for root: String in ROOTS:
		for path: String in _files_below(root):
			var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if resource == null:
				failures += 1
				push_error("RESOURCE AUDIT FAIL: could not load %s" % path)
			else:
				loaded_count += 1
	print("Project resource audit: %d loaded, %d failure(s)" % [loaded_count, failures])
	quit(1 if failures > 0 else 0)


func _files_below(root_path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		failures += 1
		push_error("RESOURCE AUDIT FAIL: cannot open %s" % root_path)
		return result
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var path := root_path.path_join(name)
		if directory.current_is_dir():
			result.append_array(_files_below(path))
		elif name.get_extension().to_lower() in EXTENSIONS:
			result.append(path)
		name = directory.get_next()
	directory.list_dir_end()
	result.sort()
	return result
