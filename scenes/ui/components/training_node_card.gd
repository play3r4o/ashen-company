class_name AshenTrainingNodeCard
extends Button

@onready var type_marker: Label = AshenSceneBindings.optional(self, &"TypeMarker") as Label
@onready var state_marker: Label = AshenSceneBindings.optional(self, &"StateMarker") as Label

@export var node_id: String = ""

func configure(id_value: String, definition: Dictionary, state: String) -> void:
	node_id = id_value
	var node_type: String = String(definition.get("node_type", "minor"))
	text = String(definition.get("name", node_id)).to_upper()
	tooltip_text = String(definition.get("description", ""))
	if type_marker != null:
		type_marker.text = _marker_for_type(node_type)
	set_state(state)

func set_state(state: String) -> void:
	if state_marker != null:
		state_marker.text = {"purchased": "✓", "available": "◆", "selected": "✦", "tier_locked": "T", "exclusive_locked": "×"}.get(state, "·")
	self_modulate = {
		"purchased": Color("b9d4bd"), "available": Color("f3dfac"), "selected": Color.WHITE,
		"tier_locked": Color("777b7b"), "exclusive_locked": Color("9c6666")
	}.get(state, Color("777b7b"))

func _marker_for_type(node_type: String) -> String:
	return {"weapon": "⚔", "technique": "✦", "doctrine": "◇", "keystone": "♜", "mastery": "✹", "major": "◆", "root": "✥", "utility": "✥"}.get(node_type, "•")
