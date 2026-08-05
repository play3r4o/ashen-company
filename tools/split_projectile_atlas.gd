extends SceneTree

const SOURCE := "res://art/generated/combat/projectile_atlas_v01/v001/projectile_atlas_chromakey.png"
const APPROVED := "res://art/approved/combat/projectile_atlas_v01/projectile_atlas_alpha.png"
const OUTPUTS: Array[String] = [
	"res://assets/runtime/combat/crossbow_bolt.png",
	"res://assets/runtime/combat/dagger.png",
	"res://assets/runtime/combat/staff_bolt.png",
	"res://assets/runtime/combat/witchfire.png",
]
const CELL_SIZE := Vector2i(64, 64)


func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Unable to load projectile atlas: %s" % SOURCE)
		quit(1)
		return
	var cell_source_size := Vector2i(source.get_width() / 2, source.get_height() / 2)
	var approved := Image.create(CELL_SIZE.x * 2, CELL_SIZE.y * 2, false, Image.FORMAT_RGBA8)
	for index: int in OUTPUTS.size():
		var source_position := Vector2i(index % 2, index / 2) * cell_source_size
		var cell := source.get_region(Rect2i(source_position, cell_source_size))
		cell.resize(CELL_SIZE.x, CELL_SIZE.y, Image.INTERPOLATE_NEAREST)
		_remove_chroma(cell)
		var output_path := OUTPUTS[index]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
		var error := cell.save_png(output_path)
		if error != OK:
			push_error("Unable to save %s: %s" % [output_path, error_string(error)])
			quit(1)
			return
		approved.blit_rect(cell, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(index % 2, index / 2) * CELL_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(APPROVED.get_base_dir()))
	var approved_error := approved.save_png(APPROVED)
	if approved_error != OK:
		push_error("Unable to save approved projectile atlas: %s" % error_string(approved_error))
		quit(1)
		return
	print("Authored four dedicated projectile textures.")
	quit()


func _remove_chroma(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			if color.r > 0.72 and color.b > 0.62 and color.g < 0.38:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))
