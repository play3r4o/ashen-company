class_name AshenWorldPresentationController
extends Node2D

const ExplorationMarkerScene = preload("res://scenes/world/landmarks/exploration_marker.tscn")
const RETIRED_LANDMARK_KINDS := {"ruined_city": true, "prison": true}

@onready var frontier_gate: AshenFrontierGate = AshenSceneBindings.optional(self, &"FrontierGate") as AshenFrontierGate
@onready var landmark_host: Node2D = AshenSceneBindings.required(self, &"Landmarks", "WorldPresentation") as Node2D

var active_landmarks: Dictionary = {}
var landmark_pool: Array[Node2D] = []
var live_landmark_ids: Dictionary = {}
var stale_landmark_ids: Array = []


func sync_frame(run_active: bool, frontier_position: Vector2, frontier_unlocked: bool, points: Array, elapsed: float, prisoner_rescued: bool = false, prison_key_available: bool = false) -> void:
	if frontier_gate != null:
		frontier_gate.visible = run_active
	if run_active and frontier_gate != null:
		frontier_gate.bind_state(frontier_position, frontier_unlocked)
	live_landmark_ids.clear()
	stale_landmark_ids.clear()
	if run_active:
		for point: Variant in points:
			if bool(point.get("discovered")):
				continue
			# The ruined-city district and its prison wing are intentionally not
			# part of the current Meadow presentation. Keep their semantic records
			# for save/progression compatibility, but do not show a replacement
			# marker or resurrect their retired art.
			if RETIRED_LANDMARK_KINDS.has(String(point.get("kind"))):
				continue
			var point_id: String = String(point.get("id"))
			live_landmark_ids[point_id] = true
			var marker := active_landmarks.get(point_id) as Node2D
			if marker == null:
				marker = _acquire_landmark()
				active_landmarks[point_id] = marker
			marker.call("sync_state", Vector2(point.get("position")), String(point.get("label")), String(point.get("kind")), elapsed)
	for point_id: Variant in active_landmarks:
		if live_landmark_ids.has(point_id):
			continue
		stale_landmark_ids.append(point_id)
	for point_id: Variant in stale_landmark_ids:
		var marker := active_landmarks[point_id] as Node2D
		active_landmarks.erase(point_id)
		marker.visible = false
		landmark_pool.append(marker)


func _acquire_landmark() -> Node2D:
	var marker: Node2D
	if landmark_pool.is_empty():
		marker = ExplorationMarkerScene.instantiate() as Node2D
		if landmark_host != null:
			landmark_host.add_child(marker)
		else:
			add_child(marker)
	else:
		marker = landmark_pool.pop_back()
	marker.call("reset_visual")
	return marker
