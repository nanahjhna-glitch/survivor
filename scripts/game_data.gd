extends Node

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
			"forward_rotation_degrees": 180.0,
			"texture": "res://assets/characters/char01/Animations/FighterTexture.png",
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char01/Animations/Walking.fbx",
					"clip": "mixamo.com",
				},
				"attack":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "Boxing",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "Boxing",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char01/Animations/Upward Thrust.fbx",
					"clip": "Upward Thrust",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char01/Animations/Hurricane Kick.fbx",
					"clip": "Hurricane Kick",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char01/Animations/Martelo 2.fbx",
					"clip": "Martelo 2",
				},
			},
		},
		"color": Color("#59a9e8"),
	},
	{
		"name": "숲의 궁수",
		"title": "빠르고 정확한 사냥꾼",
		"weapon": "참나무 활",
		"passive": "이동 속도 +10%",
		"stats": [60, 85, 65],
		"attack_style": "ranged",
		"attributes": {"STR": 3, "AGI": 5, "VIT": 3, "INT": 2, "DEX": 5, "LUK": 3},
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
		"color": Color("#9b7ce0"),
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
var run_won := true
var run_level := 1
var run_upgrades: Dictionary = {"power": 0, "vitality": 0, "fortune": 0}


func _ready() -> void:
	load_game()


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


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "level", 1)
	config.set_value("profile", "gold", gold)
	config.set_value("profile", "gems", gems)
	config.set_value("profile", "character", selected_character)
	config.set_value("profile", "stage", selected_stage)
	config.set_value("growth", "permanent_stats", permanent_stats)
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


func add_gold(amount: int) -> void:
	gold += maxi(0, amount)
	save_game()


func begin_run() -> void:
	run_gold_reward = 0
	run_won = true
	player_level = 1
	run_level = 1
	run_upgrades = {"power": 0, "vitality": 0, "fortune": 0}
