class_name FieldMonster
extends CharacterBody3D

const ATTACK_RANGE := 1.15
const TARGET_RETHINK_INTERVAL := 0.3
const TARGET_LOCK_DURATION := 0.7
const MONSTER_SEPARATION_RADIUS := 2.0
const MOVEMENT_RETHINK_INTERVAL := 0.1
const MOVE_ACCELERATION := 10.0

var arena: Node3D
var player: FieldPlayer
var monster_data: Dictionary
var health := 1.0
var attack_timer := 0.0
var target_rethink_timer := 0.0
var movement_rethink_timer := 0.0
var target_lock_remaining := 0.0
var stuck_timer := 0.0
var orbit_offset := 0.0
var movement_intent := Vector3.ZERO
var health_bar_timer := 0.0
var last_position := Vector3.ZERO
var dead := false
var body_mesh: MeshInstance3D
var health_bar: Label3D
var collision_shape: CollisionShape3D


func setup(game: Node3D, target: CharacterBody3D, data: Dictionary) -> void:
	arena = game
	player = target
	monster_data = data
	health = float(data["hp"])
	orbit_offset = float(get_instance_id() % 16) * TAU / 16.0
	var phase := float(get_instance_id() % 12) / 12.0
	target_rethink_timer = phase * TARGET_RETHINK_INTERVAL
	movement_rethink_timer = phase * MOVEMENT_RETHINK_INTERVAL
	last_position = global_position
	_build_visuals()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	collision_shape = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = float(monster_data.get("size", 0.7)) * 0.42
	shape.height = float(monster_data.get("size", 0.7)) * 1.45
	collision_shape.shape = shape
	collision_shape.position.y = shape.height * 0.5
	add_child(collision_shape)


func _build_visuals() -> void:
	var size := float(monster_data.get("size", 0.7))
	body_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, size)
	body_mesh.mesh = box
	body_mesh.position.y = size * 0.58
	body_mesh.scale.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = monster_data.get("color", Color.GREEN)
	material.roughness = 0.8
	body_mesh.material_override = material
	add_child(body_mesh)
	health_bar = Label3D.new()
	health_bar.position.y = size * 1.35
	health_bar.font_size = 24
	health_bar.pixel_size = 0.006
	health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar.modulate = Color("#fff2df")
	add_child(health_bar)
	_update_health_bar()
	health_bar.hide()


func apply_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	GameAudio.play_sfx("monster_hit")
	_update_health_bar()
	health_bar.show()
	health_bar_timer = 1.6
	arena.call("show_damage_number", global_position + Vector3.UP * 1.6, amount, false)
	if health <= 0.0:
		dead = true
		GameAudio.play_sfx("monster_death")
		set_physics_process(false)
		collision_shape.set_deferred("disabled", true)
		health_bar.hide()
		arena.call("monster_defeated", global_position, monster_data, self)
		var death_tween := create_tween()
		death_tween.tween_property(body_mesh, "scale", Vector3.ZERO, 0.22)
		death_tween.tween_callback(queue_free)


func _update_health_bar() -> void:
	health_bar.text = (
		"%s  %d%%"
		% [
			monster_data.get("name", "몬스터"),
			int(round(health / float(monster_data["hp"]) * 100.0)),
		]
	)


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector3.ZERO
		return
	if health_bar_timer > 0.0:
		health_bar_timer = maxf(0.0, health_bar_timer - delta)
		if health_bar_timer == 0.0:
			health_bar.hide()
	attack_timer = maxf(0.0, attack_timer - delta)
	target_lock_remaining = maxf(0.0, target_lock_remaining - delta)
	target_rethink_timer -= delta
	if (
		target_rethink_timer <= 0.0
		or not is_instance_valid(player)
		or player.dead
	):
		_select_target()
		target_rethink_timer = TARGET_RETHINK_INTERVAL
	if not is_instance_valid(player) or player.dead:
		movement_intent = Vector3.ZERO
		velocity.x = move_toward(velocity.x, 0.0, MOVE_ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_ACCELERATION * delta)
		move_and_slide()
		return

	var to_target := player.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	movement_rethink_timer -= delta
	if movement_rethink_timer <= 0.0:
		_update_movement_intent(distance)
		movement_rethink_timer = MOVEMENT_RETHINK_INTERVAL
	velocity.x = move_toward(velocity.x, movement_intent.x, MOVE_ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, movement_intent.z, MOVE_ACCELERATION * delta)
	var movement := Vector3(velocity.x, 0.0, velocity.z)
	if movement.length_squared() > 0.01:
		var target_yaw := atan2(-movement.x, -movement.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-8.0 * delta))
	if distance <= ATTACK_RANGE and attack_timer == 0.0:
		attack_timer = 1.25
		player.take_damage(float(monster_data["attack"]))

	var moved := global_position.distance_to(last_position)
	if movement_intent.length_squared() > 0.01 and moved < 0.015:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	last_position = global_position
	if stuck_timer >= 0.8:
		orbit_offset = fposmod(orbit_offset + PI / 4.0, TAU)
		stuck_timer = 0.0
		movement_rethink_timer = 0.0
	move_and_slide()
	if absf(global_position.x) > 12.5 or absf(global_position.z) > 12.5:
		global_position.x = clampf(global_position.x, -12.5, 12.5)
		global_position.z = clampf(global_position.z, -12.5, 12.5)


func _update_movement_intent(distance_to_target: float) -> void:
	var target_position := player.global_position
	if float(monster_data["speed"]) >= 3.0:
		target_position += player.velocity * 0.2
	var radial := Vector3(cos(orbit_offset), 0.0, sin(orbit_offset))
	var desired := target_position + radial - global_position
	desired.y = 0.0
	if distance_to_target > ATTACK_RANGE:
		desired += _monster_separation() * 0.8
	else:
		desired = _monster_separation()
	movement_intent = (
		desired.normalized() * float(monster_data["speed"])
		if desired.length_squared() > 0.01
		else Vector3.ZERO
	)


func _select_target() -> void:
	if (
		is_instance_valid(player)
		and not player.dead
		and target_lock_remaining > 0.0
	):
		return
	var allies: Array = []
	if arena != null:
		allies.append(arena.get("player"))
		allies.append_array(arena.get("companions"))
	var best_target: FieldPlayer
	var best_distance := INF
	for candidate in allies:
		if not is_instance_valid(candidate):
			continue
		var ally := candidate as FieldPlayer
		if ally == null or ally.dead:
			continue
		var offset := ally.global_position - global_position
		offset.y = 0.0
		var score := offset.length()
		if ally == player:
			score -= 0.6
		if score < best_distance:
			best_distance = score
			best_target = ally
	if best_target != null and best_target != player:
		player = best_target
		target_lock_remaining = TARGET_LOCK_DURATION


func _monster_separation() -> Vector3:
	if arena == null or not arena.has_method("get_enemies_near"):
		return Vector3.ZERO
	var separation := Vector3.ZERO
	for candidate in arena.call(
		"get_enemies_near", global_position, MONSTER_SEPARATION_RADIUS
	):
		if not is_instance_valid(candidate):
			continue
		var other := candidate as FieldMonster
		if other == null or other == self or other.dead:
			continue
		var away := global_position - other.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.01 and distance < MONSTER_SEPARATION_RADIUS:
			separation += away.normalized() * (
				1.0 - distance / MONSTER_SEPARATION_RADIUS
			)
	return separation
