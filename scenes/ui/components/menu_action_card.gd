class_name AshenMenuActionCard
extends Button

signal action_requested(action_id: String)

var action_id: String = ""


func _ready() -> void:
	pressed.connect(func() -> void: action_requested.emit(action_id))


func bind_entry(entry: Dictionary) -> void:
	action_id = String(entry.get("id", ""))
	name = String(entry.get("node_name", "Action_%s" % action_id))
	disabled = bool(entry.get("disabled", false))
	visible = bool(entry.get("visible", true))
	%Title.text = String(entry.get("title", "ACTION"))
	%Detail.text = String(entry.get("detail", ""))
