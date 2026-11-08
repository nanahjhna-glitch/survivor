extends Node

const PARTY_SIZE := 6
const SAVE_PATH := "user://survivor_save.cfg"

const CHARACTERS := [
	{
		"name": "견습 기사",
		"title": "균형 잡힌 모험가",
		"weapon": "낡은 장검",
		"passive": "최대 체력 +10%",
		"stats": [80, 60, 55],
		"attack_style": "melee",
		"attributes": {"STR": 5, "AGI": 3, "VIT": 5, "INT": 1, "DEX": 2, "LUK": 2},
		"visual":
		{
			"scene": "res://assets/characters/char01/Model/char01.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": -0.9,
			"texture": "res://assets/characters/char01/Animations/FighterTexture.png",
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo_com",
				},
				"idle":
				{
					"scene": "res://assets/characters/char01/Animations/Fighting Idle.fbx",
					"clip": "mixamo_com",
				},
				"run":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo_com",
				},
				"hit":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"death":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"attack":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char01/Animations/Kicking.fbx",
					"clip": "mixamo_com",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char01/Animations/Flying Kick.fbx",
					"clip": "mixamo_com",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char01/Animations/Hurricane Kick.fbx",
					"clip": "mixamo_com",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char01/Animations/Martelo 2.fbx",
					"clip": "mixamo_com",
				},
			},
		},
		"color": Color("#59a9e8"),
	},
	{
		"name": "무도가",
		"title": "빠르고 강력한 격투가",
		"weapon": "강철 건틀릿",
		"passive": "공격 속도 +10%",
		"stats": [70, 80, 60],
		"attack_style": "melee",
		"attributes": {"STR": 4, "AGI": 5, "VIT": 4, "INT": 2, "DEX": 4, "LUK": 3},
		"visual":
		{
			"scene": "res://assets/characters/char02/Animations/T-Pose.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": 0.0,
			"texture": "res://assets/characters/char02/Animations/Texture.png",
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo",
				},
				"idle":
				{
					"scene": "res://assets/characters/char02/Animations/Fighting Idle.fbx",
					"clip": "mixamo",
				},
				"run":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo",
				},
				"hit":
				{
					"scene": "res://assets/characters/char02/Animations/Quad Punch.fbx",
					"clip": "mixamo",
				},
				"death":
				{
					"scene": "res://assets/characters/char02/Animations/Dying.fbx",
					"clip": "mixamo",
				},
				"attack":
				{
					"scene": "res://assets/characters/char02/Animations/Quad Punch.fbx",
					"clip": "mixamo",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char02/Animations/Flying Kick.fbx",
					"clip": "mixamo",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char02/Animations/Roundhouse Kick.fbx",
					"clip": "mixamo",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char02/Animations/Hurricane Kick.fbx",
					"clip": "mixamo",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char02/Animations/Standing Dive Forward.fbx",
					"clip": "mixamo",
				},
			},
		},
		"color": Color("#e89b59"),
	},
	{
		"name": "숲의 궁수",
		"title": "빠르고 정확한 사냥꾼",
		"weapon": "참나무 활",
		"passive": "이동 속도 +10%",
		"stats": [60, 85, 65],
		"attack_style": "ranged",
		"attributes": {"STR": 3, "AGI": 5, "VIT": 3, "INT": 2, "DEX": 5, "LUK": 3},
		"visual":
		{
			"scene": "res://assets/characters/char02/Model/char02.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 8.0,
			"vertical_offset": 0.0,
			"animations":
			{
				"idle":
				{
					"scene": "res://assets/characters/char02/Animations/Fighting Idle.fbx",
					"clip": "mixamo",
				},
			},
		},
		"color": Color("#61b778"),
	},
	{
		"name": "별빛 마법사",
		"title": "원거리 마법 전문가",
		"weapon": "초보자 지팡이",
		"passive": "공격력 +10%",
		"stats": [55, 70, 90],
		"attack_style": "magic",
		"attributes": {"STR": 2, "AGI": 3, "VIT": 3, "INT": 5, "DEX": 4, "LUK": 4},
		"visual":
		{
			"scene": "res://assets/characters/char01/Model/char01.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": -8.0,
			"vertical_offset": -0.9,
			"animations":
			{
				"idle":
				{
					"scene": "res://assets/characters/char01/Animations/Fighting Idle.fbx",
					"clip": "mixamo_com",
				},
			},
		},
		"color": Color("#9b7ce0"),
	},
	{
		"name": "룬 수호자",
		"title": "견고한 방패 전사",
		"weapon": "룬 각인 방패",
		"passive": "물리 방어력 +10%",
		"stats": [65, 50, 95],
		"attack_style": "melee",
		"attributes": {"STR": 4, "AGI": 2, "VIT": 6, "INT": 2, "DEX": 2, "LUK": 2},
		"visual":
		{
			"scene": "res://assets/characters/char01/Model/char01.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": -0.9,
			"animations":
			{
				"idle":
				{
					"scene": "res://assets/characters/char01/Animations/Fighting Idle.fbx",
					"clip": "mixamo_com",
				},
			},
		},
		"color": Color("#d0a94f"),
	},
	{
		"name": "황혼 치유사",
		"title": "빛을 다루는 지원가",
		"weapon": "황혼의 성서",
		"passive": "회복 효과 +10%",
		"stats": [50, 65, 75],
		"attack_style": "magic",
		"attributes": {"STR": 1, "AGI": 3, "VIT": 4, "INT": 6, "DEX": 3, "LUK": 3},
		"visual":
		{
			"scene": "res://assets/characters/char02/Model/char02.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": 0.0,
			"animations":
			{
				"idle":
				{
					"scene": "res://assets/characters/char02/Animations/Fighting Idle.fbx",
					"clip": "mixamo",
				},
			},
		},
		"color": Color("#d77f9b"),
	},
]

