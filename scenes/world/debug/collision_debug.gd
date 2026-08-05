class_name AshenCollisionDebug
extends Node2D

var line_pool: Array[Line2D] = []


func sync_geometry(enabled: bool, entries: Array) -> void:
	visible = enabled
	if not enabled:
		return
	while line_pool.size() < entries.size():
		var line := Line2D.new()
		line.width = 1.0
		line.antialiased = false
		add_child(line)
		line_pool.append(line)
	for index: int in line_pool.size():
		var line: Line2D = line_pool[index]
		if index >= entries.size():
			line.visible = false
			continue
		var entry: Dictionary = entries[index]
		line.visible = true
		line.points = entry.get("points", PackedVector2Array())
		line.default_color = entry.get("color", Color.WHITE)
		line.width = float(entry.get("width", 1.0))
