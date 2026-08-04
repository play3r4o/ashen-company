class_name AshenRelicChoiceOverlay
extends Control

signal relic_selected(relic_id: String)

var _relic_ids: Array[String] = []


func _ready() -> void:
	for index: int in range(3):
		var button := get_node("SafeArea/Panel/Margin/Content/Choices/Choice%d" % (index + 1)) as Button
		button.pressed.connect(_on_choice_pressed.bind(index))


func bind_relics(entries: Array[Dictionary]) -> void:
	_relic_ids.clear()
	for entry: Dictionary in entries:
		_relic_ids.append(String(entry.get("id", "")))
	for index: int in range(3):
		var button := get_node("SafeArea/Panel/Margin/Content/Choices/Choice%d" % (index + 1)) as Button
		button.visible = index < entries.size()
		if not button.visible:
			continue
		var entry: Dictionary = entries[index]
		(button.get_node("Content/CardDescription") as Label).text = "%s\n%s" % [String(entry.get("name", "UNKNOWN")).to_upper(), String(entry.get("description", ""))]
		(button.get_node("Content/CardStats") as Label).text = String(entry.get("stats", ""))


func _on_choice_pressed(index: int) -> void:
	if index >= 0 and index < _relic_ids.size():
		relic_selected.emit(_relic_ids[index])
