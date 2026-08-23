class_name AshenSettingsScreen
extends Control

## The Settings screen is an authored scene.  Runtime code supplies values and
## connects the existing save callbacks; it does not rebuild this layout.

signal close_requested
signal lighting_quality_changed(quality_id: String)

## These controls intentionally resolve by stable scene names instead of a
## long parent path.  That keeps the authored layout editable: moving a row,
## changing a container, or adding a scroll wrapper in Godot does not break the
## Settings runtime bindings.
@onready var modal: AshenModal = _find_control("AshenModal") as AshenModal
@onready var safe_area_band: ColorRect = _find_control("SafeAreaTopBand") as ColorRect
@onready var music_slider: HSlider = _find_row_control("MusicRow", "Slider") as HSlider
@onready var sfx_slider: HSlider = _find_row_control("SfxRow", "Slider") as HSlider
@onready var effects_slider: HSlider = _find_row_control("EffectsRow", "Slider") as HSlider
@onready var lighting_quality_option: OptionButton = _find_row_control("LightingQualityRow", "OptionButton") as OptionButton
@onready var screen_shake_toggle: TextureButton = _find_row_control("ScreenShakeRow", "Toggle") as TextureButton
@onready var left_handed_toggle: TextureButton = _find_row_control("LeftHandedRow", "Toggle") as TextureButton
@onready var collision_debug_toggle: TextureButton = _find_row_control("CollisionDebugRow", "Toggle") as TextureButton
@onready var gate_confirmations_toggle: TextureButton = _find_row_control("GateConfirmationsRow", "Toggle") as TextureButton
@onready var save_text: TextEdit = _find_control("SaveText") as TextEdit
@onready var status_label: Label = _find_control("SettingsStatus") as Label
@onready var back_button: Button = _find_control("BackButton") as Button
@onready var export_button: Button = _find_control("ExportButton") as Button
@onready var import_button: Button = _find_control("ImportButton") as Button
@onready var reload_button: Button = _find_control("ReloadAppButton") as Button
@onready var reset_button: Button = _find_control("ResetSaveButton") as Button

func _ready() -> void:
	if modal != null:
		modal.closed.connect(func() -> void: close_requested.emit())
	if back_button != null:
		back_button.pressed.connect(func() -> void: close_requested.emit())
	if lighting_quality_option != null:
		lighting_quality_option.item_selected.connect(_on_lighting_quality_selected)
	# These are authored as rows, but the settings controller binds directly to
	# the underlying controls.  No duplicate settings model is kept here.
	set_process(true)

func apply_safe_area(top: float) -> void:
	if modal != null:
		modal.safe_area_top = top
	if safe_area_band != null:
		safe_area_band.offset_bottom = maxf(0.0, top)

func set_values(settings: Dictionary, gate_confirmations: bool) -> void:
	if music_slider != null:
		music_slider.set_value_no_signal(float(settings.get("music", 0.75)))
	if sfx_slider != null:
		sfx_slider.set_value_no_signal(float(settings.get("sfx", 0.8)))
	if effects_slider != null:
		effects_slider.set_value_no_signal(float(settings.get("effect_density", 0.85)))
	if lighting_quality_option != null:
		_set_lighting_quality(String(settings.get("lighting_quality", "medium")))
	_set_toggle(screen_shake_toggle, bool(settings.get("screen_shake", true)))
	_set_toggle(left_handed_toggle, bool(settings.get("left_handed", false)))
	_set_toggle(collision_debug_toggle, bool(settings.get("collision_debug", false)))
	_set_toggle(gate_confirmations_toggle, gate_confirmations)

func set_status(value: String) -> void:
	if status_label != null:
		status_label.text = value

func _set_toggle(toggle: TextureButton, value: bool) -> void:
	if toggle != null:
		toggle.set_pressed_no_signal(value)

func _on_lighting_quality_selected(index: int) -> void:
	var ids: Array[String] = ["low", "medium", "high"]
	if index >= 0 and index < ids.size():
		lighting_quality_changed.emit(ids[index])

func _set_lighting_quality(quality_id: String) -> void:
	if lighting_quality_option == null:
		return
	var ids: Array[String] = ["low", "medium", "high"]
	var index: int = ids.find(quality_id.to_lower())
	lighting_quality_option.select(index if index >= 0 else 1)

func _find_control(control_name: String) -> Node:
	var node := find_child(control_name, true, false)
	if node == null:
		push_error("SettingsScreen is missing authored control '%s'. Keep the node name when moving it in Godot." % control_name)
	return node

func _find_row_control(row_name: String, child_name: String) -> Node:
	var row := find_child(row_name, true, false)
	if row == null:
		push_error("SettingsScreen is missing authored row '%s'. Keep the row name when moving it in Godot." % row_name)
		return null
	var node := row.find_child(child_name, true, false)
	if node == null:
		push_error("SettingsScreen row '%s' is missing authored control '%s'." % [row_name, child_name])
	return node
