extends SceneTree

const TERRAIN_SCENE := "res://scenes/world/terrain/blackthorn_terrain.tscn"

func _init() -> void:
	var packed := load(TERRAIN_SCENE) as PackedScene
	if packed == null:
		push_error("Cannot load canonical terrain scene")
		quit(1)
		return
	var root := packed.instantiate()
	for child_name: String in ["MacroField", "BridgeTiles", "OverlayTiles"]:
		var child := root.get_node_or_null(NodePath(child_name))
		if child != null:
			child.free()
	var output := PackedScene.new()
	var result := output.pack(root)
	root.free()
	if result != OK:
		push_error("Cannot pack canonical terrain scene: %s" % result)
		quit(1)
		return
	result = ResourceSaver.save(output, TERRAIN_SCENE)
	if result != OK:
		push_error("Cannot save canonical terrain scene: %s" % result)
		quit(1)
		return
	print("Removed legacy terrain visual nodes")
	quit(0)