const STAGES := [
	{
		"name": "다이아몬드 초원",
		"subtitle": "수정의 빛이 깃든 첫 모험지",
		"difficulty": "쉬움",
		"level": 1,
		"monsters": "슬라임 · 고블린 · 들개 · 수정 골렘",
		"reward": "경험치 · 골드 · HP 포션",
		"color": Color("#91c878"),
	},
]

var player_level := 1
var gold := 500
var gems := 25
var selected_character := 0
var selected_detail_character := 0
var party_characters: Array[int] = [0, 1, 2, 3, 4, 5]
var camera_target_slot := 0
var selected_party_slot := 0
var selected_stage := 0
var permanent_stats: Dictionary = {
	"STR": 0,
	"AGI": 0,
	"VIT": 0,
	"INT": 0,
	"DEX": 0,
	"LUK": 0,
}
var sound_enabled := true
var vibration_enabled := true
var run_gold_reward := 0
var run_experience_reward := 0
var run_elapsed_time := 0.0
var run_kill_count := 0
var run_start_hero_levels: Dictionary = {}
var run_start_party_slot_levels: Array[int] = []
var run_won := true
var run_level := 1
var run_upgrades: Dictionary = {"power": 0, "vitality": 0, "fortune": 0}
var hero_levels: Dictionary = {}
var hero_experience: Dictionary = {}
var hero_ranks: Dictionary = {}
var hero_equipment: Dictionary = {}
var hero_equipped_skills: Dictionary = {}
var codex_monsters: Array[String] = ["slime"]
var codex_reward_claimed: Dictionary = {}
var party_slot_levels: Array[int] = [1, 1, 1, 1, 1, 1]
var party_slot_experience: Array[int] = [0, 0, 0, 0, 0, 0]
var party_slot_progress_loaded := false


func _ready() -> void:
	load_game()
	for i in range(CHARACTERS.size()):
		if not hero_levels.has(i):
			hero_levels[i] = 1
		if not hero_experience.has(i):
			hero_experience[i] = 0
		if not hero_ranks.has(i):
			hero_ranks[i] = 0
		if not hero_equipment.has(i):
			hero_equipment[i] = CHARACTERS[i]["weapon"]
		if not hero_equipped_skills.has(i):
			hero_equipped_skills[i] = CombatData.CHARACTER_SKILL_SETS.get(i, []).duplicate()
	if not party_slot_progress_loaded:
		_initialize_party_slot_progress()


