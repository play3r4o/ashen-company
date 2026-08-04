class_name AshenTrainingNodeCard
extends Button

@onready var type_marker: Label = $TypeMarker
@onready var state_marker: Label = $StateMarker

var node_id: String = ""

func configure(id_value: String, definition: Dictionary, state: String) -> void:
	node_id = id_value
	var node_type: String = String(definition.get("node_type", "minor"))
	custom_minimum_size = _size_for_type(node_type)
	size = custom_minimum_size
	text = String(definition.get("name", node_id)).to_upper()
	tooltip_text = String(definition.get("description", ""))
	type_marker.text = _marker_for_type(node_type)
	set_state(state)

func set_state(state: String) -> void:
	state_marker.text = {"purchased": "✓", "available": "◆", "selected": "✦", "tier_locked": "T", "exclusive_locked": "×"}.get(state, "·")
	self_modulate = {
		"purchased": Color("b9d4bd"), "available": Color("f3dfac"), "selected": Color.WHITE,
		"tier_locked": Color("777b7b"), "exclusive_locked": Color("9c6666")
	}.get(state, Color("777b7b"))

func _marker_for_type(node_type: String) -> String:
	return {"weapon": "⚔", "technique": "✦", "doctrine": "◇", "keystone": "♜", "mastery": "✹", "major": "◆", "root": "✥", "utility": "✥"}.get(node_type, "•")

func _size_for_type(node_type: String) -> Vector2:
	return {
		"root": Vector2(150, 58), "utility": Vector2(150, 52), "weapon": Vector2(142, 62),
		"technique": Vector2(142, 62), "doctrine": Vector2(148, 64), "keystone": Vector2(152, 68),
		"mastery": Vector2(152, 68), "major": Vector2(136, 54)
	}.get(node_type, Vector2(126, 48))
