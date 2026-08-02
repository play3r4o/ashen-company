class_name RunBuildState
extends Resource

@export var seed: int = 1
@export var level: int = 1
@export var weapon_ranks: Dictionary = {}
@export var technique_ranks: Dictionary = {}
@export var boon_ranks: Dictionary = {}
@export var doctrine_ids: PackedStringArray = PackedStringArray()
@export var rerolls_remaining: int = 0
@export var recently_rejected_choices: PackedStringArray = PackedStringArray()

func to_dictionary() -> Dictionary:
	return {"seed": seed, "level": level, "weapon_ranks": weapon_ranks.duplicate(true), "technique_ranks": technique_ranks.duplicate(true), "boon_ranks": boon_ranks.duplicate(true), "doctrine_ids": Array(doctrine_ids), "rerolls_remaining": rerolls_remaining, "recent_rejected_choices": Array(recently_rejected_choices)}

static func from_dictionary(data: Dictionary) -> RunBuildState:
	var result := RunBuildState.new()
	result.seed = int(data.get("seed", result.seed))
	result.level = maxi(1, int(data.get("level", result.level)))
	result.weapon_ranks = Dictionary(data.get("weapon_ranks", {})).duplicate(true)
	result.technique_ranks = Dictionary(data.get("technique_ranks", {})).duplicate(true)
	result.boon_ranks = Dictionary(data.get("boon_ranks", {})).duplicate(true)
	result.doctrine_ids = PackedStringArray(data.get("doctrine_ids", []))
	result.rerolls_remaining = maxi(0, int(data.get("rerolls_remaining", 0)))
	result.recently_rejected_choices = PackedStringArray(data.get("recent_rejected_choices", []))
	return result
