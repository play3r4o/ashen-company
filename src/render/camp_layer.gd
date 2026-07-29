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


func _draw() -> void:
	for command: Dictionary in commands:
		var texture: Texture2D = command.get("texture") as Texture2D
		if texture == null:
			continue
		var rect: Rect2 = command.get("rect", Rect2())
		rect.position = rect.position.round()
		var tint: Color = command.get("tint", Color.WHITE)
		draw_texture_rect(texture, rect, false, tint)
