extends Node3D

@export var target: Node3D
@export var follow_speed: float = 4.8
@export var target_offset: Vector3 = Vector3(0.0, 5.0, -7.0)

func _ready() -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
	if target:
		global_position = target.global_position + target_offset

func _physics_process(delta: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
		if not target:
			return
	
	var desired_pos = target.global_position + target_offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
