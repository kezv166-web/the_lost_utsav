extends CharacterBody3D

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

enum PlayerForm {
	HUMAN,
	TRANSFORMING,
	MOUSE
}

@export var current_form: PlayerForm = PlayerForm.HUMAN
@export var human_speed: float = 2.8
@export var mouse_speed: float = 2.6
@export var speed: float = 2.8
@export var acceleration: float = 24.0
@export var friction: float = 30.0
@export var gravity: float = 18.0

var current_direction: Direction = Direction.DOWN
var last_horizontal_dir: Direction = Direction.RIGHT
var is_walking: bool = false

var human_frames: SpriteFrames
var mushika_frames: SpriteFrames = preload("res://scenes/player/mushika_sprite_frames.tres")

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	add_to_group("player")
	if anim_sprite:
		human_frames = anim_sprite.sprite_frames
	_setup_inputs()
	_update_animation()

func _setup_inputs() -> void:
	_add_key_binding("move_left", KEY_A, KEY_LEFT)
	_add_key_binding("move_right", KEY_D, KEY_RIGHT)
	_add_key_binding("move_up", KEY_W, KEY_UP)
	_add_key_binding("move_down", KEY_S, KEY_DOWN)
	_add_key_binding("interact", KEY_E)
	_add_key_binding("pause", KEY_ESCAPE)
	_add_key_binding("transform_1", KEY_1, KEY_KP_1)

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
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Frozen while transforming
	if current_form == PlayerForm.TRANSFORMING:
		is_walking = false
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		return

	# Speed based on current form
	var active_speed = mouse_speed if current_form == PlayerForm.MOUSE else human_speed

	# 2.5D X/Z plane movement with normalized direction
	var input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir = Vector3(input_vec.x, 0.0, input_vec.y)
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()
	elif move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized() * clampf(input_vec.length(), 0.0, 1.0)

	if move_dir.length_squared() > 0.001:
		is_walking = true
		velocity.x = move_toward(velocity.x, move_dir.x * active_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * active_speed, acceleration * delta)
		
		# Track horizontal orientation
		if input_vec.x < -0.05:
			last_horizontal_dir = Direction.LEFT
		elif input_vec.x > 0.05:
			last_horizontal_dir = Direction.RIGHT
		
		# Determine dominant direction
		if abs(input_vec.y) >= abs(input_vec.x):
			if input_vec.y > 0.05:
				current_direction = Direction.DOWN
			elif input_vec.y < -0.05:
				current_direction = Direction.UP
		else:
			if input_vec.x > 0.05:
				current_direction = Direction.RIGHT
			elif input_vec.x < -0.05:
				current_direction = Direction.LEFT
	else:
		is_walking = false
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	_update_animation()
	move_and_slide()

func _update_animation() -> void:
	if not anim_sprite:
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
	if is_walking:
		target_anim = "walk_" + dir_str
		if current_form == PlayerForm.MOUSE:
			# Mushika's divine mouse form moves and animates at full crisp cadence
			anim_sprite.speed_scale = 1.0
		else:
			# Dynamic playback scale matching ground velocity to eliminate foot sliding for human
			var ground_speed = Vector2(velocity.x, velocity.z).length()
			anim_sprite.speed_scale = clampf(ground_speed / human_speed, 0.6, 1.25)
	else:
		target_anim = "idle_" + dir_str
		anim_sprite.speed_scale = 1.0
		
	if anim_sprite.animation != target_anim:
		anim_sprite.play(target_anim)
	elif not anim_sprite.is_playing():
		anim_sprite.play()

func start_transformation() -> void:
	current_form = PlayerForm.TRANSFORMING
	velocity = Vector3.ZERO
	is_walking = false
	if anim_sprite:
		anim_sprite.play("idle_up")

func transform_to_mouse() -> void:
	current_form = PlayerForm.MOUSE
	if anim_sprite and mushika_frames:
		anim_sprite.sprite_frames = mushika_frames
		anim_sprite.scale = Vector3(0.65, 0.65, 0.65)
		anim_sprite.position = Vector3(0, 0.12, 0)
	
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.18
		col.shape.height = 0.40
		col.position = Vector3(0, 0.20, 0)
		
	_update_animation()

func transform_to_human() -> void:
	current_form = PlayerForm.HUMAN
	if anim_sprite and human_frames:
		anim_sprite.sprite_frames = human_frames
		anim_sprite.scale = Vector3(0.68, 0.68, 0.68)
		anim_sprite.position = Vector3(0, 0.1, 0)
		
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.24
		col.shape.height = 1.4
		col.position = Vector3(0, 0.7, 0)
		
	_update_animation()
