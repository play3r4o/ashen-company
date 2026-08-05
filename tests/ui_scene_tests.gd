extends SceneTree

const SCREEN_ROOTS: Array[String] = [
	"res://scenes/ui/screens",
	"res://scenes/ui/overlays",
]

var failures: int = 0


func _init() -> void:
	var game_root_scene := load("res://scenes/app/game_root.tscn") as PackedScene
	var game_root := game_root_scene.instantiate() as Control if game_root_scene != null else null
	_check(game_root != null and game_root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the authored game root does not block world touch interaction")
	if game_root != null:
		game_root.free()
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
	for required_overlay: String in ["arrival_crest.tscn", "pause_overlay.tscn", "level_up_overlay.tscn", "relic_choice_overlay.tscn", "gate_confirmation_overlay.tscn", "reset_confirmation_overlay.tscn", "dismantle_confirmation_overlay.tscn"]:
		_check(FileAccess.file_exists("res://scenes/ui/overlays/%s" % required_overlay), "authored overlay exists: %s" % required_overlay)
	_check_pause_overlay_binding()
	for screen_name: String in ["hall_screen", "construction_screen", "building_detail_screen", "class_training_screen", "expedition_assignments_screen", "march_screen", "inventory_screen"]:
		var screen := (load("res://scenes/ui/screens/%s.tscn" % screen_name) as PackedScene).instantiate()
		_check(screen.get("entry_scene") is PackedScene, "%s owns a screen-specific dynamic entry scene" % screen_name)
		screen.free()
	var training_canvas := (load("res://scenes/ui/components/training_tree_canvas.tscn") as PackedScene).instantiate()
	var authored_training_cards: Array[Node] = training_canvas.get_children().filter(func(child: Node) -> bool: return child is AshenTrainingNodeCard)
	_check(authored_training_cards.size() == 156, "Training Grounds canvas owns all 156 editable runtime cards")
	var training_source := FileAccess.get_file_as_string("res://scenes/ui/screens/training_tree_screen.gd")
	_check(not training_source.contains("button.position ="), "Training Grounds runtime binding does not reposition authored cards")
	training_canvas.free()
	print("UI scene guards: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures > 0 else 0)


func _check_pause_overlay_binding() -> void:
	var hud_scene := load("res://scenes/ui/hud/hud.tscn") as PackedScene
	_check(hud_scene != null, "HUD scene loads for pause overlay regression coverage")
	if hud_scene == null:
		return
	var hud := hud_scene.instantiate()
	_check(hud.has_method("set_paused"), "HUD owns an explicit pause overlay state binding")
	hud.call("configure", "run", 0.0)
	var overlay := hud.get_node_or_null("PauseLabel") as CanvasItem
	_check(overlay != null, "HUD contains the authored pause overlay")
	if overlay != null:
		_check(not overlay.visible, "run HUD starts with the pause overlay hidden")
		hud.call("set_paused", true)
		_check(overlay.visible, "pausing shows the complete pause overlay")
		hud.call("set_paused", false)
		_check(not overlay.visible, "resuming hides the complete pause overlay")
	hud.free()


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
