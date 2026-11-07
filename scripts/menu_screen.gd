extends Control

const INK := Color("#28313d")
const MUTED := Color("#737d87")
const PAPER := Color("#fff9e9")
const GOLD := Color("#e5ad35")
const GOLD_DARK := Color("#9b6b16")
const LINE := Color("#d8c99e")

@export var screen_id := "main_menu"

var page_body: VBoxContainer
var footer: HBoxContainer
var status_label: Label


func _ready() -> void:
	_build_shell()
	_build_page()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#f3edda")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := _make_header()
	layout.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	page_body = VBoxContainer.new()
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation", 14)
	scroll.add_child(page_body)

	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	layout.add_child(footer)

	status_label = _label("", 15, MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false
	layout.add_child(status_label)


func _make_header() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 58
	row.add_theme_constant_override("separation", 10)
	if screen_id != "main_menu":
		var back := _button("‹", false, 42)
		back.pressed.connect(_go_back)
		row.add_child(back)
	var title := _label(_screen_title(), 27, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	if screen_id != "battle":
		var wallet := _label("골드 %d  |  보석 %d" % [GameData.gold, GameData.gems], 16, GOLD_DARK)
		wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(wallet)
	return row


func _build_page() -> void:
	match screen_id:
		"main_menu":
			_build_main_menu()
		"character_select":
			_build_character_select()
		"stage_select":
			_build_stage_select()
		"battle":
			_build_battle()
		"level_up":
			_build_level_up()
		"pause":
			_build_pause()
		"chest_reward":
			_build_chest_reward()
		"result":
			_build_result()
		"permanent_growth":
			_build_growth()
		"collection":
			_build_collection()
		"settings":
			_build_settings()
		_:
			_add_text_card("화면을 찾을 수 없습니다.", "등록된 메뉴 화면이 아닙니다.")


func _build_main_menu() -> void:
	_add_text_card("PIXEL QUEST", "작은 영웅의 큰 모험")
	page_body.add_child(_label("Lv.%d  |  골드 %d  |  보석 %d" % [GameData.player_level, GameData.gold, GameData.gems], 16, GOLD_DARK))
	_add_hero_card()
	_add_text_card("오늘도 모험을 떠나 볼까요?", "간결한 한 판 액션 로그라이크")
	_add_action("전투 시작", func(): _go("character_select"), true)
	footer.add_child(_footer_button("영웅", "character_select"))
	footer.add_child(_footer_button("영구 성장", "permanent_growth"))
	footer.add_child(_footer_button("도감", "collection"))
	footer.add_child(_footer_button("업적", "collection"))
	footer.add_child(_footer_button("설정", "settings"))


func _build_character_select() -> void:
	_add_text_card("모험가를 선택하세요", "직업마다 무기와 패시브가 달라요.")
	for i in range(GameData.CHARACTERS.size()):
		var character: Dictionary = GameData.CHARACTERS[i]
		var card := _panel()
		var column := _column_in(card)
		var select := _button(
			"%s%s" % ["✓  " if i == GameData.selected_character else "", character["name"]],
			i == GameData.selected_character
		)
		select.pressed.connect(_select_character.bind(i))
		column.add_child(select)
		column.add_child(
			_label("%s  ·  시작 무기: %s" % [character["title"], character["weapon"]], 16, MUTED)
		)
		var attributes: Dictionary = character["attributes"].duplicate()
		for key in GameData.permanent_stats:
			attributes[key] += GameData.permanent_stats[key]
		column.add_child(
			_label(
				"STR %d  AGI %d  VIT %d  INT %d  DEX %d  LUK %d"
				% [
					attributes["STR"],
					attributes["AGI"],
					attributes["VIT"],
					attributes["INT"],
					attributes["DEX"],
					attributes["LUK"],
				],
				15,
				INK
			)
		)
		column.add_child(_label("패시브  %s" % character["passive"], 15, GOLD_DARK))
	_add_hero_card()
	_add_action("스테이지 선택", func(): _go("stage_select"), true)


func _build_stage_select() -> void:
	_add_text_card("어디로 떠날까요?", "추천 레벨과 보상을 확인해 보세요.")
	for i in range(GameData.STAGES.size()):
		var stage: Dictionary = GameData.STAGES[i]
		var card := _panel()
		var column := _column_in(card)
		var select := _button(
			(
				"%s%s  ·  %s"
				% [
					"✓  " if i == GameData.selected_stage else "",
					stage["name"],
					stage["difficulty"]
				]
			),
			i == GameData.selected_stage
		)
		select.pressed.connect(_select_stage.bind(i))
		column.add_child(select)
		var banner := ColorRect.new()
		banner.color = stage["color"]
		banner.custom_minimum_size.y = 48
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(banner)
		column.add_child(_label("%s   |   권장 레벨 %d" % [stage["subtitle"], stage["level"]], 15, INK))
		column.add_child(_label("몬스터  %s" % stage["monsters"], 15, MUTED))
		column.add_child(_label("보상  %s" % stage["reward"], 15, GOLD_DARK))
	var party_row := HBoxContainer.new()
	party_row.add_theme_constant_override("separation", 8)
	page_body.add_child(party_row)
	var slot_indices := [GameData.selected_character, 1, 0, 1]
	for i in range(4):
		var slot := _panel()
		slot.custom_minimum_size = Vector2(0, 64)
		var col := _column_in(slot)
		var idx: int = slot_indices[i] if slot_indices[i] < GameData.CHARACTERS.size() else 0
		col.add_child(_label("슬롯 %d" % (i + 1), 12, MUTED))
		col.add_child(_label(GameData.CHARACTERS[idx]["name"], 15, INK))
		party_row.add_child(slot)
	_add_action("전투 시작", _start_battle, true)


func _build_battle() -> void:
	_add_text_card("전투 화면 연결 대기", "현재 저장소에는 기존 전투 씬과 전투 시스템이 없습니다.\n이 화면은 메뉴 흐름 확인용 플레이스홀더입니다.")
	_add_hero_card()
	var upgrade_count: int = (
		GameData.run_upgrades["power"]
		+ GameData.run_upgrades["vitality"]
		+ GameData.run_upgrades["fortune"]
	)
	_add_text_card(
		"메뉴 흐름 테스트",
		(
			"이번 모험 레벨 %d  ·  선택 강화 %d개\n아래 버튼으로 각 메뉴 화면을 확인할 수 있어요."
			% [GameData.run_level, upgrade_count]
		)
	)
	_add_action("레벨 업 화면 보기", func(): _go("level_up"), true)
	_add_action("일시정지", func(): _go("pause"))
	_add_action("보물상자 획득", func(): _go("chest_reward"))
	_add_action("전투 결과 보기", _finish_demo_run)


func _build_level_up() -> void:
	_add_text_card("레벨 업!", "강화할 능력을 하나 선택하세요.")
	_add_choice("power", "빠른 검격", "공격 속도가 상승합니다.")
	_add_choice("vitality", "든든한 체력", "최대 체력이 상승합니다.")
	_add_choice("fortune", "행운의 발걸음", "아이템 획득 확률이 상승합니다.")


func _build_pause() -> void:
	_add_text_card("잠시 쉬어 가요", "모험은 여기서 기다리고 있어요.")
	_add_action("계속하기", func(): _go("battle"), true)
	_add_action("전투 결과 보기", _finish_demo_run)
	_add_action("메인 메뉴로", func(): _go("main_menu"))


func _build_chest_reward() -> void:
	_add_text_card("보물상자 발견!", "반짝이는 보상이 기다리고 있어요.")
	_add_hero_card()
	_add_text_card("모험 보상", "골드 +%d   ·   별빛 조각 +1" % _preview_reward())
	_add_action("보상 받고 결과 보기", _claim_chest, true)


func _build_result() -> void:
	var title := "모험 완료!" if GameData.run_won else "모험 종료"
	var description := (
		"%s에서 무사히 돌아왔어요." % GameData.STAGES[GameData.selected_stage]["name"]
		if GameData.run_won
		else "다음 모험에서 다시 도전해 보세요."
	)
	_add_text_card(title, description)
	_add_hero_card()
	_add_text_card("획득 골드", "+%d" % GameData.run_gold_reward)
	_add_text_card("획득 경험치", "+%d" % GameData.run_experience_reward)
	_add_action("다시 모험하기", func(): _go("stage_select"), true)
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_growth() -> void:
	_add_text_card(
		"영구 능력치 성장",
		"골드로 올린 능력치는 저장되며 매 모험에 적용됩니다.\n모험 중 레벨은 매번 Lv.1부터 시작합니다."
	)
	var stat_info := {
		"STR": ["힘", "근접 물리 피해 증가"],
		"AGI": ["민첩", "공격 속도와 회피율 증가"],
		"VIT": ["체력", "최대 HP, HP 회복력, 물리 방어력 증가"],
		"INT": ["지능", "마법 피해와 캐스팅 속도 증가"],
		"DEX": ["손재주", "명중률, 원거리 피해, 캐스팅 속도 증가"],
		"LUK": ["행운", "크리티컬과 완전 회피율 증가"],
	}
	for key in ["STR", "AGI", "VIT", "INT", "DEX", "LUK"]:
		var level: int = GameData.permanent_stats[key]
		var cost := 100 + level * 75
		var card := _panel()
		var column := _column_in(card)
		column.add_child(_label("%s (%s)  Lv.%d" % [key, stat_info[key][0], level], 19, INK))
		column.add_child(_label(stat_info[key][1], 15, MUTED))
		column.add_child(_label("다음 강화 비용  골드 %d" % cost, 15, GOLD_DARK))
		var purchase := _button("강화하기", GameData.gold >= cost)
		purchase.pressed.connect(_buy_permanent_stat.bind(key, cost))
		column.add_child(purchase)
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_collection() -> void:
	_add_text_card("모험 도감", "지금까지 만난 동료와 몬스터")
	for character in GameData.CHARACTERS:
		_add_text_card(
			"동료  ·  %s" % character["name"],
			"%s  |  %s" % [character["weapon"], character["passive"]]
		)
	for stage in GameData.STAGES:
		_add_text_card("지역  ·  %s" % stage["name"], "몬스터  %s" % stage["monsters"])
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_settings() -> void:
	_add_text_card("설정", "기기에서 사용할 옵션을 선택하세요.")
	_add_toggle("효과음", GameData.sound_enabled, _toggle_sound)
	_add_toggle("진동", GameData.vibration_enabled, _toggle_vibration)
	_add_text_card("저장 데이터", "진행 상황은 기기에 자동 저장됩니다.")
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _add_hero_card() -> void:
	var character: Dictionary = GameData.CHARACTERS[GameData.selected_character]
	var card := _panel()
	var column := _column_in(card)
	var center := CenterContainer.new()
	center.custom_minimum_size.y = 220
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var art := Control.new()
	art.custom_minimum_size = Vector2(150, 210)
	center.add_child(art)
	_add_pixel_hero(art, character["color"])
	column.add_child(_label(character["name"], 23, INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(
		_label("Lv.%d 모험가" % GameData.player_level, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	)


func _add_pixel_hero(art: Control, tunic: Color) -> void:
	_pixel(art, Vector2(46, 3), Vector2(58, 18), Color("#5a3a2a"))
	_pixel(art, Vector2(38, 17), Vector2(74, 12), Color("#5a3a2a"))
	_pixel(art, Vector2(46, 27), Vector2(58, 54), Color("#edbd83"))
	_pixel(art, Vector2(44, 21), Vector2(62, 12), Color("#795137"))
	_pixel(art, Vector2(54, 47), Vector2(9, 9), INK)
	_pixel(art, Vector2(88, 47), Vector2(9, 9), INK)
	_pixel(art, Vector2(64, 66), Vector2(23, 5), Color("#a95f54"))
	_pixel(art, Vector2(44, 81), Vector2(62, 48), tunic)
	_pixel(art, Vector2(21, 86), Vector2(23, 43), Color("#edbd83"))
	_pixel(art, Vector2(106, 86), Vector2(23, 43), Color("#edbd83"))
	_pixel(art, Vector2(51, 128), Vector2(22, 43), Color("#454f68"))
	_pixel(art, Vector2(77, 128), Vector2(22, 43), Color("#454f68"))
	_pixel(art, Vector2(45, 168), Vector2(31, 14), Color("#68412e"))
	_pixel(art, Vector2(74, 168), Vector2(31, 14), Color("#68412e"))
	_pixel(art, Vector2(118, 68), Vector2(8, 86), Color("#a7c7d2"))
	_pixel(art, Vector2(111, 63), Vector2(22, 16), GOLD)


func _pixel(parent: Control, position: Vector2, dimensions: Vector2, color: Color) -> void:
	var block := ColorRect.new()
	block.position = position
	block.size = dimensions
	block.color = color
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(block)


func _add_choice(key: String, title: String, description: String) -> void:
	var card := _panel()
	var column := _column_in(card)
	column.add_child(_label(title, 20, INK))
	column.add_child(_label(description, 15, MUTED))
	var choice := _button("선택하고 전투로 돌아가기", true)
	choice.pressed.connect(_choose_level_up.bind(key))
	column.add_child(choice)


func _add_toggle(title: String, value: bool, action: Callable) -> void:
	var row := _panel()
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	var name := _label(title, 18, INK)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name)
	var toggle := _button("켜짐" if value else "꺼짐", value)
	toggle.pressed.connect(action)
	line.add_child(toggle)


func _add_text_card(title: String, description: String) -> void:
	var card := _panel()
	var column := _column_in(card)
	column.add_child(_label(title, 21, INK))
	column.add_child(_label(description, 15, MUTED))


func _add_action(text: String, action: Callable, primary := false) -> void:
	var control := _button(text, primary, 74 if primary else 62)
	control.pressed.connect(action)
	page_body.add_child(control)


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = LINE
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	page_body.add_child(panel)
	return panel


func _column_in(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	return column


func _button(text: String, primary := false, height := 58) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(primary, false))
	button.add_theme_stylebox_override("hover", _button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _button_style(primary, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _button_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f3ca69") if primary else Color("#f7f0dc")
	if hovered:
		style.bg_color = Color("#f8d981") if primary else Color("#eee3c5")
	style.border_color = GOLD_DARK if primary else LINE
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	return style


func _label(
	text: String, font_size := 16, color := INK, alignment := HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _footer_button(text: String, target: String) -> Button:
	var button := _button(text, false, 58)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(func(): _go(target))
	return button


func _screen_title() -> String:
	var titles := {
		"main_menu": "PIXEL QUEST",
		"character_select": "모험가 선택",
		"stage_select": "스테이지 선택",
		"battle": "모험 진행 중",
		"level_up": "레벨 업",
		"pause": "일시정지",
		"chest_reward": "보물상자",
		"result": "모험 결과",
		"permanent_growth": "영구 성장",
		"collection": "모험 도감",
		"settings": "설정",
	}
	return titles.get(screen_id, "모험")


func _go(target: String) -> void:
	ScreenRouter.go(target)


func _go_back() -> void:
	var destinations := {
		"character_select": "main_menu",
		"stage_select": "character_select",
		"battle": "stage_select",
		"level_up": "battle",
		"pause": "battle",
		"chest_reward": "battle",
		"result": "main_menu",
		"permanent_growth": "main_menu",
		"collection": "main_menu",
		"settings": "main_menu",
	}
	_go(destinations.get(screen_id, "main_menu"))


func _select_character(index: int) -> void:
	GameData.selected_character = index
	GameData.save_game()
	_go("character_select")


func _select_stage(index: int) -> void:
	GameData.selected_stage = index
	GameData.save_game()
	_go("stage_select")


func _start_battle() -> void:
	GameData.begin_run()
	_go("battle")


func _choose_level_up(key: String) -> void:
	if not GameData.run_upgrades.has(key):
		push_error("등록되지 않은 강화 항목입니다: %s" % key)
		return
	GameData.run_upgrades[key] += 1
	GameData.run_level += 1
	_go("battle")


func _preview_reward() -> int:
	return 75 + GameData.selected_stage * 25


func _claim_chest() -> void:
	GameData.run_gold_reward += _preview_reward()
	GameData.add_gold(_preview_reward())
	GameData.gems += 1
	GameData.save_game()
	_go("result")


func _finish_demo_run() -> void:
	GameData.run_won = true
	GameData.run_gold_reward += 50 + GameData.selected_stage * 25
	GameData.add_gold(50 + GameData.selected_stage * 25)
	_go("result")


func _buy_permanent_stat(key: String, cost: int) -> void:
	if not GameData.permanent_stats.has(key):
		push_error("등록되지 않은 영구 능력치입니다: %s" % key)
		return
	if not GameData.spend_gold(cost):
		_show_status("골드가 부족해요.")
		return
	GameData.permanent_stats[key] += 1
	GameData.save_game()
	_go("permanent_growth")


func _toggle_sound() -> void:
	GameData.sound_enabled = not GameData.sound_enabled
	GameData.save_game()
	_go("settings")


func _toggle_vibration() -> void:
	GameData.vibration_enabled = not GameData.vibration_enabled
	GameData.save_game()
	_go("settings")


func _show_status(message: String) -> void:
	status_label.text = message
	status_label.visible = true
