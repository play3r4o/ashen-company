class_name RunBoonDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var stat: String = ""
@export var rank_values: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
@export var tags: PackedStringArray = PackedStringArray(["boon"])

func value_at_rank(rank: int) -> float:
	if rank <= 0 or rank > rank_values.size():
		return 0.0
	return float(rank_values[rank - 1])

func to_dictionary() -> Dictionary:
	return {"id": id, "display_name": display_name, "description": description, "stat": stat, "rank_values": rank_values.duplicate(), "tags": Array(tags)}
