extends SceneTree

## One-shot, idempotent migration helper for the authored world scenes.
##
## The old authored Meadow used 64px atlas regions on a 0.5 render scale.
## This tool keeps the same world-space footprint by coalescing each 2x2
## authored cell block into one native 64px cell, then saves the scene with
## an authored scale of Vector2.ONE. It never touches gameplay coordinates.

const TARGET_SCENES: Array[String] = [
	"res://scenes/world/terrain/blackthorn_terrain.tscn",
	"res://scenes/world/biomes/blackthorn_moor_preview.tscn",
]
const LAYER_NAMES: Array[String] = ["BaseTiles", "WaterFill"]
const BACKUP_DIR := "res://artifacts/foundation_cleanup/pre64_world_scenes"

func _init() -> void:
	for scene_path: String in TARGET_SCENES:
		_migrate_scene(scene_path)
	quit()

func _migrate_scene(scene_path: String) -> void:
	if not FileAccess.file_exists(scene_path):
		push_error("Native 64 migration cannot find %s" % scene_path)
		return
	_backup_once(scene_path)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Native 64 migration could not load %s" % scene_path)
		return
	var root := packed.instantiate()
	for layer_name: String in LAYER_NAMES:
		var layer := root.get_node_or_null("Terrain/%s" % layer_name) as TileMapLayer
		if layer == null:
			# The terrain scene owns these layers at its root; the Meadow preview
			# owns them beneath its Terrain instance.
			layer = root.get_node_or_null(layer_name) as TileMapLayer
		if layer == null:
			push_error("Native 64 migration missing Terrain/%s in %s" % [layer_name, scene_path])
			continue
		_coalesce_layer(layer)
		layer.scale = Vector2.ONE
	var native := PackedScene.new()
	var pack_result := native.pack(root)
	if pack_result != OK:
		push_error("Native 64 migration could not pack %s (%s)" % [scene_path, pack_result])
		root.free()
		return
	var save_result := ResourceSaver.save(native, scene_path)
	if save_result != OK:
		push_error("Native 64 migration could not save %s (%s)" % [scene_path, save_result])
	else:
		print("Native 64 migrated ", scene_path)
	root.free()

func _coalesce_layer(layer: TileMapLayer) -> void:
	var cells: Array[Vector2i] = layer.get_used_cells()
	if cells.is_empty():
		return
	var max_cell := Vector2i(-1, -1)
	for cell: Vector2i in cells:
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	# Running the migration again must not halve an already-native layer.
	if max_cell.x <= 20 and max_cell.y <= 54:
		return
	var authored: Array[Array] = []
	for cell: Vector2i in cells:
		authored.append([
			cell,
			layer.get_cell_source_id(cell),
			layer.get_cell_atlas_coords(cell),
			layer.get_cell_alternative_tile(cell),
		])
	layer.clear()
	for value: Array in authored:
		var old_cell: Vector2i = value[0]
		var new_cell := Vector2i(floori(float(old_cell.x) / 2.0), floori(float(old_cell.y) / 2.0))
		if layer.get_cell_source_id(new_cell) >= 0:
			continue
		layer.set_cell(new_cell, int(value[1]), value[2], int(value[3]))

func _backup_once(scene_path: String) -> void:
	var file_name := scene_path.get_file().get_basename()
	var backup_path := "%s/%s_pre64.tscn" % [BACKUP_DIR, file_name]
	if FileAccess.file_exists(backup_path):
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	var bytes := FileAccess.get_file_as_bytes(scene_path)
	var backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		push_error("Native 64 migration could not create backup %s" % backup_path)
		return
	backup.store_buffer(bytes)
	backup.close()
	print("Backed up ", scene_path, " to ", backup_path)
