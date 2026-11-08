extends Control

const INK := Color("#28313d")
const MUTED := Color("#737d87")
const PAPER := Color("#fff9e9")
const GOLD := Color("#e5ad35")
const GOLD_DARK := Color("#9b6b16")
const LINE := Color("#d8c99e")

@export var screen_id := "main_menu"

var page_body: VBoxContainer
var action_bar: VBoxContainer
var footer: HBoxContainer
var status_label: Label
var collection_filter := "영웅"
var hero_detail_tab := "정보"
var growth_tab := "레벨업"


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
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 34)
	var safe_area := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	var viewport_size := get_viewport_rect().size
	if (
		OS.has_feature("mobile")
		and safe_area.size.x > 0
		and screen_size.x > 0
		and screen_size.y > 0
	):
		var scale_x := viewport_size.x / float(screen_size.x)
		var scale_y := viewport_size.y / float(screen_size.y)
		var left_margin := maxi(24, roundi(safe_area.position.x * scale_x))
		margin.add_theme_constant_override("margin_left", left_margin)
		margin.add_theme_constant_override("margin_top", maxi(34, roundi(safe_area.position.y * scale_y)))
		margin.add_theme_constant_override(
			"margin_right", maxi(24, roundi((screen_size.x - safe_area.end.x) * scale_x))
		)
		margin.add_theme_constant_override(
			"margin_bottom", maxi(34, roundi((screen_size.y - safe_area.end.y) * scale_y))
		)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := _make_header()
	layout.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_body = VBoxContainer.new()
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation", 14)
	scroll.add_child(page_body)

	action_bar = VBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)

	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	if screen_id == "main_menu":
		layout.add_child(action_bar)
		layout.add_child(footer)
		layout.add_child(scroll)
	else:
		layout.add_child(scroll)
		layout.add_child(action_bar)
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
		var back := _button("‹", false, 48)
		back.pressed.connect(_go_back)
		row.add_child(back)
	var title := _label(_screen_title(), 27, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	if screen_id != "battle":
		var wallet := _label("골드 %d  |  보석 %d" % [GameData.gold, GameData.gems], 16, GOLD_DARK)
		wallet.autowrap_mode = TextServer.AUTOWRAP_OFF
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
		"hero_detail":
			_build_hero_detail()
		"settings":
			_build_settings()
		_:
			_add_text_card("화면을 찾을 수 없습니다.", "등록된 메뉴 화면이 아닙니다.")


func _build_main_menu() -> void:
	# 상단 프로필/재화 영역
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 8)
	page_body.add_child(profile_row)
	var level_label := _label("Lv.%d" % GameData.run_level, 16, INK)
	level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	profile_row.add_child(level_label)
	var gold_label := _label("골드 %d" % GameData.gold, 16, GOLD_DARK)
	gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	profile_row.add_child(gold_label)
	_add_text_card("모험가의 기록", "오늘도 새로운 모험을 시작해 보세요.")
	_add_text_card("방치 보상", "누적 시간 00:00 · 골드 0 · EXP 0")
	_add_text_card("스테이지", "현재 스테이지 1 · 추천 전투력 0")
	_add_hero_lobby()
	_add_action("전투 시작", _begin_party_selection, true)
	footer.add_child(_footer_button("홈", "main_menu"))
	footer.add_child(_footer_button("영웅", "collection"))
	footer.add_child(_footer_button("파티", "character_select"))
	footer.add_child(_growth_footer_button())
	footer.add_child(_footer_button("도감", "collection"))


