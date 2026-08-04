class_name AshenCampLayer
extends Node2D

## Compatibility presentation host used while the authored camp-tier scenes
## replace the former retained command renderer. Every command is represented
## by a real Sprite2D node; this class never draws production pixels itself.

var commands: Array = []
var rebuild_count: int = 0
var last_signature: String = ""
var _sprites: Array[Sprite2D] = []


func rebuild(camp_render_state: Dictionary, _theme: Dictionary = {}) -> void:
	var signature: String = String(camp_render_state.get("signature", ""))
	if signature == last_signature and not commands.is_empty():
		return
	last_signature = signature
	commands = camp_render_state.get("commands", [])
	rebuild_count += 1
	_sync_sprite_nodes()


func update_commands(p_commands: Array[Dictionary]) -> void:
	if commands == p_commands:
		return
	commands = p_commands
	_sync_sprite_nodes()


func _sync_sprite_nodes() -> void:
	while _sprites.size() < commands.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		_sprites.append(sprite)
	for index: int in _sprites.size():
		var sprite: Sprite2D = _sprites[index]
		if index >= commands.size():
			sprite.visible = false
			continue
		var command: Dictionary = commands[index]
		var texture: Texture2D = command.get("texture") as Texture2D
		if texture == null:
			push_error("Camp presentation command %d has no canonical texture" % index)
			sprite.visible = false
			continue
		var rect: Rect2 = command.get("rect", Rect2())
		sprite.visible = true
		sprite.texture = texture
		sprite.position = rect.position.round()
		sprite.scale = Vector2(
			rect.size.x / maxf(1.0, float(texture.get_width())),
			rect.size.y / maxf(1.0, float(texture.get_height()))
		)
		sprite.flip_h = bool(command.get("flip_h", false))
		sprite.flip_v = bool(command.get("flip_v", false))
		sprite.modulate = command.get("tint", Color.WHITE)
