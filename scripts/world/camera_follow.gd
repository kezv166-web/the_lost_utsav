extends Node3D

@export var target: Node3D
@export var follow_speed: float = 5.0
@export var target_offset: Vector3 = Vector3(0.0, 1.35, -2.0)
@export var min_x: float = -3.5
@export var max_x: float = 3.5
@export var min_z: float = -1000.0
@export var max_z: float = 1000.0

var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0
var _pivot_node: Node3D = null

func _ready() -> void:
	_pivot_node = get_node_or_null("Pivot")
	if not target:
		target = get_tree().get_first_node_in_group("player")
	if target:
		var initial_pos = target.global_position + target_offset
		initial_pos.x = clamp(initial_pos.x, min_x, max_x)
		initial_pos.z = clamp(initial_pos.z, min_z, max_z)
		global_position = initial_pos

func shake(duration: float = 0.3, intensity: float = 16.0) -> void:
	_shake_duration = maxf(0.05, duration)
	_shake_timer = _shake_duration
	_shake_intensity = intensity

func _physics_process(delta: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
		if not target:
			return
	
	var desired_pos = target.global_position + target_offset
	desired_pos.x = clamp(desired_pos.x, min_x, max_x)
	desired_pos.z = clamp(desired_pos.z, min_z, max_z)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Handle camera shake on the Pivot child (or local offset)
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var damping: float = clampf(_shake_timer / _shake_duration, 0.0, 1.0)
		var amp: float = _shake_intensity * 0.012 * damping
		var offset = Vector3(
			randf_range(-amp, amp),
			randf_range(-amp * 0.6, amp * 0.6),
			randf_range(-amp * 0.4, amp * 0.4)
		)
		if _pivot_node:
			_pivot_node.position = offset
	elif _pivot_node and _pivot_node.position != Vector3.ZERO:
		_pivot_node.position = Vector3.ZERO
