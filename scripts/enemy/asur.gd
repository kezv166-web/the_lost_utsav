extends CharacterBody3D

signal boss_roared
signal boss_damaged(new_hp: int)
signal boss_defeated

enum State {
	IDLE,
	ROAR,
	ATTACK,
	RECOVERY,
	STAGGER,
	HURT,
	STUN
}

enum AttackType {
	GADHA_SLAM,
	MEGA_STOMP
}

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export var max_health: int = 1000
@export var attack_range: float = 3.2
@export var stomp_range: float = 5.5
@export var attack_cooldown_duration: float = 3.0
@export var telegraph_duration: float = 0.95
@export var recovery_duration: float = 1.8
@export var stun_duration: float = 2.2

var health: int = 1000
var current_state: State = State.IDLE
var current_attack_type: AttackType = AttackType.GADHA_SLAM
var current_direction: Direction = Direction.DOWN
var attack_cooldown: float = 1.0
var attack_counter: int = 0
var recovery_timer: float = 0.0
var stun_timer: float = 0.0
var has_hit_in_current_attack: bool = false
var is_telegraphing: bool = false

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var aura_light: OmniLight3D = $AuraLight
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var aura_particles: CPUParticles3D = $AuraParticles

var spikes_scene: PackedScene = preload("res://scenes/enemy/asur_spikes.tscn")
var quake_scene: PackedScene = preload("res://scenes/enemy/asur_quake.tscn")
var ground_cracks_scene: PackedScene = preload("res://scenes/enemy/asur_ground_cracks.tscn")
var telegraph_scene: PackedScene = preload("res://scenes/enemy/asur_telegraph.tscn")
var active_telegraph: Node3D = null

var player_ref: Node3D = null
var pulse_time: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	add_to_group("boss")
	
	var solid_obstacle = get_node_or_null("SolidObstacle")
	if solid_obstacle:
		add_collision_exception_with(solid_obstacle)
	
	if anim_sprite:
		anim_sprite.animation_finished.connect(_on_animation_finished)
		anim_sprite.frame_changed.connect(_on_anim_frame_changed)
	
	# Configure visual settings
	if anim_sprite:
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.sorting_offset = 0.0
		anim_sprite.render_priority = 0
		anim_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		anim_sprite.pixel_size = 0.020
		anim_sprite.position = Vector3(0, 2.30, 0)
	
	_play_anim("idle_down")

func set_player(p: Node3D) -> void:
	player_ref = p

func _physics_process(delta: float) -> void:
	if recovery_timer > 0.0:
		recovery_timer -= delta
		if recovery_timer <= 0.0 and current_state == State.RECOVERY:
			current_state = State.IDLE
			attack_cooldown = attack_cooldown_duration
			_play_anim("idle_down")

	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0 and current_state == State.STUN:
			_play_anim("recover_stun")

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	
	if health <= 0 or not visible:
		return
		
	# Attack evaluation against player
	if current_state == State.IDLE and player_ref and is_instance_valid(player_ref):
		var offset = player_ref.global_position - global_position
		var dist = offset.length()
		
		# If player is in front/side within attack range and attack is off cooldown
		if dist <= stomp_range and offset.z > -0.8 and attack_cooldown <= 0.0:
			if dist > attack_range:
				# Far / big range attack: Mega Earthquake Stomp Slam!
				attack_stomp()
			else:
				# Close to mid range: alternate between Gadha Slam and Stomp Slam
				if attack_counter % 2 == 1:
					attack_stomp()
				else:
					attack()

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if aura_light:
		aura_light.light_energy = 1.8 + sin(pulse_time) * 0.5
	
	# Track player facing when in IDLE
	if current_state == State.IDLE and player_ref and is_instance_valid(player_ref):
		var offset = player_ref.global_position - global_position
		if offset.x < -1.0:
			current_direction = Direction.LEFT
			_play_anim("idle_left")
		elif offset.x > 1.0:
			current_direction = Direction.RIGHT
			_play_anim("idle_right")
		else:
			current_direction = Direction.DOWN
			_play_anim("idle_down")
	elif current_state == State.IDLE:
		_play_anim("idle_down")

func roar() -> void:
	if current_state == State.ROAR:
		return
	current_state = State.ROAR
	var dir_str = _get_dir_str()
	_play_anim("roar_" + dir_str)
	if aura_particles:
		aura_particles.emitting = true
	emit_signal("boss_roared")

