extends Area3D

@export var speed: float = 7.0
@export var max_distance: float = 6.5
@export var damage: int = 35

var travel_direction: Vector3 = Vector3(0, 0, 1)
var distance_traveled: float = 0.0
var has_damaged_player: bool = false

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var particles: CPUParticles3D = get_node_or_null("SpikeDust")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if anim_sprite:
		anim_sprite.animation_finished.connect(_on_animation_finished)

func setup(dir: Vector3, anim_name: String) -> void:
	travel_direction = dir.normalized()
	travel_direction.y = 0.0
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)

func _physics_process(delta: float) -> void:
	var step = travel_direction * speed * delta
	global_position += step
	distance_traveled += step.length()
	
	if distance_traveled >= max_distance:
		# Let remaining spike frames play, then destroy
		speed = 0.0
		if anim_sprite and not anim_sprite.is_playing():
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_damaged_player:
		has_damaged_player = true
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
	elif body.is_in_group("cover") or body.name.begins_with("Col") or body.name.begins_with("Cover") or body.name.begins_with("Wall"):
		# Hit pillar or cover wall in the arena -> shockwave is blocked by cover!
		speed = 0.0
		if particles:
			particles.emitting = true
		if body.name.begins_with("Col"):
			var scene = get_tree().current_scene
			if scene and scene.has_method("smash_pillar_direct"):
				scene.smash_pillar_direct(body)
		var tw = create_tween()
		if anim_sprite:
			tw.tween_property(anim_sprite, "modulate:a", 0.0, 0.25)
		tw.tween_callback(queue_free)

func _on_animation_finished() -> void:
	# Once the crumbling frame finishes, remove the spike wave
	queue_free()
