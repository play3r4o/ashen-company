extends SceneTree

func _init() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var scene := load("res://scenes/world/terrain/blackthorn_terrain.tscn") as PackedScene
	var terrain := scene.instantiate()
	root.add_child(terrain)
	await process_frame
	var base := terrain.get_node("BaseTiles") as TileMapLayer
	var cells := base.get_used_cells()
	var min_cell := Vector2i(999999, 999999)
	var max_cell := Vector2i(-999999, -999999)
	for cell: Vector2i in cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	print("cells=%d min=%s max=%s size=%s" % [cells.size(), min_cell, max_cell, max_cell - min_cell + Vector2i.ONE])
	terrain.queue_free()
	quit()
