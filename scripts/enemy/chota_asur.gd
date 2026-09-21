extends CharacterBody3D

signal minion_died(minion: Node3D)

enum State {
	SPAWN,
	CHASE,
	ATTACK,
	RECOVERY,
	HURT,
	GRABBED,
	THROWN,
	DEAD
}

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export var max_health: int = 60
@export var move_speed: float = 2.8
@export var attack_damage: int = 14
@export var attack_reach: float = 1.7
@export var recovery_duration: float = 0.8

var health: int = 60
var current_state: State = State.SPAWN
var current_direction: Direction = Direction.DOWN

var player_ref: Node3D = null
var assigned_slot: int = 0
var has_attack_token: bool = false
var has_hit_in_current_attack: bool = false

var attack_cooldown: float = 0.6
var ai_tick_timer: float = 0.0
var recovery_timer: float = 0.0
var hurt_timer: float = 0.0
var desired_target_pos: Vector3 = Vector3.ZERO
var separation_force: Vector3 = Vector3.ZERO

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var health_bar: Sprite3D = $HealthBar
@onready var drop_shadow: Sprite3D = $DropShadow
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Preloaded health textures 0..11
var health_textures: Array[Texture2D] = []

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	add_to_group("chota_asur")
	
	_load_health_textures()
	_update_health_bar()
	
	if anim_sprite:
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.pixel_size = 0.0075
		anim_sprite.animation_finished.connect(_on_animation_finished)
		anim_sprite.frame_changed.connect(_on_anim_frame_changed)
	
	# Spawn scale-in pop
	scale = Vector3(0.1, 0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		current_state = State.CHASE
	)

func _load_health_textures() -> void:
	health_textures.clear()
	for i in range(12):
		var path = "res://assets/asur/frames/chota_asur/extracted/health/health_%d.png" % i
		if ResourceLoader.exists(path):
			health_textures.append(load(path))
		else:
			health_textures.append(null)

func _update_health_bar() -> void:
	if not health_bar or health_textures.is_empty():
		return
	var ratio = clampf(float(health) / float(max_health), 0.0, 1.0)
	var stage_idx = clamp(int(round((1.0 - ratio) * 11.0)), 0, 11)
	if stage_idx < health_textures.size() and health_textures[stage_idx]:
		health_bar.texture = health_textures[stage_idx]

func set_player(p: Node3D) -> void:
	player_ref = p

func _physics_process(delta: float) -> void:
	if current_state in [State.DEAD, State.THROWN]:
		return

	if current_state == State.GRABBED:
		if is_instance_valid(player_ref):
			var facing_dir = Vector3.BACK
			if "current_direction" in player_ref:
				match player_ref.current_direction:
					0: facing_dir = Vector3(0, 0, 1)   # DOWN
					1: facing_dir = Vector3(0, 0, -1)  # UP
					2: facing_dir = Vector3(-1, 0, 0)  # LEFT
					3: facing_dir = Vector3(1, 0, 0)   # RIGHT
			var tether_offset = facing_dir * 1.1 + Vector3(0, 0.15, 0)
			global_position = player_ref.global_position + tether_offset
		return
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	if recovery_timer > 0.0:
		recovery_timer -= delta
		if recovery_timer <= 0.0 and current_state == State.RECOVERY:
			current_state = State.CHASE
			_release_attack_token()
			
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and current_state == State.HURT:
			current_state = State.CHASE
			
	if not player_ref or not is_instance_valid(player_ref):
		var p = get_tree().get_first_node_in_group("player")
		if p:
			player_ref = p
		else:
			velocity = Vector3.ZERO
			move_and_slide()
			return

	# Throttled AI evaluation (10 Hz) for Web performance
	ai_tick_timer -= delta
	if ai_tick_timer <= 0.0:
		ai_tick_timer = 0.1 # 10 Hz
		_evaluate_tactical_ai()

	# Movement execution
	if current_state == State.CHASE:
		var move_dir = (desired_target_pos - global_position)
		move_dir.y = 0.0
		var dist = move_dir.length()
		
		if dist > 0.25:
			var norm_dir = move_dir.normalized()
			var combined_dir = (norm_dir * 0.8 + separation_force * 0.2).normalized()
			velocity.x = combined_dir.x * move_speed
			velocity.z = combined_dir.z * move_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			
		_update_facing(velocity if velocity.length_squared() > 0.01 else (player_ref.global_position - global_position))
		_play_anim("walk_" + _get_dir_str())
		
		# Check if in strike range and attempt attack
		var offset_to_player = player_ref.global_position - global_position
		offset_to_player.y = 0.0
		if offset_to_player.length() <= attack_reach and attack_cooldown <= 0.0:
			_attempt_attack()
	elif current_state == State.ATTACK:
		# Slight forward momentum during strike
		if anim_sprite and anim_sprite.frame < 5:
			var forward = (player_ref.global_position - global_position)
			forward.y = 0.0
			velocity = forward.normalized() * 0.8
		else:
			velocity = Vector3.ZERO
	elif current_state == State.HURT:
		# Smoothly decelerate horizontal knockback velocity
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
		_play_anim("hurt_" + _get_dir_str())
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Keep grounded on Y
	if not is_on_floor() and global_position.y > 0.1:
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()

