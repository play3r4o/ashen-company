class_name TrainingGroundsService
extends RefCounted

const Content = preload("res://src/content/training_grounds_content.gd")

const XP_PER_POINT: int = 100
const MAX_WEAPON_CANDIDATES: int = 4
const MAX_TECHNIQUE_CANDIDATES: int = 4

var profile: Dictionary = {}

func _init(target_profile: Dictionary = {}) -> void:
	bind_profile(target_profile)

func bind_profile(target_profile: Dictionary) -> void:
	profile = target_profile
	if profile.is_empty():
		return
	if not profile.get("training_nodes", {}) is Dictionary:
		profile.training_nodes = {}
	if not profile.get("training_points", 0) is int and not profile.get("training_points", 0) is float:
		profile.training_points = 0
	if not profile.get("training_xp", 0) is int and not profile.get("training_xp", 0) is float:
		profile.training_xp = 0
	ensure_free_nodes()

func ensure_free_nodes() -> void:
	if profile.is_empty():
		return
	var nodes: Dictionary = profile.training_nodes
	# The Company Crest is always present. Expedition Arsenal is deliberately
	# granted by constructing the Training Grounds; before that, the campfire
	# still permits a starter-only expedition but the preparation tree remains
	# unavailable.
	var free_nodes: Array[String] = ["company_crest"]
	if training_tier() > 0 or "training" in Array(profile.get("constructed_buildings", [])):
		free_nodes.append("expedition_arsenal")
	for node_id: String in free_nodes:
		nodes[node_id] = 1
	for school: String in Content.SCHOOLS:
		var starter: String = String(Content.SCHOOL_WEAPONS[school][0])
		nodes[starter] = 1
	profile.training_nodes = nodes
	# Four starters are always the class options; they are not an economic sink.
	if String(profile.get("starting_weapon", "")).is_empty():
		profile.starting_weapon = Content.starter_weapon_for_class(String(profile.get("starting_class", "warrior")))

func node(node_id: String) -> Dictionary:
	return Content.all_nodes().get(node_id, {})

func purchased_nodes() -> Dictionary:
	return Dictionary(profile.get("training_nodes", {}))

func node_rank(node_id: String) -> int:
	return int(purchased_nodes().get(node_id, 0))

func training_tier() -> int:
	return int(profile.get("training_level", 0))

func tree_available() -> bool:
	# Tier zero represents the newly built yard before its first restoration;
	# the Arsenal is available at construction, but the tree itself opens at
	# Training Grounds tier one as specified by the progression gates.
	return training_tier() > 0

func node_state(node_id: String) -> String:
	if not Content.all_nodes().has(node_id):
		return "unknown"
	if node_rank(node_id) > 0:
		return "purchased"
	var check: Dictionary = can_purchase(node_id)
	if bool(check.get("ok", false)):
		return "available"
	var reason: String = String(check.get("reason", ""))
	if reason.begins_with("Requires Training Grounds tier") or reason.contains("constructed Training Grounds"):
		return "tier_locked"
	if reason.contains("conflicts"):
		return "exclusive_locked"
	return "prerequisite_locked"

func school_outer_count(school: String) -> int:
	var result: int = 0
	for node_id: String in purchased_nodes():
		var definition: Dictionary = node(node_id)
		if String(definition.get("school", "")) == school and int(definition.get("training_ground_tier", 0)) >= 3:
			result += 1
	return result

func has_two_school_outers() -> bool:
	var schools_with_outer: int = 0
	for school: String in Content.SCHOOLS:
		if school_outer_count(school) > 0:
			schools_with_outer += 1
	return schools_with_outer >= 2

func has_exclusive_conflict(node_id: String) -> bool:
	var candidate: Dictionary = node(node_id)
	var candidate_unlock: String = String(candidate.get("unlock_id", node_id))
	for purchased_id: String in purchased_nodes():
		if node_rank(purchased_id) <= 0:
			continue
		var purchased: Dictionary = node(purchased_id)
		var conflicts: Array = purchased.get("exclusive_with", [])
		if node_id in conflicts or candidate_unlock in conflicts:
			return true
		if String(purchased.get("unlock_id", purchased_id)) == candidate_unlock and String(candidate.get("node_type", "")) == "doctrine":
			return true
	return false

