class_name FieldPlayer
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal experience_changed(current: int, required: int)
signal level_changed(level: int, unlocked_skill: int)
signal player_died

const WALK_SPEED := 4.2
const RUN_MULTIPLIER := 1.65
const ATTACK_COOLDOWN := 0.55
const BASE_EXPERIENCE_MAGNET_RANGE := 0.9
const MELEE_ATTACK_RANGE := 1.5
const ANIMATION_BLEND_TIME := 0.16
const TURN_SPEED := 9.0
const MOVE_ACCELERATION := 18.0
const MOVE_DECELERATION := 22.0
const IDLE_SPEED_THRESHOLD := 0.12
const RUN_ANIMATION_ENTER_SPEED := WALK_SPEED * 1.2
const RUN_ANIMATION_EXIT_SPEED := WALK_SPEED * 1.08
const ANIMATION_SPEED_SMOOTHING := 12.0

var arena: Node3D
var level := 1
var experience := 0
var next_level_experience := CombatData.XP_PER_LEVEL
var max_health := 100.0
var health := 100.0
var attack_damage := 12.0
var move_speed := WALK_SPEED
var hitbox_size_multiplier := 1.0
var attack_cooldown_duration := ATTACK_COOLDOWN
var experience_magnet_range := BASE_EXPERIENCE_MAGNET_RANGE
var attributes: Dictionary = {}
var attack_style := "melee"
var attack_range := 2.2
var flee_chance := 0.0
var physical_defense := 0.0
var hp_regen_per_second := 0.0
var hit_chance := 0.9
var critical_chance := 0.05
var perfect_dodge_chance := 0.0
var casting_time_multiplier := 1.0
var attack_cooldown := 0.0
var input_direction := Vector2.ZERO
var running := false
var dead := false
var auto_hunt_disabled := false
var stunned := false
var frozen := false
var silenced := false
var auto_hunt_controller: AutoHuntController = null
var invulnerability_time := 0.0
var visual_root: Node3D
var model_animation_player: AnimationPlayer
var world_hp_fill: MeshInstance3D
var current_model_animation := ""
var action_animation_remaining := 0.0
var skill_movement_locked := false
var skill_animation_name := ""
var skill_movement_lock_remaining := 0.0
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var casting_skill_index := -1
var skill_cast_remaining := 0.0
var facing_target: Node3D
var movement_animation_state := "idle"
var animation_playback_speed := 1.0
var legs: Array[MeshInstance3D] = []
var weapon: MeshInstance3D
var animation_clock := 0.0
var attack_animation_time := 0.0
var regen_timer := 0.0
var random := RandomNumberGenerator.new()


func setup(game: Node3D, character: Dictionary) -> void:
	arena = game
	level = 1
	next_level_experience = CombatData.XP_PER_LEVEL
	attributes = character.get("attributes", {}).duplicate()
	for key in GameData.permanent_stats:
		attributes[key] = int(attributes.get(key, 1)) + int(GameData.permanent_stats[key])
	var agility := float(attributes["AGI"])
	var vitality := float(attributes["VIT"])
	var intelligence := float(attributes["INT"])
	var dexterity := float(attributes["DEX"])
	var luck := float(attributes["LUK"])
	attack_style = character.get("attack_style", "melee")
	attack_range = 8.0 if attack_style != "melee" else MELEE_ATTACK_RANGE
	max_health = 100.0 + vitality * 12.0
	health = max_health
	move_speed = WALK_SPEED
	attack_damage = 12.0
	attack_cooldown_duration = maxf(0.22, ATTACK_COOLDOWN / (1.0 + agility * 0.035))
	flee_chance = minf(0.35, agility * 0.012)
	physical_defense = vitality * 0.6
	hp_regen_per_second = 0.2 + vitality * 0.08
	hit_chance = clampf(0.8 + dexterity * 0.02, 0.7, 0.99)
	critical_chance = minf(0.5, 0.05 + luck * 0.015)
	perfect_dodge_chance = minf(0.2, luck * 0.006)
	casting_time_multiplier = clampf(1.0 - intelligence * 0.025 - dexterity * 0.02, 0.4, 1.0)
	experience_magnet_range = BASE_EXPERIENCE_MAGNET_RANGE
	random.randomize()
	auto_hunt_controller = AutoHuntController.new()
	auto_hunt_controller.setup(self, arena)
	add_child(auto_hunt_controller)
	health_changed.connect(_update_world_health_bar)
	_build_body(character)
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, next_level_experience)


