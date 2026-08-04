extends SceneTree

const GameScene := preload("res://main.tscn")

var game: Control
var output_root: String = "res://artifacts/foundation_cleanup/screenshots"


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
	game._show_settings()
	await _settle()
	_capture("settings")
	game._show_camp()
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
	game.queue_free()
	await process_frame
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _capture(file_name: String) -> void:
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png("%s/%s_390x844.png" % [output_root, file_name])
	if result != OK:
		push_error("Unable to save capture %s: %s" % [file_name, error_string(result)])
