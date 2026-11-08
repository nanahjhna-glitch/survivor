extends Control

signal camera_target_slot_changed(slot_index: int)

@onready var grid: GridContainer = $MainLayout/SlotSection/Grid
@onready var char_list: HBoxContainer = $MainLayout/BottomPanel/Scroll/CharList
@onready var cancel_btn: Button = $MainLayout/BottomPanel/Buttons/CancelBtn
@onready var confirm_btn: Button = $MainLayout/BottomPanel/Buttons/ConfirmBtn

var selected_party_slot: int = -1
var slots: Array[PartySlotUI] = []

func _ready() -> void:
	cancel_btn.pressed.connect(_on_cancel)
	confirm_btn.pressed.connect(_on_confirm)
	grid.columns = 6
	_build_slots()
	_build_char_list()
	_refresh()

func _build_slots() -> void:
	for i in range(GameData.party_size):
		var s = preload("res://scripts/party_slot_ui.gd").new()
		s.slot_index = i
		s.slot_tapped.connect(_on_slot_tapped)
		s.slot_dropped.connect(_on_slot_dropped)
		grid.add_child(s)
		slots.append(s)

func _build_char_list() -> void:
	for i in range(GameData.CHARACTERS.size()):
		var btn = Button.new()
		btn.text = str(GameData.CHARACTERS[i].get("name", ""))
		btn.pressed.connect(func(): _on_char_selected(i))
		char_list.add_child(btn)

func _refresh() -> void:
	for i in range(slots.size()):
		var ci = GameData.party_characters[i] if i < GameData.party_characters.size() else -1
		if ci >= 0 and ci < GameData.CHARACTERS.size():
			slots[i].setup_character(ci)
		else:
			slots[i].setup_empty()
		slots[i].set_selected(i == selected_party_slot)

func _on_slot_tapped(slot: int) -> void:
	selected_party_slot = slot
	camera_target_slot_changed.emit(slot)
	_refresh()

func _on_slot_dropped(from_slot: int, to_slot: int) -> void:
	if from_slot < 0 or to_slot < 0:
		return
	var from_char = GameData.party_characters[from_slot]
	var to_char = GameData.party_characters[to_slot]
	GameData.party_characters[from_slot] = to_char
	GameData.party_characters[to_slot] = from_char
	GameData.set_party_slot_character(from_slot, to_char)
	GameData.set_party_slot_character(to_slot, from_char)
	_refresh()

func _on_char_selected(char_index: int) -> void:
	if selected_party_slot < 0:
		return
	# remove from previous slot
	for i in range(GameData.party_characters.size()):
		if GameData.party_characters[i] == char_index and i != selected_party_slot:
			GameData.party_characters[i] = GameData.party_characters[selected_party_slot]
			GameData.set_party_slot_character(i, GameData.party_characters[i])
	GameData.set_party_slot_character(selected_party_slot, char_index)
	_refresh()

func _on_cancel() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_confirm() -> void:
	GameData.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")