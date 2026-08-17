extends SceneTree

const CAMP_SCENES: Array[String] = [
	"res://scenes/world/camp/camp_tier_0.tscn",
	"res://scenes/world/camp/camp_tier_1.tscn",
	"res://scenes/world/camp/camp_tier_2.tscn",
	"res://scenes/world/camp/camp_tier_3.tscn",
	"res://scenes/world/camp/camp_tier_4.tscn",
]
const BACKUP_DIR := "res://artifacts/foundation_cleanup/pre64_world_scenes"

func _init() -> void:
	var shared_tileset := load("res://scenes/world/terrain/blackthorn_tileset_64.tres") as TileSet
	if shared_tileset == null:
		push_error("Native camp migration requires blackthorn_tileset_64.tres")
		quit(1)
		return
	var tier_zero_tileset := _build_tier_zero_tileset()
	for index: int in CAMP_SCENES.size():
		_migrate_camp(CAMP_SCENES[index], tier_zero_tileset if index == 0 else shared_tileset, index == 0)
	quit()

func _migrate_camp(scene_path: String, tile_set: TileSet, tier_zero: bool) -> void:
	if not FileAccess.file_exists(scene_path):
		push_error("Missing camp scene %s" % scene_path)
		return
	_backup_once(scene_path)
	var packed := load(scene_path) as PackedScene
	var root := packed.instantiate() as Node2D
	if root == null:
		push_error("Could not instantiate %s" % scene_path)
		return
	if tier_zero:
		_replace_tier_zero_sprite(root, tile_set)
	else:
		var ground := root.get_node_or_null("Ground") as TileMapLayer
		if ground == null:
			push_error("Camp scene %s has no Ground TileMapLayer" % scene_path)
		else:
			if not bool(ground.get_meta("native64_migrated", false)):
				_coalesce_ground(ground)
			ground.tile_set = tile_set
			ground.scale = Vector2.ONE
			ground.position = Vector2.ZERO
			ground.set_meta("native64_migrated", true)
	var native := PackedScene.new()
	var pack_result := native.pack(root)
	if pack_result != OK:
		push_error("Could not pack %s" % scene_path)
		root.free()
		return
	var save_result := ResourceSaver.save(native, scene_path)
	if save_result != OK:
		push_error("Could not save %s (%s)" % [scene_path, save_result])
	else:
		print("Native 64 migrated ", scene_path)
	root.free()

func _coalesce_ground(ground: TileMapLayer) -> void:
	var cells: Array[Vector2i] = ground.get_used_cells()
	if cells.is_empty():
		return
	var authored: Array[Array] = []
	for cell: Vector2i in cells:
		authored.append([cell, ground.get_cell_source_id(cell), ground.get_cell_atlas_coords(cell), ground.get_cell_alternative_tile(cell)])
	ground.clear()
	for value: Array in authored:
		var old_cell: Vector2i = value[0]
		var new_cell := Vector2i(floori(float(old_cell.x) / 2.0), floori(float(old_cell.y) / 2.0))
		if ground.get_cell_source_id(new_cell) >= 0:
			continue
		ground.set_cell(new_cell, int(value[1]), value[2], int(value[3]))

func _replace_tier_zero_sprite(root: Node2D, tile_set: TileSet) -> void:
	var existing_ground := root.get_node_or_null("Ground")
	var ground := existing_ground as TileMapLayer
	if ground == null:
		ground = TileMapLayer.new()
		ground.name = "Ground"
		ground.z_index = (existing_ground as Sprite2D).z_index if existing_ground is Sprite2D else -20
		var insert_index := root.get_child_count()
		if existing_ground != null:
			insert_index = existing_ground.get_index()
			root.remove_child(existing_ground)
			existing_ground.free()
		root.add_child(ground)
		root.move_child(ground, insert_index)
	# A previous interrupted migration could leave a second generated layer in
	# the packed scene. Keep the named Ground layer as the sole source of truth.
	for child: Node in root.get_children():
		if child != ground and child is TileMapLayer and bool(child.get_meta("native64_migrated", false)):
			root.remove_child(child)
			child.free()
	ground.clear()
	ground.position = Vector2(411, 282)
	ground.tile_set = tile_set
	for y: int in 5:
		for x: int in 5:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(x, y))
	# PackedScene only serializes authored children. Give the generated replacement
	# the same owner as the camp root so it remains part of the editable scene.
	ground.owner = root
	ground.set_meta("native64_migrated", true)

func _build_tier_zero_tileset() -> TileSet:
	var image := Image.load_from_file("assets/runtime/world/camp_ground_tier_0_background.png")
	image.resize(320, 320, Image.INTERPOLATE_NEAREST)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(64, 64)
	for y: int in 5:
		for x: int in 5:
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)
	return tile_set

func _backup_once(scene_path: String) -> void:
	var file_name := scene_path.get_file().get_basename()
	var backup_path := "%s/%s_pre64.tscn" % [BACKUP_DIR, file_name]
	if FileAccess.file_exists(backup_path):
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	var bytes := FileAccess.get_file_as_bytes(scene_path)
	var backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		push_error("Could not create backup %s" % backup_path)
		return
	backup.store_buffer(bytes)
	backup.close()
