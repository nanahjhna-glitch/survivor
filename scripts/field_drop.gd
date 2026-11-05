class_name FieldDrop
extends Node3D

var arena: Node3D
var player: CharacterBody3D
var item_type := "experience"
var amount := 1
var life_time := float(CombatData.DROP_RULES["life_time"])
var elapsed := 0.0
var visual: MeshInstance3D


func setup(game: Node3D, target: CharacterBody3D, kind: String, quantity: int) -> void:
	arena = game
	player = target
	item_type = kind
	amount = quantity
	_build_visual()


func _build_visual() -> void:
	visual = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22 if item_type == "experience" else 0.26
	sphere.height = sphere.radius * 2.0
	visual.mesh = sphere
	var material := StandardMaterial3D.new()
	match item_type:
		"experience":
			material.albedo_color = Color("#64dce1")
			material.emission_enabled = true
			material.emission = Color("#259da6")
		"potion":
			material.albedo_color = Color("#ed5b5b")
			material.emission_enabled = true
			material.emission = Color("#8c2020")
		"gold":
			material.albedo_color = Color("#ffcf50")
			material.metallic = 0.25
	visual.material_override = material
	add_child(visual)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= life_time or not is_instance_valid(player):
		queue_free()
		return
	visual.position.y = 0.2 + sin(elapsed * 4.0) * 0.08
	visual.rotate_y(delta * 1.8)
	var distance := _ground_distance_to_player()
	if item_type == "experience" and distance < player.experience_magnet_range:
		global_position = global_position.move_toward(
			player.global_position + Vector3.UP * 0.8,
			delta * float(CombatData.DROP_RULES["experience_magnet_speed"])
		)
	if _ground_distance_to_player() < 0.85 and arena.call("collect_drop", item_type, amount):
		queue_free()


func _ground_distance_to_player() -> float:
	var drop_position := Vector2(global_position.x, global_position.z)
	var player_position := Vector2(player.global_position.x, player.global_position.z)
	return drop_position.distance_to(player_position)
