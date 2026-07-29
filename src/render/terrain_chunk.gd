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


func _draw() -> void:
	for command: Dictionary in commands:
		var texture: Texture2D = overlay_atlas if bool(command.get("overlay", false)) else base_atlas
		if texture == null:
			continue
		var destination: Rect2 = command.get("destination", Rect2())
		var source: Rect2 = command.get("source", Rect2())
		var tint: Color = command.get("tint", Color.WHITE)
		draw_texture_rect_region(texture, destination, source, tint)
