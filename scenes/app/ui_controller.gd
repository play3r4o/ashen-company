class_name AshenUiController
extends Node

@onready var hud_layer: CanvasLayer = AshenSceneBindings.required(get_parent(), &"HudLayer", "UIController") as CanvasLayer
@onready var menu_layer: CanvasLayer = AshenSceneBindings.required(get_parent(), &"MenuLayer", "UIController") as CanvasLayer
@onready var modal_layer: CanvasLayer = AshenSceneBindings.required(get_parent(), &"ModalLayer", "UIController") as CanvasLayer


func mount_hud(root: Control) -> void:
	if hud_layer == null or root == null:
		return
	_clear_layer(hud_layer)
	hud_layer.add_child(root)


func mount_screen(root: Control) -> void:
	if menu_layer == null or root == null:
		return
	_clear_layer(menu_layer)
	menu_layer.add_child(root)


func mount_modal(root: Control) -> void:
	if modal_layer == null or root == null:
		return
	_clear_layer(modal_layer)
	modal_layer.add_child(root)


func clear_all() -> void:
	_clear_layer(hud_layer)
	_clear_layer(menu_layer)
	_clear_layer(modal_layer)


func _clear_layer(layer: CanvasLayer) -> void:
	if layer == null:
		return
	for child: Node in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
