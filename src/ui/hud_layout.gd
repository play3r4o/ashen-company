@tool
class_name AshenHudLayout
extends Control

## Screen-space authoring guide for the live HUD. The game reads the Control
## nodes from this scene as reference rectangles, then binds real values and
## input handlers to the resulting runtime controls.

@export var reference_viewport: Vector2 = Vector2(390.0, 844.0)
@export var safe_area_preview: float = 34.0
@export var show_guides: bool = true

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	if node == null:
		return fallback
	return Rect2(node.position, node.size)

func _ready() -> void:
	if Engine.is_editor_hint():
		size = reference_viewport
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not show_guides:
		return
	var viewport_rect := Rect2(Vector2.ZERO, reference_viewport)
	draw_rect(viewport_rect, Color("111518"), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(reference_viewport.x, safe_area_preview)), Color(0.0, 0.0, 0.0, 0.96), true)
	draw_rect(viewport_rect, Color("bca77a"), false, 2.0)
	_draw_guide("HUD / RESOURCE RAIL", "ResourceRail", Color("d38a36"))
	_draw_guide("LOCATION CREST", "CampTitleCrest", Color("78aaa2"))
	_draw_guide("SETTINGS", "SettingsCogButton", Color("e2d2ac"))
	_draw_guide("CAMP ACTION", "CampInteractButton", Color("713f45"))
	_draw_guide("RUN STATUS", "Run/HudLabel", Color("78aaa2"))
	_draw_guide("BOSS STATUS", "Run/BossLabel", Color("873f3e"))
	_draw_guide("OBJECTIVE", "Run/ObjectiveLabel", Color("d38a36"))
	_draw_guide("PAUSE", "Run/PauseButton", Color("596268"))
	_draw_guide("GUARD STEP", "Run/GuardStepButton", Color("596268"))
	_draw_guide("SEARCH", "Run/ExpeditionInteractButton", Color("4d5b55"))
	draw_string(ThemeDB.fallback_font, Vector2(8.0, reference_viewport.y - 10.0), "DRAG HUD NODES  ·  SAFE AREA PREVIEW: %.0f PX" % safe_area_preview, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("bca77a"))

func _draw_guide(label: String, node_path: NodePath, color: Color) -> void:
	var rect := rect_for(node_path)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Color(color, 0.10), true)
	draw_rect(rect, Color(color, 0.88), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 10, color)
