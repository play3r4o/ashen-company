class_name AshenCampGate
extends Node2D

@onready var prompt: CanvasGroup = AshenSceneBindings.optional(self, &"Prompt") as CanvasGroup

var pulse_time: float = 0.0


func _ready() -> void:
	set_process(prompt != null and prompt.visible)


func _process(delta: float) -> void:
	if prompt == null:
		set_process(false)
		return
	pulse_time = fmod(pulse_time + delta, TAU / 3.5)
	prompt.modulate.a = 0.78 + (sin(pulse_time * 3.5) + 1.0) * 0.08


func set_prompt_visible(value: bool) -> void:
	if prompt == null:
		return
	prompt.visible = value
	set_process(value)
	if not value:
		prompt.modulate.a = 0.0