func _ready() -> void:
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.65
	collider.shape = shape
	collider.position.y = 0.83
	add_child(collider)


func _build_body(character: Dictionary) -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.scale = Vector3.ONE * 1.2
	_build_world_health_bar()
	if _build_model_visual(character):
		return
	var tunic_color: Color = character.get("color", Color("#59a9e8"))
	var character_name: String = character.get("name", "")
	_add_block(Vector3(0, 1.28, 0), Vector3(0.58, 0.56, 0.42), Color("#edbd83"))
	_add_block(Vector3(0, 0.77, 0), Vector3(0.72, 0.62, 0.46), tunic_color)
	_add_block(Vector3(-0.39, 0.82, 0), Vector3(0.2, 0.56, 0.24), Color("#edbd83"))
	_add_block(Vector3(0.39, 0.82, 0), Vector3(0.2, 0.56, 0.24), Color("#edbd83"))
	var left_leg := _add_block(Vector3(-0.18, 0.31, 0), Vector3(0.25, 0.46, 0.3), Color("#454f68"))
	var right_leg := _add_block(Vector3(0.18, 0.31, 0), Vector3(0.25, 0.46, 0.3), Color("#454f68"))
	legs = [left_leg, right_leg]
	_add_block(Vector3(0, 1.64, 0.06), Vector3(0.63, 0.16, 0.5), Color("#795137"))
	_add_block(Vector3(-0.17, 1.31, -0.22), Vector3(0.07, 0.09, 0.05), Color("#28313d"))
	_add_block(Vector3(0.17, 1.31, -0.22), Vector3(0.07, 0.09, 0.05), Color("#28313d"))

	match character_name:
		"견습 기사":
			_add_knight_details()
		"숲의 궁수":
			_add_archer_details()
		"별빛 마법사":
			_add_mage_details(tunic_color)
		_:
			weapon = _add_block(
				Vector3(0.49, 0.94, -0.05), Vector3(0.12, 0.82, 0.12), Color("#b9dbe1")
			)


func _build_world_health_bar() -> void:
	var bar_root := Node3D.new()
	bar_root.name = "WorldHealthBar"
	bar_root.position = Vector3(0.0, 2.75, 0.0)
	add_child(bar_root)
	var background := MeshInstance3D.new()
	var background_mesh := QuadMesh.new()
	background_mesh.size = Vector2(1.05, 0.12)
	background.mesh = background_mesh
	var background_material := StandardMaterial3D.new()
	background_material.albedo_color = Color("#202a31")
	background_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	background_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	background.material_override = background_material
	bar_root.add_child(background)
	world_hp_fill = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(1.0, 0.08)
	world_hp_fill.mesh = fill_mesh
	var fill_material := StandardMaterial3D.new()
	fill_material.albedo_color = Color("#db6558")
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	world_hp_fill.material_override = fill_material
	bar_root.add_child(world_hp_fill)
	_update_world_health_bar(health, max_health)


func _update_world_health_bar(current: float, maximum: float) -> void:
	if world_hp_fill == null or maximum <= 0.0:
		return
	var ratio := clampf(current / maximum, 0.0, 1.0)
	world_hp_fill.scale = Vector3(maxf(ratio, 0.001), 1.0, 1.0)
	world_hp_fill.position.x = -(1.0 - ratio) * 0.5


