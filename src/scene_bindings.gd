class_name AshenSceneBindings
extends RefCounted

## Resilient bindings for authored runtime scenes.
##
## Visual scenes are deliberately editable: a node may be moved or reparented
## without invalidating a long NodePath stored in code.  Runtime scripts bind
## by stable role/name and treat missing optional artwork as absent instead of
## crashing.  Required functional controls produce one clear warning and let
## the rest of the scene continue running.

static var _reported_missing: Dictionary = {}


static func find(root: Node, role: StringName, recursive: bool = true) -> Node:
	if root == null or role.is_empty():
		return null
	if root.name == role:
		return root
	return root.find_child(String(role), recursive, false)


static func optional(root: Node, role: StringName) -> Node:
	return find(root, role, true)


static func required(root: Node, role: StringName, owner_label: String = "authored scene") -> Node:
	var node: Node = find(root, role, true)
	if node != null:
		return node
	var root_path: String = String(root.scene_file_path) if root != null else "<freed root>"
	var key: String = "%s|%s|%s" % [root_path, owner_label, role]
	if not _reported_missing.has(key):
		_reported_missing[key] = true
		push_warning("%s is missing functional node '%s' in %s. The scene will stay open, but that specific action is unavailable until the node is restored." % [owner_label, role, root_path])
	return null


static func connect_pressed(button: BaseButton, callable: Callable) -> void:
	if button != null and not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


static func connect_toggled(button: BaseButton, callable: Callable) -> void:
	if button != null and not button.toggled.is_connected(callable):
		button.toggled.connect(callable)

