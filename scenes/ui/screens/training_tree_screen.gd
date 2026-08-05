class_name AshenTrainingTreeScreen
extends Control

signal closed
signal profile_changed

const Content = preload("res://src/content/training_grounds_content.gd")
const TrainingGrounds = preload("res://src/services/training_grounds_service.gd")

var profile: Dictionary = {}
var pending_profile: Dictionary = {}
var service: TrainingGroundsService
@onready var viewport: Control = $TreeViewport
@onready var canvas: Control = $TreeViewport/TrainingTreeCanvas
var node_buttons: Dictionary = {}
var selected_node_id: String = ""
var refund_confirmation_pending: bool = false
var zoom: float = 0.52
var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var pan_start: Vector2 = Vector2.ZERO
var pinch_distance: float = 0.0
var pinch_center: Vector2 = Vector2.ZERO
var pinch_start_zoom: float = 0.52
var pinch_start_pan: Vector2 = Vector2.ZERO
var touch_points: Dictionary = {}
var initial_focus_applied: bool = false

@onready var points_label: Label = $Header/HeaderContent/PointsLabel
@onready var xp_label: Label = $Header/HeaderContent/XPLabel
@onready var tier_label: Label = $Header/HeaderContent/TierLabel
@onready var details_panel: PanelContainer = $DetailsPanel
@onready var details_title: Label = $DetailsPanel/DetailsRoot/DetailsTitle
@onready var details_description: Label = $DetailsPanel/DetailsRoot/DetailsDescription
@onready var details_stats: Label = $DetailsPanel/DetailsRoot/DetailsStats
@onready var details_action: Button = $DetailsPanel/DetailsRoot/DetailsAction
@onready var close_button: Button = $CloseButton

func _ready() -> void:
	close_button.pressed.connect(func() -> void: closed.emit())
	details_action.pressed.connect(_activate_selected)
	$BranchVanguard.pressed.connect(_center_school.bind("vanguard"))
	$BranchRanger.pressed.connect(_center_school.bind("ranger"))
	$BranchShadow.pressed.connect(_center_school.bind("shadow"))
	$BranchArcanist.pressed.connect(_center_school.bind("arcanist"))
	viewport.gui_input.connect(_on_viewport_input)
	details_panel.visible = false
	if not pending_profile.is_empty():
		var deferred_profile: Dictionary = pending_profile
		pending_profile.clear()
		_bind_profile_now(deferred_profile)

func bind_profile(target_profile: Dictionary) -> void:
	if not is_node_ready():
		pending_profile = target_profile
		return
	_bind_profile_now(target_profile)

func _bind_profile_now(target_profile: Dictionary) -> void:
	profile = target_profile
	service = TrainingGrounds.new(profile)
	_build_graph()
	_update_header()
	if not initial_focus_applied:
		_center_node("company_crest", 0.52)
		initial_focus_applied = true

## The screen is authored at the 390x844 reference size, but the parent can
## provide the device's top safe-area inset without replacing any authored
## positions.  Only the navigation chrome moves; the tree remains a single
## pannable canvas.
func apply_safe_area(top_inset: float) -> void:
	var inset: float = clampf(top_inset, 0.0, 59.0)
	$Header.position.y = 12.0 + inset
	$BranchVanguard.position.y = 94.0 + inset
	$BranchRanger.position.y = 94.0 + inset
	$BranchShadow.position.y = 94.0 + inset
	$BranchArcanist.position.y = 94.0 + inset
	$TreeViewport.position.y = 132.0 + inset
	$TreeViewport.size.y = maxf(390.0, 508.0 - inset)

func _build_graph() -> void:
	node_buttons.clear()
	var nodes: Dictionary = Content.all_nodes()
	for child: Node in canvas.get_children():
		var button := child as AshenTrainingNodeCard
		if button == null:
			continue
		var node_id: String = button.node_id
		if not nodes.has(node_id):
			push_error("Authored Training Grounds card '%s' has invalid node ID '%s'." % [button.name, node_id])
			continue
		button.configure(node_id, nodes[node_id], _visual_state(node_id))
		# Locked nodes remain selectable so the details sheet can explain their
		# prerequisites and Training Grounds tier. Purchased nodes must also stay
		# interactive so a player can open the refund/cascade confirmation.
		button.disabled = false
		button.pressed.connect(_select_node.bind(node_id))
		node_buttons[node_id] = button
	if node_buttons.size() != nodes.size():
		push_error("Authored Training Grounds canvas has %d cards; expected %d." % [node_buttons.size(), nodes.size()])
	_sync_canvas_transform()

