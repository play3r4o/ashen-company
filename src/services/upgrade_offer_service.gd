class_name UpgradeOfferService
extends RefCounted

const Content = preload("res://src/content/training_grounds_content.gd")
const Arsenal = preload("res://src/services/arsenal_service.gd")
const TrainingGrounds = preload("res://src/services/training_grounds_service.gd")

static func generate(run_state: Dictionary, profile: Dictionary, arsenal: Dictionary, offer_index: int = 0) -> Array[Dictionary]:
	var normalized: Dictionary = Arsenal.normalize(profile, arsenal)
	var training := TrainingGrounds.new(profile)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_state.get("seed", 1)) ^ (int(run_state.get("level", 1)) * 7919) ^ (offer_index * 104729)
	var current_weapons: Dictionary = Dictionary(run_state.get("weapon_ranks", {}))
	var current_techniques: Dictionary = Dictionary(run_state.get("technique_ranks", {}))
	var candidates: Array[Dictionary] = []
	var owned_combat_count: int = 0
	for rank_value: Variant in current_weapons.values():
		if int(rank_value) > 0:
			owned_combat_count += 1
	for rank_value: Variant in current_techniques.values():
		if int(rank_value) > 0:
			owned_combat_count += 1
	var owned_weapon_count: int = 0
	for rank_value: Variant in current_weapons.values():
		if int(rank_value) > 0:
			owned_weapon_count += 1
	var owned_technique_count: int = 0
	for rank_value: Variant in current_techniques.values():
		if int(rank_value) > 0:
			owned_technique_count += 1
	for weapon_id_value: Variant in normalized.get("weapon_ids", []):
		var weapon_id: String = String(weapon_id_value)
		var rank: int = int(current_weapons.get(weapon_id, 0))
		if rank >= 5:
			continue
		if rank <= 0 and owned_weapon_count >= Arsenal.MAX_WEAPONS:
			continue
		if rank == 4 and not training.mastery_unlocked(Content.school_for_ability(weapon_id)):
			continue
		candidates.append({"type": "weapon", "id": weapon_id, "rank": rank + 1, "owned": rank > 0, "school": Content.school_for_ability(weapon_id)})
	for technique_id_value: Variant in normalized.get("technique_ids", []):
		var technique_id: String = String(technique_id_value)
		var rank: int = int(current_techniques.get(technique_id, 0))
		if rank >= 5:
			continue
		if rank <= 0 and owned_technique_count >= Arsenal.MAX_TECHNIQUES:
			continue
		if rank == 4 and not training.mastery_unlocked(Content.school_for_ability(technique_id)):
			continue
		candidates.append({"type": "technique", "id": technique_id, "rank": rank + 1, "owned": rank > 0, "school": Content.school_for_ability(technique_id)})
	for boon_id: String in ["damage", "attack_speed", "health", "armor", "speed", "area", "duration", "critical", "critical_damage", "projectile_speed", "pickup", "healing"]:
		var boon_rank: int = int(Dictionary(run_state.get("boon_ranks", {})).get(boon_id, 0))
		if boon_rank < 5:
			candidates.append({"type": "boon", "id": boon_id, "rank": boon_rank + 1, "owned": boon_rank > 0, "school": "company"})
	var rejected: Array = run_state.get("recent_rejected_choices", [])
	var prepared_school_counts: Dictionary = {}
	for id_value: Variant in Array(normalized.get("weapon_ids", [])) + Array(normalized.get("technique_ids", [])):
		var school: String = Content.school_for_ability(String(id_value))
		prepared_school_counts[school] = int(prepared_school_counts.get(school, 0)) + 1
	var dominant_school: String = ""
	var dominant_count: int = 0
	for school: String in prepared_school_counts:
		if int(prepared_school_counts[school]) > dominant_count:
			dominant_school = school
			dominant_count = int(prepared_school_counts[school])
	var dominant_allowed: bool = dominant_count * 4 >= maxi(1, (Array(normalized.get("weapon_ids", [])).size() + Array(normalized.get("technique_ids", [])).size()) * 3)
	var weighted: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		var weight: float = 1.0
		if bool(candidate.owned):
			weight += 1.0
		if String(candidate.id) in rejected:
			weight *= 0.25
		if not dominant_allowed and String(candidate.school) == dominant_school:
			weight *= 0.68
		weight *= _doctrine_weight(candidate, normalized)
		weighted.append({"candidate": candidate, "weight": weight})
	var result: Array[Dictionary] = []
	# The guaranteed rank-up is for an owned combat ability, not for a boon.
	# Boons are deliberately kept in the pool, but must not crowd out the
	# early-build guarantee described by the Training Grounds rules.
	var owned_candidates: Array[Dictionary] = weighted.filter(func(item: Dictionary) -> bool:
		return bool(item.candidate.owned) and String(item.candidate.type) in ["weapon", "technique"]
	)
	if not owned_candidates.is_empty():
		result.append(_weighted_pick_with_school_limit(owned_candidates, rng, result, dominant_allowed))
	if owned_combat_count < 2:
		# The early-run guarantee is specifically a new combat ability. Boons are
		# always rank-zero at the start too, but must never satisfy this slot.
		var acquisition_candidates: Array[Dictionary] = weighted.filter(func(item: Dictionary) -> bool:
			return not bool(item.candidate.owned) and String(item.candidate.type) in ["weapon", "technique"]
		)
		if not acquisition_candidates.is_empty() and not _contains_acquisition(result):
			var acquisition: Dictionary = _weighted_pick_with_school_limit(acquisition_candidates, rng, result, dominant_allowed)
			result.append(acquisition)
	while result.size() < 3 and not weighted.is_empty():
		var pick: Dictionary = _weighted_pick_with_school_limit(weighted, rng, result, dominant_allowed)
		if pick.is_empty():
			break
		if result.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(pick.get("id", ""))):
			weighted = weighted.filter(func(item: Dictionary) -> bool: return String(item.candidate.get("id", "")) != String(pick.get("id", "")))
			continue
		result.append(pick)
	if result.size() < 3:
		var boons: Array[Dictionary] = []
		for candidate: Dictionary in weighted:
			if String(candidate.candidate.get("type", "")) == "boon":
				boons.append(candidate.candidate)
		for boon: Dictionary in boons:
			if result.size() >= 3:
				break
			if not result.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(boon.get("id", ""))):
				result.append(boon)
	return result

