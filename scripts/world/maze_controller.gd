extends Node3D

@onready var player = $Player
@onready var key_area = $Interactables/GoldenKey
@onready var exit_area = $Interactables/MazeExit
@onready var chest_area = $Interactables/Chest
@onready var exit_prompt = $Interactables/MazeExit/Prompt
@onready var exit_gate_visual = $Interactables/MazeExit/GateVisual
@onready var key_visual = $Interactables/GoldenKey/KeyVisual

@onready var hud_form = $MazeHUD/Margin/VBox/TopBar/FormBadge
@onready var hud_objective = $MazeHUD/Margin/VBox/TopBar/ObjectiveLabel
@onready var hud_keys = $MazeHUD/Margin/VBox/TopBar/KeyTracker
@onready var hud_message = $MazeHUD/Margin/MessageBanner

var has_key: bool = false
var exit_unlocked: bool = false
var player_near_exit: bool = false
var player_near_chest: bool = false
var flicker_timer: float = 0.0
var key_bob_tween: Tween = null

var torch_lights: Array[OmniLight3D] = []

func _ready() -> void:
	_setup_player_as_mouse()
	_setup_camera()
	_setup_torches()
	_setup_interactables()
	_setup_fade_in()
	_update_hud()
	_show_hud_message("Level 1: Underground Maze\nNavigate the fortress foundation. Find the Golden Key to unlock the Exit Gate.", 5.0)

func _setup_fade_in() -> void:
	var hud = get_node_or_null("MazeHUD")
	if hud:
		var fade = ColorRect.new()
		fade.color = Color(0, 0, 0, 1)
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(fade)
		var tw = create_tween()
		tw.tween_property(fade, "color:a", 0.0, 0.5)
		tw.tween_callback(func():
			if is_instance_valid(fade):
				fade.queue_free()
		)