func _build_model_visual(character: Dictionary) -> bool:
	var visual: Dictionary = character.get("visual", {})
	var scene_path: String = visual.get("scene", "")
	if scene_path.is_empty():
		return false
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("캐릭터 모델을 불러오지 못했습니다: %s" % scene_path)
		return false
	var model_instance := packed_scene.instantiate()
	var model := model_instance as Node3D
	if model == null:
		# 루트가 Node3D가 아닌 경우 래퍼로 감싸 렌더링 보장
		var wrapper := Node3D.new()
		wrapper.name = "CharacterModelWrapper"
		wrapper.add_child(model_instance)
		model = wrapper
	model.name = "CharacterModel"
	model.scale = Vector3.ONE * float(visual.get("scale", 1.0))
	model.rotation.y = deg_to_rad(float(visual.get("forward_rotation_degrees", 0.0)))
	model.position.y += float(visual.get("vertical_offset", 0.0))
	visual_root.add_child(model)
	_apply_character_texture(model, str(visual.get("texture", "")))
	model_animation_player = _find_animation_player(model)
	var animation_paths: Dictionary = visual.get("animations", {})
	if model_animation_player == null and not animation_paths.is_empty():
		model_animation_player = AnimationPlayer.new()
		model_animation_player.name = "CharacterAnimations"
		model_animation_player.root_node = NodePath("..")
		model.add_child(model_animation_player)
	_load_character_animations(animation_paths)
	if model_animation_player != null:
		model_animation_player.animation_finished.connect(_on_character_animation_finished)
	return true


func _apply_character_texture(model: Node, texture_path: String) -> void:
	if texture_path.is_empty():
		return
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("캐릭터 텍스처를 불러오지 못했습니다: %s" % texture_path)
		return
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.9
	_apply_material_to_meshes(model, material)


func _apply_material_to_meshes(root: Node, material: StandardMaterial3D) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = material
	for child in root.get_children():
		_apply_material_to_meshes(child, material)


func _load_character_animations(animation_paths: Dictionary) -> void:
	if model_animation_player == null or animation_paths.is_empty():
		return
	var library := AnimationLibrary.new()
	for animation_id in animation_paths:
		var animation_config: Variant = animation_paths[animation_id]
		var scene_path := ""
		var clip_hint := ""
		if animation_config is Dictionary:
			scene_path = str(animation_config.get("scene", ""))
			clip_hint = str(animation_config.get("clip", ""))
		else:
			scene_path = str(animation_config)
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			push_error("캐릭터 애니메이션을 불러오지 못했습니다: %s" % scene_path)
			continue
		var animation_scene := packed_scene.instantiate()
		var source_player := _find_animation_player(animation_scene)
		if source_player == null:
			push_error("애니메이션 파일에 AnimationPlayer가 없습니다: %s" % scene_path)
			animation_scene.free()
			continue
		var animation_name := _select_imported_animation(source_player, clip_hint, scene_path)
		if animation_name.is_empty():
			push_error("재생 가능한 애니메이션이 없습니다: %s" % scene_path)
			animation_scene.free()
			continue
		var animation := source_player.get_animation(animation_name).duplicate(true)
		_strip_root_motion_tracks(animation)
		if animation_id == "walk" or animation_id == "run" or animation_id == "idle":
			animation.loop_mode = Animation.LOOP_LINEAR
		else:
			animation.loop_mode = Animation.LOOP_NONE
		library.add_animation(str(animation_id), animation)
		animation_scene.free()
	if library.get_animation_list().is_empty():
		return
	var target_library: AnimationLibrary
	if model_animation_player.has_animation_library("character"):
		target_library = model_animation_player.get_animation_library("character")
	else:
		var error := model_animation_player.add_animation_library("character", library)
		if error != OK:
			push_error("캐릭터 애니메이션 라이브러리를 연결하지 못했습니다: %s" % error_string(error))
			return
		target_library = library
	if target_library != library:
		for animation_id in library.get_animation_list():
			if target_library.has_animation(animation_id):
				target_library.remove_animation(animation_id)
			var error := target_library.add_animation(
				animation_id, library.get_animation(animation_id)
			)
			if error != OK:
				push_error("캐릭터 애니메이션을 등록하지 못했습니다 (%s): %s" % [animation_id, error_string(error)])
	if not _has_character_animation("walk"):
		push_error("캐릭터에 걷기 애니메이션이 등록되지 않았습니다.")


func _strip_root_motion_tracks(animation: Animation) -> void:
	var tracks_to_remove: Array[int] = []
	for track_index in range(animation.get_track_count()):
		var track_path := str(animation.track_get_path(track_index))
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		# Bone pose positions contain the imported skeleton's bind/rest offsets.
		if not track_path.contains("bone_pose/position"):
			tracks_to_remove.append(track_index)
	tracks_to_remove.reverse()
	for track_index in tracks_to_remove:
		animation.remove_track(track_index)