func can_purchase(node_id: String) -> Dictionary:
	var definition: Dictionary = node(node_id)
	if definition.is_empty():
		return {"ok": false, "reason": "Unknown Training Grounds node."}
	if node_rank(node_id) > 0:
		return {"ok": false, "reason": "Already purchased."}
	if node_id == "expedition_arsenal" and not (training_tier() > 0 or "training" in Array(profile.get("constructed_buildings", []))):
		return {"ok": false, "reason": "Requires a constructed Training Grounds."}
	if bool(definition.get("free_node", false)):
		return {"ok": true, "cost": 0}
	var required_tier: int = int(definition.get("training_ground_tier", 1))
	if training_tier() < required_tier:
		return {"ok": false, "reason": "Requires Training Grounds tier %d." % required_tier}
	if "two_school_outer" in Array(definition.get("tags", [])):
		if not has_two_school_outers():
			return {"ok": false, "reason": "Requires outer training in two schools."}
	if has_exclusive_conflict(node_id):
		return {"ok": false, "reason": "This doctrine conflicts with a purchased doctrine."}
	for required_id_value: Variant in definition.get("prerequisite_ids", []):
		var required_id: String = String(required_id_value)
		if node_rank(required_id) <= 0:
			return {"ok": false, "reason": "Requires %s." % String(node(required_id).get("name", required_id))}
	var cost: int = int(definition.get("cost", 0))
	if int(profile.get("training_points", 0)) < cost:
		return {"ok": false, "reason": "Requires %d Training Points." % cost, "cost": cost}
	return {"ok": true, "cost": cost}

func purchase(node_id: String) -> Dictionary:
	var check: Dictionary = can_purchase(node_id)
	if not bool(check.get("ok", false)):
		return check
	var definition: Dictionary = node(node_id)
	var cost: int = int(check.get("cost", 0))
	profile.training_points = int(profile.get("training_points", 0)) - cost
	var nodes: Dictionary = profile.training_nodes
	nodes[node_id] = 1
	profile.training_nodes = nodes
	return {"ok": true, "node_id": node_id, "cost": cost, "name": String(definition.get("name", node_id))}

func total_purchased_cost() -> int:
	var total: int = 0
	for node_id: String in purchased_nodes():
		if node_rank(node_id) > 0:
			total += int(node(node_id).get("cost", 0))
	return total

func validate_tree() -> Dictionary:
	var nodes: Dictionary = Content.all_nodes()
	var errors: Array[String] = []
	if nodes.size() != 156:
		errors.append("expected 156 nodes, got %d" % nodes.size())
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	for node_id: String in nodes:
		_validate_tree_node(node_id, nodes, visiting, visited, errors, [])
	# A non-root node is reachable when recursively walking prerequisites to the
	# Company Crest. This catches accidental islands in authored catalog data.
	for node_id: String in nodes:
		if node_id == "company_crest":
			continue
		var seen: Dictionary = {}
		var queue: Array[String] = [node_id]
		var reaches_root: bool = false
		while not queue.is_empty():
			var current: String = queue.pop_front()
			if current == "company_crest":
				reaches_root = true
				break
			if seen.has(current):
				continue
			seen[current] = true
			for required_value: Variant in nodes.get(current, {}).get("prerequisite_ids", []):
				queue.append(String(required_value))
		if not reaches_root:
			errors.append("%s is not connected to Company Crest" % node_id)
	return {"valid": errors.is_empty(), "errors": errors}

func _validate_tree_node(node_id: String, nodes: Dictionary, visiting: Dictionary, visited: Dictionary, errors: Array[String], stack: Array) -> void:
	if bool(visiting.get(node_id, false)):
		errors.append("cycle: %s" % " -> ".join(stack + [node_id]))
		return
	if bool(visited.get(node_id, false)) or not nodes.has(node_id):
		return
	visiting[node_id] = true
	var definition: Dictionary = nodes.get(node_id, {})
	for required_value: Variant in definition.get("prerequisite_ids", []):
		var required_id: String = String(required_value)
		if not nodes.has(required_id):
			errors.append("%s requires missing %s" % [node_id, required_id])
		else:
			_validate_tree_node(required_id, nodes, visiting, visited, errors, stack + [node_id])
	visiting.erase(node_id)
	visited[node_id] = true

