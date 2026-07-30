@tool
class_name AshenHudLayout
extends Control

## The live HUD scene. Every visible child in hud_layout.tscn is the actual
## runtime node; there are no editor-only mirror or preview nodes.

@export var reference_viewport: Vector2 = Vector2(390.0, 844.0)
@export var safe_area_preview: float = 34.0
@export var show_guides: bool = false
@export_enum("camp", "run") var editor_mode: String = "camp":
	set(value):
		editor_mode = value
		if is_inside_tree():
			set_mode(value)

var runtime_mode: String = "camp"

func _ready() -> void:
	if Engine.is_editor_hint():
		size = reference_viewport
		set_mode(editor_mode)
	else:
		set_mode(runtime_mode)
	queue_redraw()

func configure(mode: String, safe_area_top: float) -> void:
	runtime_mode = mode
	size = reference_viewport
	var safe_group := get_node_or_null("SafeAreaTop") as Control
	if safe_group != null:
		safe_group.position.y = safe_area_top
	set_mode(mode)

func set_mode(mode: String) -> void:
	runtime_mode = mode
	var camp_group := get_node_or_null("Camp") as CanvasItem
	var run_top := get_node_or_null("SafeAreaTop/RunTop") as CanvasItem
	var run_actions := get_node_or_null("RunActions") as CanvasItem
	var camp_crest := get_node_or_null("SafeAreaTop/CampTitleCrest") as CanvasItem
	var settings := get_node_or_null("SafeAreaTop/SettingsCogButton") as CanvasItem
	if camp_group != null:
		camp_group.visible = mode == "camp"
	if run_top != null:
		run_top.visible = mode == "run"
	if run_actions != null:
		run_actions.visible = mode == "run"
	if camp_crest != null:
		camp_crest.visible = mode == "camp"
	if settings != null:
		settings.visible = mode == "camp"
	queue_redraw()

func bind_profile(profile: Dictionary, hero: Dictionary, max_health: float) -> void:
	_set_common_values(
		int(hero.get("level", 1)),
		max_health,
		max_health,
		int(profile.get("silver", 0)),
		int(profile.get("provisions", 0)),
		int(profile.get("biome_keys", {}).get("barrows_key", 0))
	)

func bind_run(level: int, hp: float, max_hp: float, silver: int, provisions: int, dread: int) -> void:
	_set_common_values(level, hp, max_hp, silver, provisions, dread)

func _set_common_values(level: int, hp: float, max_hp: float, silver: int, provisions: int, key_value: int) -> void:
	var level_label := get_node_or_null("SafeAreaTop/ResourceRail/HeroLevelCell/LevelValueLabel") as Label
	var bar := get_node_or_null("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	var health_label := get_node_or_null("SafeAreaTop/ResourceRail/HealthValueLabel") as Label
	var silver_label := get_node_or_null("SafeAreaTop/ResourceRail/SilverCell/SilverValueLabel") as Label
	var provisions_label := get_node_or_null("SafeAreaTop/ResourceRail/ProvisionsCell/ProvisionsValueLabel") as Label
	var key_label := get_node_or_null("SafeAreaTop/ResourceRail/KeyCell/KeyValueLabel") as Label
	if level_label != null:
		level_label.text = str(level)
	if bar != null:
		bar.max_value = maxf(1.0, max_hp)
		bar.value = clampf(hp, 0.0, max_hp)
	if health_label != null:
		health_label.text = "%d/%d" % [ceili(hp), ceili(max_hp)]
	if silver_label != null:
		silver_label.text = str(silver)
	if provisions_label != null:
		provisions_label.text = str(provisions)
	if key_label != null:
		key_label.text = str(key_value)

func rect_for(node_path: NodePath, fallback: Rect2 = Rect2()) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	if node == null:
		return fallback
	return Rect2(node.global_position, node.size * node.scale)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_guides:
		return
	draw_rect(Rect2(Vector2.ZERO, reference_viewport), Color("bca77a"), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(8.0, reference_viewport.y - 10.0), "LIVE HUD NODES - WHAT YOU MOVE IS WHAT THE GAME USES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("bca77a"))
