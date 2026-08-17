extends SceneTree
func _initialize() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save.profile.hall_level = 0
	game.save.profile.constructed_buildings = ["veterans_hall", "campfire"]
	game.save.profile.building_plots = {}
	game.save.profile.armory_level = 0
	game.save.profile.blacksmith_level = 0
	game.save.profile.training_level = 0
	game.save.profile.quartermaster_level = 0
	game.camp_player_position = game._safe_camp_spawn_position()
	game._show_camp()
	await process_frame
	print("tier=", game._town_level(), " plots=", game._building_plots())
	print("origin=", game.world_content_origin, " camp_position=", game.active_camp_scene.position, " worldroot=", game.world_root.position)
	print("fire=", game._camp_hit_rect_world("campfire"))
	print("training=", game._camp_hit_rect_world("training"))
	print("fire info=", game.active_camp_scene.structure_info("campfire"))
	print("training info=", game.active_camp_scene.structure_info("training"))
	print("fire def anchor=", game.camp_structure_definitions["campfire"].anchor, " poly=", game.camp_structure_definitions["campfire"].interaction_polygon)
	print("training def anchor=", game.camp_structure_definitions["training"].anchor, " poly=", game.camp_structure_definitions["training"].interaction_polygon)
	print("bounds=", game._town_bounds_world(), " hall_in=", game._town_bounds_world().has_point(game.camp_structure_definitions["veterans_hall"].anchor), " fire_in=", game._town_bounds_world().has_point(game.camp_structure_definitions["campfire"].anchor))
	var start = game._safe_camp_spawn_position()
	game.camp_player_position = start
	var camera_start = game.camera_offset
	game.joystick_vector = Vector2.RIGHT
	game._process_camp(0.1)
	print("movement start=", start, " now=", game.camp_player_position, " camera_start=", camera_start, " camera_now=", game.camera_offset)
	game.free()
	quit()
