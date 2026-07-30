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
@export_enum("menu", "camp", "run", "results", "settings") var preview_context: String = "menu"

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	if node == null:
		return fallback
	return Rect2(node.global_position, node.size)

func _ready() -> void:
	if Engine.is_editor_hint():
		size = reference_viewport
		_sync_preview_visibility()
		_sync_menu_preview()
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_preview_visibility()
		_sync_menu_preview()
		queue_redraw()

func _sync_preview_visibility() -> void:
	var camp_preview: bool = show_preview_art and preview_context == "camp"
	for child_name: String in ["CampArtwork", "TitleCrestPreview", "ResourceRailPreview", "ActionButtonPreview", "SettingsCogPreview"]:
		var child := get_node_or_null(child_name) as CanvasItem
		if child != null:
			child.visible = camp_preview
	var panel_preview := get_node_or_null("MenuPanelPreview") as TextureRect
	var panel_title := get_node_or_null("MenuPreviewTitle") as Label
	var panel_subtitle := get_node_or_null("MenuPreviewSubtitle") as Label
	var panel_body := get_node_or_null("MenuPreviewBody") as Label
	var panel_action := get_node_or_null("MenuPreviewAction") as TextureRect
	var panel_close := get_node_or_null("MenuPreviewClose") as Label
	var menu_preview: bool = show_preview_art and preview_context != "camp"
	if panel_preview != null:
		panel_preview.visible = menu_preview
	if panel_title != null:
		panel_title.visible = menu_preview
	if panel_subtitle != null:
		panel_subtitle.visible = menu_preview
	if panel_body != null:
		panel_body.visible = menu_preview
	if panel_action != null:
		panel_action.visible = menu_preview
	if panel_close != null:
		panel_close.visible = menu_preview

func _sync_menu_preview() -> void:
	var panel_preview := get_node_or_null("MenuPanelPreview") as TextureRect
	if panel_preview == null:
		return
	var path: NodePath
	var fallback := Rect2(22.0, 52.0, 346.0, 760.0)
	match preview_context:
		"run":
			path = "Run/LevelUpPanel"
			fallback = Rect2(12.0, 42.0, 366.0, 724.0)
		"results":
			path = "Results/Panel"
			fallback = Rect2(24.0, 150.0, 342.0, 500.0)
		"settings":
			path = "Settings/Panel"
		"menu":
			path = "Settings/Panel"
		_:
			path = "Settings/Panel"
	var panel_rect := rect_for(path, fallback)
	panel_preview.position = panel_rect.position
	panel_preview.size = panel_rect.size
	var title := get_node_or_null("MenuPreviewTitle") as Label
	var subtitle := get_node_or_null("MenuPreviewSubtitle") as Label
	var body := get_node_or_null("MenuPreviewBody") as Label
	var action := get_node_or_null("MenuPreviewAction") as TextureRect
	var close := get_node_or_null("MenuPreviewClose") as Label
	if title == null or subtitle == null or body == null or action == null or close == null:
		return
	title.position = panel_rect.position + Vector2(18.0, 24.0)
	title.size = Vector2(panel_rect.size.x - 36.0, 34.0)
	subtitle.position = panel_rect.position + Vector2(22.0, 63.0)
	subtitle.size = Vector2(panel_rect.size.x - 44.0, 24.0)
	body.position = panel_rect.position + Vector2(24.0, 108.0)
	body.size = Vector2(panel_rect.size.x - 48.0, panel_rect.size.y - 210.0)
	action.position = panel_rect.position + Vector2(20.0, panel_rect.size.y - 86.0)
	action.size = Vector2(panel_rect.size.x - 40.0, 54.0)
	close.position = panel_rect.position + Vector2(20.0, panel_rect.size.y - 38.0)
	close.size = Vector2(panel_rect.size.x - 40.0, 20.0)
	match preview_context:
		"run":
			title.text = "CHOOSE YOUR TRAINING"
			subtitle.text = "LEVEL 4  ·  PAUSED EXPEDITION"
			body.text = "Boar Spear\n+12% MELEE DAMAGE\n\nMeasured Breath\n+8% ATTACK SPEED\n\nIron Grip\n+10% ARMOR"
			action.texture = load("res://assets/generated/reference_v2/ui/action_button.png")
		"results":
			title.text = "THE COMPANY RETURNS"
			subtitle.text = "VETERAN RECORD  ·  71% RATING"
			body.text = "06:28 SURVIVED\n128 FOES  ·  2 ELITES\n\n+152 SILVER\n+9 PROVISIONS\n\nEQUIPMENT BANKED: 1"
		"settings", "menu":
			title.text = "SETTINGS & FIELD LEDGER"
			subtitle.text = "A clean, readable control panel"
			body.text = "MUSIC        ━━━━━━━━\nSOUND        ━━━━━━━━\nEFFECT DENSITY ━━━━━\n\nSCREEN SHAKE\nSAFE-AREA PREVIEW\nSAVE BACKUP"
		_:
			title.text = "ASHEN COMPANY"
			subtitle.text = "MENU PANEL PREVIEW"
			body.text = "Editable panel frame\nReal imported UI texture\nScene-authored placement"
	close.text = "BACK TO CAMP"

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
