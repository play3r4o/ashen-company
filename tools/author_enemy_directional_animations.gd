extends SceneTree

const FRAME_RESOURCES: Array[String] = [
	"res://assets/runtime/enemies/wolf_frames.tres",
	"res://assets/runtime/enemies/raider_frames.tres",
	"res://assets/runtime/enemies/archer_frames.tres",
	"res://assets/runtime/enemies/reaver_frames.tres",
	"res://assets/runtime/enemies/blighted_frames.tres",
	"res://assets/runtime/enemies/crow_frames.tres",
	"res://assets/runtime/enemies/houndmaster_frames.tres",
	"res://assets/runtime/enemies/grave_guard_frames.tres",
	"res://assets/runtime/enemies/barrow_knight_frames.tres",
]


func _init() -> void:
	for path: String in FRAME_RESOURCES:
		var frames := load(path) as SpriteFrames
		if frames == null or not frames.has_animation(&"idle") or not frames.has_animation(&"walk"):
			push_error("Enemy animation source is incomplete: %s" % path)
			quit(1)
			return
		for facing: StringName in [&"down", &"up", &"left", &"right"]:
			_duplicate_animation(frames, &"idle", StringName("%s_idle" % facing))
			_duplicate_animation(frames, &"walk", StringName("%s_walk" % facing))
		var error := ResourceSaver.save(frames, path)
		if error != OK:
			push_error("Unable to save directional enemy animations: %s" % path)
			quit(1)
			return
	quit()


func _duplicate_animation(frames: SpriteFrames, source: StringName, target: StringName) -> void:
	if frames.has_animation(target):
		frames.remove_animation(target)
	frames.add_animation(target)
	frames.set_animation_loop(target, frames.get_animation_loop(source))
	frames.set_animation_speed(target, frames.get_animation_speed(source))
	for frame_index: int in frames.get_frame_count(source):
		frames.add_frame(target, frames.get_frame_texture(source, frame_index), frames.get_frame_duration(source, frame_index))
