extends "res://scenes/world/world_controller.gd"
func _input(event: InputEvent) -> void:
	if screen == Screen.CAMP:
		if not _camp_hub_active():
			return
		if _gate_confirmation_open():
			_reset_movement_input()
			return
		if event is InputEventScreenTouch:
			var camp_touch: InputEventScreenTouch = event
			if camp_touch.pressed and joystick_touch_id < 0 and camp_touch.position.y > size.y * 0.20 and not _point_over_camp_action_button(camp_touch.position):
				joystick_touch_id = camp_touch.index
				joystick_origin = camp_touch.position
				joystick_position = camp_touch.position
				joystick_vector = Vector2.ZERO
			elif not camp_touch.pressed and camp_touch.index == joystick_touch_id:
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
		elif event is InputEventScreenDrag:
			var camp_drag: InputEventScreenDrag = event
			if camp_drag.index == joystick_touch_id:
				joystick_position = camp_drag.position
				joystick_vector = (camp_drag.position - joystick_origin).limit_length(46.0) / 46.0
		if event.is_action_pressed("guard_step"):
			_interact_with_camp_target()
		return
	if screen != Screen.RUN:
		return
	if choosing_upgrade or run_paused:
		# Touch release events can be consumed by the pause/upgrade UI. Clear the
		# joystick here as well so a run can never resume with a dead touch id.
		_reset_movement_input()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and joystick_touch_id < 0 and touch.position.y > size.y * 0.34 and not _point_over_action_button(touch.position):
			joystick_touch_id = touch.index
			joystick_origin = touch.position
			joystick_position = touch.position
			joystick_vector = Vector2.ZERO
		elif not touch.pressed and touch.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == joystick_touch_id:
			joystick_position = drag.position
			var offset: Vector2 = joystick_position - joystick_origin
			joystick_vector = offset.limit_length(46.0) / 46.0
	if event.is_action_pressed("guard_step"):
		_guard_step()

func _camp_hub_active() -> bool:
	return screen == Screen.CAMP and is_instance_valid(camp_interact_button) and camp_interact_button.is_inside_tree()

func _process_camp(delta: float) -> void:
	camp_elapsed += delta
	_update_camp_wanderers(delta)
	if _gate_confirmation_open():
		camp_move_vector = Vector2.ZERO
		return
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard if keyboard.length_squared() > 0.01 else joystick_vector
	direction = direction.normalized() if direction.length_squared() > 0.01 else Vector2.ZERO
	camp_move_vector = direction
	if direction.length_squared() > 0.01:
		last_move_vector = direction
		var movement: Vector2 = direction * CAMP_WALK_SPEED * delta
		var next_x := Vector2(camp_player_position.x + movement.x, camp_player_position.y)
		var next_y := Vector2(camp_player_position.x, camp_player_position.y + movement.y)
		if not _camp_position_blocked(next_x):
			camp_player_position.x = next_x.x
		if not _camp_position_blocked(next_y):
			camp_player_position.y = next_y.y
	var gate: Vector2 = _camp_gate_position()
	camp_player_position.x = clampf(camp_player_position.x, 16.0, world_size.x - 16.0)
	camp_player_position.y = clampf(camp_player_position.y, 24.0, gate.y + 34.0)
	if camp_player_position.y >= gate.y:
		if is_instance_valid(active_camp_scene) and active_camp_scene.gate_opening_contains_x(camp_player_position.x):
			_begin_expedition_from_gate()
			return
		camp_player_position.y = gate.y - 1.0
	_update_world_camera(camp_player_position, not camp_uses_field_camera)
	camp_interaction_target = _nearest_camp_interaction()
	if camp_structure_definitions.has(camp_interaction_target) or camp_interaction_target.begins_with("plot_"):
		camp_highlighted_structure = camp_interaction_target
	elif not camp_highlighted_structure.is_empty():
		camp_highlighted_structure = ""
	_update_camp_interact_button()

func _camp_position_blocked(position: Vector2) -> bool:
	var gate: Vector2 = _camp_gate_position()
	var in_gate_corridor: bool = is_instance_valid(active_camp_scene) and active_camp_scene.gate_opening_contains_x(position.x, 4.0) and position.y >= gate.y - 54.0 and position.y <= gate.y + 40.0
	if _point_hits_camp_fence(position):
		return true
	if not in_gate_corridor and not Geometry2D.is_point_in_polygon(position, _camp_boundary_world()):
		return true
	for structure_id: String in camp_structure_definitions:
		if not _is_constructed(structure_id):
			continue
		var definition: StructureDefinition = camp_structure_definitions[structure_id]
		if definition.contains_ground_point_for_tier(position, 9.0, _structure_tier(structure_id)):
			return true
	if _point_hits_camp_decor(position, 9.0):
		return true
	return false