func load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	# Run levels are temporary; retain the field for old saves but always start at level 1.
	player_level = 1
	gold = maxi(0, int(config.get_value("profile", "gold", gold)))
	gems = maxi(0, int(config.get_value("profile", "gems", gems)))
	selected_character = clampi(
		int(config.get_value("profile", "character", 0)), 0, CHARACTERS.size() - 1
	)
	var saved_party: Variant = config.get_value("profile", "party", [])
	if saved_party is Array:
		for i in range(mini(PARTY_SIZE, saved_party.size())):
			party_characters[i] = clampi(int(saved_party[i]), 0, CHARACTERS.size() - 1)
	if not party_characters.is_empty():
		party_characters[0] = selected_character
	_normalize_party()
	camera_target_slot = clampi(
		int(config.get_value("profile", "camera_target_slot", 0)), 0, PARTY_SIZE - 1
	)
	selected_stage = clampi(int(config.get_value("profile", "stage", 0)), 0, STAGES.size() - 1)
	var saved_stats: Variant = config.get_value(
		"growth", "permanent_stats", config.get_value("growth", "upgrades", {})
	)
	if saved_stats is Dictionary:
		var legacy_mapping := {"power": "STR", "vitality": "VIT", "fortune": "LUK"}
		for legacy_key in legacy_mapping:
			var stat_key: String = legacy_mapping[legacy_key]
			permanent_stats[stat_key] = maxi(
				int(permanent_stats[stat_key]), int(saved_stats.get(legacy_key, 0))
			)
		for key in permanent_stats:
			permanent_stats[key] = maxi(int(permanent_stats[key]), int(saved_stats.get(key, 0)))
	sound_enabled = bool(config.get_value("settings", "sound", true))
	vibration_enabled = bool(config.get_value("settings", "vibration", true))
	for i in range(CHARACTERS.size()):
		hero_levels[i] = maxi(1, int(config.get_value("hero", "level_%d" % i, 1)))
		hero_experience[i] = maxi(0, int(config.get_value("hero", "exp_%d" % i, 0)))
		hero_ranks[i] = clampi(int(config.get_value("hero", "rank_%d" % i, 0)), 0, 5)
		hero_equipment[i] = str(
			config.get_value("hero", "equipment_%d" % i, CHARACTERS[i]["weapon"])
		)
		var skills_key := "skills_%d" % i
		var saved_skills: Variant = config.get_value("hero", skills_key, [])
		if config.has_section_key("hero", skills_key) and saved_skills is Array:
			hero_equipped_skills[i] = saved_skills.duplicate()
		else:
			hero_equipped_skills[i] = CombatData.CHARACTER_SKILL_SETS.get(i, []).duplicate()
	var saved_codex: Variant = config.get_value("collection", "monsters", ["slime"])
	if saved_codex is Array:
		codex_monsters.clear()
		for monster_id in saved_codex:
			if not codex_monsters.has(str(monster_id)):
				codex_monsters.append(str(monster_id))
	var saved_rewards: Variant = config.get_value("collection", "rewards", {})
	codex_reward_claimed = saved_rewards.duplicate() if saved_rewards is Dictionary else {}
	_initialize_party_slot_progress()
	for slot in range(PARTY_SIZE):
		var level_key := "level_%d" % slot
		var experience_key := "exp_%d" % slot
		if config.has_section_key("party_progress", level_key):
			party_slot_levels[slot] = maxi(
				1, int(config.get_value("party_progress", level_key, party_slot_levels[slot]))
			)
		if config.has_section_key("party_progress", experience_key):
			party_slot_experience[slot] = maxi(
				0,
				int(
					config.get_value(
						"party_progress", experience_key, party_slot_experience[slot]
					)
				)
			)
	party_slot_progress_loaded = true


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "level", 1)
	config.set_value("profile", "gold", gold)
	config.set_value("profile", "gems", gems)
	config.set_value("profile", "character", selected_character)
	config.set_value("profile", "party", party_characters)
	config.set_value("profile", "camera_target_slot", camera_target_slot)
	config.set_value("profile", "stage", selected_stage)
	config.set_value("growth", "permanent_stats", permanent_stats)
	for i in range(CHARACTERS.size()):
		config.set_value("hero", "level_%d" % i, int(hero_levels.get(i, 1)))
		config.set_value("hero", "exp_%d" % i, int(hero_experience.get(i, 0)))
		config.set_value("hero", "rank_%d" % i, int(hero_ranks.get(i, 0)))
		config.set_value("hero", "equipment_%d" % i, str(hero_equipment.get(i, CHARACTERS[i]["weapon"])))
		config.set_value("hero", "skills_%d" % i, hero_equipped_skills.get(i, []))
	config.set_value("collection", "monsters", codex_monsters)
	config.set_value("collection", "rewards", codex_reward_claimed)
	for slot in range(PARTY_SIZE):
		config.set_value("party_progress", "level_%d" % slot, party_slot_levels[slot])
		config.set_value("party_progress", "exp_%d" % slot, party_slot_experience[slot])
	config.set_value("settings", "sound", sound_enabled)
	config.set_value("settings", "vibration", vibration_enabled)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("게임 데이터를 저장하지 못했습니다: %s" % error_string(error))


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	save_game()
	return true


