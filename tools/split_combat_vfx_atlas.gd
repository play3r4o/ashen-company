extends SceneTree

const SOURCE := "res://art/approved/effects/combat_vfx_atlas_v01/combat_vfx_atlas_alpha.png"
const OUTPUT_ROOT := "res://assets/runtime/effects"
const CELL_SIZE := 320
const EFFECT_IDS: Array[String] = [
	"impact", "guard", "rain", "mark",
	"dash", "smoke", "poison", "nova",
	"frost", "lightning", "thrust", "arc",
	"arcane", "ring", "spark", "burst",
]


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	if image.is_empty():
		push_error("Unable to load combat VFX atlas: %s" % SOURCE)
		quit(1)
		return
	image.resize(CELL_SIZE * 4, CELL_SIZE * 4, Image.INTERPOLATE_NEAREST)
	for index: int in EFFECT_IDS.size():
		var cell := Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
		var source_rect := Rect2i((index % 4) * CELL_SIZE, (index / 4) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		cell.blit_rect(image, source_rect, Vector2i.ZERO)
		var output_path := "%s/%s.png" % [OUTPUT_ROOT, EFFECT_IDS[index]]
		var error := cell.save_png(output_path)
		if error != OK:
			push_error("Unable to save combat VFX cell: %s" % output_path)
			quit(1)
			return
	quit()
