extends SceneTree

func _init() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene := load("res://scenes/ui/screens/settings_screen.tscn") as PackedScene
	if scene == null:
		push_error("Settings scene did not load")
		quit(1)
		return
	var screen := scene.instantiate()
	get_root().add_child(screen)
	await process_frame
	if not screen is AshenSettingsScreen:
		push_error("Settings scene has the wrong script")
		quit(1)
		return
	var settings := screen as AshenSettingsScreen
	if settings.music_slider == null or settings.sfx_slider == null or settings.effects_slider == null:
		push_error("Settings audio controls are missing")
		quit(1)
		return
	if settings.screen_shake_toggle == null or settings.gate_confirmations_toggle == null:
		push_error("Settings toggle controls are missing")
		quit(1)
		return
	if settings.save_text == null or settings.export_button == null or settings.import_button == null or settings.reset_button == null:
		push_error("Settings maintenance controls are missing")
		quit(1)
		return
	print("PASS: authored Ashen Settings screen instantiates all live controls")
	quit(0)
