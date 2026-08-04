extends SceneTree

const StructureScript = preload("res://scenes/world/structures/structure_visual.gd")
const CampRuntimeScript = preload("res://scenes/world/camp/camp_runtime.gd")
const BuildingSlotScript = preload("res://scenes/world/camp/building_slot.gd")
const CampfireScene = preload("res://scenes/world/structures/campfire.tscn")
const TileSetResource = preload("res://scenes/world/terrain/blackthorn_tileset.tres")

const BUILDING_TIERS := {"veterans_hall": 5, "armory": 4, "blacksmith": 4, "quartermaster": 4, "training": 6}
var FOOTPRINTS := {
	"veterans_hall": PackedVector2Array([Vector2(-42, -22), Vector2(42, -22), Vector2(42, 0), Vector2(-42, 0)]),
	"armory": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
	"quartermaster": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
	"blacksmith": PackedVector2Array([Vector2(-50, -29), Vector2(50, -29), Vector2(50, 0), Vector2(-50, 0)]),
	"training": PackedVector2Array([Vector2(-52, -70), Vector2(52, -70), Vector2(52, 0), Vector2(-52, 0)]),
}
var INTERACTION := PackedVector2Array([Vector2(-70, -45), Vector2(70, -45), Vector2(70, 44), Vector2(-70, 44)])
const CAMP_BOUNDS := [
	Rect2(415, 105, 340, 480), Rect2(395, 80, 380, 530), Rect2(375, 55, 420, 580),
	Rect2(350, 30, 470, 630), Rect2(325, 5, 520, 680),
]
const PROP_IDS := ["barrels", "crates", "firewood", "drying_rack", "weapon_rack", "banner", "brazier", "handcart"]


