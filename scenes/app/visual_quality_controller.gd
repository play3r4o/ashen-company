class_name AshenVisualQualityController
extends Node

## Owns presentation-only quality switches. Gameplay state, collision, and
## combat limits are deliberately not changed here.

signal quality_changed(quality_id: String)

@export_group("Quality preset")
@export_enum("Low", "Medium", "High") var default_quality: String = "Medium":
	set(value):
		default_quality = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.05) var low_cosmetic_density: float = 0.5:
	set(value):
		low_cosmetic_density = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.05) var medium_cosmetic_density: float = 0.8:
	set(value):
		medium_cosmetic_density = value
		_refresh_active_quality()

@export_group("Ambient shader")
@export var ambient_material: ShaderMaterial:
	set(value):
		ambient_material = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.05) var medium_shader_strength: float = 0.55:
	set(value):
		medium_shader_strength = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.05) var high_shader_strength: float = 1.0:
	set(value):
		high_shader_strength = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.01) var medium_vignette_strength: float = 0.12:
	set(value):
		medium_vignette_strength = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.01) var high_vignette_strength: float = 0.24:
	set(value):
		high_vignette_strength = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.01) var medium_warmth_strength: float = 0.05:
	set(value):
		medium_warmth_strength = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.01) var high_warmth_strength: float = 0.10:
	set(value):
		high_warmth_strength = value
		_refresh_active_quality()

@export_group("Color grading")
@export_range(-1.0, 1.0, 0.01) var medium_brightness: float = 0.0:
	set(value):
		medium_brightness = value
		_refresh_active_quality()
@export_range(-1.0, 1.0, 0.01) var high_brightness: float = 0.0:
	set(value):
		high_brightness = value
		_refresh_active_quality()
@export_range(0.0, 2.0, 0.01) var medium_contrast: float = 1.0:
	set(value):
		medium_contrast = value
		_refresh_active_quality()
@export_range(0.0, 2.0, 0.01) var high_contrast: float = 1.0:
	set(value):
		high_contrast = value
		_refresh_active_quality()
@export_range(0.0, 2.0, 0.01) var medium_saturation: float = 1.0:
	set(value):
		medium_saturation = value
		_refresh_active_quality()
@export_range(0.0, 2.0, 0.01) var high_saturation: float = 1.0:
	set(value):
		high_saturation = value
		_refresh_active_quality()
@export_range(-180.0, 180.0, 1.0) var medium_hue_shift_degrees: float = 0.0:
	set(value):
		medium_hue_shift_degrees = value
		_refresh_active_quality()
@export_range(-180.0, 180.0, 1.0) var high_hue_shift_degrees: float = 0.0:
	set(value):
		high_hue_shift_degrees = value
		_refresh_active_quality()
@export_range(-2.0, 2.0, 0.05) var medium_exposure: float = 0.0:
	set(value):
		medium_exposure = value
		_refresh_active_quality()
@export_range(-2.0, 2.0, 0.05) var high_exposure: float = 0.0:
	set(value):
		high_exposure = value
		_refresh_active_quality()
@export_range(0.25, 4.0, 0.01) var medium_gamma: float = 1.0:
	set(value):
		medium_gamma = value
		_refresh_active_quality()
@export_range(0.25, 4.0, 0.01) var high_gamma: float = 1.0:
	set(value):
		high_gamma = value
		_refresh_active_quality()
@export_range(-1.0, 1.0, 0.01) var medium_temperature: float = 0.0:
	set(value):
		medium_temperature = value
		_refresh_active_quality()
@export_range(-1.0, 1.0, 0.01) var high_temperature: float = 0.0:
	set(value):
		high_temperature = value
		_refresh_active_quality()
@export_range(-1.0, 1.0, 0.01) var medium_tint: float = 0.0:
	set(value):
		medium_tint = value
		_refresh_active_quality()
@export_range(-1.0, 1.0, 0.01) var high_tint: float = 0.0:
	set(value):
		high_tint = value
		_refresh_active_quality()

@export_group("Dynamic lights")
@export var world_tint_path: NodePath = NodePath("../WorldTint")
@export var dynamic_light_group: StringName = &"ashen_dynamic_light"
@export var medium_light_group: StringName = &"ashen_medium_light"
@export_range(0.0, 1.0, 0.01) var medium_light_energy_scale: float = 0.72:
	set(value):
		medium_light_energy_scale = value
		_refresh_active_quality()
