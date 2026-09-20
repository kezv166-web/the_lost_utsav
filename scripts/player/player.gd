extends CharacterBody3D

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

enum State {
	IDLE_WALK,
	JUMPING,
	ATTACKING
}

enum PlayerForm {
	HUMAN,
	MOUSE,
	TRANSFORMING
}

@export var speed: float = 4.5
@export var acceleration: float = 24.0
@export var friction: float = 30.0
@export var gravity: float = 18.0
@export var jump_velocity: float = 6.8

var current_state: State = State.IDLE_WALK
var current_form: PlayerForm = PlayerForm.HUMAN
var current_direction: Direction = Direction.UP
var last_horizontal_facing: Direction = Direction.RIGHT
var current_attack_type: String = ""
var is_walking: bool = false
var is_jumping: bool = false
var is_carrying: bool = false
var has_hit_in_current_attack: bool = false
var attack_cooldown_timer: float = 0.0
var attack_duration_timer: float = 0.0

var human_frames: SpriteFrames = preload("res://scenes/player/player_sprite_frames.tres")
var mouse_frames: SpriteFrames = preload("res://scenes/player/mushika_sprite_frames.tres")

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

signal player_damaged(current_hp: int)
signal player_died

@export var max_health: int = 250
var health: int = 250
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

func _ready() -> void:
	_setup_inputs()
	if anim_sprite:
		anim_sprite.animation_finished.connect(_on_animation_finished)
		anim_sprite.frame_changed.connect(_on_anim_frame_changed)
	_update_animation()

func _setup_inputs() -> void:
	_add_key_binding("move_left", KEY_A, KEY_LEFT)
	_add_key_binding("move_right", KEY_D, KEY_RIGHT)
	_add_key_binding("move_up", KEY_W, KEY_UP)
	_add_key_binding("move_down", KEY_S, KEY_DOWN)
	_add_key_binding("jump", KEY_SPACE)
	# Attacks on F (axe) and G (rope) + K/L fallbacks + Mouse Left/Right Click
	_add_key_binding("attack_axe", KEY_F, KEY_K)
	_add_key_binding("attack_rope", KEY_G, KEY_L)
	_add_mouse_binding("attack_axe", MOUSE_BUTTON_LEFT)
	_add_mouse_binding("attack_rope", MOUSE_BUTTON_RIGHT)
	_add_key_binding("interact", KEY_E, KEY_C)
	_add_key_binding("transform_1", KEY_1)
	_add_key_binding("pause", KEY_ESCAPE)

func _on_animation_finished() -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE_WALK if is_on_floor() else State.JUMPING
		current_attack_type = ""
		attack_duration_timer = 0.0
		attack_cooldown_timer = 0.38
		_update_animation()

func _add_key_binding(action_name: String, primary_key: Key, secondary_key: Key = KEY_NONE) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	var events = InputMap.action_get_events(action_name)
	var has_primary = false
	var has_secondary = (secondary_key == KEY_NONE)
	for ev in events:
		if ev is InputEventKey:
			if ev.physical_keycode == primary_key or ev.keycode == primary_key:
				has_primary = true
			if secondary_key != KEY_NONE and (ev.physical_keycode == secondary_key or ev.keycode == secondary_key):
				has_secondary = true
				
	if not has_primary:
		var ev1 = InputEventKey.new()
		ev1.physical_keycode = primary_key
		InputMap.action_add_event(action_name, ev1)
	if not has_secondary:
		var ev2 = InputEventKey.new()
		ev2.physical_keycode = secondary_key
		InputMap.action_add_event(action_name, ev2)