func _safe_camp_spawn_position() -> Vector2:
	var gate: Vector2 = _camp_gate_position()
	var candidates: Array[Vector2] = [
		gate + Vector2(0.0, -42.0),
		_world_map_point(Vector2(600.0, 585.0)),
		_world_map_point(Vector2(585.0, 610.0)),
		_world_map_point(Vector2(520.0, 610.0)),
		_world_map_point(Vector2(650.0, 610.0))
	]
	for candidate: Vector2 in candidates:
		if not _camp_position_blocked(candidate):
			return candidate
	return gate + Vector2(0.0, -34.0)

func _structure_tier(structure_id: String) -> int:
	if structure_id == "veterans_hall":
		return _town_level()
	if structure_id in ["armory", "blacksmith", "quartermaster", "training"]:
		return int(save.get("profile", {}).get("%s_level" % structure_id, 0))
	return 0

func _point_hits_camp_fence(position: Vector2) -> bool:
	return is_instance_valid(active_camp_scene) and active_camp_scene.point_hits_wall(position)

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment: Vector2 = finish - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start)
	var progress: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * progress)

func _camp_interaction_position(target: String) -> Vector2:
	if target == "gate":
		return _camp_gate_position() + Vector2(0.0, -16.0)
	if target.begins_with("plot_"):
		return _plot_anchor(target)
	if camp_structure_definitions.has(target):
		return (camp_structure_definitions[target] as StructureDefinition).anchor
	return Vector2.ZERO

func _camp_hit_rect_world(structure_id: String) -> Rect2:
	if structure_id.begins_with("plot_"):
		var authored_polygon: PackedVector2Array = _plot_interaction_polygon_world(structure_id)
		if authored_polygon.size() >= 3:
			var authored_bounds := Rect2(authored_polygon[0], Vector2.ZERO)
			for point: Vector2 in authored_polygon:
				authored_bounds = authored_bounds.expand(point)
			return authored_bounds
		push_error("Authored plot '%s' has no interaction polygon" % structure_id)
		return Rect2()
	if camp_structure_definitions.has(structure_id):
		var definition: StructureDefinition = camp_structure_definitions[structure_id]
		var points: PackedVector2Array = definition.world_interaction_polygon()
		if not points.is_empty():
			var bounds := Rect2(points[0], Vector2.ZERO)
			for point: Vector2 in points:
				bounds = bounds.expand(point)
			return bounds
	push_error("Authored structure '%s' has no interaction polygon" % structure_id)
	return Rect2()

func _nearest_camp_interaction() -> String:
	var nearest: String = ""
	var nearest_distance: float = CAMP_INTERACTION_RADIUS
	for target: String in camp_structure_definitions:
		if not _is_constructed(target):
			continue
		var definition: StructureDefinition = camp_structure_definitions[target]
		var distance: float = camp_player_position.distance_to(definition.anchor)
		if definition.can_interact(camp_player_position) and distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	for plot_id: String in _revealed_plot_ids():
		if not _is_plot_visible(plot_id):
			continue
		var plot_distance: float = camp_player_position.distance_to(_plot_anchor(plot_id))
		var authored_polygon: PackedVector2Array = _plot_interaction_polygon_world(plot_id)
		var plot_in_range: bool = Geometry2D.is_point_in_polygon(camp_player_position, authored_polygon) if authored_polygon.size() >= 3 else plot_distance < CAMP_INTERACTION_RADIUS
		if plot_in_range and plot_distance < nearest_distance:
			nearest_distance = plot_distance
			nearest = plot_id
	var gate_distance: float = camp_player_position.distance_to(_camp_interaction_position("gate"))
	if camp_player_position.y >= _camp_gate_position().y - 34.0 and gate_distance < nearest_distance:
		nearest = "gate"
	return nearest

