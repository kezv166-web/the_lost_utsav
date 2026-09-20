extends Node3D

@onready var lever_prompt: Label3D = $Interactables/PuzzleLever/Prompt
@onready var crystal_prompt: Label3D = $Interactables/AltarCrystal/Prompt
@onready var exit_prompt: Label3D = $Interactables/SouthExit/Prompt
@onready var lever_sprite: AnimatedSprite3D = $Interactables/PuzzleLever/LeverSprite

@onready var mouse_passage_prompt: Label3D = $Interactables/MousePassage/Prompt
@onready var hole_visual: Sprite3D = $Interactables/MousePassage/HoleVisual
@onready var rubble_dust: CPUParticles3D = $Interactables/MousePassage/RubbleDust
@onready var draft_light: OmniLight3D = $Interactables/MousePassage/DraftLight

var shrine_prompt: Label3D = null
@onready var om_sprite: Sprite3D = $VFX/CutsceneVFX/OmSprite
@onready var lotus_sprite: Sprite3D = $VFX/CutsceneVFX/LotusSprite
@onready var aura_light: OmniLight3D = $VFX/CutsceneVFX/AuraLight
@onready var energy_ring: Sprite3D = $VFX/CutsceneVFX/EnergyRing
@onready var divine_flash: Sprite3D = $VFX/CutsceneVFX/DivineFlash
@onready var divine_particles: CPUParticles3D = $VFX/CutsceneVFX/DivineParticles

@onready var crystal_light: OmniLight3D = $Lights/CrystalLight
@onready var crystal_particles: CPUParticles3D = $VFX/CrystalEmbers
@onready var hud_message: Label = $UI/HUD/MessageBanner
@onready var dialogue_box: PanelContainer = $UI/HUD/DialogueBox
@onready var dialogue_label: Label = $UI/HUD/DialogueBox/Margin/DialogueLabel

var player_near_lever: bool = false
var player_near_crystal: bool = false
var player_near_exit: bool = false
var player_near_mouse_passage: bool = false
var player_near_shrine: bool = false

