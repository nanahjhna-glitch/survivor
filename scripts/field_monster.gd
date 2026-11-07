class_name FieldMonster
extends CharacterBody3D

var arena: Node3D
var player: FieldPlayer
var monster_data: Dictionary
var health := 1.0
var attack_timer := 0.0
var dead := false
var body_mesh: MeshInstance3D
var health_bar: Label3D
var collision_shape: CollisionShape3D


func setup(game: Node3D, target: CharacterBody3D, data: Dictionary) -> void:
	arena = game
	player = target
	monster_data = data
	health = float(data["hp"])
	_build_visuals()


func _ready() -> void:
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


func apply_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	GameAudio.play_sfx("monster_hit")
	_update_health_bar()
	arena.call("show_damage_number", global_position + Vector3.UP * 1.6, amount, false)
	if health <= 0.0:
		dead = true
		GameAudio.play_sfx("monster_death")
		set_physics_process(false)
		collision_shape.set_deferred("disabled", true)
		health_bar.hide()
		arena.call("monster_defeated", global_position, monster_data)
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
	var target: FieldPlayer = null
	if is_instance_valid(player) and not player.dead:
		target = player
	for companion in (arena.get("companions") if arena != null else []):
		if is_instance_valid(companion) and not companion.dead:
			if target == null or global_position.distance_to(companion.global_position) < global_position.distance_to(target.global_position):
				target = companion
	if target == null:
		velocity = Vector3.ZERO
		return
	player = target
	attack_timer = maxf(0.0, attack_timer - delta)
	var offset := player.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > 1.15:
		var direction := offset.normalized()
		velocity.x = direction.x * float(monster_data["speed"])
		velocity.z = direction.z * float(monster_data["speed"])
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer == 0.0:
			attack_timer = 1.25
			player.take_damage(float(monster_data["attack"]))
	move_and_slide()
	if absf(global_position.x) > 5.5 or absf(global_position.z) > 5.5:
		global_position.x = clampf(global_position.x, -7.5, 7.5)
		global_position.z = clampf(global_position.z, -7.5, 7.5)