func _evaluate_tactical_ai() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
		
	# Calculate tactical formation slot position around player (1.2m radius)
	var slot_offset = Vector3.ZERO
	match assigned_slot:
		0: slot_offset = Vector3(0.0, 0.0, -1.2) # North / Behind
		1: slot_offset = Vector3(0.0, 0.0, 1.2)  # South / Front
		2: slot_offset = Vector3(1.2, 0.0, 0.0)  # East / Flank
		3: slot_offset = Vector3(-1.2, 0.0, 0.0) # West / Flank
		_: slot_offset = Vector3(0.0, 0.0, 1.2)
		
	desired_target_pos = player_ref.global_position + slot_offset
	
	# Flocking separation force from other Chota Asurs
	separation_force = Vector3.ZERO
	var peers = get_tree().get_nodes_in_group("chota_asur")
	for peer in peers:
		if peer != self and is_instance_valid(peer):
			var diff = global_position - peer.global_position
			diff.y = 0.0
			var d = diff.length()
			if d > 0.001 and d < 1.1:
				separation_force += (diff / d) * (1.0 - (d / 1.1))
	if separation_force.length() > 0.001:
		separation_force = separation_force.normalized()

func _attempt_attack() -> void:
	if current_state != State.CHASE or attack_cooldown > 0.0:
		return
		
	# Request attack token from Level 3 controller
	var scene = get_tree().current_scene
	if scene and scene.has_method("request_attack_token"):
		if not scene.request_attack_token(self):
			return # Another minion is currently executing an attack; wait
			
	has_attack_token = true
	current_state = State.ATTACK
	has_hit_in_current_attack = false
	
	# Face player directly for attack
	var to_player = player_ref.global_position - global_position
	to_player.y = 0.0
	_update_facing(to_player)
	_play_anim("attack_" + _get_dir_str())

func _has_line_of_sight() -> bool:
	if not player_ref or not is_inside_tree():
		return false
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.4, 0),
		player_ref.global_position + Vector3(0, 0.4, 0),
		1 # Collision mask 1 = solid obstacles
	)
	var result = space_state.intersect_ray(query)
	return result.is_empty() # No solid pillar blocking line of sight

func _on_anim_frame_changed() -> void:
	if current_state == State.ATTACK and anim_sprite:
		# Frame 4 is the strike / impact frame
		if anim_sprite.frame == 4 and not has_hit_in_current_attack:
			_check_strike_damage()

func _check_strike_damage() -> void:
	if not player_ref or not is_instance_valid(player_ref) or has_hit_in_current_attack:
		return
	var offset = player_ref.global_position - global_position
	offset.y = 0.0
	if offset.length() <= (attack_reach + 0.4):
		has_hit_in_current_attack = true
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage, global_position)

func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.RECOVERY
		recovery_timer = recovery_duration
		attack_cooldown = randf_range(1.5, 2.5)
		_release_attack_token()
		_play_anim("idle_" + _get_dir_str())

func _release_attack_token() -> void:
	if has_attack_token:
		has_attack_token = false
		var scene = get_tree().current_scene
		if scene and scene.has_method("release_attack_token"):
			scene.release_attack_token(self)

func apply_knockback(impulse: Vector3) -> void:
	velocity.x = impulse.x
	velocity.z = impulse.z
	current_state = State.HURT
	hurt_timer = 0.4

func take_damage(amount: int = 40) -> void:
	if current_state == State.DEAD:
		return
	health = max(0, health - amount)
	_update_health_bar()
	
	# Hit flash
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(2.5, 0.5, 0.5, 1.0), 0.08)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
		
	# Small knockback if velocity not already set by apply_knockback
	if velocity.length_squared() < 0.1 and player_ref and is_instance_valid(player_ref):
		var kb_dir = (global_position - player_ref.global_position)
		kb_dir.y = 0.0
		if kb_dir.length() > 0.001:
			velocity = kb_dir.normalized() * 5.5
			
	if health <= 0:
		_die()
	else:
		if current_state != State.ATTACK:
			current_state = State.HURT
			hurt_timer = 0.35

func take_hit(amount: int = 40) -> void:
	take_damage(amount)

func take_rock_hit(amount: int = 85) -> void:
	take_damage(amount)

