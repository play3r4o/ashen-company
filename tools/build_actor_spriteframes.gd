extends SceneTree

const HEROES := ["warrior", "hunter", "mage", "rogue"]
const ENEMIES := ["wolf", "raider", "archer", "reaver", "blighted", "crow", "houndmaster", "grave_guard", "barrow_knight"]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/actors"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/enemies"))
	for hero_id: String in HEROES:
		_build_hero(hero_id)
	for enemy_id: String in ENEMIES:
		_build_enemy(enemy_id)
	quit()


func _build_hero(hero_id: String) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction: String in ["down", "left", "right", "up"]:
		var texture := load("res://assets/runtime/actors/%s_%s.png" % [hero_id, direction]) as Texture2D
		if texture == null:
			push_error("Missing hero animation strip: %s %s" % [hero_id, direction])
			continue
		_add_strip_animation(frames, "%s_idle" % direction, texture, [0, 1], 2.0, 6)
		_add_strip_animation(frames, "%s_walk" % direction, texture, [2, 3, 4, 5], 8.0, 6)
	ResourceSaver.save(frames, "res://assets/runtime/actors/%s_frames.tres" % hero_id)


func _build_enemy(enemy_id: String) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var texture := load("res://assets/runtime/enemies/%s.png" % enemy_id) as Texture2D
	if texture == null:
		push_error("Missing enemy animation strip: %s" % enemy_id)
		return
	_add_strip_animation(frames, "idle", texture, [0], 1.0, 4)
	_add_strip_animation(frames, "walk", texture, [0, 1, 2, 3], 7.0, 4)
	ResourceSaver.save(frames, "res://assets/runtime/enemies/%s_frames.tres" % enemy_id)


func _add_strip_animation(frames: SpriteFrames, animation: String, texture: Texture2D, frame_indices: Array, fps: float, columns: int) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, fps)
	var frame_size := Vector2i(texture.get_width() / columns, texture.get_height())
	for frame_index: int in frame_indices:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(animation, atlas)
