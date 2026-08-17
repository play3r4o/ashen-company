class_name AshenWorldPresentationController
extends Node2D

const ExplorationMarkerScene = preload("res://scenes/world/landmarks/exploration_marker.tscn")
const RuinedCitySiteScene = preload("res://scenes/world/landmarks/ruined_city_site.tscn")

@onready var frontier_gate: AshenFrontierGate = $FrontierGate
@onready var landmark_host: Node2D = $Landmarks
@onready var ruined_city_site: AshenRuinedCitySite = $RuinedCitySite

var active_landmarks: Dictionary = {}
var landmark_pool: Array[Node2D] = []
var live_landmark_ids: Dictionary = {}
var stale_landmark_ids: Array = []


func sync_frame(run_active: bool, frontier_position: Vector2, frontier_unlocked: bool, points: Array, elapsed: float, prisoner_rescued: bool = false, prison_key_available: bool = false) -> void:
	frontier_gate.visible = run_active
	if run_active:
		frontier_gate.bind_state(frontier_position, frontier_unlocked)
	live_landmark_ids.clear()
	stale_landmark_ids.clear()
	if run_active:
		for point: Variant in points:
			if bool(point.get("discovered")):
				continue
			# The authored ruined-city district owns its own buildings, prison
			# wing, lock marker and arrival treatment. Do not layer the generic
			# exploration marker over those production visuals.
			if String(point.get("kind")) in ["ruined_city", "prison"]:
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
	var city_point: Dictionary = {}
	for point: Variant in points:
		if point is Dictionary and String(point.get("kind", "")) == "ruined_city":
			city_point = point
			break
		if point is Object and String(point.get("kind")) == "ruined_city":
			city_point = {"position": point.get("position")}
			break
	if run_active and not city_point.is_empty():
		# Exploration points are authored-state coordinates supplied by the
		# expedition controller. That controller already applies the saved
		# canonical-scene offset to the city and prison points, so this scene only
		# presents the position it receives and never applies a second transform.
		ruined_city_site.sync_state(Vector2(city_point.get("position", Vector2.ZERO)), not prisoner_rescued, prison_key_available, elapsed)
	else:
		ruined_city_site.reset_visual()


func _acquire_landmark() -> Node2D:
	var marker: Node2D
	if landmark_pool.is_empty():
		marker = ExplorationMarkerScene.instantiate() as Node2D
		landmark_host.add_child(marker)
	else:
		marker = landmark_pool.pop_back()
	marker.call("reset_visual")
	return marker
