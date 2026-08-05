class_name AshenTerrainChunk
extends Node2D

var base_atlas: Texture2D
var overlay_atlas: Texture2D
var commands: Array = []
var rebuild_count: int = 0


func configure(p_base_atlas: Texture2D, p_overlay_atlas: Texture2D, p_commands: Array) -> void:
	base_atlas = p_base_atlas
	overlay_atlas = p_overlay_atlas
	commands = p_commands
	rebuild_count += 1
	queue_redraw()