func dependants_of(node_id: String) -> Array[String]:
	var result: Array[String] = []
	var queue: Array[String] = [node_id]
	while not queue.is_empty():
		var parent: String = queue.pop_front()
		for candidate_id: String in purchased_nodes():
			if candidate_id in result or candidate_id == node_id:
				continue
			var candidate: Dictionary = node(candidate_id)
			if parent in Array(candidate.get("prerequisite_ids", [])):
				result.append(candidate_id)
				queue.append(candidate_id)
	return result

func refund_preview(node_id: String) -> Dictionary:
	if node_rank(node_id) <= 0:
		return {"ok": false, "reason": "Node is not purchased."}
	var definition: Dictionary = node(node_id)
	if bool(definition.get("free_node", false)) or String(definition.get("node_type", "")) == "root":
		return {"ok": false, "reason": "This node is permanent."}
	var refund_ids: Array[String] = [node_id]
	refund_ids.append_array(dependants_of(node_id))
	var refund_points: int = 0
	for refund_id: String in refund_ids:
		refund_points += int(node(refund_id).get("cost", 0))
	return {"ok": true, "node_ids": refund_ids, "refund_points": refund_points}

func refund(node_id: String, cascade: bool = false) -> Dictionary:
	var preview: Dictionary = refund_preview(node_id)
	if not bool(preview.get("ok", false)):
		return preview
	var dependants: Array = preview.get("node_ids", [])
	if dependants.size() > 1 and not cascade:
		return {"ok": false, "requires_confirmation": true, "node_ids": dependants, "refund_points": int(preview.refund_points)}
	var nodes: Dictionary = profile.training_nodes
	for refund_id_value: Variant in dependants:
		nodes.erase(String(refund_id_value))
	profile.training_nodes = nodes
	profile.training_points = int(profile.get("training_points", 0)) + int(preview.refund_points)
	_repair_arsenals()
	return {"ok": true, "node_ids": dependants, "refund_points": int(preview.refund_points)}

func grant_training_xp(amount: int, source: String = "expedition") -> Dictionary:
	var safe_amount: int = maxi(0, amount)
	var before_xp: int = int(profile.get("training_xp", 0))
	var total: int = before_xp + safe_amount
	var gained_points: int = floori(float(total) / float(XP_PER_POINT))
	profile.training_points = int(profile.get("training_points", 0)) + gained_points
	profile.training_xp = posmod(total, XP_PER_POINT)
	return {"source": source, "xp": safe_amount, "points": gained_points, "remaining_xp": int(profile.training_xp)}

func grant_one_time_points(claim_id: String, amount: int, source: String = "achievement") -> Dictionary:
	var clean_id: String = claim_id.strip_edges()
	var points: int = maxi(0, amount)
	if clean_id.is_empty() or points <= 0:
		return {"claimed": false, "points": 0, "reason": "invalid_reward"}
	var claims: Dictionary = profile.get("claimed_training_rewards", {})
	if bool(claims.get(clean_id, false)):
		return {"claimed": false, "points": 0, "reason": "already_claimed"}
	claims[clean_id] = true
	profile.claimed_training_rewards = claims
	profile.training_points = int(profile.get("training_points", 0)) + points
	return {"claimed": true, "points": points, "source": source, "claim_id": clean_id}

func grant_training_reward(claim_id: String, amount: int, source: String = "achievement") -> Dictionary:
	return grant_one_time_points(claim_id, amount, source)

func training_points_from_building_upgrade(building_id: String, new_tier: int) -> Dictionary:
	if building_id == "training" and new_tier >= 2 and new_tier <= 5:
		return grant_one_time_points("training_grounds_tier_%d" % new_tier, 4, "training_grounds")
	if building_id == "veterans_hall" and new_tier > 1:
		return grant_one_time_points("hall_tier_%d" % new_tier, 2, "hall")
	return {"claimed": false, "points": 0, "reason": "no_training_reward"}

