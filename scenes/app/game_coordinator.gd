extends "res://scenes/ui/ui_flow_controller.gd"
func _exit_tree() -> void:
	if is_instance_valid(audio_controller):
		audio_controller.shutdown()

func _play_music(music_id: String) -> void:
	if is_instance_valid(audio_controller):
		audio_controller.play_music(music_id)

func _play_sfx(sfx_id: String, throttle: float = 0.06) -> void:
	if is_instance_valid(audio_controller):
		audio_controller.play_sfx(sfx_id, throttle)

func _update_audio_volumes() -> void:
	if is_instance_valid(audio_controller) and not save.is_empty():
		audio_controller.apply_volumes(float(save.settings.music), float(save.settings.sfx))

func _camp_display_max_health() -> float:
	var training: int = int(save.get("profile", {}).get("training_level", 0))
	var result: float = 100.0 * (1.0 + float(training) / 5.0 * 0.15)
	result += _equipment_total("health") + _class_total("health")
	return maxf(1.0, result)


func _format_time(seconds: float) -> String:
	var safe: int = maxi(0, floori(seconds))
	return "%02d:%02d" % [safe / 60, safe % 60]

func _point_over_action_button(point: Vector2) -> bool:
	return (skill_button != null and skill_button.get_global_rect().has_point(point)) or (pause_button != null and pause_button.get_global_rect().has_point(point)) or (expedition_interact_button != null and expedition_interact_button.visible and expedition_interact_button.get_global_rect().has_point(point))

func _point_over_camp_action_button(point: Vector2) -> bool:
	if camp_interact_button != null and camp_interact_button.visible and camp_interact_button.get_global_rect().has_point(point):
		return true
	if is_instance_valid(active_hud_layout):
		var settings_button := active_hud_layout.get_node_or_null("SafeAreaTop/SettingsCogButton") as Button
		if settings_button != null and settings_button.visible and settings_button.get_global_rect().has_point(point):
			return true
	return false

func _add_float_text(position: Vector2, text: String, color: Color) -> void:
	if float_texts.size() >= MAX_FLOAT_TEXTS:
		return
	var item: FloatTextState = FloatTextState.new()
	item.position = position
	item.text = text
	item.color = color
	float_texts.append(item)

func _add_effect(position: Vector2, radius: float, color: Color, kind: String, direction: Vector2 = Vector2.RIGHT) -> void:
	if effects.size() >= floori(MAX_EFFECTS * float(save.settings.effect_density)):
		return
	var effect: EffectState = EffectState.new()
	effect.position = position
	effect.radius = radius
	effect.color = color
	effect.kind = kind
	effect.direction = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	effects.append(effect)
