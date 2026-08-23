@tool
extends Node2D

## Compatibility script for old editor bookmarks.
##
## The bookmark scene is now a direct instance of
## `scenes/world/biomes/blackthorn_moor_preview.tscn`.  It deliberately does
## not paint tiles or maintain a second preview grid; the canonical scene is
## the only place where Meadow terrain is authored and the same scene is
## mounted by the runtime.
@export var show_collision: bool = false:
	set(value):
		show_collision = value
		if is_node_ready():
			_set_collision_preview_visible(value)


func _ready() -> void:
	_set_collision_preview_visible(show_collision)


func _set_collision_preview_visible(enabled: bool) -> void:
	var preview := AshenSceneBindings.optional(self, &"CollisionPreview")
	if preview != null:
		preview.visible = enabled