var lever_pulled: bool = false
var mouse_passage_revealed: bool = false
var shrine_prayed: bool = false
var transformation_in_progress: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play("l1_upper")

	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		if not grm.is_run_active:
			grm.start_new_run()
		grm.set_current_level(1)

	var hud_scene = preload("res://scenes/ui/speedrun_hud.tscn")
	var ui = get_node_or_null("UI")
	if ui and not ui.get_node_or_null("SpeedrunHUD"):
		var speed_hud = hud_scene.instantiate()
		ui.add_child(speed_hud)

	if not InputMap.has_action("transform_1"):
		InputMap.add_action("transform_1")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_1
		InputMap.action_add_event("transform_1", ev)

	# Configure player for Level 1 (matching outdoor version size and proportions)
	var player = get_node_or_null("Player")
	if player:
		var anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
		if anim:
			anim.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			anim.rotation_degrees = Vector3.ZERO
			anim.position = Vector3(0, 0.72, 0)
			anim.scale = Vector3(1.0, 1.0, 1.0)
			anim.sorting_offset = 0.0
			anim.render_priority = 0
			anim.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			anim.double_sided = true
			anim.no_depth_test = false
		var col: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
		if col and col.shape is CapsuleShape3D:
			col.shape.radius = 0.35
			col.shape.height = 1.4
			col.position = Vector3(0, 0.7, 0)
		var shadow = player.get_node_or_null("DropShadow")
		if shadow:
			shadow.scale = Vector3(1.0, 1.0, 1.0)
			shadow.visible = true

	# Configure camera for Level 1: close-up tracking view matching outdoor player scale
	var rig = get_node_or_null("CameraRig")
	if rig:
		rig.target_offset = Vector3(0, 0, 0)
		rig.follow_speed = 5.0
		rig.min_x = -4.5
		rig.max_x = 4.5
		rig.min_z = -1.8
		rig.max_z = 1.8
		var pivot = rig.get_node_or_null("Pivot")
		if pivot:
			pivot.rotation_degrees = Vector3(-50, 0, 0)
			var cam: Camera3D = pivot.get_node_or_null("Camera3D")
			if cam:
				cam.projection = Camera3D.PROJECTION_ORTHOGONAL
				cam.size = 9.2

	if lever_prompt:
		lever_prompt.visible = false
		lever_prompt.text = "[E] Pull Ancient Lever"
	if crystal_prompt:
		crystal_prompt.visible = false
		crystal_prompt.text = "[E] Inspect Asur Crystal"
	if exit_prompt:
		exit_prompt.visible = false
		exit_prompt.text = "[E] Return to Castle Exterior"
	if mouse_passage_prompt:
		mouse_passage_prompt.visible = false
		mouse_passage_prompt.text = "[E] Inspect Mouse Passage"
	var lever_area = get_node_or_null("Interactables/PuzzleLever")
	if lever_area:
		lever_area.body_entered.connect(_on_lever_area_entered)
		lever_area.body_exited.connect(_on_lever_area_exited)
		
	var crystal_area = get_node_or_null("Interactables/AltarCrystal")
	if crystal_area:
		crystal_area.body_entered.connect(_on_crystal_area_entered)
		crystal_area.body_exited.connect(_on_crystal_area_exited)
		
	var exit_area = get_node_or_null("Interactables/SouthExit")
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_entered)
		exit_area.body_exited.connect(_on_exit_area_exited)

	var mouse_area = get_node_or_null("Interactables/MousePassage")
	if mouse_area:
		mouse_area.body_entered.connect(_on_mouse_passage_entered)
		mouse_area.body_exited.connect(_on_mouse_passage_exited)

	if hud_message:
		hud_message.text = "Level 1: The Asur's Fortress - Inner Sanctum\nExplore the hall. Press [1] to chant mantra and transform into Mushika."
		_fade_hud_message(5.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform_1") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode == KEY_1 or event.keycode == KEY_1)):
		_on_transform_key_pressed()

func _process(delta: float) -> void:
	pulse_time += delta * (4.0 if lever_pulled else 2.0)
	if crystal_light:
		var base_energy = 4.5 if lever_pulled else 2.8
		crystal_light.light_energy = base_energy + sin(pulse_time) * (1.2 if lever_pulled else 0.6)
		
	var crystal_mesh = get_node_or_null("Visuals3D/AltarDais/CrystalMesh")
	if crystal_mesh:
		crystal_mesh.rotate_y(delta * (1.4 if lever_pulled else 0.6))
		crystal_mesh.position.y = 1.45 + sin(pulse_time * 2.0) * 0.05

	if transformation_in_progress:
		return
		
	if Input.is_action_just_pressed("transform_1"):
		_on_transform_key_pressed()
	elif player_near_lever and Input.is_action_just_pressed("interact"):
		_on_lever_interacted()
	elif player_near_crystal and Input.is_action_just_pressed("interact"):
		_on_crystal_interacted()
	elif player_near_mouse_passage and Input.is_action_just_pressed("interact"):
		_on_mouse_passage_interacted()
	elif player_near_exit and Input.is_action_just_pressed("interact"):
		_on_exit_interacted()

func _on_lever_interacted() -> void:
	if not lever_pulled:
		lever_pulled = true
		if lever_sprite:
			lever_sprite.play("pull")
			get_tree().create_timer(0.4).timeout.connect(func():
				if is_instance_valid(lever_sprite):
					lever_sprite.animation = "down"
			)
		if lever_prompt:
			lever_prompt.text = "Lever Engaged"
		if crystal_light:
			crystal_light.light_color = Color(1.0, 0.35, 0.1, 1.0)
			crystal_light.omni_range = 10.0
		if crystal_particles:
			crystal_particles.amount = 55
			crystal_particles.initial_velocity_max = 2.5
			
		reveal_mouse_passage()
	else:
		_show_hud_message("The mechanism is already engaged.", 2.5)

func reveal_mouse_passage() -> void:
	if mouse_passage_revealed:
		return
	mouse_passage_revealed = true
	
	# Rubble dust particles
	if rubble_dust:
		rubble_dust.restart()
		rubble_dust.emitting = true
		
	# Reveal hole sprite with smooth fade-in
	if hole_visual:
		hole_visual.visible = true
		hole_visual.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(hole_visual, "modulate:a", 1.0, 0.6)
		
	if draft_light:
		var ltw = create_tween()
		ltw.tween_property(draft_light, "light_energy", 1.2, 0.8)
		
	# Screen shake via CameraRig target offset bounce
	var rig = get_node_or_null("CameraRig")
	if rig:
		var stw = create_tween()
		stw.tween_property(rig, "target_offset", Vector3(0.12, 0, -0.08), 0.06)
		stw.tween_property(rig, "target_offset", Vector3(-0.12, 0, 0.08), 0.06)
		stw.tween_property(rig, "target_offset", Vector3(0.06, 0, -0.04), 0.06)
		stw.tween_property(rig, "target_offset", Vector3.ZERO, 0.1)

	_show_hud_message("CLANK-RUMBLE! An underground mechanism shifts.\nA hollow section of the western floor collapses, revealing a narrow mouse passage!", 5.5)
	print("PASSED: Level 1 Lever pulled, animated down, and mouse passage revealed on left side!")

func _on_transform_key_pressed() -> void:
	if transformation_in_progress:
		return
	var player = get_node_or_null("Player")
	if not player:
		return
	if player.current_form == player.PlayerForm.HUMAN:
		_start_transformation_cutscene()
	elif player.current_form == player.PlayerForm.MOUSE:
		_start_revert_cutscene()

func _start_revert_cutscene() -> void:
	transformation_in_progress = true
	var player = get_node_or_null("Player")
	if not player:
		return
	player.current_form = player.PlayerForm.TRANSFORMING
	player.velocity = Vector3.ZERO
	player.is_walking = false
	
	var cutscene_vfx = get_node_or_null("VFX/CutsceneVFX")
	if cutscene_vfx:
		cutscene_vfx.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)
		
	if dialogue_box:
		dialogue_box.visible = true
		dialogue_box.modulate.a = 1.0
		_set_dialogue_text("Returning to human form...")
		
	if aura_light:
		aura_light.light_energy = 0.6
		var tw_a = create_tween()
		tw_a.tween_property(aura_light, "light_energy", 0.0, 0.6)
		
	var p_anim = player.get_node_or_null("AnimatedSprite3D")
	if p_anim:
		var tw = create_tween()
		tw.tween_property(p_anim, "modulate", Color(1.2, 1.1, 0.9, 0.3), 0.3)
		tw.tween_callback(func():
			player.transform_to_human()
			player.current_form = player.PlayerForm.TRANSFORMING
			p_anim.modulate = Color(1.0, 1.0, 1.0, 1.0)
		)
		
	# Smooth camera zoom back to human full view
	var rig = get_node_or_null("CameraRig")
	if rig:
		var cam = rig.get_node_or_null("Pivot/Camera3D")
		if cam:
			var ctw = create_tween()
			ctw.tween_property(cam, "size", 9.2, 0.6)
		
	get_tree().create_timer(0.7).timeout.connect(func():
		if dialogue_box:
			dialogue_box.visible = false
		transformation_in_progress = false
		player.current_form = player.PlayerForm.HUMAN
		print("PASSED: Transformed back to human form.")
	)

