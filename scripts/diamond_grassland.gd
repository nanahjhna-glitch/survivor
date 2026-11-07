extends Node3D

const PlayerScript = preload("res://scripts/field_player.gd")
const MonsterScript = preload("res://scripts/field_monster.gd")
const DropScript = preload("res://scripts/field_drop.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const MinimapScript = preload("res://scripts/diamond_grassland_minimap.gd")
const LevelUpCardsScript = preload("res://scripts/level_up_cards.gd")

const MAX_MONSTERS := 120
const FIELD_RADIUS := 26.0
const SKILL_BUTTON_SIZE := Vector2(70, 70)
const AUTO_ATTACK_SCAN_INTERVAL := 0.1
const MONSTER_SPAWN_INTERVAL := 0.0933333
const PROGRESS_SAVE_INTERVAL := 5.0
const AUTO_SKILL_PRIORITY: Array[int] = [3, 1, 2, 0]
const SPATIAL_CELL_SIZE := 4.0
const SPATIAL_REBUILD_INTERVAL := 0.2
const CAMERA_OFFSET := Vector3(0.0, 16.0, 12.0)
const CAMERA_LOOK_HEIGHT := 0.5

enum AutoHuntState { SEARCH, APPROACH, CASTING, RECOVERY, SUSPENDED }

var player: FieldPlayer
var companions: Array[FieldPlayer] = []
var party_hud_panels: Array[PanelContainer] = []
var companion_character_index := 0
var top_time_label: Label
var top_kills_label: Label
var total_kills := 0
var camera_target: FieldPlayer = null
var camera: Camera3D
var joystick: GrasslandJoystick
var hud_layer: CanvasLayer
var hp_bar: ProgressBar
var exp_bar: ProgressBar
var exp_label: Label
var minimap: DiamondGrasslandMinimap
var level_label: Label
var time_label: Label
var gold_label: Label
var notification_label: Label
var run_button: Button
var attack_button: Button
var skill_buttons: Array[Button] = []
# skill_cooldowns moved to FieldPlayer
var casting_skill_index := -1
var skill_cast_remaining := 0.0
var elapsed_time := 0.0
var spawn_clock := 0.0
var auto_attack_scan_timer := 0.0
var auto_cast_enabled := false
var auto_cast_button: Button
var auto_hunt_state := AutoHuntState.SEARCH
var auto_hunt_target: FieldMonster
var auto_target_mode := "nearest"
var auto_hunt_gcd := 0.0
var auto_hunt_move_direction := Vector3.ZERO
var running := false
var run_button_held := false
var paused := false
var camera_yaw := 0.785
var camera_pitch := -0.6
var camera_distance := 40.0
var camera_dragging := false
var random := RandomNumberGenerator.new()
var alive_monsters: Array[FieldMonster] = []
var monster_spatial_cells: Dictionary = {}
var spatial_rebuild_timer := 0.0
var notification_timer := 0.0
var progress_save_timer := 0.0
var progress_save_pending := false
var pause_panel: PanelContainer
var pause_root: Control
var pause_detail_label: Label
var level_up_overlay: LevelUpCardOverlay
var pending_level_ups: Array[Dictionary] = []
var leveling_member: FieldPlayer = null


func _ready() -> void:
	random.randomize()
	_build_environment()
	_build_field()
	_spawn_player()
	_build_hud()
	_spawn_monster()
	_spawn_monster()


func _process(delta: float) -> void:
	if paused or player == null or not _has_living_party_members():
		return
	elapsed_time += delta
	spawn_clock += delta
	notification_timer = maxf(0.0, notification_timer - delta)
	notification_label.visible = notification_timer > 0.0
	if progress_save_pending:
		progress_save_timer += delta
		if progress_save_timer >= PROGRESS_SAVE_INTERVAL:
			GameData.save_game()
			progress_save_pending = false
			progress_save_timer = 0.0
	if is_instance_valid(player) and not player.dead:
		for index in range(player.skill_cooldowns.size()):
			player.skill_cooldowns[index] = maxf(0.0, player.skill_cooldowns[index] - delta)
			_update_skill_button(index)
		if player.casting_skill_index >= 0:
			player.skill_cast_remaining = maxf(0.0, player.skill_cast_remaining - delta)
			if player.skill_cast_remaining == 0.0:
				_execute_skill(player, player.casting_skill_index)
				player.casting_skill_index = -1
	# 동료 스킬 쿨다운/시전 처리
	for companion in companions:
		if not is_instance_valid(companion) or companion.dead:
			continue
		for index in range(companion.skill_cooldowns.size()):
			companion.skill_cooldowns[index] = maxf(0.0, companion.skill_cooldowns[index] - delta)
		if companion.casting_skill_index >= 0:
			companion.skill_cast_remaining = maxf(0.0, companion.skill_cast_remaining - delta)
			if companion.skill_cast_remaining == 0.0:
				_execute_skill(companion, companion.casting_skill_index)
				companion.casting_skill_index = -1
	if auto_cast_enabled:
		auto_attack_scan_timer -= delta
		if auto_attack_scan_timer <= 0.0:
			auto_attack_scan_timer = AUTO_ATTACK_SCAN_INTERVAL
			_auto_cast_combat()
	else:
		auto_attack_scan_timer = 0.0
	if alive_monsters.size() >= MAX_MONSTERS:
		spawn_clock = 0.0
	elif spawn_clock >= MONSTER_SPAWN_INTERVAL:
		spawn_clock -= MONSTER_SPAWN_INTERVAL
		_spawn_monster()
	_update_hud()
	_update_camera(delta)


func _physics_process(delta: float) -> void:
	if player == null or not _has_living_party_members():
		return
	spatial_rebuild_timer -= delta
	if spatial_rebuild_timer <= 0.0:
		_rebuild_monster_spatial_index()
		spatial_rebuild_timer = SPATIAL_REBUILD_INTERVAL
	for actor in [player] + companions:
		if (
			is_instance_valid(actor)
			and not actor.dead
			and actor.auto_hunt_controller != null
		):
			actor.auto_hunt_controller.update(delta)
			_try_companion_auto_skill(actor)
	_update_keyboard_movement()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = maxf(8.0, camera_distance - 1.5)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = minf(40.0, camera_distance + 1.5)
			return
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = event.pressed
			if event.pressed:
				camera_target = null
			return
	if event is InputEventMouseMotion and camera_dragging:
		camera_yaw -= event.relative.x * 0.005
		camera_pitch = clampf(camera_pitch - event.relative.y * 0.005, -1.4, 1.4)
		return
	if event is InputEventScreenDrag:
		camera_yaw -= event.relative.x * 0.005
		camera_pitch = clampf(camera_pitch - event.relative.y * 0.005, -1.4, 1.4)
		return
	if event is InputEventMagnifyGesture:
		camera_distance = clampf(camera_distance / event.factor, 8.0, 40.0)
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	if (
		not event is InputEventKey
		or not event.pressed
		or event.echo
		or player == null
		or player.dead
		or paused
	):
		return
	match event.physical_keycode:
		KEY_SPACE:
			player.try_basic_attack()
		KEY_1:
			_on_skill_pressed(0)
		KEY_2:
			_on_skill_pressed(1)
		KEY_3:
			_on_skill_pressed(2)
		KEY_4:
			_on_skill_pressed(3)

func _update_keyboard_movement() -> void:
	# 키보드 이동 비활성화 (소스 유지)
	return
	if player == null or player.dead or paused:
		return

	var keyboard_direction := Vector2(
		(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
			- float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		),
		(
			# [수정 1] W(위)를 누를 때 앞으로 가도록 W - S 순서로 변경합니다.
			float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
			- float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		)
	)

	var joystick_direction: Vector2 = joystick.direction
	var screen_direction := (keyboard_direction + joystick_direction).limit_length(1.0)
	if (
		auto_cast_enabled
		and auto_hunt_state == AutoHuntState.APPROACH
		and screen_direction.length_squared() <= 0.01
		and auto_hunt_move_direction.length_squared() > 0.01
	):
		player.set_controls(
			Vector2(auto_hunt_move_direction.x, auto_hunt_move_direction.z), true
		)
		return

	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var world_direction := camera_right * screen_direction.x
	# [수정 2] -screen_direction.y 에서 마이너스(-)를 제거하여 전진 방향을 바로잡습니다.
	world_direction += camera_forward * screen_direction.y

	var direction := Vector2(
		world_direction.x,
		world_direction.z
	).limit_length(1.0)

	running = run_button_held or Input.is_key_pressed(KEY_SHIFT)
	player.set_controls(direction, running)

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#58a8e8")
	sky_material.sky_horizon_color = Color("#d5efff")
	sky_material.ground_bottom_color = Color("#58a8e8")
	sky_material.ground_horizon_color = Color("#d5efff")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8e9ff")
	environment.ambient_light_energy = 0.65
	environment_node.environment = environment
	add_child(environment_node)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48, -32, 0)
	sunlight.light_color = Color("#fff1d2")
	sunlight.light_energy = 1.2
	add_child(sunlight)


