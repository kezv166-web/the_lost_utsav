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
@export var stomp_cooldown_duration: float = 7.0

var health: int = 1000
var current_state: State = State.IDLE
var current_attack_type: AttackType = AttackType.GADHA_SLAM
var current_direction: Direction = Direction.DOWN
var attack_cooldown: float = 1.0
var stomp_cooldown: float = 0.0
var attack_counter: int = 0
var recovery_timer: float = 0.0
var stun_timer: float = 0.0
var hurt_timer: float = 0.0
var hurt_grace_timer: float = 0.0
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
var current_phase: int = 1

# Spam-counter reactive stomp: if player lands 4 hits in a short window, Asur force-stomps
var spam_hit_count: int = 0
var spam_hit_window: float = 0.0
const SPAM_HIT_THRESHOLD: int = 4
const SPAM_HIT_WINDOW_SEC: float = 4.0

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
	_update_aggression_phase()

func _update_aggression_phase() -> void:
	var ratio = float(health) / float(max_health)
	var new_phase = 1
	if ratio <= 0.35:
		new_phase = 3
	elif ratio <= 0.70:
		new_phase = 2
	else:
		new_phase = 1
		
	if new_phase != current_phase:
		var old_phase = current_phase
		current_phase = new_phase
		print("[Asur Boss] Enrage Phase %d Activated! (HP: %d/%d)" % [current_phase, health, max_health])
		
		# Roar and visual screen shake on phase transition
		if new_phase > old_phase and current_state not in [State.STUN, State.HURT]:
			roar()
			_trigger_camera_shake(0.35, 18.0)
			
	# Dynamically tune attack aggression & speeds based on current phase
	match current_phase:
		1:
			attack_cooldown_duration = 2.8
			telegraph_duration = 0.95
			recovery_duration = 1.8
			stomp_cooldown_duration = 7.0
		2:
			# Phase 2 (35%..70% HP): 35% faster cooldowns, snappier telegraph
			attack_cooldown_duration = 1.8
			telegraph_duration = 0.75
			recovery_duration = 1.25
			stomp_cooldown_duration = 4.8
		3:
			# Phase 3 (<35% HP): Frenzy! Relentless strikes, ultra-fast recovery
			attack_cooldown_duration = 1.15
			telegraph_duration = 0.55
			recovery_duration = 0.85
			stomp_cooldown_duration = 3.2

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

	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and current_state == State.HURT:
			current_state = State.IDLE
			attack_cooldown = maxf(attack_cooldown, 0.6)
			_play_anim("idle_down")

	if hurt_grace_timer > 0.0:
		hurt_grace_timer -= delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if stomp_cooldown > 0.0:
		stomp_cooldown -= delta

	# Tick spam-hit window – reset counter if player paused their barrage
	if spam_hit_window > 0.0:
		spam_hit_window -= delta
		if spam_hit_window <= 0.0:
			spam_hit_count = 0
	
	if health <= 0 or not visible:
		return
		
	# Attack evaluation against player
	if current_state == State.IDLE and player_ref and is_instance_valid(player_ref):
		var offset = player_ref.global_position - global_position
		var dist = offset.length()
		
		# If player is in front/side within attack range and attack is off cooldown
		if dist <= stomp_range and offset.z > -0.8 and attack_cooldown <= 0.0:
			if dist > attack_range:
				# Far range: Stomp if ready; otherwise approach with Gadha Slam
				if stomp_cooldown <= 0.0:
					attack_stomp()
				else:
					attack()
			else:
				# Close to mid range: 75% Gadha Slam, 25% Mega Stomp only when stomp off cooldown
				if stomp_cooldown <= 0.0 and (attack_counter % 4 == 3):
					attack_stomp()
				else:
					attack()

