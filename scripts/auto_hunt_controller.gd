class_name AutoHuntController
extends Node

enum State { IDLE, SEARCH, APPROACH, POSITION, ATTACK, STUNNED }

@export var search_radius: float = 14.0
@export var decision_interval: float = 0.18
@export var target_lock_duration: float = 0.75
@export var target_switch_margin: float = 2.0
@export var preferred_ranged_ratio: float = 0.78

var player: FieldPlayer
var arena: Node3D
var state: State = State.IDLE
var current_target: FieldMonster
var desired_move_direction := Vector3.ZERO
var _decision_timer := 0.0
var _target_lock_remaining := 0.0
var _stuck_time := 0.0
var _slot_offset := 0
var _last_position := Vector3.ZERO


func setup(actor: FieldPlayer, field: Node3D) -> void:
	player = actor
	arena = field
	_last_position = actor.position


func update(delta: float) -> void:
	if not is_instance_valid(player) or player.dead:
		current_target = null
		desired_move_direction = Vector3.ZERO
		state = State.IDLE
		return
	if player.auto_hunt_disabled:
		desired_move_direction = Vector3.ZERO
		state = State.IDLE
		return

	_target_lock_remaining = maxf(0.0, _target_lock_remaining - delta)
	if _is_crowd_controlled():
		desired_move_direction = Vector3.ZERO
		state = State.STUNNED
		_last_position = player.global_position
		return
	if state == State.STUNNED:
		state = State.SEARCH

	_decision_timer -= delta
	if (
		_decision_timer <= 0.0
		or not is_instance_valid(current_target)
		or current_target.dead
		or not _in_search_radius(current_target)
	):
		_select_target()
		_decision_timer = decision_interval

	if not is_instance_valid(current_target):
		desired_move_direction = Vector3.ZERO
		state = State.IDLE
		_last_position = player.global_position
		return

	_update_movement_intent(delta)
	_try_basic_attack()


func _is_crowd_controlled() -> bool:
	return player.stunned or player.frozen


func _select_target() -> void:
	var candidates := _collect_enemies_in_radius(search_radius)
	if candidates.is_empty():
		current_target = null
		state = State.IDLE
		return

	if (
		is_instance_valid(current_target)
		and not current_target.dead
		and _in_search_radius(current_target)
		and _target_lock_remaining > 0.0
	):
		return

	var best_target: FieldMonster
	var best_score := -INF
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var monster := candidate as FieldMonster
		if monster == null or monster.dead:
			continue
		var score := _target_score(monster)
		if score > best_score:
			best_score = score
			best_target = monster

	if (
		is_instance_valid(current_target)
		and not current_target.dead
		and _in_search_radius(current_target)
		and best_target != current_target
		and best_score < _target_score(current_target) + target_switch_margin
	):
		return

	if best_target != current_target:
		current_target = best_target
		_target_lock_remaining = target_lock_duration
		_slot_offset = 0
	state = State.APPROACH if is_instance_valid(current_target) else State.IDLE


func _target_score(target: FieldMonster) -> float:
	var distance := _horizontal_distance(player.global_position, target.global_position)
	var maximum_health := maxf(1.0, float(target.monster_data.get("hp", 1.0)))
	var health_ratio := clampf(target.health / maximum_health, 0.0, 1.0)
	var score := search_radius - distance
	score += (1.0 - health_ratio) * 2.0
	score += float(target.monster_data.get("attack", 0.0)) * 0.04
	score += float(target.monster_data.get("speed", 0.0)) * 0.15
	if target.player == player:
		score += 3.0
	if target == current_target:
		score += 1.0
	return score


func _update_movement_intent(delta: float) -> void:
	if player.input_direction.length_squared() > 0.01:
		desired_move_direction = Vector3.ZERO
		state = State.ATTACK if _target_in_attack_range() else State.POSITION
		_last_position = player.global_position
		return

	var attack_range := player.attack_range * player.hitbox_size_multiplier
	var ranged := player.attack_style != "melee"
	var preferred_distance := (
		clampf(attack_range * preferred_ranged_ratio, 3.5, attack_range - 0.5)
		if ranged
		else minf(1.15, attack_range * 0.78)
	)
	var angle := (
		TAU * float(player.formation_slot) / float(GameData.party_size)
		+ float(_slot_offset) * PI / 4.0
	)
	var radial := Vector3(cos(angle), 0.0, sin(angle))
	var goal := current_target.global_position + radial * preferred_distance
	var to_goal := goal - player.global_position
	to_goal.y = 0.0
	var separation := _ally_separation()
	var combined := to_goal + separation * 0.9
	var distance := _horizontal_distance(player.global_position, current_target.global_position)
	var comfortable := absf(distance - preferred_distance) <= 0.35

	if comfortable and separation.length_squared() < 0.01:
		desired_move_direction = Vector3.ZERO
		state = State.ATTACK if distance <= attack_range else State.POSITION
	else:
		desired_move_direction = (
			combined.normalized() if combined.length_squared() > 0.01 else Vector3.ZERO
		)
		state = State.POSITION if distance <= attack_range else State.APPROACH

	_update_stuck_recovery(delta)


func _update_stuck_recovery(delta: float) -> void:
	var moved := player.global_position.distance_to(_last_position)
	if desired_move_direction.length_squared() > 0.01 and moved < 0.015:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	_last_position = player.global_position
	if _stuck_time >= 0.7:
		_slot_offset = (_slot_offset + 1) % 8
		_stuck_time = 0.0
		_target_lock_remaining = minf(_target_lock_remaining, 0.2)
		state = State.POSITION


func _ally_separation() -> Vector3:
	var separation := Vector3.ZERO
	if arena == null:
		return separation
	var allies: Array = [arena.get("player")]
	allies.append_array(arena.get("companions"))
	for candidate in allies:
		if not is_instance_valid(candidate):
			continue
		var ally := candidate as FieldPlayer
		if ally == null or ally == player or ally.dead:
			continue
		var away := player.global_position - ally.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.01 and distance < 1.5:
			separation += away.normalized() * (1.5 - distance)
	return separation


func _try_basic_attack() -> void:
	if not _target_in_attack_range():
		return
	state = State.ATTACK
	player.try_basic_attack(current_target)


func _target_in_attack_range() -> bool:
	return (
		is_instance_valid(current_target)
		and not current_target.dead
		and _horizontal_distance(player.global_position, current_target.global_position)
		<= player.attack_range * player.hitbox_size_multiplier
	)


func _in_search_radius(target: FieldMonster) -> bool:
	return (
		is_instance_valid(target)
		and _horizontal_distance(player.global_position, target.global_position) <= search_radius
	)


func _collect_enemies_in_radius(radius: float) -> Array:
	if arena == null:
		return []
	if arena.has_method("get_enemies_near"):
		return arena.call("get_enemies_near", player.global_position, radius)
	if arena.has_method("get_enemies"):
		var nearby: Array = []
		for enemy in arena.call("get_enemies"):
			if not is_instance_valid(enemy):
				continue
			var monster := enemy as FieldMonster
			if monster != null and not monster.dead:
				if _horizontal_distance(player.global_position, monster.global_position) <= radius:
					nearby.append(monster)
		return nearby
	return []


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)
