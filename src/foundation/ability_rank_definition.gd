class_name AbilityRankDefinition
extends Resource

@export var rank: int = 1
@export var damage_multiplier: float = 1.0
@export var cooldown_or_interval: float = 0.0
@export var area_multiplier: float = 1.0
@export var duration_multiplier: float = 1.0
@export var projectile_count: int = 0
@export var pierce: int = 0
## Named, data-only changes for this rank.  Keeping the values on the rank
## resource lets designers inspect and balance a progression without adding a
## branch to the combat controller for every weapon.
@export var stat_changes: Dictionary = {}
@export var status_application: Dictionary = {}
@export var behavior_flags: Array[String] = []
@export var visual_upgrade: String = ""
@export_multiline var description: String = ""

func to_dictionary() -> Dictionary:
	return {
		"rank": rank,
		"damage_multiplier": damage_multiplier,
		"cooldown_or_interval": cooldown_or_interval,
		"area_multiplier": area_multiplier,
		"duration_multiplier": duration_multiplier,
		"projectile_count": projectile_count,
		"pierce": pierce,
		"stat_changes": stat_changes.duplicate(true),
		"status_application": status_application.duplicate(true),
		"behavior_flags": behavior_flags.duplicate(),
		"visual_upgrade": visual_upgrade,
		"description": description
	}
