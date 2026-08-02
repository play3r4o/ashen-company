class_name RunState
extends Resource

@export var seed: int = 0
@export var biome_id: String = "blackthorn_moor"
@export var hero_id: String = "warrior"
@export var elapsed: float = 0.0
@export var dread_bonus: float = 0.0
@export var health: float = 100.0
@export var weapons: Dictionary = {}
@export var techniques: Dictionary = {}
@export var passives: Dictionary = {}
@export var boons: Dictionary = {}
@export var doctrines: Array[String] = []
## v3 names mirror the authored RunBuildState contract. The legacy fields
## above remain as compatibility aliases for older tools and snapshots.
@export var weapon_ranks: Dictionary = {}
@export var technique_ranks: Dictionary = {}
@export var boon_ranks: Dictionary = {}
@export var doctrine_ids: Array[String] = []
@export var prepared_weapon_ids: Array[String] = []
@export var prepared_technique_ids: Array[String] = []
@export var prepared_doctrine_ids: Array[String] = []
@export var free_rerolls: int = 0
@export var rejected_upgrade_ids: Array[String] = []
@export var unsecured_loot: Array[Dictionary] = []
@export var unsecured_equipment: Array[Dictionary] = []
@export var altered_chunks: Dictionary = {}