func _select_imported_animation(
	animation_player: AnimationPlayer, clip_hint: String, scene_path: String
) -> String:
	var available: Array[String] = []
	for animation_name in animation_player.get_animation_list():
		var name := str(animation_name)
		if name != "RESET" and not name.ends_with("/RESET"):
			available.append(name)
	if available.is_empty():
		return ""
	if not clip_hint.is_empty():
		var matches: Array[String] = []
		for name in available:
			if name.to_lower().contains(clip_hint.to_lower()):
				matches.append(name)
		if matches.size() == 1:
			return matches[0]
		if matches.size() > 1:
			return matches[0]
	if available.size() == 1:
		return available[0]
	push_error("FBX에서 사용할 클립을 하나로 결정할 수 없습니다 (%s): %s" % [scene_path, ", ".join(available)])
	return ""


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func play_character_animation(
	animation_id: String, playback_speed := 1.0, blend_time := ANIMATION_BLEND_TIME
) -> float:
	if model_animation_player == null:
		return 0.0
	var animation_name := "character/%s" % animation_id
	if not _has_character_animation(animation_id):
		return 0.0
	if current_model_animation == animation_name and model_animation_player.is_playing():
		model_animation_player.speed_scale = playback_speed
		return model_animation_player.current_animation_length
	model_animation_player.play(animation_name, blend_time, playback_speed)
	current_model_animation = animation_name
	return model_animation_player.current_animation_length


func play_skill_animation(animation_id: String, minimum_duration: float) -> float:
	skill_animation_name = "character/%s" % animation_id
	# 스킬 사용 중에도 이동을 허용한다 (하체 걷기 애니메이션 적용).
	skill_movement_locked = false
	var animation_length := play_character_animation(animation_id, 1.0, 0.0)
	skill_movement_lock_remaining = maxf(animation_length, minimum_duration)
	action_animation_remaining = skill_movement_lock_remaining
	return animation_length


func set_facing_target(target: Node3D) -> void:
	facing_target = target


