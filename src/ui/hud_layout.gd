@tool
class_name AshenHudLayout
extends Control

## Screen-space authoring guide for the live HUD. The game reads the Control
## nodes from this scene as reference rectangles, then binds real values and
## input handlers to the resulting runtime controls.

@export var reference_viewport: Vector2 = Vector2(390.0, 844.0)
@export var safe_area_preview: float = 34.0
@export var show_guides: bool = true
@export var show_preview_art: bool = true

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := _resolve_control(node_path)
	if node == null:
		return fallback
	# Return screen-space coordinates even for fields nested inside ResourceRail.
	# This is the same coordinate space used by the editor preview and by the
	# runtime HUD, so moving a nested field is never silently ignored.
	return Rect2(node.global_position, node.size)

func _resolve_control(node_path: NodePath) -> Control:
	var node := get_node_or_null(node_path) as Control
	if node != null:
		return node
	# The resource rail's authored fields live inside ResourceRail. Accepting
	# their short names keeps existing scene paths readable while still finding
	# the actual edited node.
	var path_text := String(node_path)
	if not path_text.contains("/"):
		return get_node_or_null(NodePath("ResourceRail/" + path_text)) as Control
	return null

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
	for child_name: String in ["PreviewResourceRail", "PreviewHealthIcon", "PreviewHealthBar", "PreviewSilverIcon", "PreviewProvisionsIcon", "PreviewKeyIcon", "PreviewTitleCrest", "PreviewActionButton", "PreviewSettingsCog", "PreviewLevelLabel", "PreviewHealthLabel", "PreviewSilverLabel", "PreviewProvisionsLabel", "PreviewKeyLabel"]:
		var child := get_node_or_null(child_name) as CanvasItem
		if child != null:
			child.visible = show_preview_art
	if not show_preview_art:
		return
	# The preview sprites are mirrors of the authored Control nodes below them,
	# never a second set of coordinates. Moving a field in the scene therefore
	# moves the visible imported art and the runtime ResourceRail together.
	_sync_preview_rect("PreviewResourceRail", "ResourceRail", Rect2(0.0, 0.0, 390.0, 52.0))
	_sync_preview_rect("PreviewLevelLabel", "HeroLevelCell", Rect2(18.0, 13.0, 37.0, 40.0))
	_sync_preview_rect("PreviewHealthIcon", "ResourceRail/HealthIcon", Rect2(64.0, 17.0, 16.0, 16.0))
	_sync_preview_rect("PreviewHealthBar", "ResourceRail/HealthBar", Rect2(83.0, 12.0, 89.0, 27.0))
	_sync_preview_rect("PreviewHealthLabel", "ResourceRail/HealthValueLabel", Rect2(83.0, 14.0, 89.0, 23.0))
	_sync_cell_preview("PreviewSilverIcon", "ResourceRail/SilverCell", true, Rect2(188.0, 14.0, 39.0, 22.0))
	_sync_cell_preview("PreviewSilverLabel", "ResourceRail/SilverCell", false, Rect2(188.0, 14.0, 39.0, 22.0))
	_sync_cell_preview("PreviewProvisionsIcon", "ResourceRail/ProvisionsCell", true, Rect2(235.0, 14.0, 45.0, 22.0))
	_sync_cell_preview("PreviewProvisionsLabel", "ResourceRail/ProvisionsCell", false, Rect2(235.0, 14.0, 45.0, 22.0))
	_sync_cell_preview("PreviewKeyIcon", "ResourceRail/KeyCell", true, Rect2(289.0, 14.0, 49.0, 22.0))
	_sync_cell_preview("PreviewKeyLabel", "ResourceRail/KeyCell", false, Rect2(289.0, 14.0, 49.0, 22.0))
	_sync_preview_rect("PreviewActionButton", "CampInteractButton", Rect2(224.0, 718.0, 150.0, 52.0))
	_sync_preview_rect("PreviewSettingsCog", "SettingsCogButton", Rect2(334.0, 786.0, 48.0, 48.0))

func _sync_preview_rect(preview_name: String, authored_path: NodePath, fallback: Rect2) -> void:
	var preview := get_node_or_null(preview_name) as Control
	if preview == null:
		return
	var authored_node := _resolve_control(authored_path)
	var authored := rect_for(authored_path, fallback)
	preview.position = authored.position
	preview.size = authored.size
	if authored_node != null:
		preview.scale = authored_node.scale

func _sync_cell_preview(preview_name: String, authored_path: NodePath, icon: bool, fallback: Rect2) -> void:
	var preview := get_node_or_null(preview_name) as Control
	if preview == null:
		return
	var cell := rect_for(authored_path, fallback)
	if icon:
		preview.position = cell.position + Vector2(0.0, 3.0)
		preview.size = Vector2(minf(15.0, cell.size.x), minf(15.0, cell.size.y))
	else:
		preview.position = cell.position + Vector2(16.0, 0.0)
		preview.size = Vector2(maxf(1.0, cell.size.x - 16.0), cell.size.y)
	var authored_node := _resolve_control(authored_path)
	if authored_node != null:
		preview.scale = authored_node.scale

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, reference_viewport), Color("111518"), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(reference_viewport.x, safe_area_preview)), Color(0.0, 0.0, 0.0, 0.96), true)
	if not show_guides:
		return
	var viewport_rect := Rect2(Vector2.ZERO, reference_viewport)
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
