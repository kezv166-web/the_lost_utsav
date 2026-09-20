class_name ModakPickup
extends Area3D

## ModakPickup – 2.5D Rotating Sacred Modak Collectible
## Grants +50 speedrun bonus points when collected by Mushika in the underground maze.
## Features both Area3D collision signal and robust proximity fallback detection.

@export var point_value: int = 50

@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var glow_light: OmniLight3D = $GlowLight
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _base_y: float = 0.0
var _anim_time: float = 0.0
var _is_collected: bool = false

func _ready() -> void:
	_base_y = position.y
	# Randomize time offset so multiple modaks don't bob in identical sync
	_anim_time = randf_range(0.0, PI * 2.0)

	body_entered.connect(_on_body_entered)

	if anim_sprite:
		anim_sprite.play("rotate")

func _process(delta: float) -> void:
	if _is_collected or not is_inside_tree():
		return

	_anim_time += delta
	# Smooth floating bob animation
	position.y = _base_y + sin(_anim_time * 3.2) * 0.10

	# Gentle breathing light pulse
	if glow_light:
		glow_light.light_energy = 1.2 + sin(_anim_time * 4.5) * 0.4

	# Robust proximity fallback: auto-collect if player is within 1.3m
	var tree = get_tree()
	if tree:
		var player = tree.get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var p_pos = player.global_position
			var dist_xz = Vector2(global_position.x - p_pos.x, global_position.z - p_pos.z).length()
			if dist_xz < 1.3:
				_collect()

func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return

	var is_player = body.is_in_group("player") or ("current_form" in body) or (body.name == "Player")
	if is_player:
		_collect()

func _collect() -> void:
	if _is_collected or not is_inside_tree():
		return
	_is_collected = true

	# Notify run manager
	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_method("collect_modak"):
		grm.collect_modak()

	# Play chime sound
	_play_pickup_chime()

	# Spawn floating "+50" indicator
	_spawn_floating_popup()

	# Disappear with quick sparkle scale animation
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.4, 1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _play_pickup_chime() -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_sibling(player)

	# Synthesize a sweet celestial chime
	var synth = UISoundSynth.get_instance(self)
	if synth:
		synth.play_tab()

	# Auto free audio player
	var tree = get_tree()
	if tree:
		tree.create_timer(1.0).timeout.connect(player.queue_free)

func _spawn_floating_popup() -> void:
	var lbl = Label3D.new()
	lbl.text = "+%d PTS" % point_value
	lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	lbl.modulate = Color(1.0, 0.9, 0.3, 1.0)
	lbl.outline_modulate = Color(0.2, 0.1, 0.0, 1.0)
	lbl.font_size = 30
	lbl.outline_size = 6
	lbl.global_position = global_position + Vector3(0, 0.5, 0)
	add_sibling(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y + 0.85, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)
