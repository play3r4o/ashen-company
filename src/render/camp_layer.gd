class_name AshenCampLayer
extends Node2D

var commands: Array = []
var rebuild_count: int = 0
var last_signature: String = ""


func rebuild(camp_render_state: Dictionary, _theme: Dictionary = {}) -> void:
	var signature: String = String(camp_render_state.get("signature", ""))
	if signature == last_signature and not commands.is_empty():
		return
	last_signature = signature
	commands = camp_render_state.get("commands", [])
	rebuild_count += 1
	queue_redraw()

## Updates the visible command partition without invalidating the retained
## artwork.  Depth partitions change as the hero walks, but the authored
## textures and geometry do not need to be rebuilt.
func update_commands(p_commands: Array[Dictionary]) -> void:
	if commands == p_commands:
		return
	commands = p_commands
	queue_redraw()


func _draw() -> void:
	for command: Dictionary in commands:
		var texture: Texture2D = command.get("texture") as Texture2D
		if texture == null:
			continue
		var rect: Rect2 = command.get("rect", Rect2())
		rect.position = rect.position.round()
		var tint: Color = command.get("tint", Color.WHITE)
		var flip_h: bool = bool(command.get("flip_h", false))
		var flip_v: bool = bool(command.get("flip_v", false))
		if flip_h or flip_v:
			var origin := rect.position + Vector2(rect.size.x if flip_h else 0.0, rect.size.y if flip_v else 0.0)
			var transform_scale := Vector2(-1.0 if flip_h else 1.0, -1.0 if flip_v else 1.0)
			draw_set_transform(origin, 0.0, transform_scale)
			draw_texture_rect(texture, Rect2(Vector2.ZERO, rect.size.abs()), false, tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(texture, rect, false, tint)
