class_name AshenWorldDepthSortController
extends Node

## Keeps world-space presentation ordered by authored ground anchors.
##
## The world is split into separate hosts for terrain, camp, actors, and
## authored meadow dressing. Godot's y-sort cannot compare descendants of
## those sibling hosts, so this controller assigns an absolute z-index to the
## roots that own a ground anchor. Internal visual children keep their local
## z offsets (roofs, flames, shadows, and foreground pieces) and therefore
## remain editable in their source scenes.

# World roots are sorted in one shared z range.  A half-pixel of z depth is
# enough to preserve the north/south order while leaving headroom for the
# combat/effect hosts above the world (the map is several thousand pixels
# tall).  Do not use the old 4x value here: it quickly reaches the renderer's
# z range and makes distant actors stop sorting correctly.
const DEPTH_SCALE: float = 0.5

var _world_root: Node2D
var _sorted_roots: Array[Node2D] = []
var _dynamic_roots: Array[Node2D] = []
var _anchor_offsets: Dictionary = {}
var _layer_offsets: Dictionary = {}
var _authored_z_offsets: Dictionary = {}
var _texture_frame_bounds: Dictionary = {}
var _tree_dirty: bool = true


func _ready() -> void:
	_world_root = get_parent() as Node2D
	# Do not subscribe to SceneTree.tree_changed. Projectile/effect pools add
	# nodes throughout a run, and every one used to trigger a complete rescan of
	# all meadow vegetation and camp art on the following frame. Static world
	# owners explicitly request a rebuild when their composition changes.
	set_process(true)


func _mark_tree_dirty() -> void:
	_tree_dirty = true


func request_rebuild() -> void:
	_tree_dirty = true


func _process(_delta: float) -> void:
	if not is_instance_valid(_world_root):
		return
	if _tree_dirty:
		_rebuild_sorted_roots()
		_tree_dirty = false
		_sync_sorted_roots(_sorted_roots)
		return
	# Camp structures and authored meadow dressing never move during a frame.
	# Rewriting their z-index at 60 Hz was pure CPU/CanvasItem churn. Only the
	# small dynamic landmark branch needs a continuing depth refresh; actor
	# visuals already update their own absolute ground depth when synchronized.
	_sync_sorted_roots(_dynamic_roots)


## Public so deterministic scene/runtime parity checks can force one sync
## without waiting for a frame.
func sync_now() -> void:
	if not is_instance_valid(_world_root):
		return
	if _tree_dirty:
		_rebuild_sorted_roots()
		_tree_dirty = false
	_sync_sorted_roots(_sorted_roots)


func _rebuild_sorted_roots() -> void:
	_sorted_roots.clear()
	_dynamic_roots.clear()
	_anchor_offsets.clear()
	_layer_offsets.clear()
	_authored_z_offsets.clear()

	# Camp tiers place physical roots in authored layer containers. Sorting the
	# layer children (rather than their sprites) keeps each object's artwork,
	# collision, interaction, and foreground children together.
	var camp := AshenSceneBindings.optional(_world_root, &"ActiveCampTier") as Node2D
	if camp != null:
		for layer_name: String in ["BackVegetation", "BackWall", "LeftWall", "RightWall", "FrontWall", "Structures", "BuildingSlots", "Props", "FrontVegetation", "Gate"]:
			var layer := AshenSceneBindings.optional(camp, StringName(layer_name)) as Node2D
			if layer == null:
				continue
			for child: Node in layer.get_children():
				_add_root(child as Node2D)

	# Actors are deliberately omitted here. The actor presentation controller
	# owns their authored feet anchor and assigns their absolute z whenever it
	# synchronizes movement, avoiding a second complete actor pass each frame.

	# Meadow dressing uses authored Sprite2D / AnimatedSprite2D nodes. Sorting
	# those leaf visuals by their authored anchor lets a south-side tree or prop
	# cover a north-side one and also compare correctly with the player/camp roots.
	var composition := AshenSceneBindings.optional(_world_root, &"AuthoredComposition") as Node2D
	if composition != null:
		_collect_authored_visuals(composition, true)

	# Dynamic meadow presentation lives in a separate sibling branch from the
	# authored dressing. Include its gate and lightweight landmark markers in
	# the same depth range so they can be crossed naturally by the player.
	var world_presentation := AshenSceneBindings.optional(_world_root, &"WorldPresentation") as Node2D
	if world_presentation != null:
		_add_root(AshenSceneBindings.optional(world_presentation, &"FrontierGate") as Node2D, false, true)
		var landmark_host := AshenSceneBindings.optional(world_presentation, &"Landmarks") as Node2D
		if landmark_host != null:
			for child: Node in landmark_host.get_children():
				_add_root(child as Node2D, false, true)