func _initialize() -> void:
	for path: String in ["res://scenes/world/structures", "res://scenes/world/props", "res://scenes/world/camp"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	_build_structures()
	_build_props()
	_build_vegetation()
	_build_palisade_segment()
	_build_gate()
	_build_plot()
	for tier: int in 5:
		_build_camp(tier)
	quit()


func _build_structures() -> void:
	for building_id: String in BUILDING_TIERS:
		for tier: int in int(BUILDING_TIERS[building_id]):
			var texture_path := "res://assets/runtime/structures/%s_%d.png" % [building_id, tier]
			var outline_path := "res://assets/runtime/structures/outlines/%s_%d.png" % [building_id, tier]
			_save_structure(building_id, tier, texture_path, outline_path, FOOTPRINTS[building_id], INTERACTION, 112.0)


func _save_structure(id: String, tier: int, texture_path: String, outline_path: String, footprint: PackedVector2Array, interaction: PackedVector2Array, draw_height: float) -> void:
	var texture := load(texture_path) as Texture2D
	var outline_texture := load(outline_path) as Texture2D
	if texture == null or outline_texture == null:
		push_error("Missing canonical structure art: %s or %s" % [texture_path, outline_path])
		return
	var root := Node2D.new()
	root.name = "%sTier%d" % [id.to_pascal_case(), tier]
	root.set_script(StructureScript)
	root.set("structure_id", id)
	root.set("tier", tier)
	var scale_value: float = draw_height / maxf(1.0, texture.get_height())
	var main := Sprite2D.new()
	main.name = "MainVisual"
	main.texture = texture
	main.centered = false
	main.position = Vector2(-texture.get_width() * scale_value * 0.5, -texture.get_height() * scale_value)
	main.scale = Vector2.ONE * scale_value
	_add_owned(root, main)
	var outline := Sprite2D.new()
	outline.name = "Outline"
	outline.texture = outline_texture
	outline.centered = false
	outline.position = main.position
	outline.scale = main.scale
	outline.visible = false
	outline.z_index = 2
	_add_owned(root, outline)
	_add_collision_polygon(root, "StaticBody2D", footprint, false)
	_add_collision_polygon(root, "InteractionArea", interaction, true)
	_add_collision_polygon(root, "TouchArea", interaction, true)
	_save_scene(root, "res://scenes/world/structures/%s_tier_%d.tscn" % [id, tier])


func _build_props() -> void:
	for id: String in PROP_IDS:
		var texture_path := "res://assets/runtime/props/%s.png" % id
		var texture := load(texture_path) as Texture2D
		if texture == null:
			push_error("Missing canonical prop art: %s" % texture_path)
			continue
		var root := Node2D.new()
		root.name = id.to_pascal_case()
		var sprite := Sprite2D.new()
		sprite.name = "MainVisual"
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		_add_owned(root, sprite)
		var half_width: float = minf(30.0, texture.get_width() * 0.36)
		var depth: float = minf(24.0, texture.get_height() * 0.25)
		_add_collision_polygon(root, "StaticBody2D", PackedVector2Array([Vector2(-half_width, -depth), Vector2(half_width, -depth), Vector2(half_width, 0), Vector2(-half_width, 0)]), false)
		_save_scene(root, "res://scenes/world/props/%s.tscn" % id)


func _build_vegetation() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/world/vegetation"))
	for index: int in 4:
		var texture := load("res://assets/runtime/world/forest_cluster_%d.png" % index) as Texture2D
		if texture == null:
			push_error("Missing canonical forest cluster %d" % index)
			continue
		var root := Node2D.new(); root.name = "TreeVariant%02d" % (index + 1)
		var sprite := Sprite2D.new(); sprite.name = "MainVisual"; sprite.texture = texture; sprite.centered = false; sprite.position = Vector2(-texture.get_width() * 0.5, -texture.get_height()); _add_owned(root, sprite)
		_add_collision_polygon(root, "StaticBody2D", PackedVector2Array([Vector2(-13,-18), Vector2(13,-18), Vector2(13,0), Vector2(-13,0)]), false)
		_save_scene(root, "res://scenes/world/vegetation/tree_variant_%02d.tscn" % (index + 1))


func _build_palisade_segment() -> void:
	var texture := load("res://assets/runtime/world/wall_pole.png") as Texture2D
	var root := Node2D.new()
	root.name = "PalisadeSegment"
	var sprite := Sprite2D.new()
	sprite.name = "MainVisual"
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(-8, -64)
	sprite.scale = Vector2(16.0 / texture.get_width(), 64.0 / texture.get_height())
	_add_owned(root, sprite)
	_add_collision_polygon(root, "StaticBody2D", PackedVector2Array([Vector2(-7, -12), Vector2(7, -12), Vector2(7, 4), Vector2(-7, 4)]), false)
	_save_scene(root, "res://scenes/world/camp/palisade_segment.tscn")


func _build_gate() -> void:
	var texture := load("res://assets/runtime/world/town_gate.png") as Texture2D
	var root := Node2D.new()
	root.name = "Gate"
	var sprite := Sprite2D.new()
	sprite.name = "MainVisual"
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(-64, -48)
	sprite.scale = Vector2(128.0 / texture.get_width(), 80.0 / texture.get_height())
	_add_owned(root, sprite)
	var body := StaticBody2D.new()
	body.name = "StaticBody2D"
	_add_owned(root, body)
	for side: float in [-1.0, 1.0]:
		var collision := CollisionPolygon2D.new()
		collision.name = "LeftPost" if side < 0 else "RightPost"
		var center_x: float = side * 53.0
		collision.polygon = PackedVector2Array([Vector2(center_x - 10, -18), Vector2(center_x + 10, -18), Vector2(center_x + 10, 8), Vector2(center_x - 10, 8)])
		_add_owned(body, collision, root)
	_save_scene(root, "res://scenes/world/camp/gate.tscn")


func _build_plot() -> void:
	var texture := load("res://assets/runtime/structures/construction_plot.png") as Texture2D
	var outline_texture := load("res://assets/runtime/structures/construction_plot_outline.png") as Texture2D
	var root := Node2D.new()
	root.name = "ConstructionPlot"
	root.set_script(StructureScript)
	root.set("structure_id", "construction_plot")
	var scale_value: float = 76.0 / maxf(1.0, texture.get_height())
	for data: Dictionary in [{"name":"MainVisual", "texture":texture, "visible":true}, {"name":"Outline", "texture":outline_texture, "visible":false}]:
		var sprite := Sprite2D.new()
		sprite.name = data.name
		sprite.texture = data.texture
		sprite.centered = false
		sprite.position = Vector2(-texture.get_width() * scale_value * 0.5, -texture.get_height() * scale_value)
		sprite.scale = Vector2.ONE * scale_value
		sprite.visible = data.visible
		_add_owned(root, sprite)
	_add_collision_polygon(root, "InteractionArea", PackedVector2Array([Vector2(-70, -48), Vector2(70, -48), Vector2(70, 48), Vector2(-70, 48)]), true)
	_add_collision_polygon(root, "TouchArea", PackedVector2Array([Vector2(-70, -48), Vector2(70, -48), Vector2(70, 48), Vector2(-70, 48)]), true)
	_save_scene(root, "res://scenes/world/camp/construction_plot.tscn")


func _build_camp(tier: int) -> void:
	var root := Node2D.new()
	root.name = "CampTier%d" % tier
	root.set_script(CampRuntimeScript)
	root.set("camp_tier", tier)
	root.y_sort_enabled = true
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = TileSetResource
	ground.z_index = -20
	_add_owned(root, ground)
	var bounds: Rect2 = CAMP_BOUNDS[tier]
	for y: int in range(floori(bounds.position.y / 32.0), ceili(bounds.end.y / 32.0)):
		for x: int in range(floori(bounds.position.x / 32.0), ceili(bounds.end.x / 32.0)):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(posmod(x + y, 6), 5))
	var back_vegetation := Node2D.new(); back_vegetation.name = "BackVegetation"; _add_owned(root, back_vegetation)
	var back_wall := Node2D.new(); back_wall.name = "BackWall"; _add_owned(root, back_wall)
	var structures := Node2D.new(); structures.name = "Structures"; _add_owned(root, structures)
	var hall_anchor := Node2D.new(); hall_anchor.name = "VeteransHallAnchor"; hall_anchor.position = Vector2(592, 207); hall_anchor.z_index = roundi(hall_anchor.position.y); _add_owned(structures, hall_anchor, root)
	var hall_scene := load("res://scenes/world/structures/veterans_hall_tier_%d.tscn" % tier) as PackedScene
	var hall_content := hall_scene.instantiate() as Node2D; hall_content.name = "Content"; hall_content.set_meta("scene_path", hall_scene.resource_path); _add_owned(hall_anchor, hall_content, root)
	var fire_anchor := Node2D.new(); fire_anchor.name = "CampfireAnchor"; fire_anchor.position = Vector2(588, 452); fire_anchor.z_index = roundi(fire_anchor.position.y); _add_owned(structures, fire_anchor, root)
	var fire := CampfireScene.instantiate(); fire.name = "Content"; _add_owned(fire_anchor, fire, root)
	var slots := Node2D.new(); slots.name = "BuildingSlots"; _add_owned(root, slots)
	var slot_positions := [Vector2(460,335), Vector2(710,335), Vector2(460,470), Vector2(710,470)]
	for index: int in 4:
		var plot_scene := load("res://scenes/world/camp/construction_plot.tscn") as PackedScene
		var slot := Node2D.new(); slot.name = "Slot%02d" % (index + 1); slot.position = slot_positions[index]; slot.z_index = roundi(slot.position.y); slot.set_script(BuildingSlotScript); slot.set("slot_id", "plot_%d" % (index + 1)); slot.set("construction_plot_scene", plot_scene); slot.visible = index < tier; _add_owned(slots, slot, root)
		if index < tier:
			var plot_content := plot_scene.instantiate() as Node2D; plot_content.name = "Content"; plot_content.set_meta("scene_path", plot_scene.resource_path); _add_owned(slot, plot_content, root)
	var props := Node2D.new(); props.name = "Props"; _add_owned(root, props)
	var prop_positions := {"barrels":Vector2(666,194), "crates":Vector2(724,154), "firewood":Vector2(460,425), "drying_rack":Vector2(450,165), "banner":Vector2(469,297), "weapon_rack":Vector2(715,366)}
	for prop_id: String in prop_positions:
		var prop_scene := load("res://scenes/world/props/%s.tscn" % prop_id) as PackedScene
		if prop_scene == null:
			continue
		var prop := prop_scene.instantiate() as Node2D; prop.name = prop_id.to_pascal_case(); prop.position = prop_positions[prop_id]; prop.z_index = roundi(prop.position.y); _add_owned(props, prop, root)
	var actor_space := Node2D.new(); actor_space.name = "ActorSpace"; actor_space.y_sort_enabled = true; _add_owned(root, actor_space)
	var front_wall := Node2D.new(); front_wall.name = "FrontWall"; _add_owned(root, front_wall)
	var front_vegetation := Node2D.new(); front_vegetation.name = "FrontVegetation"; _add_owned(root, front_vegetation)
	var gate := (load("res://scenes/world/camp/gate.tscn") as PackedScene).instantiate(); gate.name = "Gate"; gate.position = Vector2(585, 585); gate.z_index = roundi(gate.position.y); _add_owned(root, gate)
	var camp_bounds := Polygon2D.new(); camp_bounds.name = "CampBounds"; camp_bounds.visible = false; camp_bounds.polygon = PackedVector2Array([bounds.position, Vector2(bounds.end.x,bounds.position.y), bounds.end, Vector2(bounds.position.x,bounds.end.y)]); _add_owned(root, camp_bounds)
	_add_area(root, "SafeZone", PackedVector2Array([bounds.position, Vector2(bounds.end.x,bounds.position.y), bounds.end, Vector2(bounds.position.x,bounds.end.y)]))
	_add_area(root, "NoSpawnZone", PackedVector2Array([bounds.position, Vector2(bounds.end.x,bounds.position.y), bounds.end, Vector2(bounds.position.x,bounds.end.y)]))
	var markers := Node2D.new(); markers.name = "CameraMarkers"; _add_owned(root, markers)
	for data: Dictionary in [{"name":"Center", "position":bounds.get_center()}, {"name":"Gate", "position":Vector2(bounds.get_center().x,bounds.end.y)}]:
		var marker := Marker2D.new(); marker.name = data.name; marker.position = data.position; _add_owned(markers, marker, root)
	_populate_walls(root, back_wall, front_wall, bounds, Vector2(585,585))
	_populate_forest(root, back_vegetation, bounds, tier)
	_save_scene(root, "res://scenes/world/camp/camp_tier_%d.tscn" % tier)


