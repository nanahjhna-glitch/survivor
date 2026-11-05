class_name GrasslandJoystick
extends Control

signal direction_changed(direction: Vector2)

var direction := Vector2.ZERO
var knob_position := Vector2.ZERO
var active := false
var pointer_id := -1


func _ready() -> void:
	custom_minimum_size = Vector2(156, 156)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			pointer_id = event.index
			_update_direction(event.position)
		elif not event.pressed and event.index == pointer_id:
			_release()
	elif event is InputEventScreenDrag and event.index == pointer_id:
		_update_direction(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			pointer_id = -2
			_update_direction(event.position)
		elif pointer_id == -2:
			_release()
	elif event is InputEventMouseMotion and pointer_id == -2:
		_update_direction(event.position)


func _update_direction(pointer: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.38
	var offset := pointer - size * 0.5
	knob_position = offset.limit_length(radius)
	direction = (knob_position / radius).limit_length(1.0)
	direction_changed.emit(direction)
	queue_redraw()


func _release() -> void:
	active = false
	pointer_id = -1
	direction = Vector2.ZERO
	knob_position = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	draw_circle(center, radius, Color(0.08, 0.12, 0.16, 0.3))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.95, 0.89, 0.7, 0.8), 3.0)
	draw_circle(center + knob_position, radius * 0.44, Color(0.92, 0.78, 0.43, 0.82))
	draw_arc(center + knob_position, radius * 0.44, 0.0, TAU, 32, Color("#fff2cf"), 2.0)
