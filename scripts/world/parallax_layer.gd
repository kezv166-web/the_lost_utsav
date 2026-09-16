extends Node3D

@export var parallax_ratio: float = 0.92
@export var offset_z: float = -12.0
@export var offset_y: float = 3.5

var _cam: Camera3D

func _process(_delta: float) -> void:
	if not _cam:
		_cam = get_viewport().get_camera_3d()
	if _cam:
		global_position.z = _cam.global_position.z * parallax_ratio + offset_z
		global_position.y = _cam.global_position.y * 0.5 + offset_y
