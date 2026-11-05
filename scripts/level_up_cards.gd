class_name LevelUpCardOverlay
extends Control

signal card_selected(card_id: String)


func setup(level: int, cards: Array) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.08, 0.1, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.12
	panel.anchor_top = 0.22
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.78
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff9e9")
	panel_style.border_color = Color("#e8cb79")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var heading := _label("레벨 업!  Lv.%d" % level, 25, Color("#28313d"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var hint := _label("강화 카드 3장 중 하나를 선택하세요", 15, Color("#737d87"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	var card_list := VBoxContainer.new()
	card_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_list.add_theme_constant_override("separation", 10)
	content.add_child(card_list)
	for card in cards:
		var button := Button.new()
		button.text = "%s\n%s" % [card["name"], card["description"]]
		button.custom_minimum_size.y = 108
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color("#28313d"))
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("#fffdf5")
		card_style.border_color = card["accent"]
		card_style.set_border_width_all(3)
		card_style.set_corner_radius_all(12)
		card_style.set_content_margin_all(10)
		button.add_theme_stylebox_override("normal", card_style)
		button.add_theme_stylebox_override("hover", card_style)
		button.add_theme_stylebox_override("pressed", card_style)
		button.pressed.connect(_select_card.bind(card["id"]))
		card_list.add_child(button)


func _select_card(card_id: String) -> void:
	card_selected.emit(card_id)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
