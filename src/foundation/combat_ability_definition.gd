class_name CombatAbilityDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var school: String = ""
@export var category: String = "weapon"
@export var tags: Array[String] = []
@export var base_stats: Dictionary = {}
@export var ranks: Array[Resource] = []
@export var environment_interactions: Array[String] = []
@export var visual_effect_ids: Array[String] = []
@export var audio_effect_ids: Array[String] = []
@export var eligible_doctrines: Array[String] = []

func to_dictionary() -> Dictionary:
	var rank_data: Array[Dictionary] = []
	for rank_value: Variant in ranks:
		if rank_value is AbilityRankDefinition:
			rank_data.append(rank_value.to_dictionary())
	return {
		"id": id,
		"name": display_name,
		"school": school,
		"category": category,
		"tags": tags.duplicate(),
		"base_stats": base_stats.duplicate(true),
		"ranks": rank_data,
		"environment_interactions": environment_interactions.duplicate(),
		"visual_effect_ids": visual_effect_ids.duplicate(),
		"audio_effect_ids": audio_effect_ids.duplicate(),
		"eligible_doctrines": eligible_doctrines.duplicate()
	}

## Build the small immutable payload consumed by a run. The hot combat loop
## never needs to inspect Resource objects or parse string tags repeatedly.
func compile_rank(rank_index: int) -> Dictionary:
	var index: int = clampi(rank_index - 1, 0, maxi(0, ranks.size() - 1))
	var rank_data: Dictionary = {}
	if not ranks.is_empty() and ranks[index] is AbilityRankDefinition:
		rank_data = (ranks[index] as AbilityRankDefinition).to_dictionary()
	return {
		"id": id,
		"school": school,
		"category": category,
		"rank": int(rank_data.get("rank", index + 1)),
		"base_stats": base_stats.duplicate(true),
		"rank_stats": rank_data,
		"tags": tags.duplicate(),
		"environment_interactions": environment_interactions.duplicate(),
		"eligible_doctrines": eligible_doctrines.duplicate()
	}