func _build_character_select() -> void:
	_add_text_card(
		"6인 파티 편성",
		"슬롯을 선택한 뒤 아래 영웅을 지정하세요. 같은 영웅은 중복 편성할 수 없습니다."
	)
	var party_grid := GridContainer.new()
	party_grid.columns = 6
	party_grid.add_theme_constant_override("h_separation", 8)
	party_grid.add_theme_constant_override("v_separation", 8)
	page_body.add_child(party_grid)
	var total_power := 0
	var composition: Dictionary = {}
	for slot_index in range(GameData.party_size):
		var character_index := GameData.party_characters[slot_index]
		var character: Dictionary = GameData.CHARACTERS[character_index]
		total_power += _character_power(character_index)
		var role := str(character["attack_style"])
		composition[role] = int(composition.get(role, 0)) + 1
		var slot_card := _panel_in(party_grid)
		slot_card.custom_minimum_size = Vector2(0, 130)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		slot_card.add_child(row)
		row.add_child(_hero_portrait(character_index, 72))
		row.add_child(_label("슬롯 %d" % (slot_index + 1), 14, INK, HORIZONTAL_ALIGNMENT_CENTER))
		var slot_info := VBoxContainer.new()
		slot_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slot_info)
		var slot_button := _button(
			"%s슬롯 %d" % ["● " if GameData.selected_party_slot == slot_index else "", slot_index + 1],
			GameData.selected_party_slot == slot_index,
			48
		)
		slot_button.pressed.connect(_select_party_slot.bind(slot_index))
		slot_info.add_child(slot_button)
		slot_info.add_child(_label("%s · Lv.%d" % [
			character["name"], GameData.party_slot_levels[slot_index]
		], 14, MUTED))
		var change_button := _button("변경", false, 48)
		change_button.pressed.connect(_select_party_slot.bind(slot_index))
		slot_info.add_child(change_button)
	_add_text_card(
		"파티 전투력 %d" % total_power,
		"근접 %d  ·  원거리 %d  ·  마법 %d"
		% [composition.get("melee", 0), composition.get("ranged", 0), composition.get("magic", 0)]
	)
	_add_text_card(
		"슬롯 %d에 배치할 영웅" % (GameData.selected_party_slot + 1),
		"보유 영웅 %d명" % GameData.CHARACTERS.size()
	)
	for i in range(GameData.CHARACTERS.size()):
		var character: Dictionary = GameData.CHARACTERS[i]
		var already_assigned := false
		for slot_index in range(GameData.party_characters.size()):
			if slot_index != GameData.selected_party_slot and GameData.party_characters[slot_index] == i:
				already_assigned = true
				break
		var card := _panel()
		var column := _column_in(card)
		var select := _button(
			"%s%s"
			% [
				"✓  " if GameData.party_characters[GameData.selected_party_slot] == i else "",
				character["name"]
			],
			GameData.party_characters[GameData.selected_party_slot] == i,
			52
		)
		select.disabled = already_assigned
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
		column.add_child(
			_label(
				"영웅 Lv.%d  EXP %d%s"
				% [
					GameData.hero_levels.get(i, 1),
					GameData.hero_experience.get(i, 0),
					" · 다른 슬롯 편성 중" if already_assigned else ""
				],
				14,
				MUTED
			)
		)
	_add_action("편성 완료 · 스테이지 선택", func(): _go("stage_select"), true)


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
	var party_grid := GridContainer.new()
	party_grid.columns = 2
	party_grid.add_theme_constant_override("h_separation", 8)
	party_grid.add_theme_constant_override("v_separation", 8)
	page_body.add_child(party_grid)
	for i in range(GameData.party_characters.size()):
		var slot := _panel_in(party_grid)
		slot.custom_minimum_size = Vector2(0, 82)
		var col := _column_in(slot)
		var idx := clampi(GameData.party_characters[i], 0, GameData.CHARACTERS.size() - 1)
		var select := _button(
			"슬롯 %d  ·  %s  ·  Lv.%d" % [
				i + 1,
				GameData.CHARACTERS[idx]["name"],
				GameData.party_slot_levels[i]
			],
			idx == GameData.selected_character,
			52
		)
		select.pressed.connect(_open_party_slot.bind(i))
		col.add_child(select)
		col.add_child(_label("터치하여 영웅 변경", 13, MUTED))
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
	_add_text_card(
		"전투 기록",
		"생존 %02d:%02d  ·  처치 %d\n획득 골드 %d  ·  획득 EXP %d"
		% [
			int(GameData.run_elapsed_time / 60.0),
			int(GameData.run_elapsed_time) % 60,
			GameData.run_kill_count,
			GameData.run_gold_reward,
			GameData.run_experience_reward,
		]
	)
	_add_text_card("파티 성장", "이번 전투에 참여한 영웅의 레벨 변화")
	for slot in range(GameData.party_characters.size()):
		var index := GameData.party_characters[slot]
		var before := (
			GameData.run_start_party_slot_levels[slot]
			if slot < GameData.run_start_party_slot_levels.size()
			else GameData.party_slot_levels[slot]
		)
		var after := GameData.party_slot_levels[slot]
		_add_text_card(
			"슬롯 %d · %s" % [slot + 1, GameData.CHARACTERS[index]["name"]],
			"Lv.%d → Lv.%d" % [before, after]
		)
	_add_action("다시 모험하기", func(): _go("stage_select"), true)
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_growth() -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	var character: Dictionary = GameData.CHARACTERS[index]
	_add_text_card(
		"영웅 성장 · %s Lv.%d" % [character["name"], GameData.hero_levels.get(index, 1)],
		"예상 능력치와 필요한 재화를 확인하고 강화하세요. 보유 골드 %d" % GameData.gold
	)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	page_body.add_child(tabs)
	for tab_name in ["레벨업", "승급", "장비", "스킬", "영구 성장"]:
		var tab := _button(tab_name, growth_tab == tab_name, 50)
		tab.add_theme_font_size_override("font_size", 13)
		tab.pressed.connect(_set_growth_tab.bind(tab_name))
		tabs.add_child(tab)

	match growth_tab:
		"레벨업":
			var level := int(GameData.hero_levels.get(index, 1))
			var current := _combat_stats(index, level, int(GameData.hero_ranks.get(index, 0)))
			var upcoming := _combat_stats(index, level + 1, int(GameData.hero_ranks.get(index, 0)))
			_add_text_card(
				"강화 전 → 강화 후",
				"공격력 %d → %d\n방어력 %d → %d\n체력 %d → %d\n치명타 %.1f%% → %.1f%%"
				% [current["attack"], upcoming["attack"], current["defense"], upcoming["defense"],
					current["health"], upcoming["health"], current["critical"], upcoming["critical"]]
			)
			var cost := 100 + level * 75
			_add_text_card("소모 재료", "골드 %d · 영웅 경험치 %d / %d" % [
				cost, GameData.hero_experience.get(index, 0), 100 + level * 50
			])
			_add_action("레벨업 · 골드 %d" % cost, _upgrade_hero_level, true)
		"승급":
			var rank := int(GameData.hero_ranks.get(index, 0))
			var cost := 1000 * (rank + 1)
			_add_text_card(
				"현재 등급  %s" % "★".repeat(rank + 1),
				"승급 시 공격력 +5 · 방어력 +2 · 체력 +20\n필요 골드 %d" % cost
			)
			_add_action("승급하기", _promote_hero, true)
		"장비":
			_add_text_card("현재 무기", str(GameData.hero_equipment.get(index, character["weapon"])))
			for available in GameData.CHARACTERS:
				var weapon := str(available["weapon"])
				var equip := _button("%s 장착" % weapon, GameData.hero_equipment.get(index) == weapon)
				equip.pressed.connect(_equip_hero_weapon.bind(weapon))
				page_body.add_child(equip)
		"스킬":
			var skill_ids: Array = CombatData.CHARACTER_SKILL_SETS.get(index, [])
			for skill_index in skill_ids:
				var skill: Dictionary = CombatData.SKILLS[skill_index]
				var equipped: Array = GameData.hero_equipped_skills.get(index, [])
				var is_equipped := equipped.has(skill_index)
				var skill_button := _button(
					"%s  ·  Lv.%d 해금  ·  피해 %d%s"
					% [skill["name"], skill["unlock_level"], int(skill["damage"]),
						"  ✓ 장착" if is_equipped else "  장착"],
					is_equipped,
					56
				)
				skill_button.disabled = int(GameData.hero_levels.get(index, 1)) < int(skill["unlock_level"])
				skill_button.pressed.connect(_toggle_hero_skill.bind(skill_index))
				page_body.add_child(skill_button)
		"영구 성장":
			_build_permanent_growth_options()
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_collection() -> void:
	var collected := _game_collection_count()
	var total := _game_collection_total()
	_add_text_card(
		"%s 도감" % collection_filter,
		"수집률 %d/%d (%d%%)" % [collected, total, int(float(collected) / maxf(float(total), 1.0) * 100.0)]
	)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	page_body.add_child(filters)
	for filter_name in ["영웅", "몬스터", "스킬", "장비"]:
		var filter := _button(filter_name, filter_name == collection_filter, 48)
		filter.pressed.connect(_set_collection_filter.bind(filter_name))
		filter.add_theme_font_size_override("font_size", 14)
		filters.add_child(filter)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	if collection_filter != "영웅":
		page_body.add_child(grid)
	match collection_filter:
		"영웅":
			_build_hero_collection_grid()
		"몬스터":
			for monster in CombatData.MONSTERS:
				var discovered := GameData.codex_monsters.has(str(monster["id"]))
				if discovered:
					_add_codex_card(
						str(monster["name"]),
						"HP %d  ·  공격력 %d" % [int(monster["hp"]), int(monster["attack"])],
						"경험치 %d  ·  골드 %d" % [int(monster["exp"]), int(monster["gold"])],
						grid
					)
				else:
					_add_codex_card(
						"???", "전투에서 조우하면 도감에 등록됩니다.", "", grid, true
					)
		"스킬":
			for skill in CombatData.SKILLS:
				_add_codex_card(
					str(skill["name"]),
					"해금 Lv.%d  ·  피해 %d" % [skill["unlock_level"], int(skill["damage"])],
					"사거리 %.1f  ·  재사용 %.1f초" % [skill["range"], skill["cooldown"]],
					grid
				)
		"장비":
			for character in GameData.CHARACTERS:
				_add_codex_card(
					str(character["weapon"]),
					"사용 영웅  ·  %s" % character["name"],
					"전투 시작 무기",
					grid
				)
	if collection_filter in ["영웅", "몬스터"]:
		var reward_amount := 300 if collection_filter == "영웅" else 500
		var reward_claimed := bool(GameData.codex_reward_claimed.get(collection_filter, false))
		var reward_button := _button(
			"수집 보상 받기 · 골드 %d" % reward_amount if not reward_claimed else "수집 보상 수령 완료",
			collected == total and not reward_claimed,
			52
		)
		reward_button.disabled = collected != total or reward_claimed
		reward_button.pressed.connect(_claim_collection_reward)
		page_body.add_child(reward_button)
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _build_hero_detail() -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	var character: Dictionary = GameData.CHARACTERS[index]
	var level := int(GameData.hero_levels.get(index, 1))
	_add_hero_card(index)
	_add_text_card(
		"%s  ·  Lv.%d" % [character["name"], level],
		"%s  ·  %s\n%s" % [
			character["title"], "★".repeat(int(GameData.hero_ranks.get(index, 0)) + 1),
			character["passive"]
		]
	)
	var experience := int(GameData.hero_experience.get(index, 0))
	var required_experience := 100 + level * 50
	var experience_panel := _panel()
	var experience_column := _column_in(experience_panel)
	experience_column.add_child(
		_label("경험치  %d / %d" % [experience, required_experience], 14, MUTED)
	)
	var experience_bar := ProgressBar.new()
	experience_bar.custom_minimum_size.y = 18
	experience_bar.max_value = required_experience
	experience_bar.value = experience
	experience_bar.show_percentage = false
	experience_column.add_child(experience_bar)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	page_body.add_child(tabs)
	for tab_name in ["정보", "장비", "스킬", "성장"]:
		var tab := _button(tab_name, tab_name == hero_detail_tab, 48)
		tab.add_theme_font_size_override("font_size", 14)
		tab.pressed.connect(_set_hero_detail_tab.bind(tab_name))
		tabs.add_child(tab)

	match hero_detail_tab:
		"정보":
			var combat_stats := _combat_stats(index, level, int(GameData.hero_ranks.get(index, 0)))
			_add_stat_row("공격력", combat_stats["attack"])
			_add_stat_row("방어력", combat_stats["defense"])
			_add_stat_row("체력", combat_stats["health"])
			_add_stat_row("치명타", "%.1f%%" % combat_stats["critical"])
			var attributes: Dictionary = character["attributes"]
			for key in ["STR", "AGI", "VIT", "INT", "DEX", "LUK"]:
				_add_stat_row(key, int(attributes[key]) + int(GameData.permanent_stats.get(key, 0)))
		"장비":
			_add_text_card("장착 무기", str(GameData.hero_equipment.get(index, character["weapon"])))
			_add_text_card("패시브", str(character["passive"]))
		"스킬":
			var skill_ids: Array = CombatData.CHARACTER_SKILL_SETS.get(index, [])
			for skill_index in skill_ids:
				var skill: Dictionary = CombatData.SKILLS[skill_index]
				var equipped: Array = GameData.hero_equipped_skills.get(index, [])
				_add_codex_card(
					"%s%s" % [skill["name"], "  ✓" if equipped.has(skill_index) else ""],
					"해금 Lv.%d  ·  피해 %d  ·  재사용 %.1f초"
					% [skill["unlock_level"], int(skill["damage"]), skill["cooldown"]]
				)
		"성장":
			var current_stats := _combat_stats(index, level, int(GameData.hero_ranks.get(index, 0)))
			_add_text_card(
				"현재 능력치",
				"공격력 %d · 방어력 %d · 체력 %d · 치명타 %.1f%%"
				% [
					current_stats["attack"],
					current_stats["defense"],
					current_stats["health"],
					current_stats["critical"]
				]
			)
			var open_growth := _button("레벨업 / 승급 / 장비 / 스킬 관리", true)
			open_growth.pressed.connect(_go_to_growth)
			page_body.add_child(open_growth)
	if hero_detail_tab != "성장":
		_add_action("성장 관리", _go_to_growth, true)
		_add_action("장비 관리", _show_hero_equipment_tab)
		_add_action("스킬 관리", _show_hero_skill_tab)
	_add_action("영웅 목록", func(): _go("collection"))