func _add_mouse_binding(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var events = InputMap.action_get_events(action_name)
	for ev in events:
		if ev is InputEventMouseButton and ev.button_index == button_index:
			return
	var ev = InputEventMouseButton.new()
	ev.button_index = button_index
	InputMap.action_add_event(action_name, ev)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform_1") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode == KEY_1 or event.keycode == KEY_1)):
		var current_sc = get_tree().current_scene if get_tree() else null
		# If Level 1 controller handles transformation (full cutscene), defer to it
		if current_sc and current_sc.has_method("_on_transform_key_pressed"):
			return
		# Transformation is ONLY allowed in Level 1 scenes (upper/lower l1_map)
		# Block it in outdoor_map, l3_map, maze, and all other levels
		var scene_path: String = current_sc.scene_file_path if current_sc else ""
		if "/l1/" not in scene_path:
			# Not in Level 1 — transformation is locked
			return
		# Fallback direct toggle (if somehow in an l1 scene without the controller)
		if current_form == PlayerForm.HUMAN:
			transform_to_mouse()
		elif current_form == PlayerForm.MOUSE:
			transform_to_human()

func _physics_process(delta: float) -> void:
	# Invulnerability timer & visual sprite flicker
	if is_invulnerable:
		invulnerable_timer -= delta
		if anim_sprite:
			anim_sprite.modulate.a = 0.35 if int(invulnerable_timer * 12.0) % 2 == 0 else 1.0
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
			if anim_sprite:
				anim_sprite.modulate.a = 1.0

	if current_form == PlayerForm.TRANSFORMING:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Jump & Gravity
	if is_on_floor():
		if current_state != State.ATTACKING and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			is_jumping = true
			current_state = State.JUMPING
		else:
			is_jumping = false
			velocity.y = 0.0
			if current_state == State.JUMPING:
				current_state = State.IDLE_WALK
	else:
		velocity.y -= gravity * delta

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if attack_duration_timer > 0.0:
		attack_duration_timer -= delta
		if attack_duration_timer <= 0.0 and current_state == State.ATTACKING:
			current_state = State.IDLE_WALK if is_on_floor() else State.JUMPING
			current_attack_type = ""
			attack_cooldown_timer = 0.38
			_update_animation()

	# Combat attack triggers (allowed on ground or airborne when in human form and not already attacking)
	if current_state != State.ATTACKING and attack_cooldown_timer <= 0.0 and current_form == PlayerForm.HUMAN:
		if Input.is_action_just_pressed("attack_axe"):
			attack("axe")
		elif Input.is_action_just_pressed("attack_rope"):
			attack("rope")

	if current_state == State.ATTACKING:
		if is_on_floor():
			# Smoothly decelerate into the strike on ground
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		else:
			# Mid-air attack: preserve momentum with slight air resistance
			velocity.x = move_toward(velocity.x, 0.0, friction * 0.25 * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * 0.25 * delta)
	else:
		# 2.5D X/Z plane movement
		var input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var move_dir = Vector3(input_vec.x, 0.0, input_vec.y).normalized()

		if move_dir.length_squared() > 0.001:
			is_walking = true
			velocity.x = move_toward(velocity.x, move_dir.x * speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * speed, acceleration * delta)
			
			# Determine dominant direction and update last horizontal facing
			if abs(input_vec.y) > abs(input_vec.x):
				if input_vec.y > 0.05:
					current_direction = Direction.DOWN
				elif input_vec.y < -0.05:
					current_direction = Direction.UP
			else:
				if input_vec.x > 0.05:
					current_direction = Direction.RIGHT
					last_horizontal_facing = Direction.RIGHT
				elif input_vec.x < -0.05:
					current_direction = Direction.LEFT
					last_horizontal_facing = Direction.LEFT
		else:
			is_walking = false
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)

		_update_animation()

	move_and_slide()

func attack(type: String = "axe") -> bool:
	if current_state == State.ATTACKING or attack_cooldown_timer > 0.0 or current_form != PlayerForm.HUMAN:
		return false
	current_state = State.ATTACKING
	current_attack_type = type
	is_walking = false
	_play_attack_animation()
	return true

