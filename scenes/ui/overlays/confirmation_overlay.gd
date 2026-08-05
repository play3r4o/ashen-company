class_name AshenConfirmationOverlay
extends Control

signal confirmed
signal cancelled

@export var title_text: String = "CONFIRM?"
@export_multiline var body_text: String = "Continue?"
@export var cancel_text: String = "NO"
@export var confirm_text: String = "YES"


func _ready() -> void:
	var title_label := get_node("SafeArea/Panel/Margin/Content/Title") as Label
	var body_label := get_node("SafeArea/Panel/Margin/Content/Body") as Label
	var cancel_button := get_node("SafeArea/Panel/Margin/Content/Actions/CancelButton") as Button
	var confirm_button := get_node("SafeArea/Panel/Margin/Content/Actions/ConfirmButton") as Button
	title_label.text = title_text
	body_label.text = body_text
	cancel_button.text = cancel_text
	confirm_button.text = confirm_text
	cancel_button.pressed.connect(func() -> void: cancelled.emit())
	confirm_button.pressed.connect(func() -> void: confirmed.emit())


func configure(title: String, body: String, cancel_caption: String = "NO", confirm_caption: String = "YES") -> void:
	title_text = title
	body_text = body
	cancel_text = cancel_caption
	confirm_text = confirm_caption
	if is_node_ready():
		(get_node("SafeArea/Panel/Margin/Content/Title") as Label).text = title_text
		(get_node("SafeArea/Panel/Margin/Content/Body") as Label).text = body_text
		(get_node("SafeArea/Panel/Margin/Content/Actions/CancelButton") as Button).text = cancel_text
		(get_node("SafeArea/Panel/Margin/Content/Actions/ConfirmButton") as Button).text = confirm_text
