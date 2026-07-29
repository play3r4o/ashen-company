class_name AshenResourceRail
extends Control

var silver_value_label: Label
var provisions_value_label: Label
var level_value_label: Label
var health_value_label: Label
var key_value_label: Label
var health_bar: ProgressBar


func build(width: float, rail_texture: Texture2D, textures: Dictionary, fonts: Dictionary) -> void:
	name = "ResourceRail"
	size = Vector2(width, 52.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := TextureRect.new()
	background.name = "CurrencyBarBackground"
	background.texture = rail_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	level_value_label = _icon_value_cell("HeroLevelCell", textures.get("level"), Vector2(12.0, 11.0), Vector2(43.0, 30.0), "1", fonts)
	_add_icon(textures.get("heart"), Vector2(61.0, 14.0), Vector2(22.0, 22.0), "HealthIcon")
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(86.0, 14.0)
	health_bar.size = Vector2(116.0, 22.0)
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_theme_stylebox_override("background", _style(Color("171514"), Color("090909")))
	health_bar.add_theme_stylebox_override("fill", _style(Color("9f2e26"), Color("d78c3b")))
	add_child(health_bar)
	health_value_label = _label("", 10, fonts)
	health_value_label.name = "HealthValueLabel"
	health_value_label.position = Vector2(86.0, 13.0)
	health_value_label.size = Vector2(116.0, 24.0)
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(health_value_label)

	silver_value_label = _icon_value_cell("SilverCell", textures.get("silver"), Vector2(211.0, 11.0), Vector2(55.0, 30.0), "0", fonts)
	silver_value_label.name = "SilverValueLabel"
	provisions_value_label = _icon_value_cell("ProvisionsCell", textures.get("provisions"), Vector2(270.0, 11.0), Vector2(58.0, 30.0), "0", fonts)
	provisions_value_label.name = "ProvisionsValueLabel"
	key_value_label = _icon_value_cell("KeyCell", textures.get("key"), Vector2(333.0, 11.0), Vector2(48.0, 30.0), "0", fonts)
	key_value_label.name = "BossKeyValueLabel"


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


func _icon_value_cell(cell_name: String, texture: Texture2D, position_value: Vector2, cell_size: Vector2, text_value: String, fonts: Dictionary) -> Label:
	var cell := Control.new()
	cell.name = cell_name
	cell.position = position_value
	cell.size = cell_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cell)
	var icon := TextureRect.new()
	icon.name = "SilverIcon" if cell_name == "SilverCell" else ("ProvisionsIcon" if cell_name == "ProvisionsCell" else "%sIcon" % cell_name)
	icon.texture = texture
	icon.position = Vector2.ZERO
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(24.0, 24.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	var value := _label(text_value, 11, fonts)
	value.position = Vector2(24.0, 1.0)
	value.size = Vector2(cell_size.x - 24.0, 24.0)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.add_child(value)
	return value


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
