class_name TrainingNodeDefinition
extends Resource

## Authoring resource for one permanent Training Grounds node.
## The runtime registry uses the same fields, so edits made in Godot remain
## the source of truth for the tree UI and purchasing rules.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var node_type: String = "minor"
@export var school: String = "company"
@export var icon: String = ""
@export var cost: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var prerequisite_ids: Array[String] = []
@export var exclusive_with: Array[String] = []
@export var unlock_id: String = ""
@export var stat_modifiers: Dictionary = {}
@export var tags: Array[String] = []
@export var training_ground_tier: int = 1
@export var free_node: bool = false

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"description": description,
		"node_type": node_type,
		"school": school,
		"icon": icon,
		"cost": cost,
		"position": position,
		"prerequisite_ids": prerequisite_ids.duplicate(),
		"exclusive_with": exclusive_with.duplicate(),
		"unlock_id": unlock_id,
		"stat_modifiers": stat_modifiers.duplicate(true),
		"tags": tags.duplicate(),
		"training_ground_tier": training_ground_tier,
		"free_node": free_node
	}
