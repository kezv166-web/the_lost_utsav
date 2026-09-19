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

var human_frames: SpriteFrames = preload("res://scenes/player/player_sprite_frames.tres")
var mouse_frames: SpriteFrames = preload("res://scenes/player/mushika_sprite_frames.tres")

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	_setup_inputs()
	if anim_sprite:
		anim_sprite.animation_finished.connect(_on_animation_finished)
	_update_animation()

func _setup_inputs() -> void:
	_add_key_binding("move_left", KEY_A, KEY_LEFT)
	_add_key_binding("move_right", KEY_D, KEY_RIGHT)
	_add_key_binding("move_up", KEY_W, KEY_UP)
	_add_key_binding("move_down", KEY_S, KEY_DOWN)
	_add_key_binding("jump", KEY_SPACE)
	# Attacks on K (axe) and L (rope) only
	_add_key_binding("attack_axe", KEY_K)
	_add_key_binding("attack_rope", KEY_L)
	_add_key_binding("interact", KEY_E)
	_add_key_binding("transform_1", KEY_1)
	_add_key_binding("pause", KEY_ESCAPE)

func _on_animation_finished() -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE_WALK if is_on_floor() else State.JUMPING
		current_attack_type = ""
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform_1") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode == KEY_1 or event.keycode == KEY_1)):
		# If level controller is handling transformation (like in Level 1 with full cutscene), let it handle it
		var current_sc = get_tree().current_scene if get_tree() else null
		if current_sc and current_sc.has_method("_on_transform_key_pressed"):
			return
		# Otherwise direct toggle
		if current_form == PlayerForm.HUMAN:
			transform_to_mouse()
		elif current_form == PlayerForm.MOUSE:
			transform_to_human()

func _physics_process(delta: float) -> void:
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

	# Combat attack triggers (allowed on ground or airborne when in human form and not already attacking)
	if current_state != State.ATTACKING and current_form == PlayerForm.HUMAN:
		if Input.is_action_just_pressed("attack_axe"):
			current_state = State.ATTACKING
			current_attack_type = "axe"
			is_walking = false
			_play_attack_animation()
		elif Input.is_action_just_pressed("attack_rope"):
			current_state = State.ATTACKING
			current_attack_type = "rope"
			is_walking = false
			_play_attack_animation()

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

func _play_attack_animation() -> void:
	if not anim_sprite:
		return
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
	if is_carrying and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("carry_rock"):
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
		anim_sprite.play("transform")

func transform_to_mouse() -> void:
	current_form = PlayerForm.MOUSE
	current_state = State.IDLE_WALK
	speed = 5.2
	jump_velocity = 4.2
	if anim_sprite and mouse_frames:
		anim_sprite.sprite_frames = mouse_frames
		anim_sprite.position = Vector3(0, 0.22, 0)
		anim_sprite.pixel_size = 0.011
		anim_sprite.play("idle_down")
	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.18
		col.shape.height = 0.45
		col.position = Vector3(0, 0.25, 0)
	var shadow = get_node_or_null("DropShadow")
	if shadow:
		shadow.scale = Vector3(0.4, 0.4, 0.4)
	print("Player transformed to MOUSE (Mushika).")

func transform_to_human() -> void:
	current_form = PlayerForm.HUMAN
	current_state = State.IDLE_WALK
	speed = 4.5
	jump_velocity = 6.8
	if anim_sprite and human_frames:
		anim_sprite.sprite_frames = human_frames
		anim_sprite.position = Vector3(0, 0.72, 0)
		anim_sprite.pixel_size = 0.0125
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
