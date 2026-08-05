class_name AshenCampGate
extends Node2D

@onready var prompt: CanvasGroup = $Prompt


func _process(_delta: float) -> void:
	if prompt.visible:
		prompt.modulate.a = 0.78 + (sin(Time.get_ticks_msec() * 0.0035) + 1.0) * 0.08


func set_prompt_visible(value: bool) -> void:
	prompt.visible = value
	if not value:
		prompt.modulate.a = 0.0
