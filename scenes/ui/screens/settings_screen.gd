class_name AshenSettingsScreen
extends Control

## The Settings screen is an authored scene.  Runtime code supplies values and
## connects the existing save callbacks; it does not rebuild this layout.

signal close_requested

@onready var modal: AshenModal = $AshenModal
@onready var safe_area_band: ColorRect = $SafeAreaTopBand
@onready var music_slider: HSlider = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/MusicRow/Slider
@onready var sfx_slider: HSlider = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/SfxRow/Slider
@onready var effects_slider: HSlider = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/EffectsRow/Slider
@onready var screen_shake_toggle: TextureButton = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/ScreenShakeRow/Toggle
@onready var left_handed_toggle: TextureButton = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/LeftHandedRow/Toggle
@onready var collision_debug_toggle: TextureButton = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/CollisionDebugRow/Toggle
@onready var gate_confirmations_toggle: TextureButton = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/GateConfirmationsRow/Toggle
@onready var save_text: TextEdit = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/SaveText
@onready var status_label: Label = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/SettingsStatus
@onready var back_button: Button = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/BackButton
@onready var export_button: Button = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/BackupButtons/ExportButton
@onready var import_button: Button = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/BackupButtons/ImportButton
@onready var reload_button: Button = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/ReloadAppButton
@onready var reset_button: Button = $AshenModal/SafeMargin/Frame/ContentMargin/Content/ContentScroll/ScrollContent/ResetSaveButton

func _ready() -> void:
	modal.closed.connect(func() -> void: close_requested.emit())
	back_button.pressed.connect(func() -> void: close_requested.emit())
	# These are authored as rows, but the settings controller binds directly to
	# the underlying controls.  No duplicate settings model is kept here.
	set_process(true)

func apply_safe_area(top: float) -> void:
	modal.safe_area_top = top
	safe_area_band.offset_bottom = maxf(0.0, top)

func set_values(settings: Dictionary, gate_confirmations: bool) -> void:
	music_slider.set_value_no_signal(float(settings.get("music", 0.75)))
	sfx_slider.set_value_no_signal(float(settings.get("sfx", 0.8)))
	effects_slider.set_value_no_signal(float(settings.get("effect_density", 0.85)))
	_set_toggle(screen_shake_toggle, bool(settings.get("screen_shake", true)))
	_set_toggle(left_handed_toggle, bool(settings.get("left_handed", false)))
	_set_toggle(collision_debug_toggle, bool(settings.get("collision_debug", false)))
	_set_toggle(gate_confirmations_toggle, gate_confirmations)

func set_status(value: String) -> void:
	status_label.text = value

func _set_toggle(toggle: TextureButton, value: bool) -> void:
	toggle.set_pressed_no_signal(value)
