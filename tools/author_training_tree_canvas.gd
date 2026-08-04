extends SceneTree

const Content = preload("res://src/content/training_grounds_content.gd")
const NodeCardScene = preload("res://scenes/ui/components/training_node_card.tscn")
const ConnectorScene = preload("res://scenes/ui/components/training_connector.tscn")
const OUTPUT_PATH := "res://scenes/ui/components/training_tree_canvas.tscn"
const CANVAS_CENTER := Vector2(1100.0, 1100.0)


func _init() -> void:
	var root := Control.new()
	root.name = "TrainingTreeCanvas"
	root.custom_minimum_size = Vector2(2200.0, 2200.0)
	root.size = Vector2(2200.0, 2200.0)
	root.mouse_filter = Control.MOUSE_FILTER_PASS

	var nodes: Dictionary = Content.all_nodes()
	for node_id: String in nodes:
		var definition: Dictionary = nodes[node_id]
		for required_value: Variant in definition.get("prerequisite_ids", []):
			var required_id := String(required_value)
			if not nodes.has(required_id):
				continue
			var connector := ConnectorScene.instantiate() as Line2D
			connector.name = "Connector_%s_%s" % [required_id, node_id]
			connector.points = PackedVector2Array([
				CANVAS_CENTER + Vector2(nodes[required_id].position),
				CANVAS_CENTER + Vector2(definition.position),
			])
			root.add_child(connector)
			connector.owner = root

	for node_id: String in nodes:
		var definition: Dictionary = nodes[node_id]
		var card := NodeCardScene.instantiate() as AshenTrainingNodeCard
		var card_size := _size_for_type(String(definition.get("node_type", "minor")))
		card.name = "TrainingNode_%s" % node_id
		card.node_id = node_id
		card.custom_minimum_size = card_size
		card.size = card_size
		card.position = CANVAS_CENTER + Vector2(definition.position) - card_size * 0.5
		card.text = String(definition.get("name", node_id)).to_upper()
		card.tooltip_text = String(definition.get("description", ""))
		root.add_child(card)
		card.owner = root

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Unable to pack authored Training Grounds canvas: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	root.free()
	if save_error != OK:
		push_error("Unable to save authored Training Grounds canvas: %s" % error_string(save_error))
		quit(1)
		return
	print("Authored 156-node Training Grounds canvas: %s" % OUTPUT_PATH)
	quit()


func _size_for_type(node_type: String) -> Vector2:
	return {
		"root": Vector2(150, 58), "utility": Vector2(150, 52), "weapon": Vector2(142, 62),
		"technique": Vector2(142, 62), "doctrine": Vector2(148, 64), "keystone": Vector2(152, 68),
		"mastery": Vector2(152, 68), "major": Vector2(136, 54),
	}.get(node_type, Vector2(126, 48))