func _build_settings() -> void:
	_add_text_card("설정", "기기에서 사용할 옵션을 선택하세요.")
	_add_toggle("효과음", GameData.sound_enabled, _toggle_sound)
	_add_toggle("진동", GameData.vibration_enabled, _toggle_vibration)
	_add_text_card("저장 데이터", "진행 상황은 기기에 자동 저장됩니다.")
	_add_action("메인 메뉴", func(): _go("main_menu"))


func _add_hero_card(character_index: int = -1) -> void:
	var requested_index := GameData.selected_character if character_index < 0 else character_index
	var index := clampi(requested_index, 0, GameData.CHARACTERS.size() - 1)
	var character: Dictionary = GameData.CHARACTERS[index]
	var portrait_height := 450 if screen_id in ["main_menu", "hero_detail"] else 250
	var card := _panel()
	var column := _column_in(card)
	var center := CenterContainer.new()
	center.custom_minimum_size.y = portrait_height + 40
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	center.add_child(_hero_portrait(index, portrait_height))
	column.add_child(_label(character["name"], 23, INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(
		_label(
			"Lv.%d 모험가" % GameData.hero_levels.get(index, 1),
			15,
			MUTED,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)


func _add_hero_lobby() -> void:
	var index := clampi(GameData.selected_character, 0, GameData.CHARACTERS.size() - 1)
	var hero: Dictionary = GameData.CHARACTERS[index]
	var exhibit := _panel()
	var column := _column_in(exhibit)
	column.add_child(_label("길드 영웅 전시", 19, GOLD_DARK))
	var center := CenterContainer.new()
	center.custom_minimum_size.y = 460
	column.add_child(center)
	center.add_child(_hero_portrait(index, 450))
	column.add_child(_label(
		"%s  ·  Lv.%d" % [hero["name"], GameData.hero_levels.get(index, 1)],
		22, INK, HORIZONTAL_ALIGNMENT_CENTER
	))
	var detail := _button("대표 영웅 상세 보기", true, 52)
	detail.pressed.connect(_open_hero_detail.bind(index))
	column.add_child(detail)

	var roster_scroll := ScrollContainer.new()
	roster_scroll.custom_minimum_size.y = 190
	roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(roster_scroll)
	var roster := HBoxContainer.new()
	roster.add_theme_constant_override("separation", 8)
	roster_scroll.add_child(roster)
	for hero_index in range(GameData.CHARACTERS.size()):
		if hero_index == index:
			continue
		var character: Dictionary = GameData.CHARACTERS[hero_index]
		var hero_card := _panel_in(roster)
		hero_card.custom_minimum_size = Vector2(108, 178)
		var hero_column := _column_in(hero_card)
		hero_column.add_child(_hero_portrait(hero_index, 105))
		var select := _button(str(character["name"]), false, 50)
		select.add_theme_font_size_override("font_size", 13)
		select.pressed.connect(_select_lobby_hero.bind(hero_index))
		hero_column.add_child(select)


func _hero_portrait(index: int, height: int) -> Control:
	var character: Dictionary = GameData.CHARACTERS[index]
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, height)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	var character_color: Color = character["color"]
	frame_style.bg_color = character_color.darkened(0.55)
	frame_style.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel", frame_style)

	var visual: Dictionary = character.get("visual", {})
	var scene_path := str(visual.get("scene", ""))
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var viewport_container := SubViewportContainer.new()
		viewport_container.stretch = true
		viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
		viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		frame.add_child(viewport_container)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(300, height)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport_container.add_child(viewport)
		var world := Node3D.new()
		viewport.add_child(world)
		var environment := Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color("#a9c7c0")
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color("#f3e7cb")
		environment.ambient_light_energy = 0.8
		var world_environment := WorldEnvironment.new()
		world_environment.environment = environment
		world.add_child(world_environment)
		_add_guild_backdrop(world)
		var camera := Camera3D.new()
		camera.position = Vector3(0, 1.2, 3.8)
		camera.rotation.x = deg_to_rad(-4.5)
		world.add_child(camera)
		camera.call_deferred("make_current")
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35, -25, 0)
		light.light_energy = 1.5
		world.add_child(light)
		var model_resource := load(scene_path)
		if model_resource is PackedScene:
			var model := (model_resource as PackedScene).instantiate() as Node3D
			if model != null:
				model.scale = Vector3.ONE * float(visual.get("scale", 1.0))
				model.position.y = float(visual.get("vertical_offset", 0.0))
				model.rotation_degrees.y = float(visual.get("forward_rotation_degrees", 0.0))
				world.add_child(model)
				if not _play_preview_idle(model):
					var idle_tween := model.create_tween().set_loops()
					idle_tween.tween_property(
						model, "position:y", model.position.y + 0.045, 1.15
					).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					idle_tween.tween_property(
						model, "position:y", model.position.y, 1.15
					).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				viewport_container.gui_input.connect(_rotate_hero_preview.bind(model))
		return frame

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)
	var art := Control.new()
	art.custom_minimum_size = Vector2(150, 182)
	center.add_child(art)
	_add_pixel_hero(art, character["color"])
	return frame