func _build_field() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "GrasslandGround"
	floor_body.position.y = -0.3
	var tile_size := 1.0
	var half := 12
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var tile := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(tile_size, 0.12, tile_size)
			tile.mesh = box
			tile.position = Vector3(x * tile_size + 0.5, random.randf_range(-0.08, 0.08), z * tile_size + 0.5)
			var mat := StandardMaterial3D.new()
			if (x + z) % 2 == 0:
				mat.albedo_color = Color("#8fd16a")
			else:
				mat.albedo_color = Color("#4f9a3c")
			mat.roughness = 1.0
			tile.material_override = mat
			add_child(tile)
	var floor_collider := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(25.0, 0.2, 25.0)
	floor_collider.shape = box_shape
	floor_body.add_child(floor_collider)
	add_child(floor_body)
	_add_square_boundary()

	# 맵 오브젝트 모두 제거 (체스판만 유지)

	# 맵 오브젝트 모두 제거 (바닥과 빨간 테두리 선만 유지)


func _create_diamond_ground_mesh() -> ArrayMesh:
	var half_size := FIELD_RADIUS
	var corners := [
		Vector3(0, 0.3, -half_size),
		Vector3(half_size, 0.3, 0),
		Vector3(0, 0.3, half_size),
		Vector3(-half_size, 0.3, 0),
	]
	var vertices := PackedVector3Array()
	var center := Vector3(0, 0.3, 0)
	for index in range(corners.size()):
		vertices.append(center)
		vertices.append(corners[(index + 1) % corners.size()])
		vertices.append(corners[index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_square_boundary() -> void:
	var half := 12.5
	var corners := [
		Vector3(-half, 0, -half),
		Vector3(half, 0, -half),
		Vector3(half, 0, half),
		Vector3(-half, 0, half),
	]
	for index in range(corners.size()):
		_add_boundary_line(corners[index], corners[(index + 1) % corners.size()])


func _add_boundary_line(start: Vector3, finish: Vector3) -> void:
	var edge := finish - start
	var segment_length := edge.length()
	var midpoint := (start + finish) * 0.5
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, segment_length)
	line.mesh = box
	line.position = midpoint + Vector3.UP * 0.05
	line.rotation.y = atan2(edge.x, edge.z)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#000000")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = material
	add_child(line)

func _add_boundary_wall_unused(start: Vector3, finish: Vector3) -> void:
	var edge := finish - start
	var segment_length := edge.length()
	var midpoint := (start + finish) * 0.5
	var wall := StaticBody3D.new()
	wall.name = "GrasslandBoundary"
	wall.position = midpoint + Vector3.UP * 1.1
	wall.rotation.y = atan2(edge.x, edge.z)
	var stone := Color("#657b59")
	var wall_mesh := MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(0.55, 2.2, segment_length + 0.1)
	wall_mesh.mesh = wall_box
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = stone
	wall_material.roughness = 0.92
	wall_mesh.material_override = wall_material
	wall.add_child(wall_mesh)

	var top_rail := MeshInstance3D.new()
	var rail_box := BoxMesh.new()
	rail_box.size = Vector3(0.82, 0.18, segment_length + 0.2)
	top_rail.mesh = rail_box
	top_rail.position.y = 1.04
	var rail_material := StandardMaterial3D.new()
	rail_material.albedo_color = Color("#e8cb79")
	top_rail.material_override = rail_material
	wall.add_child(top_rail)

	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = wall_box.size
	collision.shape = collision_box
	wall.add_child(collision)
	add_child(wall)


func _add_boundary_marker(at: Vector3) -> void:
	var marker := Node3D.new()
	marker.position = at + Vector3.UP * 0.8
	add_child(marker)
	for block in [
		[Vector3(0, 0.8, 0), Vector3(0.8, 2.0, 0.8), Color("#e8cb79")],
		[Vector3(0, 1.85, 0), Vector3(0.46, 0.46, 0.46), Color("#71cbd0")],
	]:
		marker.add_child(_box_mesh(block[0], block[1], block[2]))


func _add_tree(at: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = at
	var trunk := _box_mesh(Vector3(0, 1.1, 0), Vector3(0.65, 2.2, 0.65), Color("#805032"))
	tree.add_child(trunk)
	for part in [
		[Vector3(0, 2.45, 0), Vector3(2.2, 1.7, 2.2), Color("#43864f")],
		[Vector3(0, 3.35, 0), Vector3(1.45, 1.15, 1.45), Color("#58a65c")],
		[Vector3(0, 4.0, 0), Vector3(0.8, 0.7, 0.8), Color("#75bb65")],
	]:
		tree.add_child(_box_mesh(part[0], part[1], part[2]))
	add_child(tree)


func _add_rock(at: Vector3) -> void:
	var rock := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(random.randf_range(0.8, 1.6), random.randf_range(0.7, 1.5), 1.0)
	rock.mesh = box
	rock.position = at + Vector3.UP * box.size.y * 0.5
	rock.rotation.y = random.randf_range(0.0, TAU)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#8b9587")
	material.roughness = 1.0
	rock.material_override = material
	add_child(rock)


func _add_crystal(at: Vector3) -> void:
	var crystal := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 1.8, 0.8)
	crystal.mesh = box
	crystal.position = at + Vector3.UP * 0.9
	crystal.rotation_degrees = Vector3(0, 45, 45)
	var material := StandardMaterial3D.new()
	var crystal_color := Color("#73e5ed")
	crystal_color.a = 0.9
	material.albedo_color = crystal_color
	material.emission_enabled = true
	material.emission = Color("#39cfe0")
	material.emission_energy_multiplier = 0.7
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal.material_override = material
	add_child(crystal)


func _add_flower(at: Vector3) -> void:
	var flower := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	flower.mesh = sphere
	flower.position = at + Vector3.UP * 0.18
	var material := StandardMaterial3D.new()
	material.albedo_color = [Color("#fff0a0"), Color("#f6a8c8"), Color("#c7b6f0")][
		random.randi_range(0, 2)
	]
	flower.material_override = material
	add_child(flower)


func _build_voxel_forest_decorations() -> void:
	var base := "res://assets/field/Voxel_Animal_Asset_Pack/Main/Green/"
	var tree_paths := [base + "tree1/tree.vox.obj", base + "tree2/tree2.vox.obj"]
	var grass_paths := [
		base + "grass1/grass1.vox.obj",
		base + "grass2/grass2.vox.obj",
		base + "grass3/grass3.vox.obj",
	]
	var flower_paths := [
		base + "grassflower1/grassflower1.vox.obj",
		base + "grassflower2/grassflower2.vox.obj",
	]
	var mushroom_path := base + "grassmushroom/grassmushroom.vox.obj"
	var box_paths := [base + "box1/box1.vox.obj", base + "box2/box2.vox.obj"]

	# 경계 근처에 나무 배치
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + random.randf_range(-0.15, 0.15)
		var dist := random.randf_range(FIELD_RADIUS - 6.0, FIELD_RADIUS - 2.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var path: String = tree_paths[random.randi_range(0, tree_paths.size() - 1)]
		_add_voxel_decoration(path, pos, Vector3.ONE * random.randf_range(0.9, 1.2), random.randf_range(0.0, TAU), true)

	# 잔디/꽃 산포
	for i in range(20):
		var p := Vector3(random.randf_range(-20.0, 20.0), 0.0, random.randf_range(-20.0, 20.0))
		if absf(p.x) >= 12.5 or absf(p.z) >= 12.5:
			continue
		if Vector2(p.x, p.z).length() < 3.0:
			continue
		var pool := grass_paths if random.randf() < 0.6 else flower_paths
		var path: String = pool[random.randi_range(0, pool.size() - 1)]
		_add_voxel_decoration(path, p, Vector3.ONE * random.randf_range(0.8, 1.1), random.randf_range(0.0, TAU), false)

	# 버섯 소수 배치
	for i in range(3):
		var p := Vector3(random.randf_range(-18.0, 18.0), 0.0, random.randf_range(-18.0, 18.0))
		if absf(p.x) >= 12.5 or absf(p.z) >= 12.5:
			continue
		_add_voxel_decoration(mushroom_path, p, Vector3.ONE * random.randf_range(0.9, 1.1), random.randf_range(0.0, TAU), false)

	# 상자 소품
	for i in range(2):
		var p := Vector3(random.randf_range(-12.0, 12.0), 0.0, random.randf_range(-12.0, 12.0))
		if absf(p.x) >= 12.5 or absf(p.z) >= 12.5:
			continue
		var path: String = box_paths[random.randi_range(0, box_paths.size() - 1)]
		_add_voxel_decoration(path, p, Vector3.ONE * 0.9, random.randf_range(0.0, TAU), true)

func _add_voxel_decoration(path: String, position: Vector3, scale: Vector3, yaw: float, collidable: bool = false) -> void:
	var mesh_resource := load(path)
	if mesh_resource == null:
		return
	var instance := MeshInstance3D.new()
	if mesh_resource is ArrayMesh:
		instance.mesh = mesh_resource
	elif mesh_resource is Mesh:
		instance.mesh = mesh_resource
	else:
		var importer := mesh_resource as Resource
		if importer != null and importer.has_method("get_mesh"):
			instance.mesh = importer.call("get_mesh")
	if instance.mesh == null:
		return
	instance.position = position
	instance.scale = scale
	instance.rotation.y = yaw
	add_child(instance)
	if collidable:
		instance.create_convex_collision()

func _box_mesh(at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	block.mesh = mesh
	block.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	block.material_override = material
	return block


func _spawn_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.setup(self, GameData.CHARACTERS[GameData.selected_character])
	player.formation_slot = 0
	player.party_slot = 0
	# 기존 코드
	# player.position = Vector3.ZERO
	# 변경 코드 (Y축을 1.0만큼 공중으로 띄움)
	var start_angles := [2.094, 4.189, -1.571, -1.047, 1.047, 1.571]
	player.position = Vector3(cos(start_angles[2]) * 8.0, 0.0, sin(start_angles[2]) * 8.0)
	player.character_index = GameData.selected_character
	player.health_changed.connect(_on_health_changed)
	player.experience_changed.connect(_on_experience_changed)
	player.level_changed.connect(_on_level_changed.bind(player))
	player.player_died.connect(_on_party_member_died.bind(player))
	add_child(player)
	GameData.run_level = player.get("level")

	camera = Camera3D.new()
	camera.name = "FieldCamera"
	camera.current = true
	camera.fov = 60.0
	add_child(camera)

	# AI 동료 캐릭터 출전 (주인공 포함 6명 파티)
	var companion_angles: Array[float] = [2.094, 4.189, -1.047, 1.047, 1.571, -1.571]
	for i in range(GameData.PARTY_SIZE - 1):
		var companion_index := GameData.party_characters[i + 1]
		if i == 0:
			companion_character_index = companion_index
		var companion: FieldPlayer = PlayerScript.new()
		companion.name = "Companion%d" % i
		companion.setup(self, GameData.CHARACTERS[companion_index])
		companion.character_index = companion_index
		companion.formation_slot = i + 1
		companion.party_slot = i + 1
		var a: float = companion_angles[i]
		companion.position = Vector3(cos(a) * 8.0, 0.0, sin(a) * 8.0)
		companion.auto_hunt_disabled = false
		companion.player_died.connect(_on_party_member_died.bind(companion))
		companion.level_changed.connect(_on_level_changed.bind(companion))
		add_child(companion)
		companions.append(companion)

	var saved_target := _party_member_at_slot(GameData.camera_target_slot)
	camera_target = saved_target if is_instance_valid(saved_target) and not saved_target.dead else player
	_update_camera(1.0)


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	var top := VBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 18
	top.offset_top = 42
	top.offset_right = -18
	top.add_theme_constant_override("separation", 6)
	root.add_child(top)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	top.add_child(info)
	var stage_lbl := _hud_label("ST %d" % (GameData.selected_stage + 1), 15)
	info.add_child(stage_lbl)
	time_label = _hud_label("00:00", 16)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_time_label = time_label
	info.add_child(time_label)
	top_kills_label = _hud_label("처치 0", 14)
	info.add_child(top_kills_label)
	var pause_btn := _make_hud_button("Ⅱ", Vector2(48, 42))
	pause_btn.pressed.connect(_toggle_pause)
	info.add_child(pause_btn)

	var status_row := HBoxContainer.new()
	top.add_child(status_row)
	level_label = _hud_label("Lv. %d" % GameData.run_level, 15)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(level_label)
	gold_label = _hud_label("골드 %d" % GameData.gold, 17)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(gold_label)
	# 기존 HP/EXP 바 제거 (캐릭터별 바 사용)

	notification_label = _hud_label("", 23)
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.anchor_left = 0.12
	notification_label.anchor_right = 0.88
	notification_label.anchor_top = 0.18
	notification_label.offset_top = 4
	notification_label.offset_bottom = 48
	notification_label.visible = false
	root.add_child(notification_label)

	# 상단 캐릭터 바 제거

	# 3x2 캐릭터 상태 패널
	var bottom_panel := GridContainer.new()
	bottom_panel.columns = 3
	bottom_panel.anchor_left = 0.04
	bottom_panel.anchor_right = 0.96
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_top = -184
	bottom_panel.offset_bottom = -20
	bottom_panel.add_theme_constant_override("h_separation", 8)
	bottom_panel.add_theme_constant_override("v_separation", 8)
	root.add_child(bottom_panel)
	party_hud_panels.clear()
	var bidx := 0
	for c in [player] + companions:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 76)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event: InputEvent) -> void:
			if (
				(event is InputEventMouseButton and event.pressed)
				or (event is InputEventScreenTouch and event.pressed)
			):
				_select_camera_target(c)
		)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.09, 0.12, 0.78)
		style.border_color = (
			Color("#f0c65b")
			if c.party_slot == GameData.camera_target_slot
			else Color("#d8c99e")
		)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(8)
		panel.add_theme_stylebox_override("panel", style)
		party_hud_panels.append(panel)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		panel.add_child(content)
		var name_row := HBoxContainer.new()
		var character_index: int = (
			GameData.selected_character if bidx == 0 else GameData.party_characters[bidx]
		)
		var character_name := str(GameData.CHARACTERS[character_index]["name"])
		var name_lbl := _hud_label(character_name, 12)
		var level_lbl := _hud_label("Lv.1", 11)
		name_row.add_child(name_lbl)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(spacer)
		name_row.add_child(level_lbl)
		content.add_child(name_row)
		var hp := _make_bar(Color("#db6558"))
		hp.custom_minimum_size = Vector2(0, 10)
		hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var exp := _make_bar(Color("#55c6d1"))
		exp.custom_minimum_size = Vector2(0, 8)
		exp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(hp)
		content.add_child(exp)
		c.level_changed.connect(func(new_level: int, _u: int) -> void:
			level_lbl.text = "Lv.%d" % new_level
		)
		bottom_panel.add_child(panel)
		c.health_changed.connect(func(cur: float, maximum: float) -> void:
			hp.max_value = maximum
			hp.value = cur
			name_lbl.text = "%s  ·  사망" % character_name if cur <= 0.0 else character_name
			panel.modulate = Color(0.55, 0.55, 0.55) if cur <= 0.0 else Color.WHITE
		)
		c.experience_changed.connect(func(current: int, required: int) -> void:
			exp.max_value = required
			exp.value = current
		)
		bidx += 1

	joystick = JoystickScript.new()
	joystick.position = Vector2(22, -178)
	joystick.visible = false
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.direction_changed.connect(_on_joystick_changed)
	root.add_child(joystick)

	# 달리기 버튼 제거

	var combat_controls := VBoxContainer.new()
	combat_controls.visible = false
	combat_controls.anchor_left = 1.0
	combat_controls.anchor_top = 0.5
	combat_controls.anchor_right = 1.0
	combat_controls.anchor_bottom = 0.5
	combat_controls.offset_left = -82
	combat_controls.offset_top = -205
	combat_controls.offset_right = -12
	combat_controls.offset_bottom = 205
	combat_controls.add_theme_constant_override("separation", 8)
	root.add_child(combat_controls)

	attack_button = _make_hud_button("공격", SKILL_BUTTON_SIZE)
	attack_button.add_theme_font_size_override("font_size", 19)
	attack_button.pressed.connect(_on_attack_pressed)
	combat_controls.add_child(attack_button)
	var skill_grid := GridContainer.new()
	skill_grid.columns = 1
	skill_grid.add_theme_constant_override("h_separation", 5)
	skill_grid.add_theme_constant_override("v_separation", 5)
	combat_controls.add_child(skill_grid)
	for index in range(CombatData.SKILLS.size()):
		if casting_skill_index >= 0:
			break
		var skill: Dictionary = CombatData.SKILLS[index]
		var button := _make_hud_button(
			"S%d\nLv.%d" % [skill["id"], skill["unlock_level"]], SKILL_BUTTON_SIZE
		)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_skill_pressed.bind(index))
		skill_buttons.append(button)
		skill_grid.add_child(button)

	# 자동 ON/OFF 버튼 제거
	# 맵 전체 보기 버튼
	var map_view_btn := _make_hud_button("맵", Vector2(58, 46))
	map_view_btn.anchor_left = 1.0
	map_view_btn.anchor_right = 1.0
	map_view_btn.offset_left = -100
	map_view_btn.offset_top = 0
	map_view_btn.offset_right = -42
	map_view_btn.offset_bottom = 46
	map_view_btn.add_theme_font_size_override("font_size", 13)
	map_view_btn.pressed.connect(_toggle_map_view)
	root.add_child(map_view_btn)

	var pause_button := _make_hud_button("Ⅱ", Vector2(58, 52))
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.offset_left = -160
	pause_button.offset_top = 0
	pause_button.offset_right = -108
	pause_button.offset_bottom = 46
	pause_button.pressed.connect(_toggle_pause)
	root.add_child(pause_button)
	# minimap 비활성화 (소스 유지)
	# minimap = MinimapScript.new() ...
	_on_health_changed(player.health, player.max_health)
	_on_experience_changed(player.experience, player.next_level_experience)
	_update_hud()


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 20
	bar.show_percentage = false
	bar.max_value = 100.0
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#2c3940")
	background.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _hud_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#fff8e9"))
	label.add_theme_color_override("font_shadow_color", Color("#29333b"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_hud_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.add_theme_color_override("font_color", Color("#fff8e9"))
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#354958")
	normal.border_color = Color("#e8bf62")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(7)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#597383")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _disabled_button_style())
	return button


func _disabled_button_style() -> StyleBoxFlat:
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#3d4245")
	disabled.border_color = Color("#6c7477")
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(18)
	return disabled


func _spawn_monster() -> void:
	var spawn_target := _nearest_character(player.global_position) if player != null else null
	if alive_monsters.size() >= MAX_MONSTERS or not is_instance_valid(spawn_target):
		return
	var data: Dictionary = _choose_monster(spawn_target.level)
	var enemy: FieldMonster = MonsterScript.new()
	enemy.setup(self, spawn_target, data)
	var base_angles := [0.0, PI * 0.5, PI, PI * 1.5]
	var angle: float = base_angles[random.randi_range(0, 3)] + random.randf_range(-0.35, 0.35)
	var distance := random.randf_range(8.0, 12.0)
	enemy.position = spawn_target.position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	enemy.position.x = clampf(enemy.position.x, -12.5, 12.5)
	enemy.position.z = clampf(enemy.position.z, -12.5, 12.5)
	add_child(enemy)
	alive_monsters.append(enemy)
	var cell := _spatial_cell(enemy.global_position)
	var cell_enemies: Array = monster_spatial_cells.get(cell, [])
	cell_enemies.append(enemy)
	monster_spatial_cells[cell] = cell_enemies


func _choose_monster(level: int) -> Dictionary:
	if elapsed_time > 100.0 and level >= 7 and random.randf() < 0.12:
		return CombatData.MONSTERS[4]
	var choices: Array[int] = [0, 0, 0, 1, 1, 3]
	if level >= 3 or elapsed_time > 30.0:
		choices.append(2)
	return CombatData.MONSTERS[choices[random.randi_range(0, choices.size() - 1)]]


func perform_basic_attack(
	attacker: Node3D, damage: float, attack_range: float, angle: float
) -> void:
	var attacking_player := attacker as FieldPlayer
	if attacking_player == null:
		return
	var facing := -attacker.global_transform.basis.z
	facing.y = 0.0
	if facing.length_squared() <= 0.01:
		return
	facing = facing.normalized()
	_show_hitbox(
		_create_hitbox_sector(attack_range, angle),
		attacker.global_position,
		attacker.rotation.y,
		Color("#ffd16b")
	)
	var target: FieldMonster
	var nearest_distance := attack_range
	for enemy in get_enemies_near(attacker.global_position, attack_range):
		var monster := enemy as FieldMonster
		if not is_instance_valid(monster) or monster.dead:
			continue
		var from_player := monster.global_position - attacker.global_position
		from_player.y = 0.0
		var distance := from_player.length()
		if (
			distance < nearest_distance
			and distance > 0.0
			and from_player.normalized().dot(facing) >= cos(angle)
		):
			target = monster
			nearest_distance = distance
	if target == null:
		return
	var damage_type := "physical"
	if attacking_player.attack_style == "magic":
		damage_type = "magic"
	var final_damage := attacking_player.calculate_outgoing_damage(
		damage, damage_type, attacking_player.attack_style == "ranged"
	)
	if final_damage <= 0.0:
		_show_notification("빗나감!", 0.55)
		return
	target.apply_damage(final_damage)
	_spawn_hit_effect(target.global_position + Vector3.UP * 0.5, Color("#fff0a0"), 0.55)


func _on_attack_pressed() -> void:
	player.try_basic_attack()


func _toggle_auto_cast() -> void:
	auto_cast_enabled = not auto_cast_enabled
	if auto_cast_button != null:
		auto_cast_button.text = "자동: %s" % ("ON" if auto_cast_enabled else "OFF")

var map_view_toggled := false
func _toggle_map_view() -> void:
	camera_target = null
	camera_distance = 40.0
	camera_pitch = -0.6
	camera_yaw = 0.785


func _on_skill_pressed(index: int, actor: FieldPlayer = null) -> void:
	var caster: FieldPlayer = player if actor == null else actor
	if (
		not is_instance_valid(caster)
		or caster.dead
		or paused
		or index < 0
		or index >= CombatData.SKILLS.size()
		or not _actor_has_skill(caster, index)
	):
		return
	if caster.casting_skill_index >= 0 or caster.skill_movement_locked:
		return
	var skill: Dictionary = CombatData.SKILLS[index]
	if caster.level < int(skill["unlock_level"]):
		if caster == player:
			_show_notification("스킬 %d는 Lv.%d에 해금됩니다." % [skill["id"], skill["unlock_level"]])
		return
	if caster.skill_cooldowns[index] > 0.0:
		return
	var skill_range := float(skill["range"]) * caster.hitbox_size_multiplier
	var target := _nearest_monster(caster.global_position, skill_range)
	if target != null:
		_face_target(caster, target)
	caster.skill_cooldowns[index] = float(skill["cooldown"])
	caster.casting_skill_index = index
	caster.skill_cast_remaining = float(skill["cast_time"]) * caster.casting_time_multiplier
	if caster == player:
		GameAudio.play_sfx("skill_%d" % (index + 1))
	caster.play_skill_animation(
		"skill_%d" % (index + 1), caster.skill_cast_remaining + 0.45
	)
	if caster == player:
		_update_skill_button(index)


func _execute_skill(actor: FieldPlayer, index: int) -> void:
	if (
		not is_instance_valid(actor)
		or actor.dead
		or paused
		or index < 0
		or index >= CombatData.SKILLS.size()
		or not _actor_has_skill(actor, index)
	):
		return
	var skill: Dictionary = CombatData.SKILLS[index]
	var range_value := float(skill["range"]) * actor.hitbox_size_multiplier
	var targets := _monsters_in_range(actor.global_position, range_value)
	var damage_type: String = skill["damage_type"]
	if index == 0:
		if actor == player:
			_show_hitbox(
				_create_hitbox_circle(range_value), actor.global_position, 0.0, Color("#ffcf72")
			)
		for enemy in targets:
			_deal_skill_damage(actor, enemy, float(skill["damage"]), damage_type)
	elif index == 1:
		var nearest := _nearest_monster(actor.global_position, range_value)
		if nearest != null:
			var impact := nearest.global_position
			var impact_radius := 2.4 * actor.hitbox_size_multiplier
			if actor == player:
				_show_hitbox(_create_hitbox_circle(impact_radius), impact, 0.0, Color("#75e8ed"))
			for enemy in _monsters_in_range(impact, impact_radius):
				_deal_skill_damage(actor, enemy, float(skill["damage"]), damage_type)
			if actor == player:
				_spawn_hit_effect(impact + Vector3.UP, Color("#75e8ed"), 1.8)
	elif index == 2:
		if actor == player:
			_show_hitbox(
				_create_hitbox_circle(range_value), actor.global_position, 0.0, Color("#d4b8ff")
			)
		for enemy in targets:
			_deal_skill_damage(actor, enemy, float(skill["damage"]), damage_type)
		if actor == player:
			_spawn_hit_effect(
				actor.global_position + Vector3.UP * 0.3, Color("#d4b8ff"), range_value * 0.55
			)
	else:
		if actor == player:
			_show_hitbox(
				_create_hitbox_circle(range_value), actor.global_position, 0.0, Color("#69e4eb")
			)
		for enemy in targets:
			_deal_skill_damage(actor, enemy, float(skill["damage"]), damage_type)
		if actor == player:
			_spawn_hit_effect(
				actor.global_position + Vector3.UP, Color("#69e4eb"), range_value * 0.65
			)
	if actor == player:
		_show_notification("%s!" % skill["name"])
		_update_skill_button(index)


func _try_companion_auto_skill(actor: FieldPlayer) -> void:
	if actor == null or actor.dead or actor == player:
		return
	_auto_cast_for(actor)


func _deal_skill_damage(
	actor: FieldPlayer, enemy: FieldMonster, damage: float, damage_type: String
) -> void:
	var is_ranged := actor.attack_style == "ranged" and damage_type == "physical"
	var final_damage := actor.calculate_outgoing_damage(damage, damage_type, is_ranged)
	if final_damage > 0.0:
		enemy.apply_damage(final_damage)


func _auto_cast_combat() -> void:
	_auto_cast_for(player)


func _auto_cast_for(actor: FieldPlayer) -> void:
	if not is_instance_valid(actor) or actor.dead or actor.casting_skill_index >= 0:
		return
	for index in AUTO_SKILL_PRIORITY:
		if not _actor_has_skill(actor, index):
			continue
		var skill: Dictionary = CombatData.SKILLS[index]
		if actor.skill_cooldowns[index] > 0.0:
			continue
		if actor.level < int(skill["unlock_level"]):
			continue
		var skill_range := float(skill["range"]) * actor.hitbox_size_multiplier
		var rule: Dictionary = CombatData.AUTO_SKILL_RULES.get(int(skill["id"]), {})
		var target_count := _auto_skill_target_count(actor, index, skill_range)
		var strong_target := _has_strong_enemy(actor, index, skill_range)
		if (
			target_count < int(rule.get("minimum_targets", 1))
			and not (bool(rule.get("use_on_strong_target", false)) and strong_target)
		):
			continue
		_on_skill_pressed(index, actor)
		if actor.casting_skill_index >= 0:
			return


func _actor_skill_indices(actor: FieldPlayer) -> Array:
	return CombatData.CHARACTER_SKILL_SETS.get(actor.character_index, [])


func _actor_has_skill(actor: FieldPlayer, index: int) -> bool:
	return _actor_skill_indices(actor).has(index)


func _auto_skill_target_count(actor: FieldPlayer, index: int, skill_range: float) -> int:
	if index == 1:
		var target := _nearest_monster(actor.global_position, skill_range)
		if target == null:
			return 0
		return _monsters_in_range(
			target.global_position, 2.4 * actor.hitbox_size_multiplier
		).size()
	return _monsters_in_range(actor.global_position, skill_range).size()


func _has_strong_enemy(actor: FieldPlayer, index: int, skill_range: float) -> bool:
	var targets: Array[FieldMonster]
	if index == 1:
		var nearest := _nearest_monster(actor.global_position, skill_range)
		if nearest == null:
			return false
		targets = _monsters_in_range(
			nearest.global_position, 2.4 * actor.hitbox_size_multiplier
		)
	else:
		targets = _monsters_in_range(actor.global_position, skill_range)
	for enemy in targets:
		if float(enemy.monster_data.get("hp", 0.0)) >= 150.0:
			return true
	return false


func _face_target(actor: FieldPlayer, target: FieldMonster) -> void:
	actor.set_facing_target(target)
	if target != null and is_instance_valid(target):
		var dir := target.global_position - actor.global_position
		dir.y = 0.0
		if dir.length_squared() > 0.001:
			actor.rotation.y = atan2(-dir.x, -dir.z)


func _nearest_character(origin: Vector3) -> FieldPlayer:
	var best: FieldPlayer
	var best_dist := INF
	for c in [player] + companions:
		if is_instance_valid(c) and not c.dead:
			var d := origin.distance_to(c.global_position)
			if d < best_dist:
				best_dist = d
				best = c
	return best


func _has_living_party_members() -> bool:
	for member in [player] + companions:
		if is_instance_valid(member) and not member.dead:
			return true
	return false

func _nearest_monster(origin: Vector3, range_value: float) -> FieldMonster:
	var nearest: FieldMonster
	var nearest_distance := range_value
	for candidate in get_enemies_near(origin, range_value):
		var enemy := candidate as FieldMonster
		if not is_instance_valid(enemy) or enemy.get("dead"):
			continue
		var distance := origin.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func get_enemies() -> Array:
	return alive_monsters


func get_enemies_near(origin: Vector3, radius: float) -> Array:
	var found: Array = []
	var center_cell := _spatial_cell(origin)
	var cell_radius := ceili(radius / SPATIAL_CELL_SIZE) + 1
	for x in range(center_cell.x - cell_radius, center_cell.x + cell_radius + 1):
		for z in range(center_cell.y - cell_radius, center_cell.y + cell_radius + 1):
			var cell_enemies: Array = monster_spatial_cells.get(Vector2i(x, z), [])
			for enemy in cell_enemies:
				if not is_instance_valid(enemy):
					continue
				var monster := enemy as FieldMonster
				if monster == null or monster.dead:
					continue
				var offset: Vector3 = monster.global_position - origin
				offset.y = 0.0
				if offset.length_squared() <= radius * radius:
					found.append(monster)
	return found


func _rebuild_monster_spatial_index() -> void:
	monster_spatial_cells.clear()
	for enemy in alive_monsters:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var cell := _spatial_cell(enemy.global_position)
		var cell_enemies: Array = monster_spatial_cells.get(cell, [])
		cell_enemies.append(enemy)
		monster_spatial_cells[cell] = cell_enemies


func _spatial_cell(position: Vector3) -> Vector2i:
	return Vector2i(
		floori(position.x / SPATIAL_CELL_SIZE),
		floori(position.z / SPATIAL_CELL_SIZE)
	)


func _monsters_in_range(origin: Vector3, range_value: float) -> Array[FieldMonster]:
	var found: Array[FieldMonster] = []
	for candidate in get_enemies_near(origin, range_value):
		var enemy := candidate as FieldMonster
		if is_instance_valid(enemy) and not enemy.get("dead"):
			if origin.distance_to(enemy.global_position) <= range_value:
				found.append(enemy)
	return found


func _create_hitbox_circle(radius: float) -> Mesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.035
	cylinder.radial_segments = 48
	return cylinder


func _create_hitbox_sector(radius: float, half_angle: float) -> Mesh:
	var vertices := PackedVector3Array()
	var segments := 24
	for index in range(segments):
		var start_angle := lerpf(-half_angle, half_angle, float(index) / segments)
		var end_angle := lerpf(-half_angle, half_angle, float(index + 1) / segments)
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(sin(start_angle) * radius, 0.0, -cos(start_angle) * radius))
		vertices.append(Vector3(sin(end_angle) * radius, 0.0, -cos(end_angle) * radius))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var sector := ArrayMesh.new()
	sector.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return sector


func _show_hitbox(mesh: Mesh, at: Vector3, yaw: float, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at + Vector3.UP * 0.04
	visual.rotation.y = yaw
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = material
	add_child(visual)
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.42)
	tween.tween_callback(visual.queue_free)


func monster_defeated(at: Vector3, data: Dictionary, defeated_monster: FieldMonster) -> void:
	total_kills += 1
	alive_monsters.erase(defeated_monster)
	# 경험치를 파티원 전원에게 동일하게 지급 (분할 없음)
	var exp_amount := int(data["exp"])
	GameData.run_experience_reward += exp_amount
	for member in [player] + companions:
		if not is_instance_valid(member) or member.dead:
			continue
		member.gain_experience(exp_amount)
		var idx := member.character_index
		GameData.hero_experience[idx] = int(GameData.hero_experience.get(idx, 0)) + exp_amount
		var cur_level := int(GameData.hero_levels.get(idx, 1))
		var cur_exp := int(GameData.hero_experience.get(idx, 0))
		var need := 100 + cur_level * 50
		while cur_exp >= need:
			cur_exp -= need
			cur_level += 1
			need = 100 + cur_level * 50
		GameData.hero_levels[idx] = cur_level
		GameData.hero_experience[idx] = cur_exp
	if random.randf() < float(CombatData.DROP_RULES["gold_chance"]):
		GameData.add_gold(int(data["gold"]), false)
		_queue_progress_save()
		gold_label.text = "골드 %d" % GameData.gold


func _spawn_drop(at: Vector3, kind: String, amount: int, target: FieldPlayer = null) -> void:
	if target == null:
		target = player
	var drop: FieldDrop = DropScript.new()
	drop.setup(self, target, kind, amount)
	drop.position = at + Vector3.UP * 0.05
	add_child(drop)


func collect_drop(kind: String, amount: int) -> bool:
	match kind:
		"experience":
			player.gain_experience(amount)
			GameAudio.play_sfx("experience")
			_spawn_hit_effect(player.global_position + Vector3.UP, Color("#63e2e8"), 0.45)
			_show_notification("+%d 경험치" % amount, 0.8)
		"potion":
			if not player.heal(float(amount)):
				return false
			GameAudio.play_sfx("potion")
			_show_notification("HP +%d" % amount, 1.2)
		"gold":
			GameData.add_gold(amount, false)
			_queue_progress_save()
			GameData.run_gold_reward += amount
			GameAudio.play_sfx("gold")
			gold_label.text = "골드 %d" % GameData.gold
			_show_notification("+%d 골드" % amount, 1.0)
	return true


func _queue_progress_save() -> void:
	if progress_save_pending:
		return
	progress_save_pending = true
	progress_save_timer = 0.0


func show_damage_number(at: Vector3, amount: float, is_player_damage: bool) -> void:
	var label := Label3D.new()
	label.text = str(int(round(amount)))
	label.position = at
	label.font_size = 30 if not is_player_damage else 34
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ff7972") if is_player_damage else Color("#fff2b0")
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", at.y + 0.8, 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)


func _spawn_hit_effect(at: Vector3, color: Color, radius: float) -> void:
	var effect := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	effect.mesh = sphere
	effect.position = at
	effect.scale = Vector3.ONE * maxf(0.2, radius)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	effect.material_override = material
	add_child(effect)
	var tween := create_tween()
	tween.tween_property(effect, "scale", effect.scale * 1.6, 0.24)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.24)
	tween.tween_callback(effect.queue_free)