func _process(delta: float) -> void:
	var pulse_speed = 3.0
	var base_energy = 1.8
	var energy_amp = 0.5
	var target_color = Color(1.0, 0.3, 0.3, 1.0)
	
	if current_phase == 2:
		pulse_speed = 5.5
		base_energy = 2.4
		energy_amp = 0.8
		target_color = Color(1.0, 0.45, 0.15, 1.0)
	elif current_phase == 3:
		pulse_speed = 8.5
		base_energy = 3.4
		energy_amp = 1.2
		target_color = Color(1.5, 0.1, 0.1, 1.0)

	pulse_time += delta * pulse_speed
	if aura_light:
		aura_light.light_energy = base_energy + sin(pulse_time) * energy_amp
		aura_light.light_color = aura_light.light_color.lerp(target_color, delta * 4.0)
	
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
	stomp_cooldown = stomp_cooldown_duration
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
	var spawn_pos = _get_stomp_epicenter()
	telegraph.setup_circle(spawn_pos, 5.0, telegraph_duration)
	telegraph.telegraph_completed.connect(_on_telegraph_completed)

func _get_stomp_epicenter() -> Vector3:
	var spawn_pos = global_position
	match current_direction:
		Direction.LEFT:
			spawn_pos += Vector3(-1.0, 0.0, 0.0)
		Direction.RIGHT:
			spawn_pos += Vector3(1.0, 0.0, 0.0)
		_:
			spawn_pos += Vector3(0.0, 0.0, 0.8)
	return spawn_pos

func _trigger_camera_shake(duration: float, intensity: float) -> void:
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	var node: Node = cam
	while node:
		if node.has_method("shake"):
			node.shake(duration, intensity)
			return
		node = node.get_parent()

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
					var slam_pos = global_position + Vector3(0, 0, 1.4)
					if current_direction == Direction.LEFT:
						slam_pos = global_position + Vector3(-2.0, 0, 0)
					elif current_direction == Direction.RIGHT:
						slam_pos = global_position + Vector3(2.0, 0, 0)
					parent_node.smash_nearby_pillars(slam_pos, 5.0)
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
	_trigger_camera_shake(0.4, 24.0)
		
	var spawn_pos = _get_stomp_epicenter()
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

	# 4. Smash nearby pillars (Point A - seismic shockwave expands to arena colonnade at 7.5m)
	if parent_node and parent_node.has_method("smash_nearby_pillars"):
		parent_node.smash_nearby_pillars(spawn_pos, 7.5)

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
	if health <= 0:
		return
	if hurt_grace_timer > 0.0:
		return
	_cleanup_telegraph()
	recovery_timer = 0.0
	stun_timer = 0.0
	health = max(0, health - amount)
	_update_aggression_phase()
	has_hit_in_current_attack = false
	attack_cooldown = attack_cooldown_duration + 0.5
	emit_signal("boss_damaged", health)

	# --- Spam-counter reactive stomp ---
	# Track consecutive melee hits within a rolling time window
	spam_hit_count += 1
	spam_hit_window = SPAM_HIT_WINDOW_SEC  # refresh/extend window on every hit
	if spam_hit_count >= SPAM_HIT_THRESHOLD and health > 0:
		# Player is spamming – Asur retaliates with a force stomp regardless of cooldown
		spam_hit_count = 0
		spam_hit_window = 0.0
		stomp_cooldown = 0.0           # bypass stomp cooldown
		attack_cooldown = 0.0          # bypass attack cooldown
		current_state = State.IDLE     # exit HURT so stomp can fire next physics frame
		hurt_timer = 0.0
		hurt_grace_timer = 0.0
		_play_anim("idle_down")
		attack_stomp()
		return
	
	# Flash red on hit
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.1)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	
	if health <= 0:
		_on_defeated()
	else:
		current_state = State.HURT
		hurt_timer = 0.55
		hurt_grace_timer = 0.35
		_play_anim("hurt")

func take_rock_hit(amount: int = 85) -> void:
	if health <= 0:
		return
	_cleanup_telegraph()
	recovery_timer = 0.0
	health = max(0, health - amount)
	_update_aggression_phase()
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
		hurt_grace_timer = 0.5
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
		hurt_timer = 0.0
		attack_cooldown = attack_cooldown_duration
		_play_anim("idle_down")
	elif current_state == State.STUN:
		if anim_sprite and anim_sprite.animation == "recover_stun":
			current_state = State.IDLE
			attack_cooldown = attack_cooldown_duration
			_play_anim("idle_down")
	elif current_state == State.ATTACK:
		_start_recovery()
