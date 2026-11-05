class_name DiamondGrasslandMinimap
extends Control

const MAP_COLOR := Color("#6aab63")
const MAP_BORDER := Color("#e8cb79")
const PLAYER_COLOR := Color("#fff1a8")
const ENEMY_COLOR := Color("#ec6660")
const CRYSTAL_COLOR := Color("#6ee4ed")

var field: Node3D
var player: FieldPlayer
var field_radius := 26.0


func setup(game: Node3D, target: FieldPlayer, radius: float) -> void:
	field = game
	player = target
	field_radius = radius


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var half_width := size.x * 0.43
	var half_height := size.y * 0.43
	var diamond := PackedVector2Array(
		[
			center + Vector2(0, -half_height),
			center + Vector2(half_width, 0),
			center + Vector2(0, half_height),
			center + Vector2(-half_width, 0),
		]
	)
	draw_colored_polygon(diamond, Color(0.08, 0.16, 0.12, 0.88))
	draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(0, -half_height + 3),
				center + Vector2(half_width - 3, 0),
				center + Vector2(0, half_height - 3),
				center + Vector2(-half_width + 3, 0),
			]
		),
		MAP_COLOR
	)
	var border := diamond.duplicate()
	border.append(diamond[0])
	draw_polyline(border, MAP_BORDER, 3.0, true)
	_draw_crystals(center, half_width, half_height)
	_draw_enemies(center, half_width, half_height)
	if is_instance_valid(player):
		draw_circle(
			_map_position(player.global_position, center, half_width, half_height),
			6.0,
			PLAYER_COLOR
		)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 26, size.y - 2),
		"초원",
		HORIZONTAL_ALIGNMENT_CENTER,
		52,
		13,
		Color("#fff8e9")
	)


func _draw_crystals(center: Vector2, half_width: float, half_height: float) -> void:
	for world_position in [
		Vector3(0, 0, -13),
		Vector3(13, 0, 12),
		Vector3(-13, 0, 12),
	]:
		var point := _map_position(world_position, center, half_width, half_height)
		draw_colored_polygon(
			PackedVector2Array(
				[
					point + Vector2(0, -4),
					point + Vector2(4, 0),
					point + Vector2(0, 4),
					point + Vector2(-4, 0)
				]
			),
			CRYSTAL_COLOR
		)


func _draw_enemies(center: Vector2, half_width: float, half_height: float) -> void:
	if not is_instance_valid(field):
		return
	var enemies: Array = field.get("alive_monsters")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			draw_circle(
				_map_position(enemy.global_position, center, half_width, half_height),
				3.5,
				ENEMY_COLOR
			)


func _map_position(
	world_position: Vector3, center: Vector2, half_width: float, half_height: float
) -> Vector2:
	return (
		center
		+ Vector2(
			world_position.x / field_radius * half_width,
			world_position.z / field_radius * half_height
		)
	)
