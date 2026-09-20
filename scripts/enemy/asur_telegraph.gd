extends Node3D

signal telegraph_completed

enum ShapeType {
	RECTANGLE,
	CIRCLE
}

@export var shape_type: ShapeType = ShapeType.RECTANGLE
@export var duration: float = 1.0
@export var width: float = 2.4
@export var length: float = 6.5
@export var radius: float = 7.5

# High-contrast, rich dark crimson danger palette
const COLOR_BASE_BG: Color = Color(1.0, 0.57, 0.0, 0.32)         # Glowing amber footprint (#FF9100)
const COLOR_BORDER: Color = Color(1.0, 0.09, 0.27, 0.95)          # High-contrast searing crimson border (#FF1744)
const COLOR_FILL: Color = Color(0.92, 0.08, 0.16, 0.65)           # Vibrant danger red fill
const COLOR_FLASH: Color = Color(1.8, 0.35, 0.35, 0.95)           # Full charge peak flash

var elapsed_time: float = 0.0
var progress: float = 0.0
var is_completed: bool = false
var attack_dir: Vector3 = Vector3(0, 0, 1)

@onready var base_mesh: MeshInstance3D = $BaseFootprint
@onready var border_mesh: MeshInstance3D = $BorderMesh
@onready var fill_mesh: MeshInstance3D = $FillMesh
@onready var warning_light: OmniLight3D = get_node_or_null("WarningLight")

var base_mat: StandardMaterial3D
var border_mat: StandardMaterial3D
var fill_mat: StandardMaterial3D

var fill_quad: QuadMesh = null
var fill_cyl: CylinderMesh = null

func _ready() -> void:
	global_position.y = 0.04
	if not warning_light:
		warning_light = OmniLight3D.new()
		warning_light.name = "WarningLight"
		warning_light.light_color = Color(1.0, 0.35, 0.1)
		warning_light.omni_range = 7.5
		warning_light.light_energy = 2.0
		add_child(warning_light)
	_setup_materials()
	_rebuild_geometry()

func setup_rect(dir: Vector3, lane_width: float = 2.4, lane_length: float = 6.5, time_sec: float = 1.0) -> void:
	shape_type = ShapeType.RECTANGLE
	width = lane_width
	length = lane_length
	duration = time_sec
	
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		attack_dir = dir.normalized()
		# Align local Z with the attack direction
		rotation.y = atan2(attack_dir.x, attack_dir.z)
		
	_rebuild_geometry()

func setup_circle(epicenter: Vector3, circle_radius: float = 7.5, time_sec: float = 1.0) -> void:
	shape_type = ShapeType.CIRCLE
	radius = circle_radius
	duration = time_sec
	global_position = epicenter
	global_position.y = 0.04
	_rebuild_geometry()

func _setup_materials() -> void:
	base_mat = StandardMaterial3D.new()
	base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	base_mat.albedo_color = COLOR_BASE_BG
	
	border_mat = StandardMaterial3D.new()
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	border_mat.albedo_color = COLOR_BORDER
	border_mat.emission_enabled = true
	border_mat.emission = Color(1.0, 0.57, 0.0) # Glowing amber rim (#FF9100)
	border_mat.emission_energy_multiplier = 1.6

	fill_mat = StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill_mat.albedo_color = COLOR_FILL

func _rebuild_geometry() -> void:
	if not base_mesh or not fill_mesh:
		return
	if not base_mat:
		_setup_materials()

	if shape_type == ShapeType.RECTANGLE:
		# Static base footprint (full lane)
		var base_quad = QuadMesh.new()
		base_quad.size = Vector2(width, length)
		base_quad.orientation = PlaneMesh.FACE_Y
		base_mesh.mesh = base_quad
		base_mesh.material_override = base_mat
		base_mesh.position = Vector3(0, 0.005, length * 0.5)
		
		# Static border outline
		if border_mesh:
			var b_quad = QuadMesh.new()
			b_quad.size = Vector2(width + 0.15, length + 0.15)
			b_quad.orientation = PlaneMesh.FACE_Y
			border_mesh.mesh = b_quad
			border_mesh.material_override = border_mat
			border_mesh.position = Vector3(0, 0.002, length * 0.5)

		# Dynamic progressive fill mesh (grows forward from 0 to length)
		fill_quad = QuadMesh.new()
		fill_quad.size = Vector2(width, 0.01)
		fill_quad.orientation = PlaneMesh.FACE_Y
		fill_mesh.mesh = fill_quad
		fill_mesh.material_override = fill_mat
		fill_mesh.position = Vector3(0, 0.01, 0.005)
	else:
		# Static base footprint (full circle)
		var base_cyl = CylinderMesh.new()
		base_cyl.top_radius = radius
		base_cyl.bottom_radius = radius
		base_cyl.height = 0.01
		base_cyl.radial_segments = 48
		base_mesh.mesh = base_cyl
		base_mesh.material_override = base_mat
		base_mesh.position = Vector3.ZERO
		
		# Static border outline
		if border_mesh:
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = radius + 0.15
			b_cyl.bottom_radius = radius + 0.15
			b_cyl.height = 0.008
			b_cyl.radial_segments = 48
			border_mesh.mesh = b_cyl
			border_mesh.material_override = border_mat
			border_mesh.position = Vector3.ZERO

		# Dynamic progressive fill mesh (expands outward from 0.1 to radius)
		fill_cyl = CylinderMesh.new()
		fill_cyl.top_radius = 0.1
		fill_cyl.bottom_radius = 0.1
		fill_cyl.height = 0.012
		fill_cyl.radial_segments = 48
		fill_mesh.mesh = fill_cyl
		fill_mesh.material_override = fill_mat
		fill_mesh.position = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if is_completed:
		return
		
	elapsed_time += delta
	progress = clampf(elapsed_time / duration, 0.0, 1.0)
	
	# Update progressive fill geometry
	if shape_type == ShapeType.RECTANGLE:
		var current_len = maxf(0.01, length * progress)
		if fill_quad:
			fill_quad.size = Vector2(width, current_len)
			fill_mesh.position = Vector3(0, 0.01, current_len * 0.5)
	else:
		var current_rad = maxf(0.1, radius * progress)
		if fill_cyl:
			fill_cyl.top_radius = current_rad
			fill_cyl.bottom_radius = current_rad
			
	# Pulse warning light and fill brightness
	if warning_light:
		var shimmer = sin(elapsed_time * 18.0) * 0.45
		warning_light.light_energy = 1.2 + progress * 2.8 + shimmer
		warning_light.omni_range = (radius if shape_type == ShapeType.CIRCLE else length) + 1.5
		
	if progress >= 1.0 and not is_completed:
		is_completed = true
		_on_telegraph_finish()

func _on_telegraph_finish() -> void:
	# Peak danger reached -> notify boss to strike!
	emit_signal("telegraph_completed")
	
	# Flash red-white on full fill impact then fade out smoothly
	if fill_mat:
		fill_mat.albedo_color = COLOR_FLASH
	if border_mat:
		border_mat.albedo_color = COLOR_FLASH
		
	var tw = create_tween().set_parallel(true)
	if fill_mat:
		tw.tween_property(fill_mat, "albedo_color:a", 0.0, 0.16)
	if border_mat:
		tw.tween_property(border_mat, "albedo_color:a", 0.0, 0.16)
	var end_tw = create_tween()
	end_tw.tween_interval(0.18)
	end_tw.tween_callback(queue_free)