func attack() -> void:
	if current_state == State.ATTACK or health <= 0:
		return
	current_state = State.ATTACK
	current_attack_type = AttackType.GADHA_SLAM
	attack_counter += 1
	has_hit_in_current_attack = false
	is_telegraphing = true
	
	if player_ref and is_instance_valid(player_ref):
		var offset = player_ref.global_position - global_position
		if offset.x < -0.8:
			current_direction = Direction.LEFT
		elif offset.x > 0.8:
			current_direction = Direction.RIGHT
		else:
			current_direction = Direction.DOWN

	var dir_str = _get_dir_str()
	_play_anim("attack_" + dir_str)
	if anim_sprite:
		anim_sprite.frame = 1
		anim_sprite.pause()
		
	_spawn_telegraph_lane()

func attack_stomp() -> void:
	if current_state == State.ATTACK or health <= 0:
		return
	current_state = State.ATTACK
	current_attack_type = AttackType.MEGA_STOMP
	attack_counter += 1
	has_hit_in_current_attack = false
	is_telegraphing = true
	
	if player_ref and is_instance_valid(player_ref):
		var offset = player_ref.global_position - global_position
		if offset.x < -0.8:
			current_direction = Direction.LEFT
		elif offset.x > 0.8:
			current_direction = Direction.RIGHT
		else:
			current_direction = Direction.DOWN

	var dir_str = _get_dir_str()
	_play_anim("stomp_" + dir_str)
	if anim_sprite:
		anim_sprite.frame = 2
		anim_sprite.pause()
		
	_spawn_telegraph_circle()

func _spawn_telegraph_lane() -> void:
	_cleanup_telegraph()
	if not telegraph_scene:
		_on_telegraph_completed()
		return
	var telegraph = telegraph_scene.instantiate()
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(telegraph)
	telegraph.global_position = global_position
	active_telegraph = telegraph
	
	var travel_dir = Vector3(0, 0, 1)
	match current_direction:
		Direction.LEFT: travel_dir = Vector3(-1, 0, 0)
		Direction.RIGHT: travel_dir = Vector3(1, 0, 0)
		_: travel_dir = Vector3(0, 0, 1)
		
	telegraph.setup_rect(travel_dir, 2.4, 6.5, telegraph_duration)
	telegraph.telegraph_completed.connect(_on_telegraph_completed)

func _spawn_telegraph_circle() -> void:
	_cleanup_telegraph()
	if not telegraph_scene:
		_on_telegraph_completed()
		return
	var telegraph = telegraph_scene.instantiate()
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(telegraph)
	active_telegraph = telegraph
	telegraph.setup_circle(global_position, 5.0, telegraph_duration)
	telegraph.telegraph_completed.connect(_on_telegraph_completed)

func _on_telegraph_completed() -> void:
	is_telegraphing = false
	active_telegraph = null
	if current_state != State.ATTACK or health <= 0:
		return
	if anim_sprite:
		anim_sprite.play()

func _cleanup_telegraph() -> void:
	if active_telegraph and is_instance_valid(active_telegraph):
		active_telegraph.queue_free()
	active_telegraph = null
	is_telegraphing = false

func _on_anim_frame_changed() -> void:
	if current_state == State.ATTACK and anim_sprite:
		if current_attack_type == AttackType.GADHA_SLAM:
			# Frame 3 is the exact frame where the gadha hits the floor
			if anim_sprite.frame == 3:
				if not has_hit_in_current_attack:
					_check_strike_hit()
				_spawn_ground_spikes()
				var parent_node = get_parent()
				if parent_node and parent_node.has_method("smash_nearby_pillars"):
					parent_node.smash_nearby_pillars(global_position + Vector3(0, 0, 1.4), 3.2)
				# Frame 3 lands slam -> begin recovery punish window!
				_start_recovery()
		elif current_attack_type == AttackType.MEGA_STOMP:
			# Frame 4 is the exact frame where both gadhas slam the floor into a massive shockwave
			if anim_sprite.frame == 4:
				_trigger_quake_slam()
				# Frame 4 lands quake -> begin recovery punish window!
				_start_recovery()

func _start_recovery() -> void:
	current_state = State.RECOVERY
	recovery_timer = recovery_duration
	if anim_sprite:
		anim_sprite.pause()

func _trigger_quake_slam() -> void:
	# 1. Camera shake (heavy 0.4s, 24.0)
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	if cam and cam.get_parent() and cam.get_parent().has_method("shake"):
		cam.get_parent().shake(0.4, 24.0)
		
	var spawn_pos = global_position
	match current_direction:
		Direction.LEFT:
			spawn_pos += Vector3(-1.0, 0.0, 0.0)
		Direction.RIGHT:
			spawn_pos += Vector3(1.0, 0.0, 0.0)
		_:
			spawn_pos += Vector3(0.0, 0.0, 0.8)
			
	var parent_node = get_parent()
	
	# 2. Spawn Ground Cracks Decal & Debris
	if ground_cracks_scene:
		var cracks = ground_cracks_scene.instantiate()
		if parent_node:
			parent_node.add_child(cracks)
		cracks.setup(spawn_pos)

	# 3. Spawn Expanding Earthquake Area
	if quake_scene:
		var quake = quake_scene.instantiate()
		if parent_node:
			parent_node.add_child(quake)
		quake.setup(spawn_pos)

	# 4. Smash nearby pillars (Point A)
	if parent_node and parent_node.has_method("smash_nearby_pillars"):
		parent_node.smash_nearby_pillars(spawn_pos, 3.5)

