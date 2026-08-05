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
	_check_player_animation_frames()
	_check_projectile_registry()
	_check_effect_registry()
	print("Combat scene guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check_player_animation_frames() -> void:
	for path: String in _scene_files("res://scenes/actors/player"):
		var actor := (load(path) as PackedScene).instantiate()
		var body := actor.get_node_or_null("BodyVisual") as AnimatedSprite2D
		_check(body != null and body.sprite_frames != null, "%s owns player animation frames" % path)
		if body == null or body.sprite_frames == null:
			actor.free()
			continue
		for direction: String in ["down", "left", "right", "up"]:
			for suffix: String in ["idle", "walk"]:
				var animation := StringName("%s_%s" % [direction, suffix])
				var frame_count: int = body.sprite_frames.get_frame_count(animation)
				_check(frame_count > 0, "%s defines %s" % [path, animation])
				for frame_index: int in frame_count:
					var texture := body.sprite_frames.get_frame_texture(animation, frame_index)
					_check(_frame_region_is_valid(texture), "%s %s frame %d stays inside its source canvas" % [path, animation, frame_index])
		actor.free()


func _frame_region_is_valid(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var atlas := texture as AtlasTexture
	if atlas == null:
		return texture.get_size().x > 0.0 and texture.get_size().y > 0.0
	if atlas.atlas == null or atlas.region.size.x <= 0.0 or atlas.region.size.y <= 0.0:
		return false
	var source_size := atlas.atlas.get_size()
	return atlas.region.position.x >= 0.0 and atlas.region.position.y >= 0.0 and atlas.region.end.x <= source_size.x and atlas.region.end.y <= source_size.y


func _check_directory(root: String, require_area_root: bool) -> void:
	for path: String in _scene_files(root):
		var instance := (load(path) as PackedScene).instantiate()
		if require_area_root:
			_check(instance is Area2D, "%s uses Area2D root" % path)
			_check(instance.get("hit_effect_scene") is PackedScene, "%s owns its authored hit-effect reference" % path)
		_check(_has_texture_art(instance), "%s owns explicitly assigned texture artwork" % path)
		_check(not _has_shape_art(instance), "%s does not expose fallback Line2D/Polygon2D production art" % path)
		instance.free()


func _check_projectile_registry() -> void:
	var script := load("res://scenes/combat/combat_presentation_controller.gd") as Script
	var registry: Dictionary = script.get_script_constant_map().get("PROJECTILE_SCENES", {})
	for required_id: String in ["bow", "crossbow", "sling", "throwing_knives", "daggers", "chakrams", "staff", "wand", "runic_orb", "witchfire", "enemy_arrow"]:
		_check(registry.get(required_id) is PackedScene, "projectile registry owns %s" % required_id)
	var scene_paths: Dictionary = {}
	var texture_paths: Dictionary = {}
	for projectile_id: String in registry:
		var scene := registry[projectile_id] as PackedScene
		var scene_path: String = scene.resource_path
		_check(not scene_paths.has(scene_path), "projectile %s has a dedicated scene instead of sharing %s" % [projectile_id, scene_path])
		scene_paths[scene_path] = projectile_id
		var instance := scene.instantiate()
		var texture_path := _first_texture_path(instance)
		_check(not texture_path.is_empty(), "projectile %s owns a canonical texture" % projectile_id)
		_check(not texture_paths.has(texture_path), "projectile %s does not substitute %s artwork" % [projectile_id, texture_paths.get(texture_path, texture_path)])
		texture_paths[texture_path] = projectile_id
		instance.free()


func _check_effect_registry() -> void:
	var script := load("res://scenes/combat/combat_presentation_controller.gd") as Script
	var registry: Dictionary = script.get_script_constant_map().get("EFFECT_SCENES", {})
	var expected: Array[String] = ["impact", "guard", "rain", "mark", "dash", "smoke", "poison", "nova", "frost", "lightning", "thrust", "arc", "arcane", "ring", "spark", "burst"]
	_check(registry.size() == expected.size(), "combat presentation registers exactly the authored effect set")
	var scene_paths: Dictionary = {}
	for effect_id: String in expected:
		var scene := registry.get(effect_id) as PackedScene
		_check(scene != null, "effect registry owns %s" % effect_id)
		if scene == null:
			continue
		_check(not scene_paths.has(scene.resource_path), "effect %s has a dedicated scene" % effect_id)
		scene_paths[scene.resource_path] = effect_id
		var instance := scene.instantiate()
		_check(String(instance.get("effect_id")) == effect_id, "%s scene declares its stable ID" % effect_id)
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


func _first_texture_path(root: Node) -> String:
	for child: Node in root.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			return (child as Sprite2D).texture.resource_path
		var nested := _first_texture_path(child)
		if not nested.is_empty():
			return nested
	return ""


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
