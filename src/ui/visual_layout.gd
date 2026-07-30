@tool
class_name AshenVisualLayout
extends Control

## Screen-space authoring guide for menus and modal overlays.
##
## These controls are intentionally plain Control nodes rather than live UI
## widgets.  Designers can move and resize them in the Godot 2D viewport;
## runtime menus read the same rectangles and populate them with real labels,
## buttons, and state.  The scene is reference-authored at 390x844 and is
## scaled uniformly for other portrait widths.

@export var reference_viewport: Vector2 = Vector2(390.0, 844.0)
@export var safe_area_preview: float = 34.0
@export var show_guides: bool = true
@export var show_preview_art: bool = true

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	if node == null:
		return fallback
	return Rect2(node.global_position, node.size)

func _ready() -> void:
	if Engine.is_editor_hint():
		size = reference_viewport
		_sync_preview_visibility()
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_preview_visibility()
		queue_redraw()

func _sync_preview_visibility() -> void:
	for child_name: String in ["CampArtwork", "TitleCrestPreview", "ResourceRailPreview", "ActionButtonPreview", "SettingsCogPreview"]:
		var child := get_node_or_null(child_name) as CanvasItem
		if child != null:
			child.visible = show_preview_art

func _draw() -> void:
	# The authoring scene is also a real presentation preview.  CampLayout and
	# the Sprite2D children in the scene provide the same imported pixels used by
	# the game; this dark ground simply gives those assets a readable surround.
	draw_rect(Rect2(Vector2.ZERO, reference_viewport), Color("18231c"), true)
	draw_rect(Rect2(0.0, safe_area_preview, reference_viewport.x, reference_viewport.y - safe_area_preview), Color("202a21"), true)
	if not show_guides:
		return
	var viewport_rect := Rect2(Vector2.ZERO, reference_viewport)
	draw_rect(viewport_rect, Color("111518"), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(reference_viewport.x, safe_area_preview)), Color(0.0, 0.0, 0.0, 0.96), true)
	draw_rect(viewport_rect, Color("bca77a"), false, 2.0)
	_draw_guide("CAMP / HALL", "Camp/HallPanel", Color("d38a36"))
	_draw_guide("CAMP / CONSTRUCTION", "Camp/ConstructionPanel", Color("78aaa2"))
	_draw_guide("CAMP / BUILDING", "Camp/BuildingDetailPanel", Color("78aaa2"))
	_draw_guide("CAMP / EXPEDITIONS", "Camp/ExpeditionsPanel", Color("d38a36"))
	_draw_guide("CAMP / EQUIPMENT", "Camp/EquipmentPanel", Color("78aaa2"))
	_draw_guide("RUN / LEVEL UP", "Run/LevelUpPanel", Color("d38a36"))
	_draw_guide("RUN / RELIC", "Run/RelicBox", Color("78aaa2"))
	_draw_guide("RESULTS", "Results/Panel", Color("d38a36"))
	_draw_guide("SETTINGS", "Settings/Panel", Color("e2d2ac"))
	_draw_guide("GATE CONFIRM", "Modal/GateConfirmation", Color("873f3e"))
	draw_string(ThemeDB.fallback_font, Vector2(8.0, reference_viewport.y - 10.0), "DRAG MENU NODES  ·  SAFE AREA PREVIEW: %.0f PX" % safe_area_preview, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("bca77a"))

func _draw_guide(label: String, node_path: NodePath, color: Color) -> void:
	var rect := rect_for(node_path)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(Rect2(rect.position, rect.size), Color(color, 0.10), true)
	draw_rect(Rect2(rect.position, rect.size), Color(color, 0.88), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 10, color)
