extends Node3D

@export var depth_distance: float = 80.0
@export var base_vertical_offset: float = 20.0
@export var parallax_factor_x: float = 0.15
@export var parallax_factor_y: float = 0.06
@export var ref_cam_z: float = 24.6
@export var ref_cam_x: float = 0.0

var _camera: Camera3D

func _process(_delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera:
		# Align orientation directly with camera view plane
		global_transform.basis = _camera.global_transform.basis
		var forward = -_camera.global_transform.basis.z
		var up = _camera.global_transform.basis.y
		var right = _camera.global_transform.basis.x
		
		# Travel relative to bridge center reference
		var cam_x = _camera.global_position.x
		var cam_z = _camera.global_position.z
		var dx = cam_x - ref_cam_x
		var dz = cam_z - ref_cam_z
		
		# Pitch angle for 3D perspective projection (-10.5 degrees)
		var sin_pitch = sin(deg_to_rad(10.5))
		
		# Subtle distant parallax displacement in camera screen space
		var offset_x = -dx * parallax_factor_x
		var offset_y = base_vertical_offset - (dz * sin_pitch * parallax_factor_y)
		
		global_position = _camera.global_position + (forward * depth_distance) + (right * offset_x) + (up * offset_y)