func _on_joystick_changed(direction: Vector2) -> void:
	if player != null and not paused:
		player.set_controls(direction, running)


func _set_running(value: bool) -> void:
	run_button_held = value
	running = value
	if joystick != null and player != null:
		var direction: Vector2 = joystick.get("direction")
		player.set_controls(direction, running)


func _on_health_changed(current: float, maximum: float) -> void:
	if hp_bar != null:
		hp_bar.max_value = maximum
		hp_bar.value = current


func _on_experience_changed(current: int, required: int) -> void:
	if exp_bar != null:
		exp_bar.max_value = required
		exp_bar.value = current
		exp_label.text = "EXP %d / %d" % [current, required]


func _on_level_changed(new_level: int, unlocked_skill: int, member: FieldPlayer = null) -> void:
	if member == null:
		member = player
	GameData.run_level = new_level
	GameData.save_game()
	GameAudio.play_sfx("level_up")
	pending_level_ups.append({"level": new_level, "unlocked_skill": unlocked_skill, "member": member})
	paused = true
	get_tree().paused = true
	if pending_level_ups.size() == 1:
		call_deferred("_show_next_level_up_cards")
	_update_hud()


func _show_next_level_up_cards() -> void:
	if pending_level_ups.is_empty() or not is_instance_valid(hud_layer):
		return
	if level_up_overlay != null:
		level_up_overlay.queue_free()
	var level_info: Dictionary = pending_level_ups.front()
	leveling_member = level_info.get("member", player)
	var cards := CombatData.LEVEL_UP_CARDS.duplicate()
	cards.shuffle()
	cards = cards.slice(0, 3)
	level_up_overlay = LevelUpCardsScript.new()
	level_up_overlay.card_selected.connect(_choose_level_up_card)
	level_up_overlay.setup(int(level_info["level"]), cards)
	hud_layer.add_child(level_up_overlay)


