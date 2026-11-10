class_name FieldMonster
extends CharacterBody3D

const ATTACK_RANGE := 1.15
const TARGET_RETHINK_INTERVAL := 0.6
const TARGET_LOCK_DURATION := 0.7
const MONSTER_SEPARATION_RADIUS := 2.0
const MOVEMENT_RETHINK_INTERVAL := 0.25
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
var model_root: Node3D
var animation_player: AnimationPlayer
var current_animation_kind := ""
var action_animation_kind := ""
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
	var scene_path: String = str(monster_data.get("scene", ""))
	if not scene_path.is_empty():
		var packed := load(scene_path) as PackedScene
		if packed != null:
			var model := packed.instantiate() as Node3D
			if model != null:
				model.name = "MonsterModel"
				model.scale = Vector3.ONE * size
				add_child(model)
				model_root = model
				var texture_path := str(monster_data.get("texture", ""))
				if not texture_path.is_empty():
					var texture := load(texture_path) as Texture2D
					if texture == null:
						push_error("몬스터 텍스처를 불러오지 못했습니다: %s" % texture_path)
					else:
						_apply_model_texture(model, texture)
				body_mesh = model as MeshInstance3D
				if body_mesh == null:
					body_mesh = _find_mesh_instance(model)
				animation_player = _find_animation_player(model)
				var animation_paths: Dictionary = monster_data.get("animations", {})
				_load_monster_animations(animation_paths)
				if animation_player != null:
					if not animation_player.animation_finished.is_connected(
						_on_monster_animation_finished
					):
						animation_player.animation_finished.connect(
							_on_monster_animation_finished
						)
					_play_monster_animation("idle")
				if body_mesh == null:
					body_mesh = null
					push_warning("몬스터 모델에서 MeshInstance3D를 찾지 못했습니다.")
				health_bar = Label3D.new()
				health_bar.position.y = size * 1.35
				health_bar.font_size = 24
				health_bar.pixel_size = 0.006
				health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				health_bar.modulate = Color("#fff2df")
				add_child(health_bar)
				_update_health_bar()
				health_bar.hide()
				return
	# 기본 박스 비주얼
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
	health_bar = Label3D.new()
	health_bar.position.y = size * 1.35
	health_bar.font_size = 24
	health_bar.pixel_size = 0.006
	health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar.modulate = Color("#fff2df")
	add_child(health_bar)
	_update_health_bar()
	health_bar.hide()


func _apply_model_texture(root: Node, texture: Texture2D) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var existing_material := mesh_instance.get_active_material(surface_index)
				var textured_material: BaseMaterial3D
				if existing_material is BaseMaterial3D:
					textured_material = (existing_material as BaseMaterial3D).duplicate() as BaseMaterial3D
				else:
					textured_material = StandardMaterial3D.new()
				textured_material.albedo_texture = texture
				textured_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mesh_instance.set_surface_override_material(surface_index, textured_material)
	for child in root.get_children():
		_apply_model_texture(child, texture)


func _load_monster_animations(animation_paths: Dictionary) -> void:
	if animation_paths.is_empty():
		return
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "MonsterAnimations"
		model_root.add_child(animation_player)
	animation_player.root_node = NodePath("..")
	var library := AnimationLibrary.new()
	for animation_kind in animation_paths:
		var scene_path := str(animation_paths[animation_kind])
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			push_error("몬스터 애니메이션을 불러오지 못했습니다: %s" % scene_path)
			continue
		var animation_scene := packed_scene.instantiate()
		var source_player := _find_animation_player(animation_scene)
		if source_player == null:
			push_error("애니메이션 파일에 AnimationPlayer가 없습니다: %s" % scene_path)
			animation_scene.free()
			continue
		var source_animation_name := _select_monster_source_animation(source_player)
		if source_animation_name.is_empty():
			push_error("재생 가능한 몬스터 애니메이션이 없습니다: %s" % scene_path)
			animation_scene.free()
			continue
		var animation := source_player.get_animation(source_animation_name).duplicate(true)
		_strip_monster_root_motion(animation)
		if animation_kind == "idle":
			_remove_idle_hip_tilt(animation)
		if animation_kind == "idle" or animation_kind == "walk":
			animation.loop_mode = Animation.LOOP_LINEAR
		else:
			animation.loop_mode = Animation.LOOP_NONE
		var error := library.add_animation(str(animation_kind), animation)
		if error != OK:
			push_error(
				"몬스터 애니메이션을 등록하지 못했습니다 (%s): %s"
				% [animation_kind, error_string(error)]
			)
		animation_scene.free()
	if library.get_animation_list().is_empty():
		return
	var error := animation_player.add_animation_library("monster", library)
	if error != OK:
		push_error("몬스터 애니메이션 라이브러리를 연결하지 못했습니다: %s" % error_string(error))