@export_range(0.0, 1.0, 0.01) var high_light_energy_scale: float = 1.0:
	set(value):
		high_light_energy_scale = value
		_refresh_active_quality()

const LOW_ID: String = "low"
const MEDIUM_ID: String = "medium"
const HIGH_ID: String = "high"

var active_quality_id: String = MEDIUM_ID
var _base_light_energy: Dictionary = {}
var _applying_quality: bool = false

func _ready() -> void:
	set_process(false)
	apply_quality_id(_normalize_quality(default_quality), false)

func apply_quality_id(value: String, emit_signal: bool = true) -> void:
	var normalized: String = _normalize_quality(value)
	active_quality_id = normalized
	# Keep the Inspector's Default Quality field useful while the game is
	# running: it reflects the active saved preset, not only the scene default.
	_applying_quality = true
	default_quality = normalized.capitalize()
	_applying_quality = false
	_apply_ambient_shader(normalized)
	_apply_dynamic_lights(normalized)
	if emit_signal:
		quality_changed.emit(normalized)

func quality_id() -> String:
	return active_quality_id

func _refresh_active_quality() -> void:
	# Inspector edits on the Remote scene tree should be visible immediately.
	# Scene-load assignments happen before the node enters the tree, so they do
	# not trigger work until the normal _ready() application below.
	if is_inside_tree() and not _applying_quality:
		apply_quality_id(active_quality_id, false)

func cosmetic_density_cap() -> float:
	match active_quality_id:
		LOW_ID:
			return clampf(low_cosmetic_density, 0.1, 1.0)
		MEDIUM_ID:
			return clampf(medium_cosmetic_density, 0.1, 1.0)
		_:
			return 1.0

func _normalize_quality(value: String) -> String:
	var clean: String = value.strip_edges().to_lower()
	return clean if clean in [LOW_ID, MEDIUM_ID, HIGH_ID] else MEDIUM_ID

func _apply_ambient_shader(quality: String) -> void:
	var tint := get_node_or_null(world_tint_path) as CanvasItem
	if tint == null:
		return
	if quality == LOW_ID:
		# Keep the authored translucent tint, but skip shader work entirely.
		tint.material = null
		return
	if ambient_material == null:
		push_error("Visual quality requires the authored ambient ShaderMaterial.")
		return
	tint.material = ambient_material
	var strength: float = high_shader_strength if quality == HIGH_ID else medium_shader_strength
	ambient_material.set_shader_parameter("quality_strength", clampf(strength, 0.0, 1.0))
	ambient_material.set_shader_parameter("vignette_strength", clampf(high_vignette_strength if quality == HIGH_ID else medium_vignette_strength, 0.0, 1.0))
	ambient_material.set_shader_parameter("warmth_strength", clampf(high_warmth_strength if quality == HIGH_ID else medium_warmth_strength, 0.0, 1.0))
	ambient_material.set_shader_parameter("brightness", high_brightness if quality == HIGH_ID else medium_brightness)
	ambient_material.set_shader_parameter("contrast", maxf(0.0, high_contrast if quality == HIGH_ID else medium_contrast))
	ambient_material.set_shader_parameter("saturation", maxf(0.0, high_saturation if quality == HIGH_ID else medium_saturation))
	ambient_material.set_shader_parameter("hue_shift_degrees", high_hue_shift_degrees if quality == HIGH_ID else medium_hue_shift_degrees)
	ambient_material.set_shader_parameter("exposure", high_exposure if quality == HIGH_ID else medium_exposure)
	ambient_material.set_shader_parameter("gamma", maxf(0.25, high_gamma if quality == HIGH_ID else medium_gamma))
	ambient_material.set_shader_parameter("temperature", high_temperature if quality == HIGH_ID else medium_temperature)
	ambient_material.set_shader_parameter("tint", high_tint if quality == HIGH_ID else medium_tint)

func _apply_dynamic_lights(quality: String) -> void:
	for node: Node in get_tree().get_nodes_in_group(dynamic_light_group):
		var light := node as PointLight2D
		if light == null:
			continue
		var instance_id: int = light.get_instance_id()
		if not _base_light_energy.has(instance_id):
			_base_light_energy[instance_id] = light.energy
		var enabled: bool = quality != LOW_ID and (quality == HIGH_ID or light.is_in_group(medium_light_group))
		light.visible = enabled
		var energy_scale: float = high_light_energy_scale if quality == HIGH_ID else medium_light_energy_scale
		light.energy = float(_base_light_energy[instance_id]) * clampf(energy_scale, 0.0, 1.0)