func _spawn_ground_spikes() -> void:
	if not spikes_scene:
		return
	var spikes = spikes_scene.instantiate()
	var spawn_pos = global_position
	var travel_dir = Vector3(0, 0, 1)
	var anim_name = "spikes_down"
	
	match current_direction:
		Direction.LEFT:
			spawn_pos += Vector3(-1.4, 0.0, 0.0)
			travel_dir = Vector3(-1, 0, 0)
			anim_name = "spikes_left"
		Direction.RIGHT:
			spawn_pos += Vector3(1.4, 0.0, 0.0)
			travel_dir = Vector3(1, 0, 0)
			anim_name = "spikes_right"
		_:
			spawn_pos += Vector3(0.0, 0.0, 1.4)
			travel_dir = Vector3(0, 0, 1)
			anim_name = "spikes_down"
			
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(spikes)
	spikes.global_position = spawn_pos
	spikes.setup(travel_dir, anim_name)

func _check_strike_hit() -> void:
	if not player_ref or not is_instance_valid(player_ref) or has_hit_in_current_attack:
		return
	var offset = player_ref.global_position - global_position
	var dist = offset.length()
	
	var in_strike_arc = true
	if current_direction == Direction.DOWN and offset.z < -0.3:
		in_strike_arc = false
	elif current_direction == Direction.LEFT and offset.x > 0.3:
		in_strike_arc = false
	elif current_direction == Direction.RIGHT and offset.x < -0.3:
		in_strike_arc = false
		
	if in_strike_arc and dist <= (attack_range + 0.3):
		has_hit_in_current_attack = true
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(45, global_position)

func take_damage(amount: int = 40) -> void:
	_cleanup_telegraph()
	recovery_timer = 0.0
	stun_timer = 0.0
	health = max(0, health - amount)
	has_hit_in_current_attack = false
	attack_cooldown = attack_cooldown_duration + 0.5
	emit_signal("boss_damaged", health)
	
	# Flash red on hit
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.1)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	
	if health <= 0:
		_on_defeated()
	else:
		current_state = State.HURT
		_play_anim("hurt")

func take_rock_hit(amount: int = 175) -> void:
	_cleanup_telegraph()
	recovery_timer = 0.0
	health = max(0, health - amount)
	has_hit_in_current_attack = false
	attack_cooldown = attack_cooldown_duration + 1.0
	emit_signal("boss_damaged", health)
	
	# Flash golden-amber on rock impact
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(3.0, 1.2, 0.4, 1.0), 0.12)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)
		
	if health <= 0:
		_on_defeated()
	else:
		current_state = State.STUN
		stun_timer = stun_duration
		_play_anim("stunned")

func _on_defeated() -> void:
	_cleanup_telegraph()
	recovery_timer = 0.0
	stun_timer = 0.0
	emit_signal("boss_defeated")
	if aura_particles:
		aura_particles.emitting = false
	var solid = get_node_or_null("SolidObstacle/SolidCollision")
	if solid and solid is CollisionShape3D:
		solid.disabled = true
	var col = get_node_or_null("CollisionShape3D")
	if col and col is CollisionShape3D:
		col.disabled = true
	var hurt = get_node_or_null("Hurtbox/HurtCollision")
	if hurt and hurt is CollisionShape3D:
		hurt.disabled = true
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate:a", 0.0, 1.2)
		tw.tween_callback(func():
			visible = false
		)

func _play_anim(anim_name: String) -> void:
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
			anim_sprite.play(anim_name)

func _get_dir_str() -> String:
	match current_direction:
		Direction.DOWN: return "down"
		Direction.UP: return "up"
		Direction.LEFT: return "left"
		Direction.RIGHT: return "right"
	return "down"

func _on_animation_finished() -> void:
	_cleanup_telegraph()
	if current_state in [State.ROAR, State.STAGGER, State.HURT]:
		current_state = State.IDLE
		attack_cooldown = attack_cooldown_duration
		_play_anim("idle_down")
	elif current_state == State.STUN:
		if anim_sprite and anim_sprite.animation == "recover_stun":
			current_state = State.IDLE
			attack_cooldown = attack_cooldown_duration
			_play_anim("idle_down")
	elif current_state == State.ATTACK:
		_start_recovery()