func _start_transformation_cutscene() -> void:
	transformation_in_progress = true
		
	var player = get_node_or_null("Player")
	var p_anim: AnimatedSprite3D = null
	if player:
		p_anim = player.get_node_or_null("AnimatedSprite3D")
		if p_anim:
			p_anim.play("idle_up")
		player.velocity = Vector3.ZERO
		player.is_walking = false

	# Center cutscene VFX directly onto the player's ground position
	var cutscene_vfx = get_node_or_null("VFX/CutsceneVFX")
	if cutscene_vfx and player:
		cutscene_vfx.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)
			
	if dialogue_box:
		dialogue_box.visible = true
		dialogue_box.modulate.a = 0.0
		var d_tw = create_tween()
		d_tw.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
		
	# =========================================================================
	# PHASE 1 — Human Chanting (0.0 – 0.9 sec)
	# Human facing shrine, chanting mantra, warm golden glow builds
	# =========================================================================
	_set_dialogue_text("“ॐ गं गणपतये नमः ...”\n“ॐ गं गणपतये नमः ...”")
	
	if aura_light:
		aura_light.light_color = Color(1.0, 0.82, 0.45, 1.0)
		aura_light.light_energy = 0.0
		aura_light.omni_range = 2.2
		var tw_aura1 = create_tween()
		tw_aura1.tween_property(aura_light, "light_energy", 0.75, 0.8)
		
	if divine_particles:
		divine_particles.amount = 12
		divine_particles.restart()
		divine_particles.emitting = true

	# =========================================================================
	# PHASE 2 — 8-Frame Divine Transformation Sequence (0.9 – 2.5 sec)
	# Plays all 8 frames from mouse_tranformation.png:
	# Kneeling boy -> Golden Aura -> Divine Lotus & Mouse Form -> Mushika
	# =========================================================================
	get_tree().create_timer(0.9).timeout.connect(func():
		_set_dialogue_text("A divine energy surrounds you...")
		if player:
			player.start_transformation()
	)

	get_tree().create_timer(1.8).timeout.connect(func():
		_set_dialogue_text("Your form begins to change...")
	)

	# =========================================================================
	# PHASE 3 — Mushika Awakens (2.5 – 3.6 sec)
	# Transformation completes into Mushika mouse, glow gently settles
	# =========================================================================
	get_tree().create_timer(2.5).timeout.connect(func():
		_set_dialogue_text("The divine mouse form awakens.")
		if player and player.current_form != player.PlayerForm.MOUSE:
			player.transform_to_mouse()
			player.current_form = player.PlayerForm.TRANSFORMING
		
		# Smooth camera zoom for mouse close-up view
		var rig = get_node_or_null("CameraRig")
		if rig:
			var cam = rig.get_node_or_null("Pivot/Camera3D")
			if cam:
				var ctw = create_tween()
				ctw.tween_property(cam, "size", 7.8, 0.8)
		
		if divine_particles:
			divine_particles.emitting = false
		if aura_light:
			var tw_aout = create_tween()
			tw_aout.tween_property(aura_light, "light_energy", 0.0, 0.6)
	)

	get_tree().create_timer(3.1).timeout.connect(func():
		_set_dialogue_text("Small form. Great purpose.")
	)

	get_tree().create_timer(3.8).timeout.connect(func():
		if dialogue_box:
			var d_tw = create_tween()
			d_tw.tween_property(dialogue_box, "modulate:a", 0.0, 0.3)
			d_tw.tween_callback(func(): dialogue_box.visible = false)
		transformation_in_progress = false
		if player:
			player.current_form = player.PlayerForm.MOUSE
		print("PASSED: Ganesha to Mushika transformation cutscene completed successfully!")
	)

