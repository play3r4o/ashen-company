class_name AshenHeader
extends PanelContainer

@export var title_text: String = "SETTINGS":
	set(value):
		title_text = value
		if is_inside_tree():
			$Row/Title.text = title_text

@export var show_crest: bool = true:
	set(value):
		show_crest = value
		if is_inside_tree():
			$Row/LeftCrest.visible = show_crest
			$Row/RightCrest.visible = show_crest

func _ready() -> void:
	$Row/Title.text = title_text
	$Row/LeftCrest.visible = show_crest
	$Row/RightCrest.visible = show_crest
