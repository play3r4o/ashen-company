class_name AshenUiController
extends Node

@onready var hud_layer: CanvasLayer = get_parent().get_node("HudLayer") as CanvasLayer
@onready var menu_layer: CanvasLayer = get_parent().get_node("MenuLayer") as CanvasLayer
@onready var modal_layer: CanvasLayer = get_parent().get_node("ModalLayer") as CanvasLayer


func mount_hud(root: Control) -> void:
	_clear_layer(hud_layer)
	hud_layer.add_child(root)


func mount_screen(root: Control) -> void:
	_clear_layer(menu_layer)
	menu_layer.add_child(root)


func mount_modal(root: Control) -> void:
	_clear_layer(modal_layer)
	modal_layer.add_child(root)


func clear_all() -> void:
	_clear_layer(hud_layer)
	_clear_layer(menu_layer)
	_clear_layer(modal_layer)


func _clear_layer(layer: CanvasLayer) -> void:
	for child: Node in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