func _set_dialogue_text(txt: String) -> void:
	if dialogue_label:
		dialogue_label.text = txt

func _on_crystal_interacted() -> void:
	if not lever_pulled:
		_show_hud_message("A Sindhurasura power crystal radiates dark heat. A mechanical lock binds its flow.", 4.5)
	else:
		_show_hud_message("The crystal resonance is active! The energy hums through the foundation tunnels.", 4.5)

func _on_mouse_passage_interacted() -> void:
	if not mouse_passage_revealed:
		_show_hud_message("Solid stone floor tiles. Nothing unusual here.", 3.0)
		return
		
	var player = get_node_or_null("Player")
	if player and player.get("current_form") == player.PlayerForm.MOUSE:
		_show_hud_message("The path ahead is now open.\nMushika slips effortlessly through the narrow broken-brick passage into the hidden tunnels beyond!", 3.0)
		print("PASSED: Mushika entered the hidden mouse passage!")
		var maze_path = "res://scenes/levels/maze/maze.tscn"
		if ResourceLoader.exists(maze_path):
			var fade = ColorRect.new()
			fade.color = Color(0, 0, 0, 0)
			fade.set_anchors_preset(Control.PRESET_FULL_RECT)
			fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ui = get_node_or_null("UI")
			if ui:
				ui.add_child(fade)
				var tw = create_tween()
				tw.tween_property(fade, "color:a", 1.0, 0.45)
				tw.tween_callback(func():
					get_tree().change_scene_to_file(maze_path)
				)
			else:
				get_tree().create_timer(0.45).timeout.connect(func():
					get_tree().change_scene_to_file(maze_path)
				)
	else:
		_show_hud_message("A broken-brick opening into the dark dungeon foundations.\nToo narrow for a human, but a mouse could easily navigate it.\nPress [1] to chant mantra and transform into Mushika!", 5.0)
		print("PASSED: Player inspected the narrow mouse passage!")

func _on_exit_interacted() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/outdoor/outdoor_map.tscn")

func _show_hud_message(msg: String, duration: float) -> void:
	if hud_message:
		hud_message.text = msg
		hud_message.visible = true
		_fade_hud_message(duration)

func _fade_hud_message(delay: float) -> void:
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(hud_message, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		if is_instance_valid(hud_message):
			hud_message.visible = false
			hud_message.modulate.a = 1.0
	)

# Area trigger callbacks
func _on_lever_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_lever = true
		if lever_prompt:
			lever_prompt.visible = true

func _on_lever_area_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_lever = false
		if lever_prompt:
			lever_prompt.visible = false

func _on_crystal_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_crystal = true
		if crystal_prompt:
			crystal_prompt.visible = true

func _on_crystal_area_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_crystal = false
		if crystal_prompt:
			crystal_prompt.visible = false

func _on_mouse_passage_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_mouse_passage = true
		if mouse_passage_prompt and mouse_passage_revealed:
			var player = get_node_or_null("Player")
			if player and player.get("current_form") == player.PlayerForm.MOUSE:
				mouse_passage_prompt.text = "[E] Enter Mouse Passage"
			else:
				mouse_passage_prompt.text = "[E] Inspect Mouse Passage"
			mouse_passage_prompt.visible = true

func _on_mouse_passage_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_mouse_passage = false
		if mouse_passage_prompt:
			mouse_passage_prompt.visible = false

func _on_exit_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_exit = true
		if exit_prompt:
			exit_prompt.visible = true

func _on_exit_area_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_exit = false
		if exit_prompt:
			exit_prompt.visible = false