func _play_attack_animation() -> void:
	if not anim_sprite:
		return
	has_hit_in_current_attack = false
	var dir_str: String
	match current_direction:
		Direction.LEFT:
			dir_str = "left"
		Direction.RIGHT:
			dir_str = "right"
		Direction.UP, Direction.DOWN:
			dir_str = "left" if last_horizontal_facing == Direction.LEFT else "right"

	var anim_name = "attack_" + current_attack_type + "_" + dir_str
	if anim_sprite.sprite_frames and not anim_sprite.sprite_frames.has_animation(anim_name):
		var fallback_dir = "left" if (current_direction == Direction.LEFT or last_horizontal_facing == Direction.LEFT) else "right"
		anim_name = "attack_" + current_attack_type + "_" + fallback_dir

	anim_sprite.speed_scale = 1.0
	anim_sprite.play(anim_name)
	attack_duration_timer = 0.42
	_execute_attack_hit()

func _on_anim_frame_changed() -> void:
	if current_state == State.ATTACKING and not has_hit_in_current_attack:
		if anim_sprite and anim_sprite.frame in [1, 2, 3]:
			_execute_attack_hit()

func _execute_attack_hit() -> void:
	if has_hit_in_current_attack:
		return
		
	var reach: float = 3.2 if current_attack_type == "axe" else 4.6
	var damage_amount: int = 40 if current_attack_type == "axe" else 28
	
	# Compute horizontal facing vector
	var face_vec = Vector3.ZERO
	match current_direction:
		Direction.UP:
			face_vec = Vector3(0, 0, -1)
		Direction.DOWN:
			face_vec = Vector3(0, 0, 1)
		Direction.LEFT:
			face_vec = Vector3(-1, 0, 0)
		Direction.RIGHT:
			face_vec = Vector3(1, 0, 0)
			
	if current_direction in [Direction.UP, Direction.DOWN]:
		var h_bias = -0.35 if last_horizontal_facing == Direction.LEFT else 0.35
		face_vec.x += h_bias
		face_vec = face_vec.normalized()
		
	var tree = get_tree()
	if not tree:
		return
		
	var targets: Array[Node] = []
	targets.append_array(tree.get_nodes_in_group("enemy"))
	targets.append_array(tree.get_nodes_in_group("boss"))
	
	for enemy in targets:
		if not is_instance_valid(enemy) or not (enemy is Node3D) or enemy == self:
			continue
		if "visible" in enemy and not enemy.visible:
			continue
			
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist = to_enemy.length()
		
		var hit_connected = false
		if dist <= 1.35:
			hit_connected = true
		elif dist <= reach:
			var dot = face_vec.dot(to_enemy.normalized())
			if dot >= 0.15:
				hit_connected = true
				
		if hit_connected:
			has_hit_in_current_attack = true
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_amount)
			elif enemy.has_method("take_hit"):
				enemy.take_hit(damage_amount)
				
			# Impact visual / camera shake
			_trigger_camera_shake(0.25, 16.0)
				
			# Hitstop micro-pause (2 frames / 0.04s real time)
			Engine.time_scale = 0.05
			tree.create_timer(0.04, true, false, true).timeout.connect(func():
				Engine.time_scale = 1.0
			)
				
			# Sprite flash on player strike
			if anim_sprite:
				var tw = create_tween()
				tw.tween_property(anim_sprite, "modulate", Color(2.0, 1.8, 1.2, 1.0), 0.06)
				tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
			break

func _trigger_camera_shake(duration: float, intensity: float) -> void:
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	var node: Node = cam
	while node:
		if node.has_method("shake"):
			node.shake(duration, intensity)
			return
		node = node.get_parent()

func _update_animation() -> void:
	if not anim_sprite or current_state == State.ATTACKING or current_form == PlayerForm.TRANSFORMING:
		return
		
	var dir_str: String
	match current_direction:
		Direction.DOWN:
			dir_str = "down"
		Direction.UP:
			dir_str = "up"
		Direction.LEFT:
			dir_str = "left"
		Direction.RIGHT:
			dir_str = "right"
			
	var target_anim: String
	if is_carrying:
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("carry_" + dir_str):
			target_anim = "carry_" + dir_str
		elif anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("carry_rock"):
			target_anim = "carry_rock"
		anim_sprite.speed_scale = 1.0
	elif not is_on_floor() or is_jumping:
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("jump_" + dir_str):
			target_anim = "jump_" + dir_str
		else:
			target_anim = "walk_" + dir_str
		anim_sprite.speed_scale = 1.0
	elif is_walking:
		target_anim = "walk_" + dir_str
		var ground_speed = Vector2(velocity.x, velocity.z).length()
		anim_sprite.speed_scale = clampf(ground_speed / speed, 0.6, 1.25)
	else:
		target_anim = "idle_" + dir_str
		anim_sprite.speed_scale = 1.0
		
	if anim_sprite.animation != target_anim:
		var prev_anim = anim_sprite.animation
		var prev_frame = anim_sprite.frame
		anim_sprite.play(target_anim)
		if ("jump" in str(prev_anim)) and ("jump" in target_anim):
			anim_sprite.frame = prev_frame

