class_name AshenModal
extends Control

signal closed

## Settings-only fixed-frame presentation. The standard modal keeps its legacy
## placement; the HQ Settings scene opts into the authored 354x724 frame.
@export var fixed_modal: bool = false
@export var fixed_modal_top: float = 102.0
@export var fixed_modal_bottom: float = 18.0

@export var safe_area_top: float = 0.0:
	set(value):
		safe_area_top = maxf(0.0, value)
		if is_inside_tree():
			_apply_safe_area()

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var frame: PanelContainer = $SafeMargin/Frame
@onready var close_button: TextureButton = $SafeMargin/Frame/Overlay/CloseButton

func _ready() -> void:
	_apply_safe_area()
	close_button.pressed.connect(func() -> void: closed.emit())

func _apply_safe_area() -> void:
	if safe_margin == null:
		return
	safe_margin.add_theme_constant_override("margin_left", 18)
	safe_margin.add_theme_constant_override("margin_right", 18)
	if fixed_modal:
		# Keep the authored frame below the persistent HUD and preserve its
		# 354x724 logical size on the 390x844 portrait viewport.
		safe_margin.add_theme_constant_override("margin_top", int(maxf(fixed_modal_top, 56.0 + safe_area_top)))
		safe_margin.add_theme_constant_override("margin_bottom", int(fixed_modal_bottom))
	else:
		safe_margin.add_theme_constant_override("margin_top", int(12.0 + safe_area_top))
		safe_margin.add_theme_constant_override("margin_bottom", 12)

func content_root() -> VBoxContainer:
	return $SafeMargin/Frame/ContentMargin/Content as VBoxContainer