static func _contains_acquisition(choices: Array[Dictionary]) -> bool:
	for choice: Dictionary in choices:
		if not bool(choice.get("owned", false)) and String(choice.get("type", "")) in ["weapon", "technique"]:
			return true
	return false

## Generate a deterministic reroll and guarantee that it is not the exact
## three-card set currently on screen. The caller owns the reroll counter;
## this helper only advances the deterministic offer index.
static func reroll(run_state: Dictionary, profile: Dictionary, arsenal: Dictionary, current_choices: Array[Dictionary], offer_index: int) -> Dictionary:
	var current_signature: String = choice_signature(current_choices)
	for attempt: int in range(1, 33):
		var candidate_index: int = offer_index + attempt
		var choices: Array[Dictionary] = generate(run_state, profile, arsenal, candidate_index)
		if choice_signature(choices) != current_signature:
			return {"choices": choices, "offer_index": candidate_index}
	return {"choices": generate(run_state, profile, arsenal, offer_index + 1), "offer_index": offer_index + 1}

static func choice_signature(choices: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for choice: Dictionary in choices:
		parts.append("%s:%s:%d" % [String(choice.get("type", "")), String(choice.get("id", "")), int(choice.get("rank", 0))])
	parts.sort()
	return "|".join(parts)

static func _doctrine_weight(candidate: Dictionary, arsenal: Dictionary) -> float:
	var school: String = String(candidate.get("school", ""))
	var doctrines: Array = arsenal.get("doctrine_ids", [])
	var weight: float = 1.0
	for doctrine_id_value: Variant in doctrines:
		var doctrine_id: String = String(doctrine_id_value)
		var definition: Dictionary = Content.doctrines().get(doctrine_id, {})
		if String(definition.get("school", "")) == school:
			weight *= 1.20
		elif String(definition.get("school", "")) == "hybrid":
			weight *= 1.10
	return clampf(weight, 0.80, 1.20)

static func _weighted_pick(weighted: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	if weighted.is_empty():
		return {}
	var total: float = 0.0
	for item: Dictionary in weighted:
		total += maxf(0.01, float(item.weight))
	var roll: float = rng.randf() * total
	for item: Dictionary in weighted:
		roll -= maxf(0.01, float(item.weight))
		if roll <= 0.0:
			return Dictionary(item.candidate).duplicate(true)
	return Dictionary(weighted.back().candidate).duplicate(true)

static func _weighted_pick_with_school_limit(weighted: Array[Dictionary], rng: RandomNumberGenerator, selected: Array[Dictionary], dominant_allowed: bool) -> Dictionary:
	var eligible: Array[Dictionary] = []
	for item: Dictionary in weighted:
		var candidate: Dictionary = item.get("candidate", {})
		if selected.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(candidate.get("id", ""))):
			continue
		var school: String = String(candidate.get("school", ""))
		if not dominant_allowed and school not in ["", "company"]:
			var same_school: int = 0
			for existing: Dictionary in selected:
				if String(existing.get("school", "")) == school:
					same_school += 1
			if same_school >= 2:
				continue
		eligible.append(item)
	if eligible.is_empty():
		# A fully committed school or a very small pool is still valid.  Prefer
		# a non-duplicate card, but do not let the diversity rule create fewer
		# than three choices.
		for item: Dictionary in weighted:
			var candidate: Dictionary = item.get("candidate", {})
			if not selected.any(func(existing: Dictionary) -> bool: return String(existing.get("id", "")) == String(candidate.get("id", ""))):
				eligible.append(item)
	return _weighted_pick(eligible, rng)