func _add_root(node: Node2D, preserve_authored_z: bool = false, dynamic: bool = false) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node == self or _sorted_roots.has(node):
		return
	_sorted_roots.append(node)
	if dynamic:
		_dynamic_roots.append(node)
	# Cache the visual's authored ground offset once. Camp and actor roots are
	# already positioned at their feet, while a standalone world Sprite2D uses
	# the bottom of its authored canvas as its depth anchor.
	if node is Sprite2D or node is AnimatedSprite2D:
		_anchor_offsets[node] = _visual_anchor_offset(node)
	else:
		_anchor_offsets[node] = Vector2.ZERO
	if not _authored_z_offsets.has(node):
		_authored_z_offsets[node] = _authored_parent_z(node, preserve_authored_z)
	_layer_offsets[node] = int(node.get_meta("depth_sort_offset", 0)) + int(_authored_z_offsets.get(node, 0))


func _collect_authored_visuals(node: Node, preserve_authored_z: bool = true, dynamic: bool = false) -> void:
	for child: Node in node.get_children():
		# Reusable physical scenes own a ground anchor on their root.  Sorting a
		# child sprite by its transparent canvas (or opaque alpha bounds) makes a
		# tall tree switch depth around its trunk instead of at the authored
		# foundation.  Keep the whole scene together so artwork, collision,
		# interaction, and foreground layers cross the player at the same line.
		if child is Node2D and _has_physical_depth_anchor(child as Node2D):
			_add_root(child as Node2D, preserve_authored_z, dynamic)
			continue
		if child is Sprite2D or child is AnimatedSprite2D:
			_add_root(child as Node2D, preserve_authored_z, dynamic)
			continue
		_collect_authored_visuals(child, preserve_authored_z, dynamic)


func _has_physical_depth_anchor(node: Node2D) -> bool:
	if bool(node.get_meta("depth_sort_root", false)):
		return true
	# A structure/prop scene's root is the shared source of truth for its
	# physical footprint.  Do not infer this from texture dimensions.
	for body_name: StringName in [&"StaticBody2D", &"CharacterBody2D", &"AnimatableBody2D"]:
		var body := AshenSceneBindings.optional(node, body_name) as Node2D
		if body == null:
			continue
		for body_child: Node in body.get_children():
			if body_child is CollisionShape2D or body_child is CollisionPolygon2D:
				return true
	return false


func _visual_anchor_offset(node: Node2D) -> Vector2:
	var rect := Rect2()
	if node is Sprite2D:
		var sprite := node as Sprite2D
		rect = sprite.get_rect()
		# Sprite sheets often have transparent padding below the actual feet or
		# trunk.  Sorting from the full canvas makes a character stay behind a
		# tree/prop until its body has already crossed the visible base.  Use the
		# lowest authored opaque pixel for the ground line instead.  This keeps
		# the visual, collision, and depth anchor in the same place without
		# changing the sprite's authored position or scale.
		var visible_bottom := _sprite_visible_bottom(sprite)
		if visible_bottom != -INF:
			var local_top: float = sprite.offset.y - (rect.size.y * 0.5 if sprite.centered else 0.0)
			return Vector2(rect.position.x + rect.size.x * 0.5, local_top + visible_bottom)
	elif node is AnimatedSprite2D:
		rect = (node as AnimatedSprite2D).get_rect()
	if rect.size == Vector2.ZERO:
		return Vector2.ZERO
	# The bottom-center of the authored canvas is the ground line. This keeps
	# tall trees/buildings behind a character until their feet are crossed,
	# regardless of how much transparent art extends north of the anchor.
	return Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y)


func _sprite_visible_bottom(sprite: Sprite2D) -> float:
	var texture := sprite.texture
	if texture == null:
		return -INF
	var hframes: int = maxi(1, sprite.hframes)
	var vframes: int = maxi(1, sprite.vframes)
	var frame_size := texture.get_size() / Vector2(hframes, vframes)
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return -INF
	var image := texture.get_image()
	if image == null or image.is_empty():
		return -INF
	# AtlasTexture and region-enabled sprites can expose a cropped image.  If
	# the image cannot be addressed as the authored sheet, retain the previous
	# full-canvas behavior instead of guessing a frame coordinate.
	var expected_size := Vector2i(roundi(texture.get_size().x), roundi(texture.get_size().y))
	if image.get_width() != expected_size.x or image.get_height() != expected_size.y:
		return -INF
	var max_bottom: float = -INF
	var frame_count: int = hframes * vframes
	for frame_index: int in range(frame_count):
		var bounds := _texture_frame_bounds_for(texture, frame_index, hframes, vframes, image)
		var bottom: float = float(bounds.position.y + bounds.size.y) if bounds.size.y > 0 else frame_size.y
		max_bottom = maxf(max_bottom, bottom)
	return max_bottom