var current_camera_pitch: float = -58.0
var current_camera_height: float = 12.0
var current_camera_fov: float = 48.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform_1") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode == KEY_1 or event.keycode == KEY_1)):
		_show_hud_message("Only Mushika can navigate these narrow underground passages!", 3.0)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_camera_distance(-1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_camera_distance(1.5)
	elif event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_PAGEDOWN or event.keycode == KEY_BRACKETRIGHT:
			_apply_camera_pitch(current_camera_pitch - 4.0)
			_show_hud_message("Camera Angle: %.0f°" % current_camera_pitch, 1.5)
		elif event.keycode == KEY_PAGEUP or event.keycode == KEY_BRACKETLEFT:
			_apply_camera_pitch(current_camera_pitch + 4.0)
			_show_hud_message("Camera Angle: %.0f°" % current_camera_pitch, 1.5)

func _adjust_camera_distance(delta_h: float) -> void:
	current_camera_height = clampf(current_camera_height + delta_h, 6.0, 24.0)
	_update_camera_transform()
	_show_hud_message("Camera Distance: %.1fm" % (current_camera_height / sin(deg_to_rad(absf(current_camera_pitch)))), 1.2)

func _setup_player_as_mouse() -> void:
	if not player:
		return
	if player.current_form != player.PlayerForm.MOUSE:
		print("Enforcing MOUSE form in underground maze.")
	player.current_form = player.PlayerForm.MOUSE
	player.transform_to_mouse()
	
	var col = player.get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.radius = 0.38
		col.shape.height = 0.60
		col.position = Vector3(0, 0.30, 0)
	
	var spawn = get_node_or_null("PlayerSpawn")
	if spawn:
		player.global_position = spawn.global_position
		
	var anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	if anim:
		anim.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		anim.rotation_degrees = Vector3.ZERO
		anim.position = Vector3(0, 0.76, 0)
		anim.pixel_size = 0.010
		anim.sorting_offset = 0.0
		anim.render_priority = 0
		anim.double_sided = true
		anim.no_depth_test = false

	var shadow = player.get_node_or_null("DropShadow")
	if shadow:
		shadow.scale = Vector3(0.5, 0.5, 0.5)
		shadow.position = Vector3(0, 0.03, 0)
		shadow.visible = true

func _setup_camera() -> void:
	var rig = get_node_or_null("CameraRig")
	if rig and player:
		rig.target = player
		rig.follow_speed = 6.0
		rig.min_x = -30.0
		rig.max_x = 30.0
		rig.min_z = -14.0
		rig.max_z = 28.0
		_apply_camera_pitch(current_camera_pitch)

func _apply_camera_pitch(pitch_deg: float) -> void:
	current_camera_pitch = clampf(pitch_deg, -80.0, -45.0)
	_update_camera_transform()

func _update_camera_transform() -> void:
	var rig = get_node_or_null("CameraRig")
	if not rig:
		return
	var pivot = rig.get_node_or_null("Pivot")
	if pivot:
		pivot.rotation_degrees = Vector3(current_camera_pitch, 0, 0)
		var cam: Camera3D = pivot.get_node_or_null("Camera3D")
		if cam:
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = current_camera_fov
	var rad = deg_to_rad(absf(current_camera_pitch))
	var forward_z = current_camera_height / tan(rad)
	rig.target_offset = Vector3(0, current_camera_height, forward_z)
	if player:
		var target_pos = player.global_position + rig.target_offset
		target_pos.x = clampf(target_pos.x, rig.min_x, rig.max_x)
		target_pos.z = clampf(target_pos.z, rig.min_z, rig.max_z)
		rig.global_position = target_pos

func _setup_torches() -> void:
	var torches_node = get_node_or_null("Torches")
	if not torches_node:
		torches_node = get_node_or_null("MazeDecorations/Torches")
	if torches_node:
		for child in torches_node.get_children():
			if child is OmniLight3D:
				torch_lights.append(child)
			elif child.has_node("Light"):
				torch_lights.append(child.get_node("Light"))
			elif child.has_node("OmniLight3D"):
				torch_lights.append(child.get_node("OmniLight3D"))

func _setup_interactables() -> void:
	if key_area:
		key_area.body_entered.connect(_on_key_body_entered)
		if key_visual:
			key_bob_tween = create_tween().set_loops()
			key_bob_tween.tween_property(key_visual, "position:y", 0.45, 0.7).set_trans(Tween.TRANS_SINE)
			key_bob_tween.tween_property(key_visual, "position:y", 0.15, 0.7).set_trans(Tween.TRANS_SINE)
			
	if chest_area:
		chest_area.body_entered.connect(_on_chest_body_entered)
		chest_area.body_exited.connect(_on_chest_body_exited)

	if exit_area:
		exit_area.body_entered.connect(_on_exit_body_entered)
		exit_area.body_exited.connect(_on_exit_body_exited)
		if exit_prompt:
			exit_prompt.visible = false

func _process(delta: float) -> void:
	flicker_timer += delta * 6.0
	var flicker = sin(flicker_timer) * 0.15 + cos(flicker_timer * 1.7) * 0.1
	for light in torch_lights:
		if is_instance_valid(light):
			light.light_energy = clampf(1.8 + flicker, 1.3, 2.4)
			
	var rig = get_node_or_null("CameraRig")
	if rig and player:
		# Clamp camera position so it does not reveal empty voids outside the maze boundaries
		rig.global_position.x = clampf(rig.global_position.x, -26.0, 26.0)
		rig.global_position.z = clampf(rig.global_position.z, -12.0, 24.0)

	if player_near_exit:
		if Input.is_action_just_pressed("interact"):
			_on_exit_interacted()
		elif exit_unlocked and exit_area and player:
			var exit_pos = exit_area.global_position
			if player.global_position.distance_to(exit_pos) < 2.5:
				_transition_to_level_3()

func _on_key_body_entered(body: Node3D) -> void:
	if has_key:
		return
	if body.is_in_group("player") or body == player:
		has_key = true
		if key_bob_tween and key_bob_tween.is_valid():
			key_bob_tween.kill()
		_update_hud()
		_show_hud_message("KEY ACQUIRED!\nYou found the Fortress Skeleton Key.\nThe eastern Exit Gate can now be unlocked!", 5.0)
		print("PASSED: Golden Key collected by Mushika!")
		if key_visual:
			var tw = create_tween()
			tw.tween_property(key_visual, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
			tw.tween_property(key_visual, "modulate:a", 0.0, 0.2)
			tw.tween_callback(func():
				if is_instance_valid(key_area):
					key_area.queue_free()
			)

func _on_chest_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body == player:
		player_near_chest = true
		_show_hud_message("An ancient Asur supply chest. Left undisturbed by subterranean vermin.", 3.5)

func _on_chest_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body == player:
		player_near_chest = false

var transitioning_to_l3: bool = false

func _on_exit_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body == player:
		player_near_exit = true
		if exit_prompt:
			exit_prompt.visible = true
			if exit_unlocked:
				exit_prompt.text = "Gate Opened\n[E] Enter Level 3: Inner Castle"
			elif has_key:
				exit_prompt.text = "[E] Unlock Exit Gate with Key"
			else:
				exit_prompt.text = "Exit Gate (Locked)\nFind the Golden Key"

func _on_exit_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body == player:
		player_near_exit = false
		if exit_prompt:
			exit_prompt.visible = false

func _on_exit_interacted() -> void:
	if exit_unlocked:
		_transition_to_level_3()
		return
		
	if has_key:
		exit_unlocked = true
		if exit_prompt:
			exit_prompt.text = "Gate Opened\n[E] Enter Level 3: Inner Castle"
		if exit_gate_visual:
			var tw = create_tween()
			tw.tween_property(exit_gate_visual, "position:y", 3.2, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_show_hud_message("CLICK-CLANK! The heavy iron portcullis rises!\nPress [E] to enter the Inner Castle Sanctum!", 5.0)
		print("PASSED: Exit gate unlocked with key and opened successfully!")
	else:
		_show_hud_message("The iron portcullis is locked solid.\nSearch the labyrinth corridors to find the Golden Key.", 3.5)

func _transition_to_level_3() -> void:
	if transitioning_to_l3:
		return
	transitioning_to_l3 = true
	var l3_path = "res://scenes/levels/l3/l3_map.tscn"
	if ResourceLoader.exists(l3_path):
		_show_hud_message("Ascending to Level 3: The Inner Castle Sanctum...", 3.0)
		var hud = get_node_or_null("MazeHUD")
		if hud:
			var fade = ColorRect.new()
			fade.color = Color(0, 0, 0, 0)
			fade.set_anchors_preset(Control.PRESET_FULL_RECT)
			fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud.add_child(fade)
			var tw = create_tween()
			tw.tween_property(fade, "color:a", 1.0, 0.45)
			tw.tween_callback(func():
				get_tree().change_scene_to_file(l3_path)
			)
		else:
			get_tree().change_scene_to_file(l3_path)
	else:
		_show_hud_message("Error: Level 3 scene file not found!", 3.0)

func _update_hud() -> void:
	if hud_form:
		hud_form.text = "FORM: MUSHIKA"
	if hud_objective:
		if exit_unlocked:
			hud_objective.text = "Objective: Proceed through the exit gate"
		elif has_key:
			hud_objective.text = "Objective: Reach the Exit Gate at the top-right"
		else:
			hud_objective.text = "Objective: Find the Golden Key hidden in the maze"
	if hud_keys:
		hud_keys.text = "Keys: %s / 1" % ("1" if has_key else "0")

func _show_hud_message(msg: String, duration: float) -> void:
	if hud_message:
		hud_message.text = msg
		hud_message.visible = true
		var tw = create_tween()
		tw.tween_interval(duration)
		tw.tween_property(hud_message, "modulate:a", 0.0, 0.8)
		tw.tween_callback(func():
			if is_instance_valid(hud_message):
				hud_message.visible = false
				hud_message.modulate.a = 1.0
		)

