class_name AshenCampListScreen
extends Control

signal action_requested(action_id: String)
signal back_requested

const DefaultActionCardScene := preload("res://scenes/ui/components/menu_action_card.tscn")

@export var default_title: String = "CAMP SERVICE"
@export_multiline var default_subtitle: String = "Manage the company."
@export var entry_scene: PackedScene = DefaultActionCardScene


func _ready() -> void:
	%Title.text = default_title
	%Subtitle.text = default_subtitle
	%BackButton.pressed.connect(func() -> void: back_requested.emit())


func bind_screen(title: String, subtitle: String, status: String, entries: Array[Dictionary], back_text: String = "RETURN TO CAMP") -> void:
	%Title.text = title
	%Subtitle.text = subtitle
	%Status.text = status
	%Status.visible = not status.is_empty()
	%BackButton.text = back_text
	for child: Node in %EntryList.get_children():
		child.queue_free()
	for entry: Dictionary in entries:
		if entry_scene == null:
			push_error("Camp list screen '%s' has no authored entry scene." % name)
			return
		var card := entry_scene.instantiate() as Button
		if card == null or not card.has_method("bind_entry"):
			push_error("Authored entry scene for '%s' must be a Button with bind_entry()." % name)
			return
		%EntryList.add_child(card)
		card.call("bind_entry", entry)
		card.connect("action_requested", func(action_id: String) -> void: action_requested.emit(action_id))