func _turn_toward(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = target_yaw


func _on_character_animation_finished(animation_name: StringName) -> void:
	if skill_movement_locked and animation_name == skill_animation_name:
		_release_skill_movement()


func _release_skill_movement() -> void:
	skill_movement_locked = false
	skill_animation_name = ""
	skill_movement_lock_remaining = 0.0
	action_animation_remaining = 0.0
	facing_target = null


func _has_character_animation(animation_id: String) -> bool:
	return (
		model_animation_player != null
		and model_animation_player.has_animation("character/%s" % animation_id)
	)


func _add_knight_details() -> void:
	var silver := Color("#bac8d1")
	var steel_dark := Color("#718594")
	_add_block(Vector3(0, 1.74, 0.02), Vector3(0.68, 0.16, 0.52), silver)
	_add_block(Vector3(0, 1.46, -0.22), Vector3(0.48, 0.08, 0.06), steel_dark)
	_add_block(Vector3(0, 1.43, -0.27), Vector3(0.24, 0.06, 0.04), Color("#f0c65b"))
	_add_block(Vector3(-0.42, 1.08, 0), Vector3(0.26, 0.2, 0.52), silver)
	_add_block(Vector3(0.42, 1.08, 0), Vector3(0.26, 0.2, 0.52), silver)
	_add_block(Vector3(0, 0.78, -0.25), Vector3(0.22, 0.3, 0.06), Color("#f0c65b"))
	weapon = _add_block(Vector3(0.5, 0.99, -0.08), Vector3(0.13, 0.92, 0.13), Color("#d9e3e7"))
	_add_block(Vector3(0.5, 0.57, -0.08), Vector3(0.22, 0.12, 0.18), Color("#805032"))


func _add_archer_details() -> void:
	var hood := Color("#397751")
	var leather := Color("#865b3c")
	var leaf := Color("#b8d77a")
	_add_block(Vector3(0, 1.58, 0.04), Vector3(0.72, 0.28, 0.58), hood)
	_add_block(Vector3(0, 1.4, -0.24), Vector3(0.58, 0.16, 0.2), hood)
	_add_block(Vector3(-0.39, 1.15, 0.02), Vector3(0.18, 0.62, 0.3), hood)
	_add_block(Vector3(0.39, 1.15, 0.02), Vector3(0.18, 0.62, 0.3), hood)
	_add_block(Vector3(0, 0.77, -0.25), Vector3(0.12, 0.36, 0.06), leather)
	_add_block(Vector3(0.08, 0.78, -0.29), Vector3(0.07, 0.28, 0.04), leaf)
	_add_block(Vector3(-0.39, 0.92, 0.28), Vector3(0.3, 0.48, 0.22), leather)
	_add_block(Vector3(-0.39, 1.2, 0.28), Vector3(0.36, 0.12, 0.25), Color("#cba36a"))
	_add_block(Vector3(-0.44, 1.0, -0.24), Vector3(0.08, 0.12, 0.04), Color("#e0c58b"))
	weapon = _add_block(Vector3(0.52, 1.02, 0.0), Vector3(0.08, 0.88, 0.08), Color("#d7a85e"))
	_add_block(Vector3(0.48, 1.4, 0), Vector3(0.1, 0.14, 0.1), Color("#f1e4b7"))


func _add_mage_details(tunic_color: Color) -> void:
	var trim := Color("#f0d47a")
	var hat := Color("#66509f")
	var skin := Color("#edbd83")
	_add_block(Vector3(0, 1.7, 0.02), Vector3(0.72, 0.13, 0.58), hat)
	_add_block(Vector3(0, 1.82, 0.06), Vector3(0.52, 0.14, 0.43), hat)
	_add_block(Vector3(0, 1.95, 0.1), Vector3(0.3, 0.12, 0.28), hat)
	_add_block(Vector3(0, 2.05, 0.13), Vector3(0.14, 0.1, 0.14), hat)
	_add_block(Vector3(0, 1.63, 0.02), Vector3(0.34, 0.07, 0.08), trim)
	_add_block(Vector3(-0.18, 1.08, 0), Vector3(0.22, 0.42, 0.48), tunic_color.darkened(0.16))
	_add_block(Vector3(0.18, 1.08, 0), Vector3(0.22, 0.42, 0.48), tunic_color.darkened(0.16))
	_add_block(Vector3(0, 1.13, -0.26), Vector3(0.12, 0.32, 0.08), skin)
	_add_block(Vector3(0, 0.78, -0.27), Vector3(0.18, 0.3, 0.06), trim)
	_add_block(Vector3(-0.39, 0.9, -0.27), Vector3(0.18, 0.13, 0.08), trim)
	_add_block(Vector3(0.39, 0.9, -0.27), Vector3(0.18, 0.13, 0.08), trim)
	weapon = _add_block(Vector3(0.52, 1.0, -0.04), Vector3(0.1, 1.0, 0.1), Color("#755834"))
	_add_block(Vector3(0.52, 1.57, -0.04), Vector3(0.24, 0.24, 0.24), Color("#77e8ed"))


func _add_block(at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	block.mesh = mesh
	block.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	block.material_override = material
	visual_root.add_child(block)
	return block


func set_controls(direction: Vector2, is_running: bool) -> void:
	input_direction = direction.limit_length(1.0)
	running = is_running


func set_auto_hunt_disabled(disabled: bool) -> void:
	auto_hunt_disabled = disabled


func try_basic_attack() -> void:
	if dead or attack_cooldown > 0.0 or action_animation_remaining > 0.0:
		return
	attack_cooldown = attack_cooldown_duration
	attack_animation_time = 0.28
	action_animation_remaining = maxf(play_character_animation("attack", 1.0, 0.0), 0.55)
	GameAudio.play_sfx("attack")
	arena.call(
		"perform_basic_attack", self, attack_damage, attack_range * hitbox_size_multiplier, 1.5
	)


func calculate_outgoing_damage(base_damage: float, damage_type: String, is_ranged: bool) -> float:
	if random.randf() > hit_chance:
		return 0.0
	var scaled_damage := base_damage
	match damage_type:
		"physical":
			if is_ranged:
				scaled_damage += float(attributes["DEX"]) * 1.8
			else:
				scaled_damage += float(attributes["STR"]) * 2.0
		"magic":
			scaled_damage *= 1.0 + float(attributes["INT"]) * 0.035
	if random.randf() < critical_chance:
		scaled_damage *= 1.75
	return scaled_damage


func apply_level_up_card(card_id: String) -> void:
	match card_id:
		"power":
			attack_damage += 8.0
		"area":
			hitbox_size_multiplier *= 1.15
		"vitality":
			max_health += 20.0
			health = minf(max_health, health + 20.0)
			health_changed.emit(health, max_health)
		"haste":
			attack_cooldown_duration = maxf(0.2, attack_cooldown_duration * 0.85)
		"swift":
			move_speed *= 1.12
		"magnet":
			experience_magnet_range += 2.0
		_:
			push_error("등록되지 않은 레벨업 카드입니다: %s" % card_id)


func take_damage(amount: float) -> void:
	if dead or invulnerability_time > 0.0:
		return
	if random.randf() < perfect_dodge_chance or random.randf() < flee_chance:
		GameAudio.play_sfx("dodge")
		arena.call("show_damage_number", global_position + Vector3.UP * 1.6, 0.0, false)
		return
	var mitigated_damage := maxf(1.0, amount - physical_defense)
	health = maxf(0.0, health - mitigated_damage)
	invulnerability_time = 0.4
	GameAudio.play_sfx("player_hit")
	health_changed.emit(health, max_health)
	arena.call("show_damage_number", global_position + Vector3.UP * 1.6, mitigated_damage, true)
	if health <= 0.0:
		dead = true
		player_died.emit()


func heal(amount: float) -> bool:
	if dead or health >= max_health:
		return false
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)
	return true


func gain_experience(amount: int) -> void:
	if dead or amount <= 0:
		return
	experience += amount
	while experience >= next_level_experience:
		experience -= next_level_experience
		level += 1
		next_level_experience = CombatData.XP_PER_LEVEL + (level - 1) * CombatData.XP_PER_LEVEL_STEP
		var unlocked_skill := 0
		if level == 2 or level == 4 or level == 7 or level == 11:
			unlocked_skill = {2: 1, 4: 2, 7: 3, 11: 4}[level]
		else:
			max_health += 3.0
			health = minf(max_health, health + 3.0)
			attack_damage += 1.5
		level_changed.emit(level, unlocked_skill)
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, next_level_experience)