func _populate_forest(root: Node2D, parent: Node2D, bounds: Rect2, tier: int) -> void:
	var anchors: Array[Vector2] = []
	for x: float in _axis_positions(bounds.position.x - 12.0, bounds.end.x + 12.0, 48.0):
		anchors.append(Vector2(x, bounds.position.y - 18.0))
	for side_x: float in [bounds.position.x - 28.0, bounds.end.x + 28.0]:
		for y: float in _axis_positions(bounds.position.y + 16.0, bounds.end.y - 14.0, 45.0):
			anchors.append(Vector2(side_x, y))
	# A deterministic, irregular half-density outer line. The southern gate and
	# wall remain clear exactly as required by the approved Refuge composition.
	for index: int in anchors.size():
		if posmod(index * 7 + tier * 3, 5) in [0, 2]:
			var anchor: Vector2 = anchors[index]
			anchor += (anchor - bounds.get_center()).normalized() * 42.0
			anchors.append(anchor)
	var scenes: Array[PackedScene] = [load("res://scenes/world/vegetation/tree_variant_01.tscn"), load("res://scenes/world/vegetation/tree_variant_02.tscn"), load("res://scenes/world/vegetation/tree_variant_03.tscn"), load("res://scenes/world/vegetation/tree_variant_04.tscn")]
	for index: int in anchors.size():
		var tree := scenes[posmod(index * 3 + tier, scenes.size())].instantiate() as Node2D
		tree.name = "Tree%03d" % index
		tree.position = anchors[index]
		tree.z_index = roundi(tree.position.y)
		_add_owned(parent, tree, root)


