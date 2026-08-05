extends SceneTree

var failures: int = 0


func _init() -> void:
	var path: String = "res://assets/runtime/asset_manifest.json"
	_check(FileAccess.file_exists(path), "canonical runtime manifest exists")
	var manifests: Array[String] = _named_files_below("res://assets/runtime", "asset_manifest.json")
	_check(manifests == [path], "assets/runtime contains exactly one canonical manifest")
	if failures == 0:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_check(parsed is Dictionary, "runtime manifest parses as a dictionary")
		if parsed is Dictionary:
			_check(int(parsed.get("schema_version", 0)) == 1, "runtime manifest schema is version 1")
			var registered_paths: Dictionary = {}
			for asset_id: String in parsed.get("assets", {}):
				var record: Dictionary = parsed.assets[asset_id]
				var asset_path: String = String(record.get("path", ""))
				_check(asset_path.begins_with("res://assets/runtime/"), "%s uses the canonical runtime root" % asset_id)
				_check(FileAccess.file_exists(asset_path), "%s exists at %s" % [asset_id, asset_path])
				_check(not registered_paths.has(asset_path), "%s is registered by one stable asset ID" % asset_path)
				_check(not String(record.get("approval", "")).begins_with("res://"), "%s approval is metadata, not a source-art runtime path" % asset_id)
				registered_paths[asset_path] = asset_id
				if asset_path.ends_with(".png"):
					var texture := load(asset_path) as Texture2D
					var expected_size: Array = record.get("size", [])
					_check(texture != null and expected_size.size() == 2 and texture.get_size() == Vector2(float(expected_size[0]), float(expected_size[1])), "%s matches its declared dimensions" % asset_id)
					_check(String(record.get("filter", "")) == "nearest", "%s declares nearest-neighbour filtering" % asset_id)
			for source_path: String in _files_below("res://scenes", ["tscn", "tres", "gd"]):
				var source: String = FileAccess.get_file_as_string(source_path)
				var offset: int = 0
				while true:
					var start: int = source.find("res://assets/runtime/", offset)
					if start < 0:
						break
					var finish: int = start
					while finish < source.length() and source[finish] not in ['\"', "'", ')', ']', '}', ' ', '\r', '\n']:
						finish += 1
					var referenced_path: String = source.substr(start, finish - start)
					if not referenced_path.contains("%"):
						_check(registered_paths.has(referenced_path), "%s reference from %s is registered" % [referenced_path, source_path])
					offset = finish + 1
			_check_combat_vfx_alpha()
			_check_projectile_alpha()
	print("Asset manifest guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _named_files_below(root_path: String, file_name: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		var child_path: String = root_path.path_join(name)
		if directory.current_is_dir():
			result.append_array(_named_files_below(child_path, file_name))
		elif name == file_name:
			result.append(child_path)
		name = directory.get_next()
	directory.list_dir_end()
	result.sort()
	return result


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("ASSET MANIFEST FAIL: %s" % message)


func _check_combat_vfx_alpha() -> void:
	for effect_id: String in ["impact", "guard", "rain", "mark", "dash", "smoke", "poison", "nova", "frost", "lightning", "thrust", "arc", "arcane", "ring", "spark", "burst"]:
		var path := "res://assets/runtime/effects/%s.png" % effect_id
		var texture := load(path) as Texture2D
		var image := texture.get_image() if texture != null else Image.new()
		_check(not image.is_empty() and image.get_size() == Vector2i(320, 320), "%s uses the stable authored VFX canvas" % effect_id)
		if image.is_empty():
			continue
		_check(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(319, 319).a <= 0.01, "%s has transparent padded corners" % effect_id)
		var used_rect := image.get_used_rect()
		_check(used_rect.has_area() and used_rect.position.x > 0 and used_rect.position.y > 0 and used_rect.end.x < 320 and used_rect.end.y < 320, "%s stays inside its fixed pivot canvas" % effect_id)


func _check_projectile_alpha() -> void:
	for projectile_id: String in ["crossbow_bolt", "dagger", "staff_bolt", "witchfire"]:
		var path := "res://assets/runtime/combat/%s.png" % projectile_id
		var texture := load(path) as Texture2D
		var image := texture.get_image() if texture != null else Image.new()
		_check(not image.is_empty() and image.get_size() == Vector2i(64, 64), "%s uses its dedicated fixed projectile canvas" % projectile_id)
		if image.is_empty():
			continue
		_check(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(63, 63).a <= 0.01, "%s has transparent padded corners" % projectile_id)


func _files_below(root_path: String, extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		var path: String = root_path.path_join(name)
		if directory.current_is_dir():
			result.append_array(_files_below(path, extensions))
		elif name.get_extension() in extensions:
			result.append(path)
		name = directory.get_next()
	directory.list_dir_end()
	return result