func _texture_frame_bounds_for(texture: Texture2D, frame_index: int, hframes: int, vframes: int, image: Image) -> Rect2i:
	var key: String = "%s:%d:%d:%d" % [str(texture.get_rid()), frame_index, hframes, vframes]
	if _texture_frame_bounds.has(key):
		return _texture_frame_bounds[key] as Rect2i
	var frame_width: int = maxi(1, int(roundi(float(image.get_width()) / float(hframes))))
	var frame_height: int = maxi(1, int(roundi(float(image.get_height()) / float(vframes))))
	var frame_x: int = (frame_index % hframes) * frame_width
	var frame_y: int = (frame_index / hframes) * frame_height
	var bottom: int = -1
	var top: int = frame_height
	var left: int = frame_width
	var right: int = -1
	for y: int in range(frame_height):
		for x: int in range(frame_width):
			if image.get_pixel(frame_x + x, frame_y + y).a <= 0.01:
				continue
			top = mini(top, y)
			bottom = maxi(bottom, y)
			left = mini(left, x)
			right = maxi(right, x)
	var result := Rect2i()
	if bottom >= 0:
		result = Rect2i(left, top, right - left + 1, bottom - top + 1)
	_texture_frame_bounds[key] = result
	return result


func _authored_parent_z(node: Node2D, include_self: bool) -> int:
	var result: int = 0
	if include_self and node.z_as_relative:
		result += node.z_index
	var parent := node.get_parent()
	while parent != null and parent != _world_root:
		# A composition instance may sit in a fixed presentation layer (for
		# example AuthoredComposition is authored at z=-90 below terrain). That
		# layer is not part of an object's north/south order. Once a leaf gets an
		# absolute z below, carrying the host's z into its depth offset pins every
		# tree/prop behind or in front of every actor. Only explicit local offsets
		# inside the authored object are allowed to participate in depth sorting.
		if parent is CanvasItem and (parent as CanvasItem).z_as_relative and not _is_depth_sort_host(parent):
			result += (parent as CanvasItem).z_index
		parent = parent.get_parent()
	return result


func _is_depth_sort_host(node: Node) -> bool:
	if bool(node.get_meta("depth_sort_host", false)):
		return true
	# Keep the rule safe for older authored scenes that predate the metadata.
	# These nodes establish a world presentation layer, not an object's local
	# foreground/background offset.
	return node.name in [
		"AuthoredComposition",
		"WorldPresentation",
		"WorldArtHost",
		"TerrainHost",
		"CampHost",
		"ActorHost",
		"CombatHost",
		"EffectsHost",
		"DebugHost",
	]


func _sync_sorted_roots(roots: Array[Node2D]) -> void:
	for index: int in range(roots.size() - 1, -1, -1):
		var root := roots[index]
		if not is_instance_valid(root) or not root.is_inside_tree():
			roots.remove_at(index)
			_sorted_roots.erase(root)
			_dynamic_roots.erase(root)
			continue
		var anchor_offset: Vector2 = _anchor_offsets.get(root, Vector2.ZERO)
		var local_y: float = _root_depth_local_y(root, anchor_offset)
		var layer_offset: int = int(_layer_offsets.get(root, root.get_meta("depth_sort_offset", 0)))
		# Absolute z is intentional: sibling hosts have their own z values, and
		# those must not add a hidden offset to the authored ground ordering.
		root.z_as_relative = false
		root.z_index = roundi(local_y * DEPTH_SCALE) + layer_offset


func _root_depth_local_y(root: Node2D, anchor_offset: Vector2) -> float:
	# Actors expose an authored feet line because their simulation position is
	# the centre of the body collider.  Use it for the same north/south rule as
	# structures; do not infer it from the actor sprite in this controller.
	if root.has_method("depth_anchor_world_y"):
		var actor_world_y: float = float(root.call("depth_anchor_world_y"))
		return actor_world_y - _world_root.global_position.y
	var anchor_world: Vector2 = root.to_global(anchor_offset)
	return _world_root.to_local(anchor_world).y


static func depth_for_world_y(world_y: float, layer_offset: int = 0) -> int:
	return roundi(world_y * DEPTH_SCALE) + layer_offset
