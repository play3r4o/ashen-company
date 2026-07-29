class_name HeroRecord
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var class_id: String = "warrior"
@export var level: int = 1
@export var xp: int = 0
@export var class_tree: Dictionary = {}
@export var equipped: Dictionary = {}

func to_save() -> Dictionary:
	return {"id": id, "name": display_name, "class_id": class_id, "level": level, "xp": xp, "class_tree": class_tree.duplicate(true), "equipped": equipped.duplicate(true)}
