extends SceneTree

## Tiny Swords UI migration guard.
## The 64px art grid is used for authored textures; controls are snapped to
## the 8px sub-grid and retain their real Godot scene ownership.

const UI_ROOT := "res://scenes/ui"
const TINY_ROOT := "res://assets/runtime/ui/tiny_swords"
const UI_TILE_SET := "res://scenes/ui/theme/tiny_swords_ui_tileset.tres"
const UI_ART_CANVAS := "res://scenes/ui/components/tiny_swords_ui_art_canvas.tscn"
const UI_MODAL_ART := "res://scenes/ui/components/tiny_swords_ui_modal_art.tscn"
const UI_PAUSE_ART := "res://scenes/ui/components/tiny_swords_ui_pause_art.tscn"
const UI_HUD_ART := "res://scenes/ui/components/tiny_swords_ui_hud_art.tscn"
const UI_HEALTH_BAR := "res://scenes/ui/components/health_bar.tscn"
const UI_HUD := "res://scenes/ui/hud/hud.tscn"
const BLACKTHORN_RUN_RIBBON := "res://assets/runtime/ui/blackthorn/blackthorn_moor_ribbon.png"
const BLACKTHORN_OBJECTIVE_SIGN := "res://assets/runtime/ui/blackthorn/objective_sign.png"
const TINY_SWORDS_PACK_ASSETS: Array[String] = [
	"cursors/cursor_01.png",
	"cursors/cursor_02.png",
	"cursors/cursor_03.png",
	"cursors/cursor_04.png",
	"human_avatars/avatars_01.png",
	"human_avatars/avatars_02.png",
	"human_avatars/avatars_03.png",
	"human_avatars/avatars_04.png",
	"human_avatars/avatars_05.png",
	"human_avatars/avatars_06.png",
	"human_avatars/avatars_07.png",
	"human_avatars/avatars_08.png",
	"human_avatars/avatars_09.png",
	"human_avatars/avatars_10.png",
	"human_avatars/avatars_11.png",
	"human_avatars/avatars_12.png",
	"human_avatars/avatars_13.png",
	"human_avatars/avatars_14.png",
	"human_avatars/avatars_15.png",
	"human_avatars/avatars_16.png",
	"human_avatars/avatars_17.png",
	"human_avatars/avatars_18.png",
	"human_avatars/avatars_19.png",
	"human_avatars/avatars_20.png",
	"human_avatars/avatars_21.png",
	"human_avatars/avatars_22.png",
	"human_avatars/avatars_23.png",
	"human_avatars/avatars_24.png",
	"human_avatars/avatars_25.png",
	"icons/icon_09.png",
	"icons/icon_10.png",
	"icons/icon_11.png",
	"icons/icon_12.png",
	"ribbons/big_ribbons.png",
	"ribbons/small_ribbons.png",
	"swords/swords.png",
	"buttons/tiny_round_blue.png",
	"buttons/tiny_round_red.png",
]
const LEGACY_MARKERS: Array[String] = [
	"assets/runtime/ui/ashen",
	"assets/runtime/ui/ashen_hq",
	"assets/runtime/ui/menu_background.png",
	"assets/runtime/ui/camp_title_crest.png",
	"assets/runtime/ui/settings_cog.png",
	"assets/runtime/ui/heart_icon.png",
	"assets/runtime/ui/silver_icon.png",
	"assets/runtime/ui/provisions_icon.png",
	"assets/runtime/ui/key_icon.png",
]
const RETIRED_RUNTIME_PATHS: Array[String] = [
	"res://assets/runtime/ui/ashen",
	"res://assets/runtime/ui/ashen_hq",
	"res://assets/runtime/ui/menu_background.png",
	"res://assets/runtime/ui/camp_title_crest.png",
	"res://assets/runtime/ui/settings_cog.png",
	"res://assets/runtime/ui/heart_icon.png",
	"res://assets/runtime/ui/silver_icon.png",
	"res://assets/runtime/ui/provisions_icon.png",
	"res://assets/runtime/ui/key_icon.png",
]

var failures := 0


