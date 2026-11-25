extends Control

const Profile = preload("res://profile.gd")
const Duel = preload("res://duel.gd")
const ACCENT := Color("#6fe0d2")
const MUTED := Color("#a3b7c6")

var swatch := ColorRect.new()
var trim_swatch := ColorRect.new()
var status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color("#101a23")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 590
	panel.add_theme_stylebox_override("panel", panel_style())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := label("MONDIGAMES", 46, ACCENT)
	column.add_child(title)
	column.add_child(label("Offline tactical duels", 20, Color.WHITE))
	column.add_child(label("Win five rounds against a bot. On timeout, higher health wins.", 16, MUTED))
	column.add_child(HSeparator.new())
	add_option(column, "Arena", "map", Duel.MAP_NAMES)
	add_option(column, "Difficulty", "difficulty", Duel.DIFFICULTIES)
	var names: Array = []
	for palette: Array in Profile.SKINS:
		names.append(palette[0])
	var skin_row := add_option(column, "Weapon skin", "skin", names)
	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 2)
	swatch.custom_minimum_size = Vector2(40, 18)
	trim_swatch.custom_minimum_size = Vector2(12, 18)
	preview.add_child(swatch)
	preview.add_child(trim_swatch)
	skin_row.add_child(preview)
	update_skin(Profile.choice("skin", names.size()))

	column.add_child(HSeparator.new())
	var duel_button := add_button(column, "Play Duel", "res://duel.tscn")
	add_button(column, "Practice Range", "res://arena.tscn")
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(get_tree().quit)
	column.add_child(quit)
	status = label("", 15, Color("#ffc594"))
	column.add_child(status)
	duel_button.grab_focus()

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a2a36")
	style.border_color = Color("#345061")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 18
	return style

func label(value: String, size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

func add_option(column: VBoxContainer, caption: String, key: String, choices: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var description := label(caption, 17, Color.WHITE)
	description.custom_minimum_size.x = 140
	row.add_child(description)
	var options := OptionButton.new()
	options.custom_minimum_size = Vector2(210, 33)
	for choice: String in choices:
		options.add_item(choice)
	options.select(Profile.choice(key, choices.size()))
	options.item_selected.connect(func(index: int) -> void:
		var error := Profile.save_choice(key, index)
		if error != OK:
			options.select(Profile.choice(key, choices.size()))
			status.text = "Could not save this setting."
			return
		status.text = ""
		if key == "skin":
			update_skin(index)
	)
	row.add_child(options)
	column.add_child(row)
	return row

func update_skin(index: int) -> void:
	swatch.color = Color(Profile.SKINS[index][1])
	trim_swatch.color = Color(Profile.SKINS[index][2])

func add_button(column: VBoxContainer, caption: String, scene: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 41
	button.pressed.connect(func() -> void:
		if get_tree().change_scene_to_file(scene) != OK:
			status.text = "Could not load this mode."
	)
	column.add_child(button)
	return button
