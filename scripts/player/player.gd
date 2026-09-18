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

@export var speed: float = 4.5
@export var acceleration: float = 24.0
@export var friction: float = 30.0
@export var gravity: float = 18.0
@export var jump_velocity: float = 6.8

var current_state: State = State.IDLE_WALK
var current_direction: Direction = Direction.UP
var last_horizontal_facing: Direction = Direction.RIGHT
var current_attack_type: String = ""
var is_walking: bool = false
var is_jumping: bool = false

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
	_add_key_binding("attack_axe", KEY_Q)
	_add_key_binding("attack_rope", KEY_E)
	_add_key_binding("interact", KEY_E)
	_add_key_binding("pause", KEY_ESCAPE)

func _on_animation_finished() -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE_WALK
		current_attack_type = ""
		_update_animation()

func _add_key_binding(action_name: String, primary_key: Key, secondary_key: Key = KEY_NONE) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	var existing_events = InputMap.action_get_events(action_name)
	if existing_events.is_empty():
		var ev1 = InputEventKey.new()
		ev1.physical_keycode = primary_key
		InputMap.action_add_event(action_name, ev1)
		
		if secondary_key != KEY_NONE:
			var ev2 = InputEventKey.new()
			ev2.physical_keycode = secondary_key
			InputMap.action_add_event(action_name, ev2)

func _physics_process(delta: float) -> void:
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

	# Combat attack triggers (allowed on ground when not already attacking)
	if is_on_floor() and current_state != State.ATTACKING:
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
		# Smoothly decelerate into the strike
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
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
	var facing_str: String = "right"
	if current_direction == Direction.LEFT:
		facing_str = "left"
	elif current_direction == Direction.RIGHT:
		facing_str = "right"
	else:
		# Up or Down facing: strike in the last horizontal direction
		facing_str = "left" if last_horizontal_facing == Direction.LEFT else "right"

	var anim_name = "attack_" + current_attack_type + "_" + facing_str
	anim_sprite.speed_scale = 1.0
	anim_sprite.play(anim_name)

func _update_animation() -> void:
	if not anim_sprite or current_state == State.ATTACKING:
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
	if not is_on_floor() or is_jumping:
		target_anim = "jump_" + dir_str
		anim_sprite.speed_scale = 1.0
	elif is_walking:
		target_anim = "walk_" + dir_str
		# Dynamic playback scale matching ground velocity to eliminate foot sliding
		var ground_speed = Vector2(velocity.x, velocity.z).length()
		anim_sprite.speed_scale = clampf(ground_speed / speed, 0.6, 1.25)
	else:
		target_anim = "idle_" + dir_str
		anim_sprite.speed_scale = 1.0
		
	if anim_sprite.animation != target_anim:
		var prev_anim = anim_sprite.animation
		var prev_frame = anim_sprite.frame
		anim_sprite.play(target_anim)
		# Preserve air-time frame when changing direction mid-air
		if ("jump" in str(prev_anim)) and ("jump" in target_anim):
			anim_sprite.frame = prev_frame
