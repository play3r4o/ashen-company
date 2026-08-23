extends SceneTree

const WorldMetrics = preload("res://src/world_metrics.gd")
const RegionGenerator = preload("res://src/services/region_generator.gd")
const DepthSort = preload("res://scenes/world/world_depth_sort_controller.gd")

var failures: int = 0


func _init() -> void:
	var preview_scene := load("res://scenes/world/biomes/blackthorn_moor_preview.tscn") as PackedScene
	_check(preview_scene != null, "Blackthorn Moor preview scene is the canonical meadow composition")
	if preview_scene != null:
		var preview := preview_scene.instantiate() as Node2D
		_check(preview != null, "Blackthorn Moor preview instantiates")
		if preview != null:
			_check(preview.get_node_or_null("Terrain") != null, "Blackthorn Moor preview owns terrain")
			var authored_composition := preview.get_node_or_null("AuthoredComposition") as Node2D
			_check(authored_composition != null, "Blackthorn Moor preview owns authored meadow dressing")
			_check(authored_composition != null and authored_composition.visible, "Blackthorn Moor preview shows authored meadow dressing in the editor/runtime scene")
			if authored_composition != null and preview.has_method("authored_composition_local_position"):
				var preview_origin := Vector2(preview.get("preview_content_origin"))
				var expected_composition_offset := authored_composition.position - preview_origin
				var actual_composition_offset := Vector2(preview.call("authored_composition_local_position"))
				_check(actual_composition_offset == expected_composition_offset, "Meadow decorations keep editor/runtime relative placement")
			var meadow_dressing := preview.get_node_or_null("AuthoredComposition/RegionDressing") as Node2D
			_check(meadow_dressing != null, "Meadow preview owns its authored vegetation scatter")
			if meadow_dressing != null:
				var back_canopy := meadow_dressing.get_node_or_null("BackCanopy") as Node2D
				var ground_accents := meadow_dressing.get_node_or_null("GroundAccents") as Node2D
				var weighted_anchor_count := (back_canopy.get_child_count() * 4 if back_canopy != null else 0) + (ground_accents.get_child_count() if ground_accents != null else 0)
				var eligible_anchor_slots := int(meadow_dressing.get_meta("scatter_eligible_anchor_slots", 0))
				var coverage_max := float(meadow_dressing.get_meta("scatter_coverage_max", 0.0))
				var coverage_target := float(meadow_dressing.get_meta("scatter_coverage_target", 0.0))
				var coverage := float(weighted_anchor_count) / float(maxi(1, eligible_anchor_slots))
				_check(eligible_anchor_slots > 0 and coverage_max <= 0.35 and coverage <= coverage_max, "Meadow vegetation and stones stay under the 35% authored coverage cap")
				_check(coverage >= coverage_target * 0.75, "Meadow vegetation and stones retain the requested natural coverage target")
				_check(back_canopy != null and back_canopy.get_child_count() == 34 and ground_accents != null and ground_accents.get_child_count() == 53, "Meadow scatter keeps the authored tree and low-prop budgets explicit")
				_check(is_equal_approx(coverage, 0.35), "Meadow scatter can use the full 35% authored coverage budget")
				for scatter_layer: Node2D in [back_canopy, ground_accents]:
					if scatter_layer == null:
						continue
					for child: Node in scatter_layer.get_children():
						var visual := child as Sprite2D
						_check(visual != null and Rect2(Vector2.ZERO, Vector2(1152, 2496)).has_point(visual.position), "Meadow scatter anchor %s stays inside the authored region" % child.name)
			var camp_authoring := preview.get_node_or_null("CampAuthoring") as Node2D
			_check(camp_authoring != null, "Blackthorn Moor preview includes the combined Refuge authoring mount")
			if camp_authoring != null:
				var preview_origin := Vector2(preview.get("preview_content_origin"))
				_check(preview_origin.is_finite() and camp_authoring.position.is_finite(), "CampAuthoring and preview expose finite shared-origin transforms")
				for camp_tier: int in range(5):
					var camp_node := camp_authoring.get_node_or_null("CampTier%d" % camp_tier) as Node2D
					_check(camp_node != null, "Blackthorn Moor preview includes editable Refuge tier %d" % camp_tier)
					if camp_node != null and preview.has_method("authored_camp_local_position"):
						var expected_local := camp_authoring.position + camp_node.position - preview_origin
						var actual_local := Vector2(preview.call("authored_camp_local_position", camp_node))
						_check(actual_local == expected_local, "Refuge tier %d keeps editor/runtime relative placement" % camp_tier)
			_check(preview.get_node_or_null("WorldPresentation") != null, "Blackthorn Moor preview owns dynamic meadow landmarks")
			_check(String(preview.get_meta("authoring_note", "")).contains("Runtime instantiates this same scene"), "Blackthorn Moor preview documents runtime source of truth")
			var terrain := preview.get_node_or_null("Terrain")
			for layer_name: String in ["WaterFill", "BaseTiles", "MeadowShadows", "MeadowComposition"]:
				var layer := terrain.get_node_or_null(layer_name) as TileMapLayer if terrain != null else null
				_check(layer != null, "Meadow preview owns the %s layer" % layer_name)
				if layer == null:
					continue
				_check(layer.scale == Vector2.ONE, "%s stays at native scale" % layer_name)
				_check(layer.position == (Vector2(0, 4) if layer_name == "MeadowShadows" else Vector2.ZERO), "%s keeps its authored transform" % layer_name)
				_check(layer.tile_set != null and layer.tile_set.tile_size == Vector2i(64, 64), "%s uses a 64px TileSet" % layer_name)
			_check(preview.get_node_or_null("Terrain/BaseTiles").get_used_cells().size() > 0, "Meadow preview contains authored base cells")
			preview.free()
	_check(WorldMetrics.TERRAIN_TILE_SIZE == 64, "terrain metrics use native 64px cells")
	_check(WorldMetrics.TERRAIN_HALF_TILE == 32.0, "terrain half-cell is 32px")
	_check(WorldMetrics.NAVIGATION_CELL_SIZE == 32 and WorldMetrics.BLOCKER_SAMPLE_SIZE == 32, "navigation and blocker sampling remain 32px")
	_check(WorldMetrics.SPATIAL_HASH_CELL_SIZE == 48.0, "combat spatial hash remains 48px")
	_check(WorldMetrics.REGION_CELLS == Vector2i(18, 39), "generated region uses 18x39 terrain cells")
	_check(WorldMetrics.REGION_PIXEL_SIZE == Vector2i(1152, 2496), "generated region keeps its physical footprint")
	var metric_cell := Vector2i(3, 4)
	_check(WorldMetrics.terrain_cell_to_origin(metric_cell) == Vector2(192, 256), "terrain cell origin uses 64px spacing")
	_check(WorldMetrics.terrain_cell_to_center(metric_cell) == Vector2(224, 288), "terrain cell center uses a 32px half-cell")
	_check(WorldMetrics.world_to_terrain_cell(Vector2(224, 288)) == metric_cell, "world-to-terrain conversion round-trips at a cell center")
	_check(WorldMetrics.world_to_navigation_cell(Vector2(63, 63)) == Vector2i(1, 1), "world-to-navigation conversion remains 32px")
	var player_controller_source := FileAccess.get_file_as_string("res://scenes/actors/player/player_controller.gd")
	_check(player_controller_source.contains("return WorldMetrics.world_to_terrain_cell(local_position)"), "environment interactions sample native 64px terrain cells")
	_check(WorldMetrics.terrain_coverage_for_rect(Rect2(0, 0, 129, 65)) == Vector2i(3, 2), "terrain coverage rounds up by native cell")
	_check(WorldMetrics.snap_visual_to_pixel(Vector2(4.4, 8.6)) == Vector2(4, 9), "visual positions snap to whole pixels")
	_check(DepthSort.DEPTH_SCALE > 0.0 and DepthSort.depth_for_world_y(100.0) < DepthSort.depth_for_world_y(200.0), "world depth sorting is monotonic from the authored ground Y")
	var actor_visual_source := FileAccess.get_file_as_string("res://scenes/actors/shared/actor_visual.gd")
	_check(actor_visual_source.contains("func depth_anchor_world_y()"), "actors expose an authored feet depth anchor")
	_check(actor_visual_source.contains("_depth_anchor_offset_y"), "actor depth uses a cached canvas feet offset")
	var actor_presentation_source := FileAccess.get_file_as_string("res://scenes/actors/actor_presentation_controller.gd")
	_check(actor_presentation_source.contains("enemy_position.y + _depth_anchor_offset_y(visual)"), "enemy visuals use their cached feet depth anchor")
	_check(actor_presentation_source.contains("p_position.y + _depth_anchor_offset_y(player_visual)"), "player visual uses its cached feet depth anchor")
	var depth_sort_source := FileAccess.get_file_as_string("res://scenes/world/world_depth_sort_controller.gd")
	_check(depth_sort_source.contains("_is_depth_sort_host(parent)"), "depth sorting ignores fixed presentation-host z offsets")
	_check(depth_sort_source.contains("\"AuthoredComposition\""), "depth sorting recognizes the authored meadow composition host")
	var game_root_source := FileAccess.get_file_as_string("res://scenes/app/game_root.tscn")
	_check(game_root_source.contains("z_index = 3000") and game_root_source.contains("z_index = 3200"), "combat and effects hosts remain above the shared world depth range")
	var generated_region := RegionGenerator.new().generate_blackthorn(41041)
	_check(int(generated_region.get("grid_version", 0)) == 64, "generated region declares grid version 64")
	_check(int(generated_region.get("tile_size", 0)) == 64, "generated region declares a 64px tile size")
	_check(generated_region.get("size_tiles", Vector2i.ZERO) == Vector2i(18, 39), "generated region reports 18x39 cells")
	_check(generated_region.get("pixel_size", Vector2i.ZERO) == Vector2i(1152, 2496), "generated region reports 1152x2496 pixels")
	var legacy_preview := load("res://scenes/world/terrain/biome_preview_blackthorn.tscn") as PackedScene
	_check(legacy_preview != null, "Legacy biome preview bookmark remains loadable")
	if legacy_preview != null:
		var legacy_instance := legacy_preview.instantiate()
		_check(legacy_instance.get_node_or_null("Terrain") != null and legacy_instance.get_node_or_null("AuthoredComposition") != null, "Legacy biome preview is only a compatibility alias to the canonical composition")
		legacy_instance.free()
	var presentation_source := FileAccess.get_file_as_string("res://scenes/app/presentation_controller.gd")
	_check(presentation_source.contains("BlackthornMoorPreviewScene.instantiate()"), "Runtime mounts the canonical Blackthorn Moor preview scene")
	_check(not presentation_source.contains("WorldPresentationScene.instantiate()"), "Runtime does not mount a second meadow presentation scene")
	_check(not presentation_source.contains("BlackthornWorldArtScene.instantiate()"), "Runtime does not mount a second meadow art scene")
	var terrain_source := FileAccess.get_file_as_string("res://scenes/world/terrain/terrain_layer.gd")
	_check(not terrain_source.contains("terrain_art_mode"), "legacy terrain art switch is removed")
	_check(not terrain_source.contains("blackthorn_tileset"), "legacy 32px tileset property is removed")
	_check(not terrain_source.contains("base_tiles.scale =") and not terrain_source.contains("water_fill.scale =") and not terrain_source.contains("meadow_shadows.scale =") and not terrain_source.contains("meadow_composition.scale ="), "runtime terrain binding does not overwrite authored layer scales")
	_check(not terrain_source.contains("\n\tbase_tiles.tile_set =") and not terrain_source.contains("water_fill.visible = true") and not terrain_source.contains("meadow_shadows.visible = true"), "runtime terrain binding does not replace authored TileSets or visibility")
	var terrain_scene_source := FileAccess.get_file_as_string("res://scenes/world/terrain/blackthorn_terrain.tscn")
	_check(not terrain_scene_source.contains("MacroField") and not terrain_scene_source.contains("BridgeTiles") and not terrain_scene_source.contains("OverlayTiles"), "canonical terrain scene has one native visual path")
	var runtime_manifest := FileAccess.get_file_as_string("res://assets/runtime/asset_manifest.json")
	_check(not runtime_manifest.contains("res://scenes/world/terrain/blackthorn_tileset.tres"), "runtime manifest has no archived 32px TileSet owner")
	_check(runtime_manifest.contains("res://scenes/world/terrain/meadow_tileset_64.tres"), "runtime manifest points world ownership at the native 64px TileSet")
	var tile_set := load("res://scenes/world/terrain/blackthorn_tileset_64.tres") as TileSet
	_check(tile_set != null and tile_set.tile_size == Vector2i(64, 64), "Blackthorn production TileSet uses native 64px cells")
	_check(tile_set != null and tile_set.get_physics_layers_count() == 1, "Blackthorn TileSet owns its authored blocker physics layer")
	if tile_set != null:
		var atlas := tile_set.get_source(0) as TileSetAtlasSource
		for row: int in [6, 7]:
			for column: int in 6:
				var tile_data := atlas.get_tile_data(Vector2i(column, row), 0)
				_check(tile_data != null and tile_data.get_collision_polygons_count(0) == 1, "blocking tile %d,%d owns collision" % [column, row])
	for tier: int in 5:
		var path: String = "res://scenes/world/camp/camp_tier_%d.tscn" % tier
		var camp_scene := load(path) as PackedScene
		_check(camp_scene != null, "%s loads as an authored camp tier scene" % path)
		if camp_scene == null:
			continue
		var camp := camp_scene.instantiate() as AshenCampRuntime
		_check(camp != null, "%s instantiates as the runtime camp scene" % path)
		if camp == null:
			continue
		camp.bind_state(tier, {}, {})
		var ground := camp.get_node_or_null("Ground") as TileMapLayer
		_check(ground != null, "%s owns its native 64px ground TileMap" % path)
		if ground != null:
			_check(ground.scale == Vector2.ONE, "%s ground stays at authored scale 1" % path)
			var expected_ground_position := Vector2(411, 282) if tier == 0 else Vector2.ZERO
			_check(ground.position == expected_ground_position, "%s ground keeps its authored position" % path)
			_check(ground.tile_set != null and ground.tile_set.tile_size == Vector2i(64, 64), "%s ground uses a 64px TileSet" % path)
			_check(not ground.visible, "%s legacy enclosed camp-floor background is hidden" % path)
			_check(bool(ground.get_meta("native64_migrated", false)), "%s records the native64 migration marker" % path)
		_check(camp.camp_bounds_world().has_area(), "%s owns authored bounds" % path)
		_check(camp.get_node_or_null("IslandBounds") != null and camp.camp_boundary_polygon_world().size() >= 8, "%s owns an editable open-island boundary" % path)
		_check(camp.safe_zone_polygon_world().size() >= 3, "%s owns a gate safe zone" % path)
		_check(camp.no_spawn_polygon_world().size() >= 3, "%s owns a no-spawn zone" % path)
		_check(camp.gate_transition_polygon_world().size() >= 3, "%s owns a gate transition polygon" % path)
		var gate := camp.get_node_or_null("Gate")
		_check(gate != null and gate.get_node_or_null("Prompt") != null, "%s gate owns its visual transition prompt" % path)
		for id: String in ["veterans_hall", "campfire"]:
			var info: Dictionary = camp.structure_info(id)
			_check(PackedVector2Array(info.get("footprint", PackedVector2Array())).size() >= 3, "%s %s owns collision" % [path, id])
			_check(PackedVector2Array(info.get("interaction", PackedVector2Array())).size() >= 3, "%s %s owns interaction" % [path, id])
		camp.free()
	print("World scene guards: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("WORLD SCENE FAIL: %s" % message)
