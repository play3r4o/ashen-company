class_name StatusDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var school: String = ""
@export var max_stacks: int = 1
@export var duration: float = 0.0
@export var tick_interval: float = 0.0
@export var default_potency: float = 1.0
@export var refresh_rule: String = "refresh_duration"
@export var boss_behavior: String = "normal"
@export var tags: PackedStringArray = PackedStringArray()

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"school": school,
		"max_stacks": max_stacks,
		"duration": duration,
		"tick_interval": tick_interval,
		"default_potency": default_potency,
		"refresh_rule": refresh_rule,
		"boss_behavior": boss_behavior,
		"tags": Array(tags)
	}