func _populate_walls(root: Node2D, back: Node2D, front: Node2D, bounds: Rect2, gate_position: Vector2) -> void:
	var segment_scene := load("res://scenes/world/camp/palisade_segment.tscn") as PackedScene
	var rear_y: float = bounds.position.y + 32.0
	var front_y: float = bounds.end.y + 32.0
	for x: float in _axis_positions(bounds.position.x, bounds.end.x, 12.0):
		_add_wall_instance(root, back, segment_scene, Vector2(x, rear_y))
	for side_x: float in [bounds.position.x, bounds.end.x]:
		for y: float in _axis_positions(rear_y, front_y, 20.0):
			_add_wall_instance(root, back, segment_scene, Vector2(side_x, y))
	for x: float in _axis_positions(bounds.position.x, gate_position.x - 44.0, 12.0):
		_add_wall_instance(root, front, segment_scene, Vector2(x, front_y))
	for x: float in _axis_positions(gate_position.x + 44.0, bounds.end.x, 12.0):
		_add_wall_instance(root, front, segment_scene, Vector2(x, front_y))


func _add_wall_instance(root: Node2D, parent: Node2D, scene: PackedScene, position: Vector2) -> void:
	var instance := scene.instantiate() as Node2D
	instance.name = "Pole%03d" % parent.get_child_count()
	instance.position = position
	instance.z_index = roundi(position.y)
	_add_owned(parent, instance, root)


func _axis_positions(start_value: float, end_value: float, spacing: float) -> Array[float]:
	var intervals: int = maxi(1, roundi((end_value - start_value) / spacing))
	var result: Array[float] = []
	for index: int in intervals + 1:
		result.append(lerpf(start_value, end_value, float(index) / intervals))
	return result


func _add_collision_polygon(root: Node2D, parent_name: String, polygon: PackedVector2Array, area: bool) -> void:
	var parent: Node2D = Area2D.new() if area else StaticBody2D.new()
	parent.name = parent_name
	_add_owned(root, parent)
	var collision := CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	collision.polygon = polygon
	_add_owned(parent, collision, root)


func _add_area(root: Node2D, area_name: String, polygon: PackedVector2Array) -> void:
	var area := Area2D.new(); area.name = area_name; _add_owned(root, area)
	var collision := CollisionPolygon2D.new(); collision.name = "CollisionPolygon2D"; collision.polygon = polygon; _add_owned(area, collision, root)


func _add_owned(parent: Node, child: Node, owner_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = owner_root if owner_root != null else parent


func _save_scene(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Unable to pack %s" % path)
		return
	if ResourceSaver.save(packed, path) != OK:
		push_error("Unable to save %s" % path)
	root.free()
