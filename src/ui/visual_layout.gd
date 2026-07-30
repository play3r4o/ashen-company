@tool
class_name AshenVisualLayout
extends Control

## Authoritative menu panel library. These PanelContainer nodes are duplicated
## directly into the running game. They are not guides or preview substitutes.

@export var reference_viewport: Vector2 = Vector2(390.0, 844.0)
@export var safe_area_preview: float = 34.0
@export var show_guides: bool = false
@export_enum("camp", "run", "results", "settings", "modal", "all") var editor_context: String = "settings":
	set(value):
		editor_context = value
		if is_inside_tree():
			_sync_editor_context()
@export var editor_panel_path: NodePath = NodePath("Settings/Panel"):
	set(value):
		editor_panel_path = value
		if is_inside_tree():
			_sync_editor_context()

func _ready() -> void:
	if Engine.is_editor_hint():
		size = reference_viewport
		_sync_editor_context()
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_editor_context()
		queue_redraw()

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	if node == null:
		return fallback
	return Rect2(node.global_position, node.size * node.scale)

func instantiate_panel(node_path: NodePath, fallback: Rect2, runtime_name: String = "AuthoredPanel") -> PanelContainer:
	var source := get_node_or_null(node_path) as PanelContainer
	if source == null:
		var fallback_panel := PanelContainer.new()
		fallback_panel.name = runtime_name
		fallback_panel.position = fallback.position
		fallback_panel.size = fallback.size
		return fallback_panel
	var panel := source.duplicate() as PanelContainer
	panel.name = runtime_name
	panel.visible = true
	return panel

func _sync_editor_context() -> void:
	if not Engine.is_editor_hint():
		return
	for group_name: String in ["Camp", "Run", "Results", "Settings", "Modal"]:
		var group := get_node_or_null(group_name) as CanvasItem
		if group != null:
			group.visible = editor_context == "all" or group_name.to_lower() == editor_context
	if editor_context == "all":
		return
	for panel_path: NodePath in _all_panel_paths():
		var panel := get_node_or_null(panel_path) as CanvasItem
		if panel != null:
			panel.visible = panel_path == editor_panel_path

func _all_panel_paths() -> Array[NodePath]:
	return [
		NodePath("Camp/HallPanel"), NodePath("Camp/ConstructionPanel"),
		NodePath("Camp/ConstructionDetailPanel"), NodePath("Camp/BuildingDetailPanel"),
		NodePath("Camp/ExpeditionsPanel"), NodePath("Camp/EquipmentPanel"),
		NodePath("Camp/ItemDetailPanel"), NodePath("Camp/MarchPanel"),
		NodePath("Camp/ClassTreePanel"), NodePath("Camp/DismantleBox"),
		NodePath("Run/LevelUpPanel"), NodePath("Run/RelicBox"),
		NodePath("Run/ContractsPanel"), NodePath("Results/Panel"),
		NodePath("Settings/Panel"), NodePath("Modal/GateConfirmation"),
		NodePath("Modal/ResetConfirmation")
	]

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2.ZERO, reference_viewport), Color("111518"), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(reference_viewport.x, safe_area_preview)), Color.BLACK, true)
	if show_guides:
		draw_rect(Rect2(Vector2.ZERO, reference_viewport), Color("bca77a"), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(8.0, reference_viewport.y - 10.0), "LIVE MENU PANEL - THIS NODE IS INSTANCED BY THE GAME", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("bca77a"))
