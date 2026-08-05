class_name StatusService
extends RefCounted

const DEFINITIONS: Dictionary = {
	"bleed": {"max_stacks": 5, "duration": 5.0, "tick_interval": 1.0, "boss_behavior": "stagger"},
	"poison": {"max_stacks": 8, "duration": 8.0, "tick_interval": 1.0, "boss_behavior": "normal"},
	"burn": {"max_stacks": 3, "duration": 4.0, "tick_interval": 0.75, "boss_behavior": "regen_reduction"},
	"chill": {"max_stacks": 100, "duration": 5.0, "tick_interval": 0.0, "boss_behavior": "slow"},
	"shock": {"max_stacks": 1, "duration": 5.0, "tick_interval": 0.0, "boss_behavior": "chain"},
	"mark": {"max_stacks": 1, "duration": 8.0, "tick_interval": 0.0, "boss_behavior": "normal"}
}

var targets: Dictionary = {}
var target_ids_scratch: Array = []
var status_ids_scratch: Array = []

func clear() -> void:
	targets.clear()
	target_ids_scratch.clear()
	status_ids_scratch.clear()

func apply(target_id: int, status_id: String, source_actor: String, source_ability: String, chance: float = 1.0, potency: float = 1.0, duration_override: float = -1.0, stacks: int = 1, is_boss: bool = false, school: String = "", damage_tags: Array[String] = []) -> Dictionary:
	if not DEFINITIONS.has(status_id) or chance <= 0.0:
		return {"applied": false, "reason": "unknown_or_zero_chance"}
	var requested_status_id: String = status_id
	var definition: Dictionary = DEFINITIONS[requested_status_id]
	var bucket: Dictionary = Dictionary(targets.get(target_id, {}))
	var current: Dictionary = Dictionary(bucket.get(requested_status_id, {}))
	var max_stacks: int = int(definition.max_stacks)
	if requested_status_id == "poison" and (current.get("venom_pact", false) or "venom_pact" in damage_tags):
		max_stacks = 12
	var total_stacks: int = clampi(int(current.get("stacks", 0)) + maxi(1, stacks), 1, max_stacks)
	var duration: float = float(definition.duration) if duration_override < 0.0 else duration_override
	var boss_substitution: String = ""
	if is_boss:
		boss_substitution = String(definition.get("boss_behavior", "normal"))
		if boss_substitution == "stagger":
			current["stagger_power"] = potency
		elif boss_substitution == "slow":
			current["action_slow"] = potency
		if boss_substitution != "normal":
			current["boss_substitution"] = boss_substitution
	current["stacks"] = total_stacks
	current["remaining"] = duration
	current["tick_timer"] = float(definition.tick_interval)
	current["source_actor"] = source_actor
	current["source_ability"] = source_ability
	current["application_chance"] = chance
	current["potency"] = potency
	current["school"] = school
	current["damage_tags"] = damage_tags.duplicate()
	current["refresh_rule"] = String(definition.get("refresh_rule", "refresh_duration"))
	if requested_status_id == "bleed" and "moving_target" in damage_tags:
		current["tick_interval"] = 0.8
		current["tick_timer"] = minf(float(current.get("tick_timer", 0.8)), 0.8)
	if requested_status_id == "poison" and "venom_pact" in damage_tags:
		current["venom_pact"] = true
	bucket[requested_status_id] = current
	targets[target_id] = bucket
	return {"applied": true, "status_id": requested_status_id, "stacks": total_stacks, "remaining": duration, "boss_substitution": boss_substitution}

func tick(delta: float, target_alive: Callable = Callable()) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	target_ids_scratch.clear()
	for target_id: Variant in targets:
		target_ids_scratch.append(target_id)
	for target_id: Variant in target_ids_scratch:
		if target_alive.is_valid() and not bool(target_alive.call(int(target_id))):
			targets.erase(target_id)
			continue
		if not targets.has(target_id):
			continue
		var bucket: Dictionary = targets[target_id]
		status_ids_scratch.clear()
		for status_id: Variant in bucket:
			status_ids_scratch.append(status_id)
		for status_id_value: Variant in status_ids_scratch:
			var status_id: String = String(status_id_value)
			if not bucket.has(status_id):
				continue
			var state: Dictionary = bucket[status_id]
			state.remaining = float(state.get("remaining", 0.0)) - delta
			if float(state.get("tick_interval", DEFINITIONS.get(status_id, {}).get("tick_interval", 0.0))) > 0.0:
				state.tick_timer = float(state.get("tick_timer", 0.0)) - delta
				if state.tick_timer <= 0.0:
					state.tick_timer = float(state.get("tick_interval", DEFINITIONS.get(status_id, {}).get("tick_interval", 1.0)))
					events.append({"target_id": target_id, "status_id": status_id, "stacks": int(state.get("stacks", 1)), "potency": float(state.get("potency", 1.0)), "source_actor": state.get("source_actor", ""), "source_ability": state.get("source_ability", "")})
			bucket[status_id] = state
			if float(state.remaining) <= 0.0:
				bucket.erase(status_id)
		if bucket.is_empty():
			targets.erase(target_id)
	return events

func state_for(target_id: int, status_id: String) -> Dictionary:
	return Dictionary(targets.get(target_id, {})).get(status_id, {})

func has(target_id: int, status_id: String) -> bool:
	var bucket_value: Variant = targets.get(target_id, null)
	if not bucket_value is Dictionary:
		return false
	return not Dictionary(bucket_value).get(status_id, {}).is_empty()

func remove(target_id: int, status_id: String) -> void:
	var bucket: Dictionary = targets.get(target_id, {})
	bucket.erase(status_id)
	if bucket.is_empty():
		targets.erase(target_id)
	else:
		targets[target_id] = bucket

func remove_target(target_id: int) -> void:
	targets.erase(target_id)

func count_for(target_id: int) -> int:
	var bucket_value: Variant = targets.get(target_id, null)
	return Dictionary(bucket_value).size() if bucket_value is Dictionary else 0

func stacks_for(target_id: int, status_id: String) -> int:
	var bucket_value: Variant = targets.get(target_id, null)
	if not bucket_value is Dictionary:
		return 0
	return int(Dictionary(bucket_value).get(status_id, {}).get("stacks", 0))

func consume_stacks(target_id: int, status_id: String, amount: int) -> int:
	var bucket: Dictionary = targets.get(target_id, {})
	var state: Dictionary = bucket.get(status_id, {})
	if state.is_empty() or amount <= 0:
		return 0
	var consumed: int = mini(int(state.get("stacks", 0)), amount)
	var remaining: int = int(state.get("stacks", 0)) - consumed
	if remaining <= 0:
		bucket.erase(status_id)
	else:
		state["stacks"] = remaining
		bucket[status_id] = state
	if bucket.is_empty():
		targets.erase(target_id)
	else:
		targets[target_id] = bucket
	return consumed
