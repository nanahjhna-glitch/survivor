class_name CombatData
extends RefCounted

const FIELD_NAME := "다이아몬드 초원"
const XP_PER_LEVEL := 30
const XP_PER_LEVEL_STEP := 18

const SKILLS := [
	{
		"id": 1,
		"name": "회전 베기",
		"unlock_level": 2,
		"damage": 32.0,
		"cooldown": 4.0,
		"cast_time": 0.25,
		"range": 4.0,
		"damage_type": "physical",
	},
	{
		"id": 2,
		"name": "별빛 파동",
		"unlock_level": 4,
		"damage": 48.0,
		"cooldown": 7.0,
		"cast_time": 0.4,
		"range": 6.0,
		"damage_type": "magic",
	},
	{
		"id": 3,
		"name": "대지 강타",
		"unlock_level": 7,
		"damage": 70.0,
		"cooldown": 10.0,
		"cast_time": 0.55,
		"range": 5.0,
		"damage_type": "physical",
	},
	{
		"id": 4,
		"name": "수정 폭발",
		"unlock_level": 11,
		"damage": 110.0,
		"cooldown": 14.0,
		"cast_time": 0.75,
		"range": 8.0,
		"damage_type": "magic",
	},
]

const CHARACTER_SKILL_SETS := {
	0: [0, 2],
	1: [0, 1, 2],
	2: [0, 1, 3],
	3: [1, 2, 3],
}

const AUTO_SKILL_RULES := {
	1: {"minimum_targets": 2, "use_on_strong_target": true},
	2: {"minimum_targets": 2, "use_on_strong_target": true},
	3: {"minimum_targets": 2, "use_on_strong_target": true},
	4: {"minimum_targets": 3, "use_on_strong_target": true},
}

const DROP_RULES := {
	"gold_chance": 0.6,
	"potion_chance": 0.12,
	"potion_heal": 28,
	"life_time": 24.0,
	"experience_magnet_range": 2.2,
	"experience_magnet_speed": 8.0,
}

const LEVEL_UP_CARDS := [
	{
		"id": "power",
		"name": "날카로운 무기",
		"description": "공격력이 8 증가합니다.",
		"accent": Color("#eaa94b"),
	},
	{
		"id": "area",
		"name": "확장된 타격 범위",
		"description": "공격과 스킬 히트박스가 15% 커집니다.",
		"accent": Color("#70b9d1"),
	},
	{
		"id": "vitality",
		"name": "튼튼한 갑옷",
		"description": "최대 HP가 20 증가하고 HP를 회복합니다.",
		"accent": Color("#db7568"),
	},
	{
		"id": "haste",
		"name": "빠른 손놀림",
		"description": "기본 공격 속도가 15% 빨라집니다.",
		"accent": Color("#d6bd62"),
	},
	{
		"id": "swift",
		"name": "가벼운 발걸음",
		"description": "이동 속도가 12% 증가합니다.",
		"accent": Color("#71bb78"),
	},
	{
		"id": "magnet",
		"name": "수정 자석",
		"description": "경험치 구슬 획득 거리가 2 증가합니다.",
		"accent": Color("#65cbd5"),
	},
]

const MONSTERS := [
	{
		"id": "slime",
		"name": "슬라임",
		"hp": 32.0,
		"attack": 5.0,
		"speed": 1.8,
		"exp": 10,
		"gold": 3,
		"color": Color("#75d882"),
		"size": 0.68,
	},
	{
		"id": "goblin",
		"name": "고블린",
		"hp": 48.0,
		"attack": 8.0,
		"speed": 2.3,
		"exp": 15,
		"gold": 5,
		"color": Color("#6aab59"),
		"size": 0.78,
	},
	{
		"id": "goblin_warrior",
		"name": "고블린 전사",
		"hp": 82.0,
		"attack": 13.0,
		"speed": 1.8,
		"exp": 24,
		"gold": 9,
		"color": Color("#a65943"),
		"size": 0.92,
	},
	{
		"id": "wild_dog",
		"name": "들개",
		"hp": 40.0,
		"attack": 10.0,
		"speed": 3.2,
		"exp": 18,
		"gold": 6,
		"color": Color("#b88755"),
		"size": 0.62,
	},
	{
		"id": "crystal_golem",
		"name": "수정 골렘",
		"hp": 190.0,
		"attack": 22.0,
		"speed": 1.15,
		"exp": 65,
		"gold": 28,
		"color": Color("#59c6d1"),
		"size": 1.25,
	},
]
