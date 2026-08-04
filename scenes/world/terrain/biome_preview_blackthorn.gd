@tool
extends Node2D

@export var show_collision: bool = false:
	set(value):
		show_collision = value
		if is_node_ready():
			$CollisionPreview.visible = value


func _ready() -> void:
	_populate_preview()
	$CollisionPreview.visible = show_collision


func _populate_preview() -> void:
	var tiles := $Terrain/BaseTiles as TileMapLayer
	var overlays := $Terrain/OverlayTiles as TileMapLayer
	tiles.clear()
	overlays.clear()
	for row: int in range(9):
		for column: int in range(6):
			tiles.set_cell(Vector2i(column, row), 0, Vector2i(column, row))
	for column: int in range(6):
		overlays.set_cell(Vector2i(column, 10), 1, Vector2i(column, 0))
