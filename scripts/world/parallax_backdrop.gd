extends Node3D

@export var depth_distance: float = 65.0
@export var vertical_offset: float = 0.0
@export var horizontal_offset: float = 0.0

var _camera: Camera3D

func _process(_delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera:
		global_transform.basis = _camera.global_transform.basis
		var forward = -_camera.global_transform.basis.z
		var up = _camera.global_transform.basis.y
		var right = _camera.global_transform.basis.x
		global_position = _camera.global_position + (forward * depth_distance) + (up * vertical_offset) + (right * horizontal_offset)