func _visual_state(node_id: String) -> String:
	if node_id == selected_node_id:
		return "selected"
	if service.node_rank(node_id) > 0:
		return "purchased"
	return service.node_state(node_id)

func _graph_point(definition_position: Vector2) -> Vector2:
	return definition_position + Vector2(1100.0, 1100.0)

func _node_text(node_id: String, definition: Dictionary) -> String:
	var state: String = "✓" if service.node_rank(node_id) > 0 else ("◆" if _node_available(node_id) else "·")
	var type_marker: String = {
		"weapon": "⚔", "technique": "✦", "doctrine": "◇", "keystone": "♜", "mastery": "✹", "major": "◆"
	}.get(String(definition.node_type), "•")
	return "%s %s\n%s" % [type_marker, state, String(definition.name).to_upper()]

func _node_available(node_id: String) -> bool:
	if service == null:
		return false
	return bool(service.can_purchase(node_id).get("ok", false))

func _select_node(node_id: String) -> void:
	var previous_selection: String = selected_node_id
	if previous_selection != node_id:
		refund_confirmation_pending = false
	selected_node_id = node_id
	var definition: Dictionary = Content.all_nodes()[node_id]
	var state: String = "PURCHASED" if service.node_rank(node_id) > 0 else ("AVAILABLE" if _node_available(node_id) else "LOCKED")
	details_title.text = "%s  ·  %s" % [String(definition.name).to_upper(), state]
	details_description.text = String(definition.description)
	var detail_lines: Array[String] = ["%s NODE  ·  TRAINING TIER %d" % [String(definition.node_type).to_upper(), int(definition.training_ground_tier)]]
	if int(definition.cost) > 0:
		detail_lines.append("COST  %d TRAINING POINTS" % int(definition.cost))
	var unlock_id: String = String(definition.get("unlock_id", ""))
	if not unlock_id.is_empty() and unlock_id != node_id:
		detail_lines.append("UNLOCKS  %s" % unlock_id.replace("_", " ").to_upper())
	var modifiers: Dictionary = Dictionary(definition.get("stat_modifiers", {}))
	for stat: String in modifiers:
		detail_lines.append("%s  %s" % [_pretty_stat(stat), _format_modifier(float(modifiers[stat]))])
	if not Array(definition.get("prerequisite_ids", [])).is_empty():
		var requirements: Array[String] = []
		for required_value: Variant in definition.prerequisite_ids:
			requirements.append(String(Content.all_nodes().get(String(required_value), {}).get("name", required_value)))
		detail_lines.append("REQUIRES  " + ", ".join(requirements))
	details_stats.text = "\n".join(detail_lines)
	var refund_preview: Dictionary = service.refund_preview(node_id) if service.node_rank(node_id) > 0 else {}
	if service.node_rank(node_id) > 0 and refund_preview.get("node_ids", []).size() > 1:
		var dependant_names: Array[String] = []
		for dependant_id_value: Variant in Array(refund_preview.get("node_ids", [])).slice(1):
			var dependant_id: String = String(dependant_id_value)
			dependant_names.append(String(Content.all_nodes().get(dependant_id, {}).get("name", dependant_id)))
		detail_lines.append("CASCADE REFUND  %d DEPENDANTS" % dependant_names.size())
		detail_lines.append("ALSO REFUNDS  " + ", ".join(dependant_names))
		details_stats.text = "\n".join(detail_lines)
	var purchased: bool = service.node_rank(node_id) > 0
	var can_refund: bool = purchased and bool(refund_preview.get("ok", false))
	details_action.text = ("CONFIRM CASCADE REFUND" if refund_confirmation_pending else "REFUND NODE") if can_refund else ("PERMANENT NODE" if purchased else "PURCHASE NODE")
	details_action.disabled = (not can_refund) if purchased else not _node_available(node_id)
	details_panel.visible = true
	for changed_id: String in [previous_selection, selected_node_id]:
		if node_buttons.has(changed_id):
			var changed_button := node_buttons[changed_id] as AshenTrainingNodeCard
			changed_button.set_state(_visual_state(changed_id))

