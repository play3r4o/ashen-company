extends SceneTree

const FORBIDDEN_DRAW_PATTERNS: Array[String] = [
	"draw_rect(", "draw_circle(", "draw_line(", "draw_arc(",
	"draw_string(", "draw_texture(", "draw_texture_rect(",
	"draw_texture_rect_region(", "func _draw(",
]
const FORBIDDEN_VISUAL_CONSTRUCTION_PATTERNS: Array[String] = [
	"Control.new(", "Button.new(", "Label.new(", "Panel.new(", "ColorRect.new(",
	"PanelContainer.new(", "NinePatchRect.new(", "TextureRect.new(",
	"StyleBoxFlat.new(", "StyleBoxTexture.new(", "Theme.new(", "CanvasLayer.new(", "Node2D.new(",
	"Sprite2D.new(", "AnimatedSprite2D.new(",
]
const FORBIDDEN_ASSET_ROOTS: Array[String] = [
	"res://art/", "res://preview/", "res://docs/", "res://artifacts/",
	"res://assets/generated/", "res://assets/ui/generated/",
]

var failures: int = 0


func _init() -> void:
	_scan_production_scripts()
	_scan_runtime_scene_assets()
	_check_controller_boundaries()
	_check_camp_contracts()
	_check_combat_contracts()
	print("Architecture guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check_controller_boundaries() -> void:
	var main_source: String = FileAccess.get_file_as_string("res://src/main.gd")
	var coordinator_source: String = FileAccess.get_file_as_string("res://scenes/app/game_coordinator.gd")
	_check(main_source.split("\n").size() <= 800, "src/main.gd remains a thin compatibility entry point")
	_check(coordinator_source.split("\n").size() <= 800, "GameCoordinator remains below 800 lines")
	var root_source: String = FileAccess.get_file_as_string("res://scenes/app/game_root.tscn")
	_check(root_source.contains("res://scenes/app/game_coordinator.gd"), "game_root.tscn directly uses GameCoordinator")
	for path: String in [
		"res://scenes/world/world_controller.gd",
		"res://scenes/world/camp/camp_controller.gd",
		"res://scenes/world/expedition/expedition_controller.gd",
		"res://scenes/actors/player/player_controller.gd",
		"res://scenes/actors/enemies/enemy_controller.gd",
		"res://scenes/combat/combat_runtime_controller.gd",
		"res://scenes/ui/ui_flow_controller.gd",
	]:
		_check(FileAccess.file_exists(path), "responsibility controller exists: %s" % path)


func _scan_production_scripts() -> void:
	for root_path: String in ["res://src", "res://scenes"]:
		for path: String in _files_below(root_path, ["gd"]):
			var source: String = FileAccess.get_file_as_string(path)
			for pattern: String in FORBIDDEN_DRAW_PATTERNS:
				var found_call: bool = false
				for line: String in source.split("\n"):
					if line.strip_edges().begins_with(pattern):
						found_call = true
						break
				_check(not found_call, "%s does not contain forbidden production drawing '%s'" % [path, pattern])
			for pattern: String in FORBIDDEN_VISUAL_CONSTRUCTION_PATTERNS:
				_check(not source.contains(pattern), "%s does not construct production presentation with '%s'" % [path, pattern])
			_check(not source.contains("load(\"res://assets/runtime/"), "%s does not replace editor-authored textures at runtime" % path)


func _scan_runtime_scene_assets() -> void:
	for path: String in _files_below("res://scenes", ["tscn", "tres", "gd"]):
		var source: String = FileAccess.get_file_as_string(path)
		for root_path: String in FORBIDDEN_ASSET_ROOTS:
			_check(not source.contains(root_path), "%s does not reference non-runtime asset root %s" % [path, root_path])


func _check_camp_contracts() -> void:
	for tier: int in 5:
		var path: String = "res://scenes/world/camp/camp_tier_%d.tscn" % tier
		var camp := (load(path) as PackedScene).instantiate()
		for required: String in ["Ground", "BackVegetation", "BackWall", "Structures", "BuildingSlots", "Props", "ActorSpace", "FrontWall", "FrontVegetation", "Gate", "CampBounds", "SafeZone", "NoSpawnZone", "CameraMarkers"]:
			_check(camp.get_node_or_null(required) != null, "%s owns %s" % [path, required])
		_check(camp.get_node_or_null("Structures/VeteransHallAnchor/Content") != null, "%s owns its live Hall instance" % path)
		_check(camp.get_node_or_null("Structures/CampfireAnchor/Content") != null, "%s owns its live campfire instance" % path)
		camp.free()


func _check_combat_contracts() -> void:
	for path: String in _files_below("res://scenes/combat/projectiles", ["tscn"]):
		var projectile := (load(path) as PackedScene).instantiate()
		_check(projectile is Area2D, "%s has an Area2D root" % path)
		_check(projectile.get_node_or_null("Sprite") != null or projectile.get_node_or_null("Artwork") is CanvasItem, "%s owns an authored visual node" % path)
		_check(projectile.get_node_or_null("CollisionShape2D") != null, "%s owns its collision" % path)
		projectile.free()


func _files_below(root_path: String, extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		var path: String = root_path.path_join(name)
		if directory.current_is_dir():
			result.append_array(_files_below(path, extensions))
		elif name.get_extension() in extensions:
			result.append(path)
		name = directory.get_next()
	directory.list_dir_end()
	return result


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("ARCHITECTURE FAIL: %s" % message)
