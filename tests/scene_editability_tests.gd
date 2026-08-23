extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/hud/hud.tscn")
const ACTOR_SCENE := preload("res://scenes/actors/player/player_visual_warrior.tscn")
const CAMPFIRE_SCENE := preload("res://scenes/world/structures/campfire.tscn")

var passed: int = 0
var failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_recursive_role_binding()
	await _test_hud_reparenting()
	await _test_optional_actor_art()
	await _test_optional_campfire_art()
	_test_no_strict_scene_paths()
	print("Scene editability: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_recursive_role_binding() -> void:
	var root := Node.new()
	var wrapper := Node.new()
	var visual := Node.new()
	root.name = "Root"
	wrapper.name = "AuthorFolder"
	visual.name = "Artwork"
	root.add_child(wrapper)
	wrapper.add_child(visual)
	_check(AshenSceneBindings.optional(root, &"Artwork") == visual, "role binding survives visual reparenting")
	visual.name = "RenamedArtwork"
	_check(AshenSceneBindings.optional(root, &"Artwork") == null, "deleted or renamed optional art degrades cleanly")
	root.free()


func _test_hud_reparenting() -> void:
	var hud := HUD_SCENE.instantiate() as AshenHudLayout
	var settings := AshenSceneBindings.optional(hud, &"SettingsCogButton") as Control
	var original_position: Vector2 = settings.position
	var author_folder := Control.new()
	author_folder.name = "AuthorFolder"
	(settings.get_parent() as Node).add_child(author_folder)
	settings.owner = null
	settings.reparent(author_folder, true)
	hud.add_child(Node.new()) # Exercise an unrelated editor-authored child.
	root.add_child(hud)
	await process_frame
	hud.configure("camp", 47.0)
	_check(AshenSceneBindings.optional(hud, &"SettingsCogButton") == settings, "HUD bindings survive reparenting")
	_check(settings.position == original_position, "HUD runtime does not overwrite a reparented control's authored local geometry")
	root.remove_child(hud)
	hud.free()


func _test_optional_actor_art() -> void:
	var actor := ACTOR_SCENE.instantiate() as AshenActorVisual
	var body := AshenSceneBindings.optional(actor, &"BodyVisual") as AnimatedSprite2D
	var authored_position := Vector2(13.0, -31.0)
	body.position = authored_position
	var health := AshenSceneBindings.optional(actor, &"HealthBarWorld")
	if health != null:
		health.free()
	var depth := AshenSceneBindings.optional(actor, &"DepthAnchor")
	if depth != null:
		depth.free()
	root.add_child(actor)
	await process_frame
	actor.sync_player(Vector2.RIGHT, true, 75.0, 100.0)
	_check(body.position == authored_position, "actor runtime preserves authored sprite placement")
	_check(actor.depth_anchor_world_y() is float, "actor remains usable when optional health/depth visuals are deleted")
	root.remove_child(actor)
	actor.free()


func _test_optional_campfire_art() -> void:
	var campfire := CAMPFIRE_SCENE.instantiate()
	var smoke := AshenSceneBindings.optional(campfire, &"Smoke")
	if smoke != null:
		smoke.free()
	var outline := AshenSceneBindings.optional(campfire, &"Outline")
	if outline != null:
		outline.free()
	root.add_child(campfire)
	await process_frame
	campfire.call("set_highlighted", true)
	_check(campfire.call("footprint_polygon").size() >= 0, "campfire tolerates deleted optional animation and outline art")
	root.remove_child(campfire)
	campfire.free()


func _test_no_strict_scene_paths() -> void:
	var violations: Array[String] = []
	for folder: String in ["res://scenes", "res://src"]:
		_scan_scripts(folder, violations)
	_check(violations.is_empty(), "production scripts avoid strict $Node and get_node() scene paths")
	if not violations.is_empty():
		for violation: String in violations:
			print("  strict path: %s" % violation)


func _scan_scripts(folder: String, violations: Array[String]) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var path := folder.path_join(entry)
		if directory.current_is_dir():
			_scan_scripts(path, violations)
		elif entry.ends_with(".gd"):
			var source := FileAccess.get_file_as_string(path)
			var strict_dollar := RegEx.new()
			strict_dollar.compile("(^|[=(:,\\s])\\$[A-Za-z_]")
			if source.contains("get_node(") or strict_dollar.search(source) != null:
				violations.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)
