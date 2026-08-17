extends SceneTree

const PREVIEW_SCENE := "res://scenes/world/biomes/blackthorn_moor_preview.tscn"

func _init() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	if packed == null:
		push_error("Cannot load canonical Meadow preview")
		quit(1)
		return
	var root := packed.instantiate()
	var output := PackedScene.new()
	var result := output.pack(root)
	root.free()
	if result != OK:
		push_error("Cannot pack canonical Meadow preview: %s" % result)
		quit(1)
		return
	result = ResourceSaver.save(output, PREVIEW_SCENE)
	if result != OK:
		push_error("Cannot save canonical Meadow preview: %s" % result)
		quit(1)
		return
	print("Resaved Meadow preview with canonical terrain instance")
	quit(0)
