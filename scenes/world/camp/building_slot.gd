class_name AshenBuildingSlot
extends Node2D

@export var slot_id: String = ""
@export var construction_plot_scene: PackedScene

var current_content: Node2D
var current_scene_path: String = ""


func _ready() -> void:
	current_content = get_node_or_null("Content") as Node2D
	if current_content != null:
		current_scene_path = String(current_content.get_meta("scene_path", ""))


func show_content(scene: PackedScene) -> void:
	var scene_path: String = scene.resource_path if scene != null else ""
	if current_scene_path == scene_path and is_instance_valid(current_content):
		return
	_clear_content()
	if scene == null:
		return
	current_content = scene.instantiate() as Node2D
	current_content.name = "Content"
	add_child(current_content)
	current_scene_path = scene_path


func show_empty_plot() -> void:
	show_content(construction_plot_scene)


func hide_slot() -> void:
	_clear_content()
	visible = false


func _clear_content() -> void:
	if is_instance_valid(current_content):
		current_content.free()
	current_content = null
	current_scene_path = ""
