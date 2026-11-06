class_name AutoHuntController
extends Node

enum State { IDLE, SEARCH, MOVE_TO_TARGET, CASTING, GCD, STUNNED }
enum TargetingMode { CURRENT, NEAREST, LOWEST_HP }

@export var search_radius: float = 12.0
@export var targeting_mode: TargetingMode = TargetingMode.CURRENT

var player: FieldPlayer
var arena: Node3D
var state: State = State.IDLE
var current_target: Node3D = null
var skill_list: Array[SkillData] = []
var gcd_remaining: float = 0.0
var cast_remaining: float = 0.0
var pending_skill: SkillData = null
var stunned: bool = false

func setup(p: FieldPlayer, a: Node3D) -> void:
	player = p
	arena = a

func register_skill(skill: SkillData) -> void:
	skill_list.append(skill)

func update(delta: float) -> void:
	if player == null or player.dead or player.auto_hunt_disabled:
		return
	# CC 상태 체크
	if _is_cc():
		if state != State.STUNNED:
			state = State.STUNNED
		_tick_cooldowns(delta)
		_tick_gcd(delta)
		return
	if state == State.STUNNED:
		state = State.IDLE
	_tick_cooldowns(delta)
	_tick_gcd(delta)
	match state:
		State.IDLE, State.SEARCH:
			_search_target()
		State.MOVE_TO_TARGET:
			_move_to_target(delta)
		State.CASTING:
			_update_cast(delta)
		State.GCD:
			if gcd_remaining <= 0.0:
				state = State.SEARCH

func _is_cc() -> bool:
	return bool(player.get("stunned")) or bool(player.get("frozen")) or bool(player.get("silenced"))

func _tick_cooldowns(delta: float) -> void:
	for s in skill_list:
		s.tick(delta)

func _tick_gcd(delta: float) -> void:
	gcd_remaining = maxf(0.0, gcd_remaining - delta)

func _search_target() -> void:
	var candidates := _collect_enemies_in_radius(search_radius)
	if candidates.is_empty():
		state = State.IDLE
		current_target = null
		return
	if not is_instance_valid(current_target) or current_target.dead:
		current_target = _pick_default(candidates)
	else:
		match targeting_mode:
			TargetingMode.NEAREST:
				current_target = _nearest(candidates)
			TargetingMode.LOWEST_HP:
				current_target = _lowest_hp(candidates)
			_:
				if not candidates.has(current_target):
					current_target = _nearest(candidates)
	if not is_instance_valid(current_target):
		state = State.IDLE
		return
	_try_cast_or_move()

func _try_cast_or_move() -> void:
	var ready := _ready_skills_sorted()
	for skill in ready:
		if _in_range(current_target, skill.range):
			_start_cast(skill)
			return
	# 기본 공격 사거리
	if _in_range(current_target, player.attack_range):
		player.try_basic_attack()
		state = State.GCD
		gcd_remaining = player.attack_cooldown_duration
		return
	state = State.MOVE_TO_TARGET

func _start_cast(skill: SkillData) -> void:
	pending_skill = skill
	cast_remaining = skill.cast_time * player.casting_time_multiplier
	state = State.CASTING
	player.play_skill_animation(skill.animation_id, skill.cast_time)
	player.skill_movement_locked = true

func _update_cast(delta: float) -> void:
	cast_remaining -= delta
	if cast_remaining > 0.0:
		return
	# 시전 완료 → 효과 적용
	if is_instance_valid(current_target) and not current_target.dead:
		if arena != null and arena.has_method("apply_skill"):
			arena.call("apply_skill", player, pending_skill, current_target)
	pending_skill.reset_cooldown()
	state = State.GCD
	gcd_remaining = pending_skill.gcd
	pending_skill = null
	player._release_skill_movement()

func _move_to_target(delta: float) -> void:
	if not is_instance_valid(current_target) or current_target.dead:
		current_target = null
		state = State.SEARCH
		return
	var dir := current_target.global_position - player.global_position
	dir.y = 0.0
	if dir.length() <= 0.1:
		state = State.SEARCH
		return
	var nav_agent := player.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	var move_dir := dir
	if nav_agent != null:
		nav_agent.target_position = current_target.global_position
		var next_pos := nav_agent.get_next_path_position()
		move_dir = next_pos - player.global_position
		move_dir.y = 0.0
	if move_dir.length_squared() <= 0.001:
		move_dir = dir
	move_dir = move_dir.normalized()
	var speed := player.move_speed * (1.65 if player.running else 1.0)
	player.velocity.x = move_dir.x * speed
	player.velocity.z = move_dir.z * speed
	player.move_and_slide()
	if _in_range(current_target, _min_skill_range()):
		state = State.SEARCH

func _collect_enemies_in_radius(r: float) -> Array:
	var result: Array = []
	if arena == null:
		return result
	var enemies: Array = []
	if arena.has_method("get_enemies"):
		enemies = arena.call("get_enemies")
	for enemy in enemies:
		var node := enemy as Node3D
		if is_instance_valid(node) and not (node.get("dead") == true) \
		   and node.global_position.distance_to(player.global_position) <= r:
			result.append(node)
	return result

func _ready_skills_sorted() -> Array:
	var ready := skill_list.filter(func(s): return s.is_ready())
	ready.sort_custom(func(a, b): return int(a.skill_type) < int(b.skill_type))
	return ready

func _in_range(target: Node3D, r: float) -> bool:
	return is_instance_valid(target) and target.global_position.distance_to(player.global_position) <= r

func _nearest(arr: Array) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for e in arr:
		var enemy := e as Node3D
		var d := enemy.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _lowest_hp(arr: Array) -> Node3D:
	var best: Node3D = null
	var best_hp := INF
	for e in arr:
		var enemy := e as Node3D
		var hp := float(enemy.get("health"))
		if hp < best_hp:
			best_hp = hp
			best = e
	return best

func _pick_default(arr: Array) -> Node3D:
	if is_instance_valid(current_target) and not current_target.dead and arr.has(current_target):
		return current_target
	return _nearest(arr)

func _min_skill_range() -> float:
	var r := player.attack_range
	for s in skill_list:
		r = minf(r, s.range)
	return r
