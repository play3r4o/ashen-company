class_name AshenRuinedCitySite
extends Node2D

## Authored Meadow city. The scene owns the complete walkable visual
## composition; runtime only moves the root and toggles prisoner state.

@onready var prisoner: Sprite2D = $Prisoner
@onready var lock_marker: Sprite2D = $LockMarker
@onready var arrival_label: Label = $ArrivalLabel

func sync_state(world_position: Vector2, prisoner_locked: bool, key_available: bool, elapsed: float) -> void:
	position = world_position.round()
	visible = true
	prisoner.visible = prisoner_locked
	lock_marker.visible = prisoner_locked and not key_available
	if arrival_label != null:
		arrival_label.visible = prisoner_locked
		arrival_label.modulate.a = 0.78 + sin(elapsed * 2.0) * 0.08

func reset_visual() -> void:
	visible = false
	prisoner.visible = true
	lock_marker.visible = true
	if arrival_label != null:
		arrival_label.visible = true
		arrival_label.modulate.a = 0.86


func authored_blocker_rects_local() -> Array[Rect2]:
	"""Return blocker bounds authored by this scene and its wall-kit child.

	The expedition keeps a compact 32px navigation grid, but the physical
	shapes belong to the same scene that owns the ruined-city artwork.  Only
	polygons beneath a StaticBody2D named Collision are included; interaction
	and touch areas are intentionally excluded.
	"""
	var result: Array[Rect2] = []
	for candidate: Node in find_children("*", "CollisionPolygon2D", true, false):
		var polygon_node := candidate as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.size() < 3:
			continue
		var parent: Node = polygon_node.get_parent()
		var is_blocker := false
		while parent != null and parent != self:
			if parent.name in ["InteractionArea", "TouchArea"]:
				is_blocker = false
				break
			if parent is StaticBody2D and String(parent.name).to_lower().contains("collision"):
				is_blocker = true
			parent = parent.get_parent()
		if not is_blocker:
			continue
		var local_points: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in polygon_node.polygon:
			local_points.append(to_local(polygon_node.to_global(point)))
		var bounds := Rect2(local_points[0], Vector2.ZERO)
		for point: Vector2 in local_points.slice(1):
			bounds = bounds.expand(point)
		if bounds.has_area():
			result.append(bounds)
	return result