func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_animation_time = maxf(0.0, attack_animation_time - delta)
	action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
	if skill_movement_locked:
		skill_movement_lock_remaining -= delta
		if skill_movement_lock_remaining <= 0.0:
			_release_skill_movement()
	elif action_animation_remaining <= 0.0:
		facing_target = null
	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	var arena_auto_cast := true
	if arena != null and arena.has_method("get"):
		arena_auto_cast = bool(arena.get("auto_cast_enabled"))
	if auto_hunt_controller != null and input_direction == Vector2.ZERO and not auto_hunt_disabled and not arena_auto_cast:
		auto_hunt_controller.update(delta)
	regen_timer += delta
	if regen_timer >= 1.0:
		regen_timer -= 1.0
		if health > 0.0 and health < max_health:
			health = minf(max_health, health + hp_regen_per_second)
			health_changed.emit(health, max_health)
	var direction := Vector3(input_direction.x, 0.0, input_direction.y)
	var target_velocity := Vector3.ZERO
	if not skill_movement_locked and direction.length_squared() > 0.01:
		direction = direction.normalized()
		target_velocity = direction * move_speed * (RUN_MULTIPLIER if running else 1.0)
	var acceleration := (
		MOVE_ACCELERATION if target_velocity.length_squared() > 0.0 else MOVE_DECELERATION
	)
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if is_instance_valid(facing_target) and facing_target.get("dead"):
		facing_target = null
	if action_animation_remaining > 0.0 and is_instance_valid(facing_target):
		_turn_toward(facing_target.global_position - global_position, delta)
	elif not skill_movement_locked and direction.length_squared() > 0.01:
		_turn_toward(direction, delta)
	if weapon != null:
		weapon.rotation.z = -sin((attack_animation_time / 0.28) * PI) * 1.15
	move_and_slide()
	_update_movement_animation(delta)
	if absf(global_position.x) > 5.5 or absf(global_position.z) > 5.5:
		global_position.x = clampf(global_position.x, -7.5, 7.5)
		global_position.z = clampf(global_position.z, -7.5, 7.5)
		var boundary_normal := Vector3(signf(global_position.x), 0.0, signf(global_position.z)).normalized()
		var outward_speed := velocity.dot(boundary_normal)
		if outward_speed > 0.0:
			velocity -= boundary_normal * outward_speed


