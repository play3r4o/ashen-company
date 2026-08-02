class_name DoctrineDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var school: String = ""
@export_multiline var description: String = ""
@export var modifiers: Dictionary = {}
@export var exclusive_with: Array[String] = []
@export var tags: Array[String] = []

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"school": school,
		"description": description,
		"modifiers": modifiers.duplicate(true),
		"exclusive_with": exclusive_with.duplicate(),
		"tags": tags.duplicate()
	}
