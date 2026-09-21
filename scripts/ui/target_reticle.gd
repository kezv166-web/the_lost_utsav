extends Node3D

var current_target: Node3D = null
var pulse_time: float = 0.0

@onready var ring: Sprite3D = $Ring
@onready var label: Label3D = $MarkerLabel

func _ready() -> void:
	visible = false
	if ring:
		ring.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		ring.no_depth_test = true
		ring.render_priority = 10

func set_target(target: Node3D) -> void:
	current_target = target
	if is_instance_valid(current_target) and current_target.is_inside_tree():
		visible = true
		_update_position(true)
	else:
		visible = false

func clear_target() -> void:
	current_target = null
	visible = false

func get_target() -> Node3D:
	return current_target if is_instance_valid(current_target) else null

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(current_target) or not current_target.is_inside_tree():
		if visible:
			visible = false
		current_target = null
		return

	pulse_time += delta
	_update_position(false)

	# Visual pulsing and spinning
	if ring:
		ring.rotation.y += delta * 2.5
		var scale_factor = 1.0 + sin(pulse_time * 6.0) * 0.12
		ring.scale = Vector3(scale_factor, scale_factor, scale_factor)

	if label:
		var bounce = sin(pulse_time * 8.0) * 0.12
		label.position.y = 1.6 + bounce

func _update_position(snap: bool = false) -> void:
	if not is_instance_valid(current_target):
		return
	
	var target_pos = current_target.global_position
	# Adjust height based on target (Boss is taller than Chota Asur)
	var offset_y = 1.2
	if current_target.is_in_group("boss"):
		offset_y = 2.4
	elif current_target.is_in_group("chota_asur"):
		offset_y = 0.9
		
	var dest = target_pos + Vector3(0, offset_y, 0)
	if snap:
		global_position = dest
	else:
		global_position = global_position.lerp(dest, 0.35)