func _pretty_stat(stat: String) -> String:
	return stat.replace("_", " ").to_upper()

func _format_modifier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % roundi(value)
	return "%+.2f" % value

func _activate_selected() -> void:
	if selected_node_id.is_empty() or service == null:
		return
	if service.node_rank(selected_node_id) > 0:
		var preview: Dictionary = service.refund_preview(selected_node_id)
		if not bool(preview.get("ok", false)):
			return
		if preview.get("node_ids", []).size() > 1 and not refund_confirmation_pending:
			refund_confirmation_pending = true
			_select_node(selected_node_id)
			return
		service.refund(selected_node_id, true)
		refund_confirmation_pending = false
	else:
		service.purchase(selected_node_id)
		refund_confirmation_pending = false
	profile_changed.emit()
	_update_header()
	_build_graph()
	_select_node(selected_node_id)

func _update_header() -> void:
	if service == null:
		return
	points_label.text = "%d TRAINING POINTS" % int(profile.get("training_points", 0))
	xp_label.text = "%d / 100 XP" % int(profile.get("training_xp", 0))
	tier_label.text = "TIER %d" % int(profile.get("training_level", 0))

func _center_school(school: String) -> void:
	var best: String = ""
	for node_id: String in Content.all_nodes():
		if String(Content.all_nodes()[node_id].get("school", "")) == school:
			best = node_id
			break
	if best.is_empty():
		return
	_center_node(best, 0.72)

func _center_node(node_id: String, target_zoom: float) -> void:
	if not node_buttons.has(node_id):
		return
	zoom = clampf(target_zoom, 0.45, 1.35)
	var target_button := node_buttons[node_id] as Control
	var target: Vector2 = target_button.position + target_button.size * 0.5
	pan = _viewport_center() - _canvas_origin() - target * zoom
	_sync_canvas_transform()

func _viewport_center() -> Vector2:
	return viewport.size * 0.5

func _canvas_origin() -> Vector2:
	return Vector2(195.0, 286.0)

func _sync_canvas_transform() -> void:
	if canvas == null:
		return
	canvas.scale = Vector2(zoom, zoom)
	canvas.position = _canvas_origin() + pan

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start = event.position
			pan_start = pan
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		pan = pan_start + event.position - drag_start
		_sync_canvas_transform()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		zoom = clampf(zoom + 0.06, 0.45, 1.35)
		_sync_canvas_transform()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		zoom = clampf(zoom - 0.06, 0.45, 1.35)
		_sync_canvas_transform()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			if touch_points.size() == 1:
				dragging = true
				drag_start = event.position
				pan_start = pan
			elif touch_points.size() == 2:
				var points: Array = touch_points.values()
				pinch_distance = maxf(1.0, Vector2(points[0]).distance_to(Vector2(points[1])))
				pinch_center = (Vector2(points[0]) + Vector2(points[1])) * 0.5
				pinch_start_zoom = zoom
				pinch_start_pan = pan
				dragging = false
		else:
			touch_points.erase(event.index)
			if touch_points.size() == 1:
				var remaining: Vector2 = Vector2(touch_points.values()[0])
				dragging = true
				drag_start = remaining
				pan_start = pan
			else:
				dragging = false
			pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() >= 2 and pinch_distance > 0.0:
			var points: Array = touch_points.values()
			var current_distance: float = maxf(1.0, Vector2(points[0]).distance_to(Vector2(points[1])))
			var center: Vector2 = (Vector2(points[0]) + Vector2(points[1])) * 0.5
			var world_at_start: Vector2 = (pinch_center - _canvas_origin() - pinch_start_pan) / pinch_start_zoom
			zoom = clampf(pinch_start_zoom * current_distance / pinch_distance, 0.45, 1.35)
			pan = center - _canvas_origin() - world_at_start * zoom
			_sync_canvas_transform()
		elif touch_points.size() == 1 and dragging:
			pan = pan_start + event.position - drag_start
			_sync_canvas_transform()