func _choose_level_up_card(card_id: String) -> void:
	if pending_level_ups.is_empty():
		return
	GameAudio.play_sfx("card_pick")
	if leveling_member != null and is_instance_valid(leveling_member):
		leveling_member.apply_level_up_card(card_id)
	_update_hud()
	var level_info: Dictionary = pending_level_ups.pop_front()
	var unlocked_skill := int(level_info["unlocked_skill"])
	if unlocked_skill > 0:
		_show_notification("강화 완료! 스킬 %d 해금" % unlocked_skill, 2.5)
	else:
		_show_notification("강화 카드 적용 완료", 1.8)
	if pending_level_ups.is_empty():
		level_up_overlay.queue_free()
		level_up_overlay = null
		paused = false
		get_tree().paused = false
		_update_skill_button_states()
	else:
		call_deferred("_show_next_level_up_cards")


func _on_party_member_died(member: FieldPlayer) -> void:
	GameAudio.play_sfx("death")
	if member.auto_hunt_controller != null:
		member.auto_hunt_controller.update(0.0)
	# 생존 파티원이 있으면 계속 진행
	if _has_living_party_members():
		_show_notification("파티원이 쓰러졌습니다.", 1.5)
		if camera_target == member or GameData.camera_target_slot == member.party_slot:
			_select_next_camera_target(member.party_slot)
		return
	# 전원 사망 → 패배
	GameData.run_won = false
	_store_run_result()
	GameData.save_game()
	_show_notification("파티 전멸. 획득 골드 %d" % GameData.run_gold_reward, 4.0)
	paused = true
	get_tree().paused = true
	_show_end_panel("모험 종료", "획득 골드  %d" % GameData.run_gold_reward)


