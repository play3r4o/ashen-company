class_name RunState
extends Resource

@export var seed: int = 0
@export var biome_id: String = "blackthorn_moor"
@export var hero_id: String = "warrior"
@export var elapsed: float = 0.0
@export var dread_bonus: float = 0.0
@export var health: float = 100.0
@export var weapons: Dictionary = {}
@export var passives: Dictionary = {}
@export var unsecured_loot: Array[Dictionary] = []
@export var altered_chunks: Dictionary = {}
