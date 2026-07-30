class_name AshenResourceRail
extends Control

var silver_value_label: Label
var provisions_value_label: Label
var level_value_label: Label
var health_value_label: Label
var key_value_label: Label
var health_bar: ProgressBar


func build(width: float, rail_texture: Texture2D, textures: Dictionary, fonts: Dictionary, layout: Control = null) -> void:
	name = "ResourceRail"
	var authored_size := layout.size if layout != null and layout.size.y > 0.0 else Vector2(width, 52.0)
	size = Vector2(width, authored_size.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := TextureRect.new()
	background.name = "CurrencyBarBackground"
	background.texture = rail_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_build_level_tab(fonts, layout)
	var health_icon_rect := _layout_rect(layout, "HealthIcon", Rect2(64.0, 17.0, 16.0, 16.0))
	_add_icon(textures.get("heart"), health_icon_rect.position, health_icon_rect.size, "HealthIcon")
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	var health_bar_rect := _layout_rect(layout, "HealthBar", Rect2(83.0, 12.0, 89.0, 27.0))
	health_bar.position = health_bar_rect.position
	health_bar.size = health_bar_rect.size
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_theme_stylebox_override("background", _style(Color("171514"), Color("090909")))
	health_bar.add_theme_stylebox_override("fill", _style(Color("9f2e26"), Color("d78c3b")))
	add_child(health_bar)
	health_value_label = _label("", 8, fonts)
	health_value_label.name = "HealthValueLabel"
	var health_value_rect := _layout_rect(layout, "HealthValueLabel", Rect2(83.0, 14.0, 89.0, 23.0))
	health_value_label.position = health_value_rect.position
	health_value_label.size = health_value_rect.size
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(health_value_label)

	# These coordinates are the actual interior recesses painted into the rail.
	# Keeping every icon and value within its own cell prevents the overlaps that
	# appeared on high-density iPhone screens.
	silver_value_label = _icon_value_cell("SilverCell", textures.get("silver"), Vector2(188.0, 14.0), Vector2(39.0, 22.0), "0", fonts, layout)
	silver_value_label.name = "SilverValueLabel"
	provisions_value_label = _icon_value_cell("ProvisionsCell", textures.get("provisions"), Vector2(235.0, 14.0), Vector2(45.0, 22.0), "0", fonts, layout)
	provisions_value_label.name = "ProvisionsValueLabel"
	key_value_label = _icon_value_cell("KeyCell", textures.get("key"), Vector2(289.0, 14.0), Vector2(49.0, 22.0), "0", fonts, layout)
	key_value_label.name = "BossKeyValueLabel"


func _build_level_tab(fonts: Dictionary, layout: Control = null) -> void:
	var cell := Control.new()
	cell.name = "HeroLevelCell"
	var cell_rect := _layout_rect(layout, "HeroLevelCell", Rect2(13.0, 6.0, 37.0, 40.0))
	cell.position = cell_rect.position
	cell.size = cell_rect.size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cell)
	var caption := _label("LVL", 7, fonts)
	caption.position = Vector2(0.0, 4.0)
	caption.size = Vector2(37.0, 10.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(caption)
	level_value_label = _label("1", 12, fonts)
	level_value_label.position = Vector2(0.0, 13.0)
	level_value_label.size = Vector2(37.0, 20.0)
	level_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.add_child(level_value_label)


func bind_profile(profile: Dictionary, hero: Dictionary, max_health: float) -> void:
	var level: int = int(hero.get("level", 1))
	level_value_label.text = str(level)
	health_bar.max_value = maxf(1.0, max_health)
	health_bar.value = max_health
	health_value_label.text = "%d/%d" % [ceili(max_health), ceili(max_health)]
	silver_value_label.text = str(int(profile.get("silver", 0)))
	provisions_value_label.text = str(int(profile.get("provisions", 0)))
	var keys: Dictionary = profile.get("biome_keys", {})
	key_value_label.text = str(int(keys.get("barrows_key", 0)))


func bind_run(level: int, hp: float, max_hp: float, silver: int, provisions: int, dread: int) -> void:
	level_value_label.text = str(level)
	health_bar.max_value = maxf(1.0, max_hp)
	health_bar.value = clampf(hp, 0.0, max_hp)
	health_value_label.text = "%d/%d" % [ceili(hp), ceili(max_hp)]
	silver_value_label.text = str(silver)
	provisions_value_label.text = str(provisions)
	key_value_label.text = str(dread)


func _icon_value_cell(cell_name: String, texture: Texture2D, position_value: Vector2, cell_size: Vector2, text_value: String, fonts: Dictionary, layout: Control = null) -> Label:
	var cell := Control.new()
	cell.name = cell_name
	var cell_rect := _layout_rect(layout, cell_name, Rect2(position_value, cell_size))
	cell.position = cell_rect.position
	cell.size = cell_rect.size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cell)
	var icon := TextureRect.new()
	icon.name = "SilverIcon" if cell_name == "SilverCell" else ("ProvisionsIcon" if cell_name == "ProvisionsCell" else "%sIcon" % cell_name)
	icon.texture = texture
	icon.position = Vector2.ZERO
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(15.0, 15.0)
	icon.position.y = 3.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	var value := _label(text_value, 9, fonts)
	value.position = Vector2(16.0, 0.0)
	value.size = Vector2(cell_size.x - 16.0, 22.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.add_child(value)
	return value

func _layout_rect(layout: Control, node_name: String, fallback: Rect2) -> Rect2:
	if layout == null:
		return fallback
	var node := layout.get_node_or_null(NodePath(node_name)) as Control
	if node == null:
		return fallback
	return Rect2(node.position, node.size)


func _add_icon(texture: Texture2D, position_value: Vector2, icon_size: Vector2, icon_name: String) -> void:
	var icon := TextureRect.new()
	icon.name = icon_name
	icon.texture = texture
	icon.position = position_value
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = icon_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)


func _label(text_value: String, font_size: int, fonts: Dictionary) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", fonts.get("body"))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ead9b0"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	return box