func _init() -> void:
	_check(FileAccess.file_exists("%s/panels/wood_table_slots.png" % TINY_ROOT), "Tiny Swords panel atlas exists")
	_check(FileAccess.file_exists("%s/buttons/tiny_square_blue.png" % TINY_ROOT), "Tiny Swords button atlas exists")
	_check(FileAccess.file_exists("%s/controls/slider_knob_32.png" % TINY_ROOT), "Tiny Swords slider knob exists")
	_check(FileAccess.file_exists("%s/controls/scroll_grabber_32.png" % TINY_ROOT), "Tiny Swords scroll grabber exists")
	_check(FileAccess.file_exists("%s/controls/close_32.png" % TINY_ROOT), "Tiny Swords close control exists")
	_check_no_legacy_ui_references()
	_check_retired_runtime_paths()
	_check_tiny_dimensions()
	_check_ui_tileset()
	_check_tiny_swords_pack_assets()
	_check_health_bar()
	_check_health_bar_hud_parity()
	_check_blackthorn_run_hud_art()
	_check_ui_art_canvas()
	_check_ui_overlay_art()
	_check_real_scenes()
	print("UI grid guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check_no_legacy_ui_references() -> void:
	for path: String in _files_below(UI_ROOT, ["tscn", "tres", "gd"]):
		var source := FileAccess.get_file_as_string(path)
		for marker: String in LEGACY_MARKERS:
			_check(not source.contains(marker), "%s does not reference retired UI art: %s" % [path, marker])


func _check_retired_runtime_paths() -> void:
	for path: String in RETIRED_RUNTIME_PATHS:
		var absolute := ProjectSettings.globalize_path(path)
		var exists := DirAccess.dir_exists_absolute(absolute) or FileAccess.file_exists(path)
		_check(not exists, "retired UI art is absent from the shipped runtime root: %s" % path)


func _check_tiny_dimensions() -> void:
	for path: String in _files_below(TINY_ROOT, ["png"]):
		var texture := load(path) as Texture2D
		_check(texture != null, "%s imports" % path)
		if texture == null:
			continue
		var size := texture.get_size()
		var is_control := path.contains("/controls/")
		var valid := (int(size.x) % 64 == 0 and int(size.y) % 64 == 0) if not is_control else (int(size.x) % 8 == 0 and int(size.y) % 8 == 0)
		_check(valid, "%s stays on the Tiny Swords grid (%s)" % [path, size])


func _check_real_scenes() -> void:
	for path: String in [
		"res://scenes/ui/hud/hud.tscn",
		"res://scenes/ui/screens/settings_screen.tscn",
		"res://scenes/ui/screens/arsenal_screen.tscn",
		"res://scenes/ui/screens/training_tree_screen.tscn",
		"res://scenes/ui/overlays/level_up_overlay.tscn",
		"res://scenes/ui/overlays/pause_overlay.tscn",
	]:
		var scene := load(path) as PackedScene
		_check(scene != null, "%s is an authored runtime scene" % path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		_check(instance is Control or instance is CanvasItem, "%s has a visual root" % path)
		instance.free()


func _check_ui_tileset() -> void:
	var tile_set := load(UI_TILE_SET) as TileSet
	_check(tile_set != null, "Tiny Swords UI TileSet is authored")
	if tile_set == null:
		return
	_check(tile_set.tile_size == Vector2i(64, 64), "Tiny Swords UI TileSet uses 64px cells")
	_check(tile_set.get_source_count() >= 30, "Tiny Swords UI TileSet exposes the full pack atlas sources")
	for index: int in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		_check(source != null, "Tiny Swords UI TileSet source %d is an atlas" % index)
		if source != null:
			_check(source.texture_region_size == Vector2i(64, 64), "Tiny Swords UI atlas source %d is 64px" % index)


func _check_tiny_swords_pack_assets() -> void:
	var tile_set := load(UI_TILE_SET) as TileSet
	for relative_path: String in TINY_SWORDS_PACK_ASSETS:
		var path := "%s/%s" % [TINY_ROOT, relative_path]
		_check(FileAccess.file_exists(path), "Tiny Swords UI pack asset exists: %s" % relative_path)
		_check(_tile_set_has_texture(tile_set, path), "Tiny Swords UI pack asset is available as a TileSet source: %s" % relative_path)


func _check_health_bar() -> void:
	var scene := load(UI_HEALTH_BAR) as PackedScene
	_check(scene != null, "health bar is an authored reusable scene")
	if scene == null:
		return
	var instance := scene.instantiate()
	_check(instance is ProgressBar, "health bar keeps a real ProgressBar root")
	_check(instance.find_child("BackgroundTiles", true, false) != null, "health bar owns a static authored frame layer")
	_check(instance.get_theme_stylebox("background") is StyleBoxEmpty, "health bar background is drawn by its authored frame layer")
	_check(instance.get_theme_stylebox("fill") is StyleBoxEmpty, "health bar root keeps rendering separate from its frame")
	var fill_visual := instance.get_node_or_null("FillVisual") as TextureProgressBar
	_check(fill_visual != null, "health bar exposes an independently editable live fill")
	if fill_visual != null:
		_check(fill_visual.texture_progress is AtlasTexture, "health bar fill uses a cropped authored texture strip")
	instance.free()


func _check_health_bar_hud_parity() -> void:
	var health_scene := load(UI_HEALTH_BAR) as PackedScene
	var hud_scene := load(UI_HUD) as PackedScene
	_check(health_scene != null and hud_scene != null, "health bar and HUD scenes load for parity")
	if health_scene == null or hud_scene == null:
		return
	var health := health_scene.instantiate() as ProgressBar
	var hud := hud_scene.instantiate()
	var hud_health := hud.get_node_or_null("SafeAreaTop/ResourceRail/HealthBar") as ProgressBar
	_check(hud_health != null, "HUD contains the authored health-bar instance")
	if hud_health != null:
		_check(hud_health.size == health.size, "HUD health bar keeps the standalone authored size")
		_check(hud_health.get_node_or_null("BackgroundTiles") != null and hud_health.get_node_or_null("FillVisual") != null, "HUD health bar keeps both authored visual layers")
	health.free()
	hud.free()


func _check_blackthorn_run_hud_art() -> void:
	var hud_scene := load(UI_HUD) as PackedScene
	_check(FileAccess.file_exists(BLACKTHORN_RUN_RIBBON), "Blackthorn run ribbon asset exists")
	_check(FileAccess.file_exists(BLACKTHORN_OBJECTIVE_SIGN), "Blackthorn objective sign asset exists")
	var ribbon := load(BLACKTHORN_RUN_RIBBON) as Texture2D
	var sign := load(BLACKTHORN_OBJECTIVE_SIGN) as Texture2D
	_check(ribbon != null and ribbon.get_size() == Vector2(256, 32), "Blackthorn run ribbon is 256x32")
	_check(sign != null and sign.get_size() == Vector2(160, 80), "Blackthorn objective sign is 160x80")
	if hud_scene == null:
		return
	var hud := hud_scene.instantiate()
	var ribbon_rect := hud.get_node_or_null("SafeAreaTop/RunTop/RunRibbon") as NinePatchRect
	var sign_rect := hud.get_node_or_null("SafeAreaTop/RunTop/ObjectiveSign") as TextureRect
	var objective := hud.get_node_or_null("SafeAreaTop/RunTop/ObjectiveLabel") as Label
	var objective_meta := hud.get_node_or_null("SafeAreaTop/RunTop/ObjectiveMetaLabel") as Label
	var pause_button := hud.get_node_or_null("RunActions/PauseButton") as Button
	_check(ribbon_rect != null and ribbon_rect.texture == ribbon, "run HUD uses the supplied Blackthorn ribbon")
	_check(sign_rect != null and sign_rect.texture == sign, "run HUD uses the supplied objective sign")
	_check(ribbon_rect != null and is_equal_approx(ribbon_rect.size.x, 390.0), "run ribbon spans the reference viewport")
	_check(ribbon_rect != null and ribbon_rect.patch_margin_left == 40.0 and ribbon_rect.patch_margin_right == 40.0, "run ribbon preserves symmetrical stretch margins")
	_check(sign_rect != null and sign_rect.size == Vector2(160, 80), "objective sign keeps its authored size")
	_check(objective != null and objective_meta != null, "objective sign keeps real editable text controls")
	_check(pause_button != null and pause_button.position == Vector2(8, 728), "pause button is authored at the bottom-left of the run")
	hud.free()


func _tile_set_has_texture(tile_set: TileSet, path: String) -> bool:
	if tile_set == null:
		return false
	for index: int in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source != null and source.texture != null and source.texture.resource_path == path:
			return true
	return false


func _check_ui_art_canvas() -> void:
	var scene := load(UI_ART_CANVAS) as PackedScene
	_check(scene != null, "Tiny Swords UI art canvas is an authored scene")
	if scene == null:
		return
	var instance := scene.instantiate()
	var tile_set := load(UI_TILE_SET) as TileSet
	var layers := instance.find_children("*", "TileMapLayer", true, false)
	_check(layers.size() >= 2, "Tiny Swords UI art canvas has paintable backdrop and panel layers")
	for layer: Node in layers:
		var tile_layer := layer as TileMapLayer
		_check(tile_layer.tile_set == tile_set, "%s uses the canonical UI TileSet" % tile_layer.name)
		_check(tile_layer.scale == Vector2.ONE, "%s stays at native grid scale" % tile_layer.name)
		var cells := tile_layer.get_used_cells()
		_check(cells.size() > 0, "%s contains authored paintable cells" % tile_layer.name)
		for cell: Vector2i in cells:
			var source_id := tile_layer.get_cell_source_id(cell)
			var source := tile_set.get_source(source_id) as TileSetAtlasSource
			var atlas_coords := tile_layer.get_cell_atlas_coords(cell)
			_check(source != null and source.get_tiles_count() > 1, "%s paints independently editable atlas slices" % tile_layer.name)
			_check(source != null and source.get_tile_size_in_atlas(atlas_coords) == Vector2i.ONE, "%s keeps every painted atlas tile to one 64px square" % tile_layer.name)
			if source != null:
				var texture_path := source.texture.resource_path if source.texture != null else ""
				var expected := "/panels/wood_table.png" if tile_layer.name == "BackdropTiles" else "/panels/regular_paper.png"
				_check(texture_path.ends_with(expected), "%s uses its authored atlas asset" % tile_layer.name)
	instance.free()


func _check_ui_overlay_art() -> void:
	for path: String in [UI_MODAL_ART, UI_PAUSE_ART, UI_HUD_ART]:
		var scene := load(path) as PackedScene
		_check(scene != null, "%s is an authored overlay art scene" % path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		var layers := instance.find_children("*", "TileMapLayer", true, false)
		_check(layers.size() > 0, "%s contains a paintable TileMapLayer" % path)
		for layer_node: Node in layers:
			var layer := layer_node as TileMapLayer
			_check(layer.tile_set == load(UI_TILE_SET), "%s uses the slice UI TileSet" % layer.name)
			_check(layer.scale == Vector2.ONE, "%s stays at native grid scale" % layer.name)
			_check(layer.get_used_cells().size() > 0, "%s contains authored cells" % layer.name)
			for cell: Vector2i in layer.get_used_cells():
				var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
				_check(source != null and source.get_tile_size_in_atlas(layer.get_cell_atlas_coords(cell)) == Vector2i.ONE, "%s keeps each overlay atlas square independently paintable" % layer.name)
		instance.free()
	var hud_scene := load("res://scenes/ui/hud/hud.tscn") as PackedScene
	var hud_instance := hud_scene.instantiate() if hud_scene != null else null
	_check(hud_instance != null and hud_instance.find_child("TinySwordsUIHudArt", true, false) != null, "HUD instantiates the editable Tiny Swords rail art")
	if hud_instance != null:
		hud_instance.free()
	for path: String in [
		"res://scenes/ui/screens/camp_list_screen.tscn",
		"res://scenes/ui/screens/arsenal_screen.tscn",
		"res://scenes/ui/screens/results_screen.tscn",
		"res://scenes/ui/screens/settings_screen.tscn",
		"res://scenes/ui/screens/training_tree_screen.tscn",
		"res://scenes/ui/overlays/level_up_overlay.tscn",
		"res://scenes/ui/overlays/relic_choice_overlay.tscn",
	]:
		var scene := load(path) as PackedScene
		var instance := scene.instantiate() if scene != null else null
		_check(instance != null and instance.find_child("TinySwordsArtCanvas", true, false) != null, "%s instantiates the editable Tiny Swords art canvas" % path)
		if instance != null:
			instance.free()
	for path: String in [
		"res://scenes/ui/overlays/confirmation_overlay.tscn",
		"res://scenes/ui/overlays/gate_confirmation_overlay.tscn",
		"res://scenes/ui/overlays/reset_confirmation_overlay.tscn",
		"res://scenes/ui/overlays/dismantle_confirmation_overlay.tscn",
	]:
		var scene := load(path) as PackedScene
		var instance := scene.instantiate() if scene != null else null
		_check(instance != null and instance.find_child("TinySwordsModalArt", true, false) != null, "%s instantiates the editable Tiny Swords modal art" % path)
		if instance != null:
			instance.free()
	var pause_scene := load("res://scenes/ui/overlays/pause_overlay.tscn") as PackedScene
	var pause_instance := pause_scene.instantiate() if pause_scene != null else null
	_check(pause_instance != null and pause_instance.find_child("TinySwordsUIPauseArt", true, false) != null, "pause overlay instantiates editable Tiny Swords art")
	if pause_instance != null:
		pause_instance.free()


func _files_below(root_path: String, extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var path := root_path.path_join(name)
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
	push_error("UI GRID FAIL: %s" % message)
