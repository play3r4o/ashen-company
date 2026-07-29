class_name BiomeDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tile_size: int = 32
@export var region_tiles: Vector2i = Vector2i(96, 96)
@export var base_dread: float = 0.0
@export var boss_id: String = "barrow_knight"
@export var boss_key: String = "barrow_key"
@export var next_biome: String = ""
@export var boundary_style: String = "thorn_and_ruin"
@export var encounter_ids: PackedStringArray = PackedStringArray()
