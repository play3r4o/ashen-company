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
var _authored_safe_area_y: float = NAN

func _ready() -> void:
	_capture_authored_geometry()
	if Engine.is_editor_hint():
		size = reference_viewport
		set_mode(editor_mode)
	else:
		set_mode(runtime_mode)

func configure(mode: String, safe_area_top: float) -> void:
	runtime_mode = mode
	size = reference_viewport
	_capture_authored_geometry()
	var safe_group := _role(&"SafeAreaTop") as Control
	if safe_group != null:
		safe_group.position.y = _authored_safe_area_y + safe_area_top
	set_mode(mode)

func set_mode(mode: String) -> void:
	runtime_mode = mode
	var camp_group := _role(&"Camp") as CanvasItem
	var run_top := _role(&"RunTop") as CanvasItem
	var run_actions := _role(&"RunActions") as CanvasItem
	var camp_crest := _role(&"CampTitleCrest") as CanvasItem
	var settings := _role(&"SettingsCogButton") as CanvasItem
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
	# The pause panel is an explicit state overlay.  It must not be inferred
	# from the HUD mode: entering a run is not the same thing as pausing it.
	# Always reset it when the HUD is mounted, then let the run controller bind
	# the actual paused state.
	set_paused(false)

func set_paused(paused: bool) -> void:
	var pause_overlay := _role(&"PauseLabel") as CanvasItem
	if pause_overlay != null:
		pause_overlay.visible = paused

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
	var level_label := _role(&"LevelValueLabel") as Label
	var bar := _role(&"HealthBar") as ProgressBar
	var health_label := _role(&"HealthValueLabel") as Label
	var silver_label := _role(&"SilverValueLabel") as Label
	var provisions_label := _role(&"ProvisionsValueLabel") as Label
	var key_label := _role(&"KeyValueLabel") as Label
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

func rect_for(node_path: NodePath) -> Rect2:
	var node := get_node_or_null(node_path) as Control
	# Editor authors frequently reparent a visual while refining the HUD.  Keep
	# old tooling paths useful by resolving their final role name recursively.
	if node == null:
		var names := String(node_path).split("/", false)
		if not names.is_empty():
			node = _role(StringName(names[names.size() - 1])) as Control
	if node == null:
		push_warning("HUD has no Control with role '%s'; its optional layout rectangle is unavailable." % node_path)
		return Rect2()
	return Rect2(node.global_position, node.size * node.scale)


func _capture_authored_geometry() -> void:
	if not is_nan(_authored_safe_area_y):
		return
	var safe_group := _role(&"SafeAreaTop") as Control
	_authored_safe_area_y = safe_group.position.y if safe_group != null else 0.0


func _role(role: StringName) -> Node:
	return AshenSceneBindings.optional(self, role)