func _update_movement_animation(delta: float) -> void:
	var real_velocity := get_real_velocity()
	real_velocity.y = 0.0
	var actual_speed := real_velocity.length()
	if actual_speed <= IDLE_SPEED_THRESHOLD:
		movement_animation_state = "idle"
	elif movement_animation_state == "run":
		if actual_speed < RUN_ANIMATION_EXIT_SPEED:
			movement_animation_state = "walk"
	else:
		movement_animation_state = ("run" if actual_speed >= RUN_ANIMATION_ENTER_SPEED else "walk")

	var has_idle_animation := (
		movement_animation_state == "idle" and _has_character_animation("idle")
	)
	var target_animation_speed := 1.0
	if movement_animation_state == "idle":
		target_animation_speed = 1.0 if has_idle_animation else actual_speed / WALK_SPEED
	elif movement_animation_state == "run":
		var run_clip_exists := _has_character_animation("run")
		target_animation_speed = (
			actual_speed / (WALK_SPEED * RUN_MULTIPLIER if run_clip_exists else WALK_SPEED)
		)
	else:
		target_animation_speed = actual_speed / WALK_SPEED
	target_animation_speed = clampf(target_animation_speed, 0.05, 1.7)
	animation_playback_speed = lerpf(
		animation_playback_speed,
		target_animation_speed,
		1.0 - exp(-ANIMATION_SPEED_SMOOTHING * delta)
	)

	if action_animation_remaining > 0.0:
		# 공격/스킬 중에도 입력이 있으면 하체(legs) 걷기 모션을 적용한다.
		var is_moving_now := input_direction.length_squared() > 0.01
		if is_moving_now and legs.size() >= 2:
			animation_clock += delta * 7.0 * animation_playback_speed
			legs[0].rotation.x = sin(animation_clock) * 0.42
			legs[1].rotation.x = -sin(animation_clock) * 0.42
			visual_root.position.y = absf(sin(animation_clock)) * 0.07
		elif legs.size() >= 2:
			legs[0].rotation.x = move_toward(legs[0].rotation.x, 0.0, delta * 4.0)
			legs[1].rotation.x = move_toward(legs[1].rotation.x, 0.0, delta * 4.0)
			visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.4)
		return
	if movement_animation_state == "idle":
		if has_idle_animation:
			play_character_animation("idle", animation_playback_speed)
		else:
			if (
				model_animation_player != null
				and model_animation_player.is_playing()
				and (
					current_model_animation == "character/walk"
					or current_model_animation == "character/run"
				)
			):
				model_animation_player.speed_scale = animation_playback_speed
				if animation_playback_speed <= 0.1:
					model_animation_player.stop(false)
					current_model_animation = ""
		# idle 클립이 없을 때 기본 포즈를 위해 walk 첫 프레임을 정지 재생
		if (
			model_animation_player != null
			and not model_animation_player.is_playing()
			and _has_character_animation("walk")
		):
			play_character_animation("walk", 0.0)
		if legs.size() >= 2:
			legs[0].rotation.x = move_toward(legs[0].rotation.x, 0.0, delta * 4.0)
			legs[1].rotation.x = move_toward(legs[1].rotation.x, 0.0, delta * 4.0)
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.4)
		return

	animation_clock += delta * 7.0 * animation_playback_speed
	if legs.size() >= 2:
		legs[0].rotation.x = sin(animation_clock) * 0.42
		legs[1].rotation.x = -sin(animation_clock) * 0.42
	var movement_animation := (
		"run" if movement_animation_state == "run" and _has_character_animation("run") else "walk"
	)
	play_character_animation(movement_animation, animation_playback_speed)
	visual_root.position.y = absf(sin(animation_clock)) * 0.07
