class_name AshenCampListScreen
extends Control

signal action_requested(action_id: String)
signal back_requested

const DefaultActionCardScene := preload("res://scenes/ui/components/menu_action_card.tscn")

@export var default_title: String = "CAMP SERVICE"
@export_multiline var default_subtitle: String = "Manage the company."
@export var entry_scene: PackedScene = DefaultActionCardScene


func _ready() -> void:
	var title := _role(&"Title") as Label
	var subtitle := _role(&"Subtitle") as Label
	var back_button := AshenSceneBindings.required(self, &"BackButton", "CampListScreen") as Button
	if title != null:
		title.text = default_title
	if subtitle != null:
		subtitle.text = default_subtitle
	if back_button != null:
		back_button.pressed.connect(func() -> void: back_requested.emit())


func bind_screen(title: String, subtitle: String, status: String, entries: Array[Dictionary], back_text: String = "RETURN TO CAMP") -> void:
	var title_label := _role(&"Title") as Label
	var subtitle_label := _role(&"Subtitle") as Label
	var status_label := _role(&"Status") as Label
	var back_button := AshenSceneBindings.required(self, &"BackButton", "CampListScreen") as Button
	var entry_list := AshenSceneBindings.required(self, &"EntryList", "CampListScreen") as Container
	if title_label != null:
		title_label.text = title
	if subtitle_label != null:
		subtitle_label.text = subtitle
	if status_label != null:
		status_label.text = status
		status_label.visible = not status.is_empty()
	if back_button != null:
		back_button.text = back_text
	if entry_list == null:
		return
	for child: Node in entry_list.get_children():
		child.queue_free()
	for entry: Dictionary in entries:
		if entry_scene == null:
			push_error("Camp list screen '%s' has no authored entry scene." % name)
			return
		var card := entry_scene.instantiate() as Button
		if card == null or not card.has_method("bind_entry"):
			push_error("Authored entry scene for '%s' must be a Button with bind_entry()." % name)
			return
		entry_list.add_child(card)
		card.call("bind_entry", entry)
		card.connect("action_requested", func(action_id: String) -> void: action_requested.emit(action_id))


func _role(role: StringName) -> Node:
	return AshenSceneBindings.optional(self, role)
