class_name EnvironmentInteractionDefinition
extends Resource

@export var id: String = ""
@export var source_tags: PackedStringArray = PackedStringArray()
@export var target_tags: PackedStringArray = PackedStringArray()
@export var result_tags: PackedStringArray = PackedStringArray()
@export var power_multiplier: float = 1.0
@export var duration: float = 0.0
@export_multiline var description: String = ""

func matches(source: Array[String], target: Array[String]) -> bool:
	for tag: String in source_tags:
		if tag not in source:
			return false
	for tag: String in target_tags:
		if tag not in target:
			return false
	return true

func to_dictionary() -> Dictionary:
	return {"id": id, "source_tags": Array(source_tags), "target_tags": Array(target_tags), "result_tags": Array(result_tags), "power_multiplier": power_multiplier, "duration": duration, "description": description}
