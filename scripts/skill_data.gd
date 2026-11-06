class_name SkillData
extends Resource

enum SkillType { ULTIMATE, MAJOR, BUFF, BASIC }

@export var skill_id: String = ""
@export var skill_type: SkillType = SkillType.BASIC
@export var cooldown: float = 5.0
@export var cast_time: float = 0.3
@export var range: float = 3.0
@export var gcd: float = 0.5
@export var animation_id: String = "attack"
@export var damage_multiplier: float = 1.0

var cooldown_remaining: float = 0.0

func is_ready() -> bool:
	return cooldown_remaining <= 0.0

func tick(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

func reset_cooldown() -> void:
	cooldown_remaining = cooldown
