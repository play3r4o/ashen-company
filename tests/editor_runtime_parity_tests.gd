extends SceneTree

const SCREENS: Array[String] = [
	"res://scenes/ui/hud/hud.tscn",
	"res://scenes/ui/screens/settings_screen.tscn",
	"res://scenes/ui/screens/training_tree_screen.tscn",
	"res://scenes/ui/screens/arsenal_screen.tscn",
	"res://scenes/ui/screens/results_screen.tscn",
	"res://scenes/ui/overlays/level_up_overlay.tscn",
	"res://scenes/ui/overlays/gate_confirmation_overlay.tscn",
]

var failures: int = 0


func _init() -> void:
	for path: String in SCREENS:
		var packed := load(path) as PackedScene
		_check(packed != null, "%s loads" % path)
		if packed == null:
			continue
		var editor_instance := packed.instantiate()
		var runtime_instance := packed.instantiate()
		_compare_tree(editor_instance, runtime_instance, path, String(editor_instance.name))
		editor_instance.free()
		runtime_instance.free()
	print("Editor/runtime parity guards: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures > 0 else 0)


func _compare_tree(authored: Node, runtime: Node, context: String, node_path: String) -> void:
	_check(authored.name == runtime.name, "%s preserves node name %s" % [context, authored.name])
	if authored is Control and runtime is Control:
		var a := authored as Control
		var b := runtime as Control
		_check(a.position == b.position and a.size == b.size and a.scale == b.scale and a.layout_mode == b.layout_mode, "%s preserves authored geometry at %s" % [context, node_path])
	if authored is Sprite2D and runtime is Sprite2D:
		var a_sprite := authored as Sprite2D
		var b_sprite := runtime as Sprite2D
		_check(a_sprite.position == b_sprite.position and a_sprite.scale == b_sprite.scale and a_sprite.texture == b_sprite.texture, "%s preserves authored sprite at %s" % [context, node_path])
	_check(authored.get_child_count() == runtime.get_child_count(), "%s preserves child count at %s" % [context, node_path])
	for index: int in mini(authored.get_child_count(), runtime.get_child_count()):
		_compare_tree(authored.get_child(index), runtime.get_child(index), context, node_path + "/" + String(authored.get_child(index).name))


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("PARITY FAIL: %s" % message)
