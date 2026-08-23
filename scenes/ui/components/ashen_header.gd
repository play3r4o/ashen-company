class_name AshenHeader
extends PanelContainer

@export var title_text: String = "SETTINGS":
	set(value):
		title_text = value
		if is_inside_tree():
			_apply_content()

@export var show_crest: bool = true:
	set(value):
		show_crest = value
		if is_inside_tree():
			_apply_content()

func _ready() -> void:
	_apply_content()


func _apply_content() -> void:
	var title := AshenSceneBindings.optional(self, &"Title") as Label
	var left_crest := AshenSceneBindings.optional(self, &"LeftCrest") as CanvasItem
	var right_crest := AshenSceneBindings.optional(self, &"RightCrest") as CanvasItem
	if title != null:
		title.text = title_text
	if left_crest != null:
		left_crest.visible = show_crest
	if right_crest != null:
		right_crest.visible = show_crest