func add_gold(amount: int, save_immediately := true) -> void:
	gold += maxi(0, amount)
	if save_immediately:
		save_game()


func add_party_slot_experience(slot: int, character_index: int, amount: int) -> void:
	if (
		slot < 0
		or slot >= party_slot_levels.size()
		or character_index < 0
		or character_index >= CHARACTERS.size()
		or amount <= 0
	):
		return
	var current_level := party_slot_levels[slot]
	var current_experience := party_slot_experience[slot] + amount
	var required_experience := 100 + current_level * 50
	while current_experience >= required_experience:
		current_experience -= required_experience
		current_level += 1
		required_experience = 100 + current_level * 50
	party_slot_levels[slot] = current_level
	party_slot_experience[slot] = current_experience

	var recorded_level := int(hero_levels.get(character_index, 1))
	if current_level > recorded_level:
		hero_levels[character_index] = current_level
		hero_experience[character_index] = current_experience
	elif current_level == recorded_level:
		hero_experience[character_index] = maxi(
			int(hero_experience.get(character_index, 0)), current_experience
		)


func _initialize_party_slot_progress() -> void:
	for slot in range(PARTY_SIZE):
		var character_index := party_characters[slot]
		party_slot_levels[slot] = int(hero_levels.get(character_index, 1))
		party_slot_experience[slot] = int(hero_experience.get(character_index, 0))


func set_party_slot_character(slot: int, character_index: int) -> void:
	if (
		slot < 0
		or slot >= party_characters.size()
		or character_index < 0
		or character_index >= CHARACTERS.size()
	):
		return
	if party_characters[slot] == character_index:
		return
	for other_slot in range(party_characters.size()):
		if other_slot != slot and party_characters[other_slot] == character_index:
			return
	party_characters[slot] = character_index
	party_slot_levels[slot] = int(hero_levels.get(character_index, 1))
	party_slot_experience[slot] = int(hero_experience.get(character_index, 0))


func discover_monster(monster_id: String) -> void:
	if monster_id.is_empty() or codex_monsters.has(monster_id):
		return
	codex_monsters.append(monster_id)
	save_game()


func _normalize_party() -> void:
	var assigned: Dictionary = {}
	for slot in range(mini(PARTY_SIZE, party_characters.size())):
		var character_index := clampi(party_characters[slot], 0, CHARACTERS.size() - 1)
		if assigned.has(character_index):
			for candidate in range(CHARACTERS.size()):
				if not assigned.has(candidate):
					character_index = candidate
					break
		party_characters[slot] = character_index
		assigned[character_index] = true


func begin_run() -> void:
	run_gold_reward = 0
	run_experience_reward = 0
	run_elapsed_time = 0.0
	run_kill_count = 0
	run_start_hero_levels = hero_levels.duplicate()
	run_start_party_slot_levels = party_slot_levels.duplicate()
	run_won = true
	player_level = 1
	run_level = 1
	run_upgrades = {"power": 0, "vitality": 0, "fortune": 0}
