extends Area3D

@export var max_radius: float = 4.8
@export var expansion_speed: float = 9.0
@export var damage: int = 50
@export var lifetime: float = 0.85

var current_radius: float = 1.0
var time_alive: float = 0.0
var has_damaged_player: bool = false
var epicenter: Vector3 = Vector3.ZERO

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var quake_light: OmniLight3D = get_node_or_null("QuakeLight")
@onready var shock_ring: Decal = get_node_or_null("ShockRing")
@onready var dust_particles: CPUParticles3D = get_node_or_null("DustParticles")

func _ready() -> void:
	epicenter = global_position
	body_entered.connect(_on_body_entered)
	if collision_shape and collision_shape.shape is CylinderShape3D:
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.radius = current_radius
		collision_shape.shape.height = 1.0

func setup(origin: Vector3) -> void:
	epicenter = origin
	global_position = origin
	global_position.y = 0.05

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return
		
	# Expand radius rapidly
	if current_radius < max_radius:
		current_radius = minf(max_radius, current_radius + expansion_speed * delta)
		if collision_shape and collision_shape.shape is CylinderShape3D:
			collision_shape.shape.radius = current_radius
			
	if shock_ring:
		shock_ring.size = Vector3(current_radius * 2.0, 1.5, current_radius * 2.0)
		var fade = clampf(1.0 - (time_alive / lifetime), 0.0, 1.0)
		shock_ring.modulate = Color(1.0, 0.6, 0.2, fade)

	if quake_light:
		var fade = clampf(1.0 - (time_alive / lifetime), 0.0, 1.0)
		quake_light.light_energy = 3.5 * fade
		quake_light.omni_range = current_radius + 2.0

	# Continuous area check for player jumping vs grounded
	_check_grounded_targets()

func _check_grounded_targets() -> void:
	if has_damaged_player:
		return
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			_try_damage_player(body)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_damaged_player:
		_try_damage_player(body)

func _try_damage_player(player: Node3D) -> void:
	if has_damaged_player:
		return
	var offset = player.global_position - epicenter
	var dist = Vector2(offset.x, offset.z).length()
	
	if dist <= current_radius:
		# If player is airborne / jumping above ground level, they evade the ground tremor!
		var is_airborne = player.global_position.y > 0.35 or (player.get("is_jumping") and player.is_jumping)
		if is_airborne:
			return # Dodged by jumping!
			
		has_damaged_player = true
		if player.has_method("take_damage"):
			player.take_damage(damage, epicenter)