func _party_member_at_slot(slot: int) -> FieldPlayer:
	if slot == 0:
		return player
	var companion_index := slot - 1
	if companion_index >= 0 and companion_index < companions.size():
		return companions[companion_index]
	return null


func _select_camera_target(member: FieldPlayer) -> void:
	if not is_instance_valid(member) or member.dead:
		return
	camera_target = member
	GameData.camera_target_slot = member.party_slot
	for index in range(party_hud_panels.size()):
		var panel := party_hud_panels[index]
		if not is_instance_valid(panel):
			continue
		var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style == null:
			continue
		style.border_color = (
			Color("#f0c65b") if index == member.party_slot else Color("#d8c99e")
		)
		panel.add_theme_stylebox_override("panel", style)


func _select_next_camera_target(dead_slot: int) -> void:
	var members: Array = [player] + companions
	if members.is_empty():
		camera_target = null
		return
	for step in range(1, members.size() + 1):
		var slot := (dead_slot + step) % members.size()
		var candidate: Variant = members[slot]
		if not is_instance_valid(candidate):
			continue
		var survivor := candidate as FieldPlayer
		if survivor != null and not survivor.dead:
			_select_camera_target(survivor)
			return
	camera_target = null


func _show_notification(message: String, duration := 2.0) -> void:
	notification_label.text = message
	notification_label.visible = true
	notification_timer = duration