func _camp_interaction_text(target: String) -> String:
	if target.begins_with("plot_") and _is_plot_visible(target):
		return "PLAN NEW BUILDING"
	match target:
		"veterans_hall": return "ENTER VETERANS' HALL"
		"armory": return "ENTER ARMORY"
		"quartermaster": return "VISIT QUARTERMASTER"
		"blacksmith": return "ENTER BLACKSMITH"
		"training": return "ENTER TRAINING YARD"
		"campfire": return "PREPARE EXPEDITION"
		"gate": return "CROSS GATE TO BEGIN"
	return "WALK THE CAMP"

func _update_camp_interact_button() -> void:
	if not is_instance_valid(camp_interact_button):
		return
	# A suspended PWA can retain the seamless field-camera arrival while the
	# camp interaction target is no longer on screen. Keep the contextual
	# button useful as a one-tap recovery instead of leaving a disabled
	# "WALK THE CAMP" control that appears to be a deadlock.
	var recenter_arrival: bool = camp_uses_field_camera and camp_interaction_target.is_empty()
	camp_interact_button.text = "RETURN TO CAMP" if recenter_arrival else _camp_interaction_text(camp_interaction_target)
	camp_interact_button.disabled = (camp_interaction_target.is_empty() or camp_interaction_target == "gate") and not recenter_arrival

func _interact_with_camp_target() -> void:
	if camp_uses_field_camera and camp_interaction_target.is_empty():
		_recover_camp_arrival()
		return
	if camp_interaction_target.begins_with("plot_"):
		_show_construction_menu(camp_interaction_target)
		return
	match camp_interaction_target:
		"veterans_hall": _show_hall_detail()
		"armory", "quartermaster", "blacksmith", "training":
			_show_building_detail(camp_interaction_target)
		"campfire": _show_weapon_picker()


func _on_authored_camp_structure_tapped(structure_id: String) -> void:
	if screen != Screen.CAMP or not _camp_hub_active():
		return
	# Distant taps never open camp services. The same authored interaction shape
	# used by the one-button interaction flow determines proximity.
	if structure_id != _nearest_camp_interaction():
		return
	camp_interaction_target = structure_id
	_interact_with_camp_target()


func _on_authored_camp_structure_hovered(structure_id: String, hovered: bool) -> void:
	if screen != Screen.CAMP or structure_id != _nearest_camp_interaction():
		return
	camp_highlighted_structure = structure_id if hovered else ""

func _begin_expedition_from_gate() -> void:
	if screen != Screen.CAMP or _gate_confirmation_open():
		return
	_reset_movement_input()
	camp_player_position.y = _camp_gate_position().y - 1.0
	if _gate_confirmations_enabled():
		_show_gate_confirmation(true)
	else:
		_confirm_begin_expedition(null)

func _confirm_begin_expedition(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	if not save.active_run.is_empty():
		_resume_run()
		return
	_show_arsenal_screen(true)

func _gate_confirmation_open() -> bool:
	return is_instance_valid(ui_root) and ui_root.get_node_or_null("GateConfirmationOverlay") != null

func _gate_confirmations_enabled() -> bool:
	return bool(save.get("settings", {}).get("gate_confirmations", true))

func _show_gate_confirmation(departing: bool) -> void:
	if not is_instance_valid(ui_root) or _gate_confirmation_open():
		return
	_reset_movement_input()
	if not departing:
		run_paused = true
	var overlay := GateConfirmationScene.instantiate() as Control
	ui_controller.mount_modal(overlay)
	var heading: String = "READY FOR BATTLE?" if departing else "FINISH THIS RUN?"
	var detail: String = "Cross into Blackthorn Moor and begin the expedition?" if departing else "Return to camp, bank your findings and end this expedition?"
	overlay.call("configure", heading, detail, "NO", "YES")
	overlay.connect("cancelled", _cancel_gate_confirmation.bind(overlay, departing))
	if departing:
		overlay.connect("confirmed", _confirm_begin_expedition.bind(overlay))
	else:
		overlay.connect("confirmed", _confirm_finish_run.bind(overlay))

func _cancel_gate_confirmation(overlay: Control, departing: bool) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_reset_movement_input()
	var gate: Vector2 = _camp_gate_position()
	if departing:
		camp_player_position = Vector2(gate.x, gate.y - 2.0)
	else:
		player_position = Vector2(gate.x, gate.y + 2.0)
		run_paused = false

func _confirm_finish_run(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_reset_movement_input()
	_finish_run(false, true)
