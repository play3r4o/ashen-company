class_name HeroClassDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var starting_weapon: String = "spear"
@export var base_stats: Dictionary = {}
@export var weapon_tags: PackedStringArray = PackedStringArray()
@export var class_tree: Array[Dictionary] = []