func _update_hud() -> void:
	if player == null:
		return
	level_label.text = "Lv. %d" % player.get("level")
	time_label.text = "%02d:%02d" % [int(elapsed_time / 60.0), int(elapsed_time) % 60]
	gold_label.text = "골드 %d" % GameData.gold
	if top_time_label != null:
		top_time_label.text = "%02d:%02d" % [int(elapsed_time / 60.0), int(elapsed_time) % 60]
	if top_kills_label != null:
		top_kills_label.text = "처치 %d" % total_kills
	for index in range(skill_buttons.size()):
		_update_skill_button(index)


func _update_skill_button(index: int) -> void:
	if index >= skill_buttons.size() or player == null:
		return
	if not _actor_has_skill(player, index):
		skill_buttons[index].disabled = true
		skill_buttons[index].text = "직업 스킬\n아님"
		return
	var skill: Dictionary = CombatData.SKILLS[index]
	var level := int(player.get("level"))
	var unlocked := level >= int(skill["unlock_level"])
	var remaining := player.skill_cooldowns[index]
	skill_buttons[index].disabled = (
		not unlocked or remaining > 0.0 or paused or player.casting_skill_index >= 0
	)
	if not unlocked:
		skill_buttons[index].text = "🔒 S%d\nLv.%d" % [skill["id"], skill["unlock_level"]]
	elif player.casting_skill_index == index:
		skill_buttons[index].text = "S%d\n시전 %.1f" % [skill["id"], player.skill_cast_remaining]
	elif remaining > 0.0:
		skill_buttons[index].text = "S%d\n%.1f초" % [skill["id"], remaining]
	else:
		skill_buttons[index].text = "S%d\n준비" % skill["id"]