func expedition_training_xp(dread: float, elite_kills: int, boss_cycles: int, objectives: int, survival_seconds: float, extracted: bool) -> int:
	var amount: int = 20
	amount += floori(clampf(minf(dread, 300.0) * 0.20, 0.0, 60.0))
	amount += mini(25, maxi(0, elite_kills) * 5)
	amount += maxi(0, boss_cycles) * 50
	amount += maxi(0, objectives) * 30
	amount += mini(25, floori(maxf(0.0, survival_seconds) / 120.0) * 5)
	if not extracted:
		amount = floori(float(amount) * 0.35)
	return amount

func unlocked_weapons() -> Array[String]:
	var result: Array[String] = []
	for node_id: String in purchased_nodes():
		var definition: Dictionary = node(node_id)
		if String(definition.get("node_type", "")) == "weapon" and node_rank(node_id) > 0:
			result.append(String(definition.get("unlock_id", node_id)))
	result.sort()
	return result

func unlocked_techniques() -> Array[String]:
	var result: Array[String] = []
	for node_id: String in purchased_nodes():
		var definition: Dictionary = node(node_id)
		if String(definition.get("node_type", "")) == "technique" and node_rank(node_id) > 0:
			result.append(String(definition.get("unlock_id", node_id)))
	result.sort()
	return result

func unlocked_doctrines() -> Array[String]:
	var result: Array[String] = []
	for node_id: String in purchased_nodes():
		var definition: Dictionary = node(node_id)
		if String(definition.get("node_type", "")) == "doctrine" and node_rank(node_id) > 0:
			result.append(String(definition.get("unlock_id", node_id)))
	result.sort()
	return result

func mastery_unlocked(school: String) -> bool:
	return node_rank(String(Content.SCHOOL_MASTERY.get(school, ""))) > 0

func permanent_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	for node_id: String in purchased_nodes():
		var definition: Dictionary = node(node_id)
		for stat: String in Dictionary(definition.get("stat_modifiers", {})):
			modifiers[stat] = float(modifiers.get(stat, 0.0)) + float(definition.stat_modifiers[stat])
	return modifiers

func _repair_arsenals() -> void:
	var unlocked_weapon_ids: Array[String] = unlocked_weapons()
	var unlocked_technique_ids: Array[String] = unlocked_techniques()
	var arsenals: Array = profile.get("expedition_arsenals", [])
	for arsenal_value: Variant in arsenals:
		if not arsenal_value is Dictionary:
			continue
		var arsenal: Dictionary = arsenal_value
		var weapons: Array = []
		for id_value: Variant in arsenal.get("weapon_ids", []):
			if String(id_value) in unlocked_weapon_ids:
				weapons.append(String(id_value))
		arsenal.weapon_ids = weapons.slice(0, MAX_WEAPON_CANDIDATES)
		var techniques: Array = []
		for id_value: Variant in arsenal.get("technique_ids", []):
			if String(id_value) in unlocked_technique_ids:
				techniques.append(String(id_value))
		arsenal.technique_ids = techniques.slice(0, MAX_TECHNIQUE_CANDIDATES)
		var doctrines: Array = []
		for id_value: Variant in arsenal.get("doctrine_ids", []):
			if String(id_value) in unlocked_doctrines():
				doctrines.append(String(id_value))
		arsenal.doctrine_ids = doctrines.slice(0, 2 if node_rank("dual_doctrine") > 0 else 1)
	profile.expedition_arsenals = arsenals
	if String(profile.get("starting_weapon", "")) not in unlocked_weapon_ids:
		profile.starting_weapon = Content.starter_weapon_for_class(String(profile.get("starting_class", "warrior")))
	if String(profile.get("starting_doctrine", "")) not in unlocked_doctrines():
		profile.starting_doctrine = ""
	for arsenal_value: Variant in arsenals:
		if arsenal_value is Dictionary:
			var arsenal: Dictionary = arsenal_value
			if String(arsenal.get("starting_weapon", "")) not in Array(arsenal.get("weapon_ids", [])):
				arsenal.starting_weapon = profile.starting_weapon
				var repaired_weapons: Array = Array(arsenal.get("weapon_ids", []))
				if profile.starting_weapon not in repaired_weapons:
					repaired_weapons.push_front(profile.starting_weapon)
				arsenal.weapon_ids = repaired_weapons.slice(0, MAX_WEAPON_CANDIDATES)
