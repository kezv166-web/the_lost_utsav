extends CharacterBody3D

signal boss_roared
signal boss_damaged(new_hp: int)
signal boss_defeated

enum State {
	IDLE,
	ROAR,
	ATTACK,
	STAGGER
}

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export var max_health: int = 3
var health: int = 3
var current_state: State = State.IDLE
var current_direction: Direction = Direction.DOWN

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var aura_light: OmniLight3D = $AuraLight
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var aura_particles: CPUParticles3D = $AuraParticles

var player_ref: Node3D = null
var pulse_time: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	add_to_group("boss")
	
	if anim_sprite:
		anim_sprite.animation_finished.connect(_on_animation_finished)
	
	# Configure visual settings
	if anim_sprite:
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.sorting_offset = 2.0
		anim_sprite.pixel_size = 0.0135
		anim_sprite.position = Vector3(0, 1.55, 0)
	
	_play_anim("idle_down")

func set_player(p: Node3D) -> void:
	player_ref = p

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if aura_light:
		aura_light.light_energy = 1.6 + sin(pulse_time) * 0.5
	
	# Face toward player if not attacking/roaring
	if current_state == State.IDLE and is_instance_valid(player_ref):
		var diff = player_ref.global_position - global_position
		if abs(diff.z) > abs(diff.x):
			current_direction = Direction.DOWN if diff.z > 0 else Direction.UP
		else:
			current_direction = Direction.RIGHT if diff.x > 0 else Direction.LEFT
		_update_idle_direction()

func _update_idle_direction() -> void:
	match current_direction:
		Direction.DOWN:
			_play_anim("idle_down")
		Direction.UP:
			_play_anim("idle_up")
		Direction.LEFT:
			_play_anim("idle_left")
		Direction.RIGHT:
			_play_anim("idle_right")

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
	if current_state == State.ATTACK:
		return
	current_state = State.ATTACK
	var dir_str = "down"
	if current_direction == Direction.LEFT:
		dir_str = "left"
	elif current_direction == Direction.RIGHT:
		dir_str = "right"
	_play_anim("attack_" + dir_str)

func take_damage(amount: int = 1) -> void:
	health = max(0, health - amount)
	emit_signal("boss_damaged", health)
	
	# Flash red on hit
	if anim_sprite:
		var tw = create_tween()
		tw.tween_property(anim_sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.1)
		tw.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	
	if health <= 0:
		_on_defeated()
	else:
		roar()

func _on_defeated() -> void:
	emit_signal("boss_defeated")
	if aura_particles:
		aura_particles.emitting = false
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
	if current_state in [State.ROAR, State.ATTACK, State.STAGGER]:
		current_state = State.IDLE
		_update_idle_direction()