func _update_camera(delta: float = 1.0 / 60.0) -> void:
	if player == null or camera == null:
		return
	if camera_target != null and not is_instance_valid(camera_target):
		_select_next_camera_target(GameData.camera_target_slot)
	elif camera_target != null and camera_target.dead:
		_select_next_camera_target(camera_target.party_slot)
	var target_origin: Vector3
	if camera_target == null and camera_distance >= 39.0:
		target_origin = Vector3.ZERO
	elif camera_target != null and is_instance_valid(camera_target) and not camera_target.dead:
		target_origin = camera_target.get_global_transform_interpolated().origin
		camera_distance = 6.0
		camera_pitch = -0.35
	elif auto_cast_enabled:
		target_origin = Vector3.ZERO
		camera_distance = 34.0
		camera_pitch = -0.8
		camera_yaw = 0.0
	else:
		target_origin = player.get_global_transform_interpolated().origin
	var cos_pitch := cos(camera_pitch)
	var offset := Vector3(
		sin(camera_yaw) * cos_pitch * camera_distance,
		sin(-camera_pitch) * camera_distance,
		cos(camera_yaw) * cos_pitch * camera_distance
	)
	var target := target_origin + offset
	var follow_weight := 1.0 - exp(-14.0 * delta)
	camera.global_position = camera.global_position.lerp(target, follow_weight)
	camera.look_at(target_origin + Vector3.UP * CAMERA_LOOK_HEIGHT, Vector3.UP)