func grab_by_player(p: Node3D) -> void:
	player_ref = p
	current_state = State.GRABBED
	_release_attack_token()
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	var hurt_col = get_node_or_null("Hurtbox/HurtCollision")
	if hurt_col and hurt_col is CollisionShape3D:
		hurt_col.set_deferred("disabled", true)
		
	if health_bar:
		health_bar.visible = false
	if drop_shadow:
		drop_shadow.visible = true
		
	# Struggle / bound flash
	if anim_sprite:
		anim_sprite.play("hurt_down" if anim_sprite.sprite_frames.has_animation("hurt_down") else "idle_down")
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(2.5, 1.8, 0.4, 1.0), 0.1)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func throw_as_projectile(start_pos: Vector3, target_pos: Vector3, target_node: Node3D = null, damage: int = 38) -> void:
	current_state = State.THROWN
	global_position = start_pos
	
	# Smooth ballistic arc tween
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position:x", target_pos.x, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:z", target_pos.z, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Parabolic height arc
	var height_tw = create_tween()
	height_tw.tween_property(self, "global_position:y", start_pos.y + 1.2, 0.21).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	height_tw.tween_property(self, "global_position:y", target_pos.y, 0.21).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Tumbling mid-air rotation
	if anim_sprite:
		var rot_tw = create_tween()
		rot_tw.tween_property(anim_sprite, "rotation_degrees:z", 720.0, 0.42)
		
	height_tw.tween_callback(func():
		_on_thrown_impact(target_pos, target_node, damage)
	)

func _on_thrown_impact(impact_pos: Vector3, target_node: Node3D, damage: int) -> void:
	# Impact VFX & Camera Shake
	_spawn_impact_burst(impact_pos)
	
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	var node: Node = cam
	while node:
		if node.has_method("shake"):
			node.shake(0.3, 18.0)
			break
		node = node.get_parent()
		
	# Damage application
	var hit_applied = false
	if is_instance_valid(target_node):
		var d = global_position.distance_to(target_node.global_position)
		if d <= 3.2:
			hit_applied = true
			if target_node.is_in_group("boss"):
				var grm = get_node_or_null("/root/GameRunManager")
				if grm and grm.has_method("record_boss_hit"):
					grm.record_boss_hit()
					
			var push_dir = (target_node.global_position - impact_pos)
			push_dir.y = 0.0
			if push_dir.length_squared() < 0.001:
				push_dir = Vector3(0, 0, 1)
			push_dir = push_dir.normalized()
			
			if target_node.has_method("apply_knockback"):
				target_node.apply_knockback(push_dir * 8.5)
			elif "velocity" in target_node:
				target_node.velocity = push_dir * 8.5
				
			if target_node.has_method("take_rock_hit"):
				target_node.take_rock_hit(damage)
			elif target_node.has_method("take_damage"):
				target_node.take_damage(damage)
			elif target_node.has_method("take_hit"):
				target_node.take_hit(damage)
				
	# Splash damage to other enemies in 2.2m radius
	var tree = get_tree()
	if tree:
		var enemies: Array[Node] = []
		enemies.append_array(tree.get_nodes_in_group("enemy"))
		enemies.append_array(tree.get_nodes_in_group("boss"))
		for enemy in enemies:
			if enemy == self or not is_instance_valid(enemy) or not (enemy is Node3D):
				continue
			if enemy == target_node and hit_applied:
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= 2.2:
				var splash_dmg = int(damage * 0.6) # 22 splash damage
				var push_dir = (enemy.global_position - impact_pos)
				push_dir.y = 0.0
				if push_dir.length_squared() < 0.001:
					push_dir = Vector3(0, 0, 1)
				push_dir = push_dir.normalized()
				
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(push_dir * 7.5)
				elif "velocity" in enemy:
					enemy.velocity = push_dir * 7.5
					
				if enemy.has_method("take_rock_hit"):
					enemy.take_rock_hit(splash_dmg)
				elif enemy.has_method("take_damage"):
					enemy.take_damage(splash_dmg)
				elif enemy.has_method("take_hit"):
					enemy.take_hit(splash_dmg)
					
	# Minion self-destructs on impact
	_die()

func _spawn_impact_burst(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 32
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 0.65
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 70.0
	particles.initial_velocity_min = 3.5
	particles.initial_velocity_max = 7.0
	particles.color = Color(1.0, 0.7, 0.2, 1.0)
	var parent_sc = get_tree().current_scene if get_tree() else get_parent()
	if parent_sc:
		parent_sc.add_child(particles)
		particles.global_position = pos + Vector3(0, 0.3, 0)
		particles.emitting = true
		get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func _die() -> void:
	current_state = State.DEAD
	_release_attack_token()
	emit_signal("minion_died", self)
	
	if collision_shape:
		collision_shape.disabled = true
	var hurt_col = get_node_or_null("Hurtbox/HurtCollision")
	if hurt_col and hurt_col is CollisionShape3D:
		hurt_col.disabled = true
		
	if anim_sprite:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(anim_sprite, "modulate:a", 0.0, 0.45)
		tw.tween_property(self, "scale", Vector3(0.2, 0.2, 0.2), 0.45)
		if health_bar:
			tw.tween_property(health_bar, "modulate:a", 0.0, 0.3)
		if drop_shadow:
			tw.tween_property(drop_shadow, "modulate:a", 0.0, 0.3)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()

func _update_facing(dir: Vector3) -> void:
	if abs(dir.x) > abs(dir.z):
		if dir.x > 0.1:
			current_direction = Direction.RIGHT
		elif dir.x < -0.1:
			current_direction = Direction.LEFT
	else:
		if dir.z > 0.1:
			current_direction = Direction.DOWN
		elif dir.z < -0.1:
			current_direction = Direction.UP

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

func _exit_tree() -> void:
	_release_attack_token()