func start_transformation() -> void:
	current_form = PlayerForm.TRANSFORMING
	velocity = Vector3.ZERO
	is_walking = false
	if anim_sprite and mouse_frames and mouse_frames.has_animation("transform"):
		anim_sprite.sprite_frames = mouse_frames
		anim_sprite.position = Vector3(0, 1.29, 0)
		anim_sprite.pixel_size = 0.007
		anim_sprite.sorting_offset = 2.0
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.no_depth_test = false
		anim_sprite.play("transform")

func transform_to_mouse() -> void:
	current_form = PlayerForm.MOUSE
	current_state = State.IDLE_WALK
	speed = 5.2
	jump_velocity = 4.2
	if anim_sprite and mouse_frames:
		anim_sprite.sprite_frames = mouse_frames
		anim_sprite.pixel_size = 0.010
		anim_sprite.position = Vector3(0, 0.76, 0)
		anim_sprite.sorting_offset = 0.0
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		anim_sprite.rotation_degrees = Vector3.ZERO
		anim_sprite.render_priority = 0
		anim_sprite.double_sided = true
		anim_sprite.no_depth_test = false
		anim_sprite.play("idle_down")
	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.38
		col.shape.height = 0.60
		col.position = Vector3(0, 0.30, 0)
	var shadow = get_node_or_null("DropShadow")
	if shadow:
		shadow.scale = Vector3(0.5, 0.5, 0.5)
		shadow.position = Vector3(0, 0.03, 0)
		shadow.visible = true
	print("Player transformed to MOUSE (Mushika) with upright 2.5D billboard.")

func transform_to_human() -> void:
	current_form = PlayerForm.HUMAN
	current_state = State.IDLE_WALK
	speed = 4.5
	jump_velocity = 6.8
	if anim_sprite and human_frames:
		anim_sprite.sprite_frames = human_frames
		anim_sprite.position = Vector3(0, 0.72, 0)
		anim_sprite.pixel_size = 0.0125
		anim_sprite.sorting_offset = 0.0
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.no_depth_test = false
		anim_sprite.play("idle_down")
	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.35
		col.shape.height = 1.4
		col.position = Vector3(0, 0.7, 0)
	var shadow = get_node_or_null("DropShadow")
	if shadow:
		shadow.scale = Vector3(1.0, 1.0, 1.0)
	print("Player transformed to HUMAN.")

func take_damage(amount: int = 1, knockback_source: Vector3 = Vector3.ZERO) -> void:
	if is_invulnerable or health <= 0:
		return
	health = max(0, health - amount)
	is_invulnerable = true
	invulnerable_timer = 1.0
	
	if knockback_source != Vector3.ZERO:
		var knock_dir = global_position - knockback_source
		knock_dir.y = 0.0
		if knock_dir.length_squared() < 0.001:
			knock_dir = Vector3(0, 0, 1) # Default push South
		else:
			knock_dir = knock_dir.normalized()
		velocity.x = knock_dir.x * 6.5
		velocity.z = knock_dir.z * 6.5
		if is_on_floor():
			velocity.y = 2.5
	
	emit_signal("player_damaged", health)
	if health <= 0:
		emit_signal("player_died")

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func reset_health() -> void:
	Engine.time_scale = 1.0
	health = max_health
	is_invulnerable = false
	invulnerable_timer = 0.0
	if anim_sprite:
		anim_sprite.modulate.a = 1.0
	emit_signal("player_damaged", health)