func _toggle_pause() -> void:
	if not _has_living_party_members():
		return
	paused = not paused
	if paused:
		get_tree().paused = true
		_show_end_panel("잠시 쉬어 가요", "모험은 여기서 기다리고 있어요.")
	else:
		get_tree().paused = false
		if pause_root != null:
			pause_root.queue_free()
			pause_root = null
		pause_panel = null
	_update_skill_button_states()


func _show_end_panel(title: String, message: String) -> void:
	if pause_root != null:
		pause_root.queue_free()
	var panel_root := Control.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_root.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_layer.add_child(panel_root)
	pause_root = panel_root
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.06, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_root.add_child(shade)
	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.08
	pause_panel.anchor_top = 0.2
	pause_panel.anchor_right = 0.92
	pause_panel.anchor_bottom = 0.8
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff9e9")
	style.border_color = Color("#d8b558")
	style.set_border_width_all(3)
	style.set_content_margin_all(22)
	pause_panel.add_theme_stylebox_override("panel", style)
	panel_root.add_child(pause_panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	pause_panel.add_child(content)
	var heading := _hud_label(title, 28)
	heading.add_theme_color_override("font_color", Color("#28313d"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	pause_detail_label = _hud_label(message, 18)
	pause_detail_label.add_theme_color_override("font_color", Color("#53606a"))
	pause_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(pause_detail_label)
	if _has_living_party_members():
		_add_panel_button(content, "계속하기", _toggle_pause)
		_add_panel_button(content, "전투 정보", _show_battle_info)
		_add_panel_button(content, "설정", _show_pause_settings)
		_add_panel_button(content, "메인 허브 (전투 종료)", _return_to_menu)
	else:
		_add_panel_button(content, "결과 보기", _return_to_result)
		_add_panel_button(content, "메인 허브 (전투 종료)", _return_to_menu)
	_update_skill_button_states()


func _show_battle_info() -> void:
	if pause_detail_label == null:
		return
	pause_detail_label.text = (
		"스테이지 %d  ·  생존 %02d:%02d\n처치 %d  ·  Lv.%d"
		% [
			GameData.selected_stage + 1,
			int(elapsed_time / 60.0),
			int(elapsed_time) % 60,
			total_kills,
			player.get("level") if player != null else 1,
		]
	)


func _show_pause_settings() -> void:
	if pause_panel == null:
		return
	for child in pause_panel.get_children():
		child.queue_free()
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	pause_panel.add_child(content)
	var heading := _hud_label("설정", 28)
	heading.add_theme_color_override("font_color", Color("#28313d"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var sound_button := _make_hud_button(
		"효과음  ·  %s" % ("켜짐" if GameData.sound_enabled else "꺼짐"),
		Vector2(0, 56)
	)
	sound_button.add_theme_color_override("font_color", Color("#28313d"))
	sound_button.pressed.connect(_toggle_pause_sound)
	content.add_child(sound_button)
	var vibration_button := _make_hud_button(
		"진동  ·  %s" % ("켜짐" if GameData.vibration_enabled else "꺼짐"),
		Vector2(0, 56)
	)
	vibration_button.add_theme_color_override("font_color", Color("#28313d"))
	vibration_button.pressed.connect(_toggle_pause_vibration)
	content.add_child(vibration_button)
	_add_panel_button(content, "일시정지 메뉴", _show_pause_menu)


func _show_pause_menu() -> void:
	_show_end_panel("PAUSED", "전투 일시정지")


func _toggle_pause_sound() -> void:
	GameData.sound_enabled = not GameData.sound_enabled
	GameData.save_game()
	_show_pause_settings()


func _toggle_pause_vibration() -> void:
	GameData.vibration_enabled = not GameData.vibration_enabled
	GameData.save_game()
	_show_pause_settings()


func _add_panel_button(parent: VBoxContainer, title: String, action: Callable) -> void:
	var button := _make_hud_button(title, Vector2(0, 56))
	button.add_theme_color_override("font_color", Color("#28313d"))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.pressed.connect(action)
	parent.add_child(button)


func _update_skill_button_states() -> void:
	for index in range(skill_buttons.size()):
		_update_skill_button(index)
	if attack_button != null:
		attack_button.disabled = paused
	if run_button != null:
		run_button.disabled = paused


func _return_to_menu() -> void:
	get_tree().paused = false
	GameData.save_game()
	ScreenRouter.go("main_menu")


func _return_to_result() -> void:
	_store_run_result()
	GameData.save_game()
	get_tree().paused = false
	ScreenRouter.go("result")


func _store_run_result() -> void:
	GameData.run_elapsed_time = elapsed_time
	GameData.run_kill_count = total_kills


func _build_field_decorations() -> void:
	var base := "res://assets/field/"
	_add_fbx(base + "misc_models/gazebo.fbx", Vector3(0, 0, 0), Vector3.ONE, 0.0, true)
	for corner in [Vector3(FIELD_RADIUS - 4, 0, 0), Vector3(0, 0, FIELD_RADIUS - 4), Vector3(-FIELD_RADIUS + 4, 0, 0), Vector3(0, 0, -FIELD_RADIUS + 4)]:
		_add_fbx(base + "misc_models/tower.fbx", corner, Vector3.ONE, random.randf_range(0.0, TAU), true)
	var fence_path := base + "misc_models/fences/fence2_01.fbx"
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var dist := FIELD_RADIUS - 1.0
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		_add_fbx(fence_path, pos, Vector3.ONE, -angle + PI * 0.5, true)
	for i in range(8):
		var p := Vector3(random.randf_range(-20.0, 20.0), 0.0, random.randf_range(-20.0, 20.0))
		if absf(p.x) >= 12.5 or absf(p.z) >= 12.5:
			continue
		if Vector2(p.x, p.z).length() < 4.0:
			continue
		var bed := base + "misc_models/flowers/flowerbed" + str(random.randi_range(1, 7)) + "_2x2.fbx"
		_add_fbx(bed, p, Vector3.ONE, random.randf_range(0.0, TAU), false)
	for i in range(6):
		var p := Vector3(random.randf_range(-18.0, 18.0), 0.0, random.randf_range(-18.0, 18.0))
		if absf(p.x) >= 12.5 or absf(p.z) >= 12.5:
			continue
		_add_fbx(base + "misc_models/stone/bench01.fbx", p, Vector3.ONE, random.randf_range(0.0, TAU), true)
	_add_fbx(base + "misc_models/stone/fountain01_round.fbx", Vector3(6, 0, 6), Vector3.ONE, 0.0, true)
	_add_fbx(base + "misc_models/stone/fountain02_square.fbx", Vector3(-6, 0, -6), Vector3.ONE, 0.0, true)
	for i in range(4):
		var p := Vector3(random.randf_range(-10.0, 10.0), 0.0, random.randf_range(-10.0, 10.0))
		_add_fbx(base + "modular_hedge/basic/basic_3x1.fbx", p, Vector3.ONE, random.randf_range(0.0, TAU), true)


func _add_fbx(path: String, position: Vector3, scale: Vector3, yaw: float, collidable: bool = false) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		return
	var instance: Node3D = scene.instantiate() as Node3D
	if instance == null:
		return
	instance.position = position
	instance.scale = scale
	instance.rotation.y = yaw
	add_child(instance)
	if collidable and instance is Node3D:
		# best-effort collision not auto-generated for FBX; leave visuals only
		pass
