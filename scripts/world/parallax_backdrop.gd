extends Node3D

@export var parallax_factor_x: float = 0.12
@export var parallax_factor_y: float = 0.08
@export var parallax_factor_z: float = 0.00

var _camera: Camera3D
var _initial_pos: Vector3
var _initialized: bool = false

func _ready() -> void:
	_initial_pos = global_position
	_initialized = true

func _process(_delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera and _initialized:
		# Subtle depth parallax relative to camera movement, keeping backdrop securely anchored behind fortress
		global_position.x = _initial_pos.x + (_camera.global_position.x * parallax_factor_x)
		global_position.y = _initial_pos.y + ((_camera.global_position.y - 3.0) * parallax_factor_y)
		global_position.z = _initial_pos.z + ((_camera.global_position.z - 17.0) * parallax_factor_z)

