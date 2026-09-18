extends Node3D

@export var target: Node3D
@export var follow_speed: float = 5.0
@export var target_offset: Vector3 = Vector3(0.0, 1.35, -2.0)
@export var min_x: float = -3.5
@export var max_x: float = 3.5

func _ready() -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
	if target:
		var initial_pos = target.global_position + target_offset
		initial_pos.x = clamp(initial_pos.x, min_x, max_x)
		global_position = initial_pos

func _physics_process(delta: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
		if not target:
			return
	
	var desired_pos = target.global_position + target_offset
	desired_pos.x = clamp(desired_pos.x, min_x, max_x)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