func _play_preview_idle(model: Node3D) -> bool:
	var player := AnimationPlayer.new()
	player.name = "PreviewAnimations"
	player.root_node = NodePath("..")
	model.add_child(player)
	var animation := Animation.new()
	animation.length = 2.3
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(".:position:y"))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	var base_height := model.position.y
	animation.track_insert_key(track, 0.0, base_height)
	animation.track_insert_key(track, 1.15, base_height + 0.045)
	animation.track_insert_key(track, 2.3, base_height)
	var library := AnimationLibrary.new()
	var add_animation_error := library.add_animation("idle", animation)
	if add_animation_error != OK:
		push_error("대기 애니메이션을 등록하지 못했습니다: %s" % error_string(add_animation_error))
		return false
	var add_library_error := player.add_animation_library("preview", library)
	if add_library_error != OK:
		push_error("대기 애니메이션 라이브러리를 연결하지 못했습니다: %s" % error_string(add_library_error))
		return false
	player.play("preview/idle")
	return true


func _add_guild_backdrop(world: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(18, 12)
	ground.mesh = ground_mesh
	ground.position = Vector3(0, -1.02, -2.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#8d9f72")
	ground.mesh.surface_set_material(0, ground_material)
	world.add_child(ground)
	for side in [-1.0, 1.0]:
		var guild := MeshInstance3D.new()
		var guild_mesh := BoxMesh.new()
		guild_mesh.size = Vector3(2.2, 1.5, 0.8)
		guild.mesh = guild_mesh
		guild.position = Vector3(side * 2.8, -0.3, -4.8)
		var guild_material := StandardMaterial3D.new()
		guild_material.albedo_color = Color("#c5a77b") if side < 0 else Color("#b9856c")
		guild.mesh.surface_set_material(0, guild_material)
		world.add_child(guild)
		var roof := MeshInstance3D.new()
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(2.8, 0.9, 1.1)
		roof.mesh = roof_mesh
		roof.position = Vector3(side * 2.8, 0.85, -4.8)
		var roof_material := StandardMaterial3D.new()
		roof_material.albedo_color = Color("#704a45")
		roof.mesh.surface_set_material(0, roof_material)
		world.add_child(roof)


func _rotate_hero_preview(event: InputEvent, model: Node3D) -> void:
	if not is_instance_valid(model):
		return
	var drag_x := 0.0
	if event is InputEventScreenDrag:
		drag_x = event.relative.x
	elif (
		event is InputEventMouseMotion
		and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	):
		drag_x = event.relative.x
	if drag_x != 0.0:
		model.rotate_y(-drag_x * 0.01)


func _add_stat_row(name: String, value: Variant) -> void:
	var row := _panel()
	var line := HBoxContainer.new()
	row.add_child(line)
	var stat_name := _label(name, 16, INK)
	stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(stat_name)
	line.add_child(_label(str(value), 16, GOLD_DARK))


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
	action_bar.add_child(control)


func _panel() -> PanelContainer:
	return _panel_in(page_body)


func _panel_in(parent: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = LINE
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _build_hero_collection_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	page_body.add_child(grid)
	for i in range(GameData.CHARACTERS.size()):
		var character: Dictionary = GameData.CHARACTERS[i]
		var card := _panel_in(grid)
		card.custom_minimum_size = Vector2(0, 220)
		var column := _column_in(card)
		column.add_child(_hero_portrait(i, 120))
		column.add_child(_label(character["name"], 17, INK))
		column.add_child(
			_label("보유  ·  Lv.%d" % GameData.hero_levels.get(i, 1), 13, GOLD_DARK)
		)
		var detail := _button("상세 보기", false, 44)
		detail.pressed.connect(_open_hero_detail.bind(i))
		column.add_child(detail)


func _add_codex_card(
	title: String, description: String, detail: String = "", parent: Control = null, locked := false
) -> void:
	var card := _panel_in(page_body if parent == null else parent)
	card.custom_minimum_size = Vector2(0, 150)
	var column := _column_in(card)
	if locked:
		column.add_child(_label("🔒 미발견", 18, MUTED))
	column.add_child(_label(title, 18, INK))
	column.add_child(_label(description, 14, MUTED))
	if not detail.is_empty() and not locked:
		var more := _button("상세 정보", false, 42)
		more.pressed.connect(_show_status.bind(detail))
		column.add_child(more)


func _set_collection_filter(filter_name: String) -> void:
	collection_filter = filter_name
	for child in page_body.get_children():
		child.queue_free()
	for child in action_bar.get_children():
		child.queue_free()
	_build_collection()


func _game_collection_count() -> int:
	match collection_filter:
		"영웅":
			return GameData.CHARACTERS.size()
		"몬스터":
			return GameData.codex_monsters.size()
		"스킬":
			return CombatData.SKILLS.size()
		"장비":
			return GameData.CHARACTERS.size()
	return 0


func _game_collection_total() -> int:
	match collection_filter:
		"영웅":
			return GameData.CHARACTERS.size()
		"몬스터":
			return CombatData.MONSTERS.size()
		"스킬":
			return CombatData.SKILLS.size()
		"장비":
			return GameData.CHARACTERS.size()
	return 0


func _column_in(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	return column


func _button(text: String, primary := false, height := 58) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, maxi(48, height))
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


func _growth_footer_button() -> Button:
	var button := _button("성장", false, 58)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(_open_growth)
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
		"hero_detail": "영웅 상세",
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
		"hero_detail": "collection",
		"settings": "main_menu",
	}
	_go(destinations.get(screen_id, "main_menu"))


func _open_hero_detail(index: int) -> void:
	GameData.selected_detail_character = index
	_go("hero_detail")


func _open_party_slot(slot_index: int) -> void:
	GameData.selected_party_slot = slot_index
	_go("character_select")


func _begin_party_selection() -> void:
	GameData.selected_party_slot = 0
	_go("character_select")


func _set_hero_detail_tab(tab_name: String) -> void:
	hero_detail_tab = tab_name
	_refresh_current_page()


func _set_growth_tab(tab_name: String) -> void:
	growth_tab = tab_name
	_refresh_current_page()


func _refresh_current_page() -> void:
	for child in page_body.get_children():
		child.queue_free()
	for child in action_bar.get_children():
		child.queue_free()
	_build_page()


func _select_party_slot(slot_index: int) -> void:
	GameData.selected_party_slot = slot_index
	_refresh_current_page()


func _select_character(index: int) -> void:
	GameData.set_party_slot_character(GameData.selected_party_slot, index)
	if GameData.party_characters[GameData.selected_party_slot] != index:
		_show_status("이미 다른 슬롯에 편성된 영웅입니다.")
		return
	if GameData.selected_party_slot == 0:
		GameData.selected_character = index
	GameData.save_game()
	_refresh_current_page()


func _select_lobby_hero(index: int) -> void:
	GameData.selected_character = index
	GameData.save_game()
	_refresh_current_page()


func _open_growth() -> void:
	GameData.selected_detail_character = GameData.selected_character
	_go_to_growth()


func _go_to_growth() -> void:
	growth_tab = "레벨업"
	_go("permanent_growth")


func _show_hero_equipment_tab() -> void:
	hero_detail_tab = "장비"
	_refresh_current_page()


func _show_hero_skill_tab() -> void:
	hero_detail_tab = "스킬"
	_refresh_current_page()


func _character_power(index: int) -> int:
	var level := int(GameData.hero_levels.get(index, 1))
	var rank := int(GameData.hero_ranks.get(index, 0))
	var stats := _combat_stats(index, level, rank)
	return int(stats["attack"]) + int(stats["defense"]) + int(stats["health"])


func _combat_stats(index: int, level: int, rank: int) -> Dictionary:
	var base_stats: Array = GameData.CHARACTERS[index]["stats"]
	var attributes: Dictionary = GameData.CHARACTERS[index]["attributes"]
	var permanent_luck := int(GameData.permanent_stats.get("LUK", 0))
	return {
		"attack": int(base_stats[0]) + (level - 1) * 2 + rank * 5,
		"defense": int(base_stats[1]) + (level - 1) + rank * 2,
		"health": int(base_stats[2]) * 10 + (level - 1) * 8 + rank * 20,
		"critical": 5.0 + (int(attributes["LUK"]) + permanent_luck) * 0.5,
	}


func _upgrade_hero_level() -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	var level := int(GameData.hero_levels.get(index, 1))
	var cost := 100 + level * 75
	if not GameData.spend_gold(cost):
		_show_status("골드가 부족해요.")
		return
	GameData.hero_levels[index] = level + 1
	GameData.save_game()
	_refresh_current_page()


func _promote_hero() -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	var rank := int(GameData.hero_ranks.get(index, 0))
	if rank >= 5:
		_show_status("최대 등급에 도달했습니다.")
		return
	if not GameData.spend_gold(1000 * (rank + 1)):
		_show_status("골드가 부족해요.")
		return
	GameData.hero_ranks[index] = rank + 1
	GameData.save_game()
	_refresh_current_page()


func _equip_hero_weapon(weapon: String) -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	GameData.hero_equipment[index] = weapon
	GameData.save_game()
	_refresh_current_page()


func _toggle_hero_skill(skill_index: int) -> void:
	var index := clampi(GameData.selected_detail_character, 0, GameData.CHARACTERS.size() - 1)
	var equipped: Array = GameData.hero_equipped_skills.get(index, []).duplicate()
	if equipped.has(skill_index):
		equipped.erase(skill_index)
	else:
		equipped.append(skill_index)
	GameData.hero_equipped_skills[index] = equipped
	GameData.save_game()
	_refresh_current_page()


func _build_permanent_growth_options() -> void:
	_add_text_card(
		"영구 능력치 성장",
		"골드로 올린 능력치는 저장되며 매 모험에 적용됩니다."
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


func _claim_collection_reward() -> void:
	var total := _game_collection_total()
	if (
		collection_filter not in ["영웅", "몬스터"]
		or _game_collection_count() < total
		or bool(GameData.codex_reward_claimed.get(collection_filter, false))
	):
		return
	GameData.codex_reward_claimed[collection_filter] = true
	var reward_amount := 300 if collection_filter == "영웅" else 500
	GameData.add_gold(reward_amount)
	_show_status("수집 보상으로 골드 %d을 획득했어요." % reward_amount)
	_refresh_current_page()


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
