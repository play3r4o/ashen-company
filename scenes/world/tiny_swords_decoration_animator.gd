@tool
class_name AshenTinySwordsDecorationAnimator
extends Node2D

## Advances Tiny Swords' authored decoration sheets without changing their
## world placement.  Any Sprite2D with more than one horizontal frame is
## treated as a visual animation; static rocks and stumps are left untouched.
## The scene remains editable: the source sheet, frame count, and FPS live on
## the Sprite2D nodes while this script only changes the current frame.

@export_range(1.0, 24.0, 0.5) var frames_per_second: float = 8.0
@export var animate_in_editor: bool = false
## Kept as a serialized compatibility property so older authored scenes still
## load, but it is intentionally ignored.  Sprite centering and offsets are
## scene-owned values now; changing them here was the reason the editor scene
## and the running Meadow could not agree on decoration placement.
@export var preserve_legacy_top_left_anchors: bool = false

var _sheet_sprites: Array[Sprite2D] = []
var _clock: float = 0.0
var _last_frame_index: int = -1


func _ready() -> void:
	_prepare_decoration_sprites(self)
	_collect_sheet_sprites(self)
	set_process((Engine.is_editor_hint() and animate_in_editor) or not Engine.is_editor_hint())


func _process(delta: float) -> void:
	if _sheet_sprites.is_empty() or frames_per_second <= 0.0:
		return
	_clock = fmod(_clock + delta, 1024.0)
	var frame_index := int(floor(_clock * frames_per_second))
	if frame_index == _last_frame_index:
		return
	_last_frame_index = frame_index
	for sprite: Sprite2D in _sheet_sprites:
		if not is_instance_valid(sprite) or sprite.hframes <= 1:
			continue
		sprite.frame = frame_index % sprite.hframes


func _collect_sheet_sprites(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			if sprite.hframes > 1:
				_sheet_sprites.append(sprite)
		_collect_sheet_sprites(child)


func _prepare_decoration_sprites(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Sprite2D:
			_prepare_sprite(child as Sprite2D)
		_prepare_decoration_sprites(child)


func _prepare_sprite(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	# Animation metadata is the only runtime preparation this component owns.
	# Do not assign hframes, centered, offset, scale, position, or pivot here:
	# all of those are authored on the Sprite2D in the preview scene (and in the
	# reusable meadow scene).  In particular, the old top-left anchor conversion
	# silently replaced editor offsets at runtime and shifted every decoration.
	# The current production scenes already serialize their correct frame counts.
	# If a sheet is missing that metadata, leave it static so it cannot change
	# its authored canvas or alignment.
