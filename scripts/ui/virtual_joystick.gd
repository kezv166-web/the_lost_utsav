class_name UIVirtualJoystick
extends Control

## Virtual Analog Joystick for Mobile Touch Controls
## Smooth 8-directional & analog movement dispatch with zero overhead.

@export var max_radius: float = 60.0
@export var deadzone: float = 10.0
@export var base_radius: float = 65.0
@export var knob_radius: float = 28.0

# Colors for Mythological Ornate Aesthetic
const COLOR_BASE_OUTER := Color(0.85, 0.68, 0.22, 0.5)      # Antique gold ring
const COLOR_BASE_INNER := Color(0.12, 0.08, 0.04, 0.45)     # Translucent obsidian base
const COLOR_BASE_BORDER := Color(1.0, 0.85, 0.35, 0.85)     # Glowing gold rim
const COLOR_BASE_ACCENT := Color(0.9, 0.35, 0.2, 0.7)       # Ruby jewel accents
const COLOR_KNOB_OUTER := Color(0.95, 0.82, 0.32, 0.95)     # Rich gold knob
const COLOR_KNOB_INNER := Color(0.25, 0.16, 0.08, 0.9)      # Dark core
const COLOR_KNOB_JEWEL := Color(0.85, 0.18, 0.15, 0.95)     # Central ruby cabochon

var _touch_index: int = -1
var _is_active: bool = false
var _center_pos: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO
var _output_vector: Vector2 = Vector2.ZERO
var _knob_tween: Tween = null

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_center_pos = size * 0.5
	_knob_pos = _center_pos

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _is_active:
			_start_touch(event.position, event.index)
			accept_event()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_end_touch()
			accept_event()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_touch(event.position)
		accept_event()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not _is_active:
				_start_touch(event.position, -1)
				accept_event()
				get_viewport().set_input_as_handled()
			elif not event.pressed and _touch_index == -1:
				_end_touch()
				accept_event()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _touch_index == -1 and _is_active:
		_update_touch(event.position)
		accept_event()
		get_viewport().set_input_as_handled()

func _start_touch(local_pos: Vector2, index: int) -> void:
	_is_active = true
	_touch_index = index
	if _knob_tween and _knob_tween.is_valid():
		_knob_tween.kill()
	_update_touch(local_pos)

func _update_touch(local_pos: Vector2) -> void:
	var delta = local_pos - _center_pos
	var dist = delta.length()
	
	if dist > max_radius:
		delta = delta.normalized() * max_radius
		_knob_pos = _center_pos + delta
	else:
		_knob_pos = local_pos
		
	if dist < deadzone:
		_output_vector = Vector2.ZERO
	else:
		var normalized_dist = (dist - deadzone) / (max_radius - deadzone)
		_output_vector = delta.normalized() * clamp(normalized_dist, 0.0, 1.0)
		
	_dispatch_movement_input(_output_vector)
	queue_redraw()

func _end_touch() -> void:
	_is_active = false
	_touch_index = -1
	_output_vector = Vector2.ZERO
	_dispatch_movement_input(Vector2.ZERO)
	
	# Smooth snappy return
	_knob_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_knob_tween.tween_property(self, "_knob_pos", _center_pos, 0.15)
	_knob_tween.parallel().tween_callback(queue_redraw)
	_knob_tween.tween_callback(func(): queue_redraw())

func _dispatch_movement_input(vec: Vector2) -> void:
	# Horizontal (move_left, move_right)
	if vec.x > 0.08:
		Input.action_press("move_right", clamp(vec.x, 0.0, 1.0))
		Input.action_release("move_left")
	elif vec.x < -0.08:
		Input.action_press("move_left", clamp(-vec.x, 0.0, 1.0))
		Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
		
	# Vertical (move_up, move_down)
	if vec.y > 0.08:
		Input.action_press("move_down", clamp(vec.y, 0.0, 1.0))
		Input.action_release("move_up")
	elif vec.y < -0.08:
		Input.action_press("move_up", clamp(-vec.y, 0.0, 1.0))
		Input.action_release("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func release_all_inputs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	_is_active = false
	_touch_index = -1
	_output_vector = Vector2.ZERO
	_knob_pos = _center_pos
	queue_redraw()

func get_output() -> Vector2:
	return _output_vector

func _draw() -> void:
	_center_pos = size * 0.5
	if not _is_active and (_knob_tween == null or not _knob_tween.is_valid()):
		_knob_pos = _center_pos

	# 1. Base Disc & Borders
	draw_circle(_center_pos, base_radius, COLOR_BASE_INNER)
	draw_arc(_center_pos, base_radius, 0, TAU, 36, COLOR_BASE_OUTER, 4.0, true)
	draw_arc(_center_pos, base_radius - 4.0, 0, TAU, 36, COLOR_BASE_BORDER, 1.5, true)
	draw_arc(_center_pos, base_radius * 0.6, 0, TAU, 28, Color(1.0, 0.85, 0.35, 0.25), 1.0, true)

	# 2. Four Directional Gem Accents (N, S, E, W)
	var dirs = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
	for d in dirs:
		var gem_pos = _center_pos + d * (base_radius - 8.0)
		draw_circle(gem_pos, 3.5, COLOR_BASE_ACCENT)
		draw_arc(gem_pos, 3.5, 0, TAU, 12, COLOR_BASE_BORDER, 1.0, true)

	# 3. Connecting Line from Center to Knob (when dragged)
	if _is_active and _knob_pos.distance_squared_to(_center_pos) > 25.0:
		var line_col = Color(1.0, 0.85, 0.35, 0.45)
		draw_line(_center_pos, _knob_pos, line_col, 3.0, true)

	# 4. Knob Disc & Glowing Core
	var knob_border = COLOR_KNOB_OUTER if _is_active else Color(0.85, 0.72, 0.28, 0.8)
	draw_circle(_knob_pos, knob_radius, COLOR_KNOB_INNER)
	draw_arc(_knob_pos, knob_radius, 0, TAU, 28, knob_border, 3.5, true)
	draw_arc(_knob_pos, knob_radius - 3.5, 0, TAU, 28, Color(1.0, 0.95, 0.6, 0.6), 1.5, true)

	# 5. Knob Center Jewel
	draw_circle(_knob_pos, 8.0, COLOR_KNOB_JEWEL)
	draw_circle(_knob_pos + Vector2(-2, -2), 2.5, Color(1.0, 1.0, 1.0, 0.75)) # Highlight
