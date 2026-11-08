extends PanelContainer

signal slot_tapped(slot_index: int)
signal slot_dropped(from_slot: int, to_slot: int)

@export var slot_index: int = -1

var vbox: VBoxContainer
var portrait: TextureRect
var name_label: Label
var level_label: Label
var selection_border: Panel
var placeholder: TextureRect
var slot_number_label: Label

var is_selected: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	vbox = VBoxContainer.new()
	add_child(vbox)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(48, 48)
	vbox.add_child(portrait)
	slot_number_label = Label.new()
	slot_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_number_label)
	name_label = Label.new()
	vbox.add_child(name_label)
	level_label = Label.new()
	vbox.add_child(level_label)
	placeholder = TextureRect.new()
	placeholder.visible = false
	vbox.add_child(placeholder)
	selection_border = Panel.new()
	selection_border.visible = false
	add_child(selection_border)
	_update_slot_number()

func _update_slot_number() -> void:
	if slot_number_label:
		slot_number_label.text = str(slot_index + 1)

func setup_empty() -> void:
	portrait.visible = false
	name_label.text = ""
	level_label.text = ""
	placeholder.visible = true

func setup_character(char_index: int) -> void:
	placeholder.visible = false
	portrait.visible = true
	if char_index >= 0 and char_index < GameData.CHARACTERS.size():
		var c = GameData.CHARACTERS[char_index]
		name_label.text = str(c.get("name", ""))
		level_label.text = "Lv.%d" % int(GameData.hero_levels.get(char_index, 1))
	else:
		setup_empty()

func set_selected(value: bool) -> void:
	is_selected = value
	if selection_border:
		selection_border.visible = value

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_tapped.emit(slot_index)
		accept_event()

func _get_drag_data(_pos: Vector2) -> Variant:
	if slot_index < 0:
		return null
	var preview = duplicate()
	set_drag_preview(preview)
	return {"type": "party_slot", "slot": slot_index}

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "party_slot"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if data is Dictionary:
		slot_dropped.emit(int(data.get("slot", -1)), slot_index)