func _select_monster_source_animation(source_player: AnimationPlayer) -> String:
	for animation_name in source_player.get_animation_list():
		var name := str(animation_name)
		if name != "RESET" and not name.ends_with("/RESET"):
			return name
	return ""


func _strip_monster_root_motion(animation: Animation) -> void:
	var tracks_to_remove: Array[int] = []
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if not str(animation.track_get_path(track_index)).contains("bone_pose/position"):
			tracks_to_remove.append(track_index)
	tracks_to_remove.reverse()
	for track_index in tracks_to_remove:
		animation.remove_track(track_index)


func _remove_idle_hip_tilt(animation: Animation) -> void:
	var tracks_to_remove: Array[int] = []
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var track_path := str(animation.track_get_path(track_index)).to_lower()
		if track_path.contains("hips") and not track_path.contains("spine"):
			tracks_to_remove.append(track_index)
	tracks_to_remove.reverse()
	for track_index in tracks_to_remove:
		animation.remove_track(track_index)


func _find_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _play_monster_animation(kind: String) -> void:
	if animation_player == null:
		return
	var target := "monster/%s" % kind
	if not animation_player.has_animation(target):
		var keywords := {
			"idle": ["idle", "stand"],
			"walk": ["walk", "run", "move"],
			"attack": ["attack"],
			"hit": ["hit", "reaction"],
			"death": ["death", "dying", "die"],
		}
		for animation_name in animation_player.get_animation_list():
			var lower := str(animation_name).to_lower()
			for keyword in keywords.get(kind, []):
				if keyword in lower:
					target = str(animation_name)
					break
			if target != "monster/%s" % kind:
				break
	if not animation_player.has_animation(target):
		return
	if current_animation_kind == kind and animation_player.is_playing():
		return
	animation_player.play(target, 0.15)
	current_animation_kind = kind
	action_animation_kind = kind if kind in ["attack", "hit", "death"] else ""


func _on_monster_animation_finished(_animation_name: StringName) -> void:
	if dead and current_animation_kind == "death":
		queue_free()
		return
	current_animation_kind = ""
	action_animation_kind = ""

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
		var has_death_animation := animation_player != null
		if has_death_animation:
			_play_monster_animation("death")
			has_death_animation = current_animation_kind == "death"
		GameAudio.play_sfx("monster_death")
		set_physics_process(false)
		collision_shape.set_deferred("disabled", true)
		health_bar.hide()
		arena.call("monster_defeated", global_position, monster_data, self)
		if has_death_animation:
			return
		var target_node: Node3D = body_mesh if body_mesh != null else model_root
		if target_node != null:
			var death_tween := create_tween()
			death_tween.tween_property(target_node, "scale", Vector3.ZERO, 0.22)
			death_tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		_play_monster_animation("hit")


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
		_play_monster_animation("attack")
		player.take_damage(float(monster_data["attack"]))
	if action_animation_kind.is_empty():
		if movement_intent.length_squared() > 0.01:
			_play_monster_animation("walk")
		else:
			_play_monster_animation("idle")

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
	if best_target != player:
		player = best_target
		target_lock_remaining = TARGET_LOCK_DURATION if best_target != null else 0.0


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
