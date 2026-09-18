class_name BlackTunnel
extends Area3D

@export var tunnel_id: String = "BlackTunnel_A"
@export var destination_id: String = "BlackTunnel_B"
@export var emergence_offset: Vector3 = Vector3(0.0, 0.0, 0.4)

@onready var prompt_label: Label3D = $PromptLabel
@onready var hole_visual: Sprite3D = $HoleVisual
@onready var draft_light: OmniLight3D = $DraftLight

var player_inside: bool = false
var current_player: CharacterBody3D = null
var is_transitioning: bool = false

signal tunnel_entered(tunnel: BlackTunnel, player: CharacterBody3D)
signal tunnel_exited(tunnel: BlackTunnel, player: CharacterBody3D)

func _ready() -> void:
	add_to_group("mouse_tunnels")
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "Press E to Enter Tunnel"
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _is_player_body(body: Node) -> bool:
	return body != null and (body.is_in_group("player") or body.name == "Player" or (body is CharacterBody3D and body.has_method("transform_to_mouse")))

func _on_body_entered(body: Node3D) -> void:
	if _is_player_body(body):
		player_inside = true
		current_player = body as CharacterBody3D
		if prompt_label and not is_transitioning:
			prompt_label.text = "Press E to Enter Tunnel"
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if _is_player_body(body) and not is_transitioning:
		player_inside = false
		current_player = null
		if prompt_label:
			prompt_label.visible = false

func _physics_process(_delta: float) -> void:
	if not is_transitioning:
		var has_player = false
		for b in get_overlapping_bodies():
			if _is_player_body(b):
				has_player = true
				if not player_inside:
					_on_body_entered(b)
				break
		if not has_player and player_inside and not is_transitioning:
			player_inside = false
			current_player = null
			if prompt_label:
				prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_inside and not is_transitioning and Input.is_action_just_pressed("interact"):
		_try_enter_tunnel()

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and not is_transitioning and event.is_action_pressed("interact"):
		_try_enter_tunnel()

func try_enter(body: CharacterBody3D = null) -> void:
	if body:
		current_player = body
	_try_enter_tunnel()

func get_destination() -> BlackTunnel:
	var tunnels = get_tree().get_nodes_in_group("mouse_tunnels")
	for node in tunnels:
		if node is BlackTunnel and node != self and node.tunnel_id == destination_id:
			return node
	return null

func get_spawn_position() -> Vector3:
	var spawn_node = get_node_or_null("SpawnPoint")
	if spawn_node:
		return spawn_node.global_position
	return global_position

func _try_enter_tunnel() -> void:
	if is_transitioning:
		return
	if not current_player:
		for b in get_overlapping_bodies():
			if _is_player_body(b):
				current_player = b as CharacterBody3D
				break
	if not current_player:
		return
		
	var player = current_player
	var form = player.get("current_form")
	var is_mouse = (form == player.PlayerForm.MOUSE)
	
	if not is_mouse:
		# Human form rejected
		_show_message("Only Mushika can enter this passage.")
		return
		
	var dest = get_destination()
	if not dest:
		_show_message("The passage seems blocked on the other side...")
		return
		
	is_transitioning = true
	dest.is_transitioning = true
	if prompt_label:
		prompt_label.visible = false
		
	tunnel_entered.emit(self, player)
	
	# 1. Lock player movement
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	
	# 2. Play enter_passage animation
	var anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("enter_passage"):
		anim.play("enter_passage")
		
	# 3. Short step into black tunnel hole with fade
	var tw = create_tween()
	tw.tween_property(player, "global_position", global_position, 0.35)
	if anim:
		tw.parallel().tween_property(anim, "modulate:a", 0.0, 0.35)
		
	await tw.finished
	await get_tree().create_timer(0.15).timeout
	
	# 4. Teleport to destination black tunnel spawn position
	var dest_pos = dest.get_spawn_position()
	player.global_position = dest_pos
	
	# 5. Snap camera immediately so it follows cleanly without lag
	var scene = get_tree().current_scene
	var cam_rig = scene.get_node_or_null("CameraRig") if scene else null
	if cam_rig:
		var target_offset = cam_rig.get("target_offset")
		if target_offset is Vector3:
			cam_rig.global_position = dest_pos + target_offset
		else:
			cam_rig.global_position = dest_pos
			
	# 6. Emerge from destination black tunnel
	if anim:
		anim.modulate.a = 1.0
		if anim.sprite_frames and anim.sprite_frames.has_animation("idle_down"):
			anim.play("idle_down")
			
	var emerge_target = dest_pos + dest.emergence_offset
	var tw2 = create_tween()
	tw2.tween_property(player, "global_position", emerge_target, 0.25)
	await tw2.finished
	
	# 7. Restore normal movement and idle
	player.set_physics_process(true)
	if anim and anim.sprite_frames:
		anim.play("idle_down")
		
	player_inside = false
	current_player = null
	is_transitioning = false
	dest.is_transitioning = false
	dest.tunnel_exited.emit(dest, player)

func _show_message(msg: String) -> void:
	if prompt_label:
		prompt_label.text = msg
		prompt_label.visible = true
	var scene = get_tree().current_scene
	if scene and scene.has_method("_show_hud_message"):
		scene._show_hud_message(msg, 3.0)
