extends SceneTree

const GameScene := preload("res://main.tscn")

var game: Control
var output_root: String = "res://artifacts/foundation_cleanup/screenshots/final"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_root))
	call_deferred("_capture_all")


func _capture_all() -> void:
	game = GameScene.instantiate() as Control
	game.set_meta("use_disposable_profile", true)
	root.add_child(game)
	await process_frame
	await process_frame
	for tier: int in 5:
		game.save.profile.hall_level = tier
		var buildings: Array[String] = ["veterans_hall", "campfire"]
		var plots: Dictionary = {}
		var available: Array[String] = ["armory", "quartermaster", "blacksmith", "training"]
		for index: int in tier:
			buildings.append(available[index])
			plots["plot_%d" % (index + 1)] = available[index]
		game.save.profile.constructed_buildings = buildings
		game.save.profile.building_plots = plots
		game._show_camp()
		await _settle()
		_capture("camp_tier_%d" % tier)
	game.save.profile.hall_level = 0
	game.save.profile.constructed_buildings = ["veterans_hall", "campfire"]
	game.save.profile.building_plots = {}
	game._show_camp()
	await _settle()
	_capture("camp_hud")
	game._show_settings()
	await _settle()
	_capture("settings")
	var settings_scroll := game.find_child("ContentScroll", true, false) as ScrollContainer
	if settings_scroll != null:
		settings_scroll.scroll_vertical = int(settings_scroll.get_v_scroll_bar().max_value)
		await _settle()
		_capture("settings_bottom")
	game._show_camp()
	game.save.profile.training_level = 1
	game._show_skill_tree()
	await _settle()
	_capture("training_grounds")
	game._show_camp()
	game._show_arsenal_screen(false)
	await _settle()
	_capture("arsenal")
	game._show_camp()
	game._show_hall_detail()
	await _settle()
	_capture("hall")
	game._show_camp()
	game._show_inventory()
	await _settle()
	_capture("inventory")
	game._show_camp()
	game._show_gate_confirmation(true)
	await _settle()
	_capture("gate_confirmation")
	game._show_camp()
	game._start_new_run("sword", true)
	await _settle()
	_capture("run_hud")
	game._show_upgrade_choices()
	await _settle()
	_capture("level_up")
	game.choosing_upgrade = false
	game.run_paused = false
	game._clear_ui()
	game._build_run_ui()
	game.player_position = game._camp_gate_position() + Vector2(0.0, 520.0)
	game._update_world_camera(game.player_position, false, true)
	for index: int in 48:
		game._spawn_enemy("raider" if index % 4 else "archer", false)
		var angle: float = TAU * float(index) / 48.0
		game.enemies[-1].position = game.player_position + Vector2.from_angle(angle) * (110.0 + float(index % 4) * 24.0)
	game._process_run(0.25)
	await _settle()
	_capture("heavy_combat")
	game._finish_run(false, false)
	await _settle()
	_capture("results")
	for safe_top: int in [0, 34, 47, 59]:
		game.safe_area_top = float(safe_top)
		game._show_camp()
		await _settle()
		_capture("camp_hud_safe_%d" % safe_top)
		game._show_settings()
		await _settle()
		_capture("settings_safe_%d" % safe_top)
	game.queue_free()
	await process_frame
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _capture(file_name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		push_error("Screenshot capture requires a rendering driver; '%s' was not captured." % file_name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null:
		push_error("Screenshot capture returned no image for '%s'." % file_name)
		return
	var result: Error = image.save_png("%s/%s_390x844.png" % [output_root, file_name])
	if result != OK:
		push_error("Unable to save capture %s: %s" % [file_name, error_string(result)])
