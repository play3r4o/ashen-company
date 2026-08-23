class_name AshenConfirmationOverlay
extends Control

signal confirmed
signal cancelled

@export var title_text: String = "CONFIRM?"
@export_multiline var body_text: String = "Continue?"
@export var cancel_text: String = "NO"
@export var confirm_text: String = "YES"


func _ready() -> void:
	_apply_content()
	var cancel_button := AshenSceneBindings.required(self, &"CancelButton", "ConfirmationOverlay") as Button
	var confirm_button := AshenSceneBindings.required(self, &"ConfirmButton", "ConfirmationOverlay") as Button
	if cancel_button != null:
		cancel_button.pressed.connect(func() -> void: cancelled.emit())
	if confirm_button != null:
		confirm_button.pressed.connect(func() -> void: confirmed.emit())


func configure(title: String, body: String, cancel_caption: String = "NO", confirm_caption: String = "YES") -> void:
	title_text = title
	body_text = body
	cancel_text = cancel_caption
	confirm_text = confirm_caption
	if is_node_ready():
		_apply_content()


func _apply_content() -> void:
	var title_label := AshenSceneBindings.optional(self, &"Title") as Label
	var body_label := AshenSceneBindings.optional(self, &"Body") as Label
	var cancel_button := AshenSceneBindings.optional(self, &"CancelButton") as Button
	var confirm_button := AshenSceneBindings.optional(self, &"ConfirmButton") as Button
	if title_label != null:
		title_label.text = title_text
	if body_label != null:
		body_label.text = body_text
	if cancel_button != null:
		cancel_button.text = cancel_text
	if confirm_button != null:
		confirm_button.text = confirm_text
