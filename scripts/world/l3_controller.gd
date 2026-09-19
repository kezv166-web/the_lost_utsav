extends Node3D

# --- Node References ---
@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig

# Interactables & Prompts
@onready var exit_prompt: Label3D = $Interactables/SouthExit/Prompt
@onready var altar_prompt: Label3D = $Interactables/AltarBlessing/Prompt
@onready var altar_area: Area3D = $Interactables/AltarBlessing
@onready var exit_area: Area3D = $Interactables/SouthExit
@onready var boss_trigger: Area3D = $Interactables/BossArenaTrigger

# Lighting & VFX
@onready var divine_light: OmniLight3D = $Lights/DivineMurtiLight
@onready var murti_particles: CPUParticles3D = $VFX/DivineMurtiParticles
@onready var asur_particles: CPUParticles3D = $VFX/AsurAuraParticles
@onready var om_sprite: Sprite3D = $VFX/BlessingVFX/OmSprite
@onready var lotus_sprite: Sprite3D = $VFX/BlessingVFX/LotusSprite
@onready var divine_flash: Sprite3D = $VFX/BlessingVFX/DivineFlash
@onready var blessing_particles: CPUParticles3D = $VFX/BlessingVFX/BlessingParticles

# UI
@onready var hud_title: Label = $UI/HUD/TitleBanner
@onready var hud_objective: Label = $UI/HUD/ObjectiveBanner
@onready var hud_action: Label = $UI/HUD/ActionPrompt
@onready var dialogue_box: PanelContainer = $UI/HUD/DialogueBox
@onready var dialogue_label: Label = $UI/HUD/DialogueBox/Margin/DialogueLabel

# --- State Variables ---
var player_near_altar: bool = false
var player_near_exit: bool = false
var nearby_rock: Node3D = null
var held_rock: Node3D = null

var blessing_claimed: bool = false
var blessing_in_progress: bool = false
var boss_encounter_started: bool = false
var torch_lights: Array[OmniLight3D] = []
var torch_base_energies: Array[float] = []

var time_passed: float = 0.0

func _ready() -> void:
	_ensure_l3_textures_cleaned()
	_setup_player()
	_setup_camera()
	_setup_torches()
	_setup_interactables()
	_setup_rocks()
	_setup_ui()

# -------------------------------------------------------------------------
# Dynamic Texture Cleaning (Removes baked-in checkerboard residues)
# -------------------------------------------------------------------------
func _ensure_l3_textures_cleaned() -> void:
	var tileset_res = "res://scenes/levels/l3/3rd-lvl-tileset.png"
	var tileset_global = ProjectSettings.globalize_path(tileset_res)
	if FileAccess.file_exists(tileset_global):
		var img = Image.load_from_file(tileset_global)
		if img and not img.is_empty():
			var sample_px = img.get_pixel(0, 0)
			# If not transparent at top-left, clean checkerboard
			if sample_px.a > 0.1:
				img.convert(Image.FORMAT_RGBA8)
				var w = img.get_width()
				var h = img.get_height()
				var data = img.get_data()
				for i in range(0, w * h):
					var base = i * 4
					var r = data[base]
					var g = data[base + 1]
					var b = data[base + 2]
					var max_c = max(r, max(g, b))
					var min_c = min(r, min(g, b))
					var c_diff = max_c - min_c
					var brightness = (int(r) + int(g) + int(b)) / 3
					if (brightness >= 195 and c_diff <= 14) or (brightness >= 180 and c_diff <= 10):
						data[base + 3] = 0
				var clean_tileset = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
				clean_tileset.save_png(tileset_global)

	# Ensure nearest filtering on all Sprite3D nodes to prevent edge bleeding
	_apply_clean_sprite_settings(self)

func _apply_clean_sprite_settings(node: Node) -> void:
	if node is Sprite3D:
		node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for child in node.get_children():
		_apply_clean_sprite_settings(child)

# -------------------------------------------------------------------------
# Player Configuration (Matches Level 1 & Outdoor 2.5D Scale and Proportions)
# -------------------------------------------------------------------------
func _setup_player() -> void:
	if not player:
		return
	
	# Ensure Human form in Level 3
	if "current_form" in player:
		player.current_form = player.PlayerForm.HUMAN
	if player.has_method("transform_to_human"):
		player.transform_to_human()

	var anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	if anim:
		anim.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim.rotation_degrees = Vector3.ZERO
		anim.position = Vector3(0, 0.72, 0)
		anim.scale = Vector3(1.0, 1.0, 1.0)
		anim.sorting_offset = 2.0
		anim.render_priority = 2
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

# -------------------------------------------------------------------------
# Camera Rig Setup (Perspective 2.5D, -12.5 deg tilt, outdoor perspective)
# -------------------------------------------------------------------------
func _setup_camera() -> void:
	if camera_rig:
		camera_rig.target = player
		camera_rig.target_offset = Vector3(0, 1.35, -2.0)
		camera_rig.follow_speed = 5.0
		camera_rig.min_x = -3.5
		camera_rig.max_x = 3.5
		camera_rig.min_z = -9.5
		camera_rig.max_z = 13.0
		
		var pivot = camera_rig.get_node_or_null("Pivot")
		if pivot:
			pivot.rotation_degrees = Vector3(-11.5, 0, 0)
			var cam: Camera3D = pivot.get_node_or_null("Camera3D")
			if cam:
				cam.projection = Camera3D.PROJECTION_PERSPECTIVE
				cam.fov = 48.0
				cam.transform.origin = Vector3(0, 0, 9.8)
				cam.current = true

# -------------------------------------------------------------------------
# Dynamic Torches & Lighting Flicker
# -------------------------------------------------------------------------
func _setup_torches() -> void:
	var lights_node = get_node_or_null("Lights")
	if lights_node:
		for child in lights_node.get_children():
			if child is OmniLight3D and child != divine_light:
				torch_lights.append(child)
				torch_base_energies.append(child.light_energy)
	
	# Also find animated torches
	var decos = get_node_or_null("Decorations/Torches")
	if decos:
		for child in decos.get_children():
			var light = child.get_node_or_null("Light")
			if light is OmniLight3D:
				torch_lights.append(light)
				torch_base_energies.append(light.light_energy)

# -------------------------------------------------------------------------
# Interactables Setup
# -------------------------------------------------------------------------
func _setup_interactables() -> void:
	if altar_prompt:
		altar_prompt.visible = false
		altar_prompt.text = "[E] Pray at Sacred Murti - Reclaim Blessing"
	if exit_prompt:
		exit_prompt.visible = false
		exit_prompt.text = "[E] Return to Castle Exterior"

	if altar_area:
		altar_area.body_entered.connect(_on_altar_entered)
		altar_area.body_exited.connect(_on_altar_exited)

	if exit_area:
		exit_area.body_entered.connect(_on_exit_entered)
		exit_area.body_exited.connect(_on_exit_exited)

	if boss_trigger:
		boss_trigger.body_entered.connect(_on_boss_trigger_entered)

func _setup_rocks() -> void:
	var rocks_parent = get_node_or_null("ArenaProps/MovableRocks")
	if rocks_parent:
		for rock in rocks_parent.get_children():
			var area = rock.get_node_or_null("InteractArea")
			if area:
				area.body_entered.connect(_on_rock_area_entered.bind(rock))
				area.body_exited.connect(_on_rock_area_exited.bind(rock))

func _setup_ui() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if hud_action:
		hud_action.text = ""

# -------------------------------------------------------------------------
# Physics Process & Dynamic Loop
# -------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	time_passed += delta

	# 1. Subtle warm torch flicker
	for i in range(torch_lights.size()):
		var light = torch_lights[i]
		var base = torch_base_energies[i]
		var noise = sin(time_passed * 7.0 + float(i) * 1.7) * 0.12 + cos(time_passed * 13.0 + float(i) * 2.3) * 0.08
		light.light_energy = base * (1.0 + noise)

	# 2. Divine Murti holy breathing pulse
	if divine_light:
		var murti_pulse = sin(time_passed * 2.2) * 0.35
		divine_light.light_energy = 3.2 + murti_pulse

	# 3. Update held rock position
	if is_instance_valid(held_rock) and is_instance_valid(player):
		held_rock.global_position = player.global_position + Vector3(0, 1.4, 0)

# -------------------------------------------------------------------------
# Input Handling
# -------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.is_echo() and event.physical_keycode == KEY_E):
		# If holding a rock, drop or throw it
		if is_instance_valid(held_rock):
			_throw_held_rock()
			return

		# Grab nearby rock
		if is_instance_valid(nearby_rock) and not is_instance_valid(held_rock):
			_grab_rock(nearby_rock)
			return

		# Pray at Altar
		if player_near_altar and not blessing_in_progress:
			_reclaim_blessing()
			return

		# South Exit
		if player_near_exit:
			_trigger_exit()
			return

	# Throw with attack key while carrying rock
	if is_instance_valid(held_rock):
		if event.is_action_pressed("attack_axe") or event.is_action_pressed("attack_rope") or (event is InputEventKey and event.pressed and (event.physical_keycode in [KEY_K, KEY_L, KEY_Q, KEY_SPACE])):
			_throw_held_rock()

# -------------------------------------------------------------------------
# Rock Grab & Throw Mechanics (DODGE • GRAB • THROW • STRIKE)
# -------------------------------------------------------------------------
func _grab_rock(rock: Node3D) -> void:
	held_rock = rock
	nearby_rock = null
	var prompt = rock.get_node_or_null("Prompt")
	if prompt:
		prompt.visible = false
	
	# Disable rock collision while holding
	var col = rock.get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = true
	
	if hud_action:
		hud_action.text = "[E / Attack] Throw Rock!"

func _throw_held_rock() -> void:
	if not is_instance_valid(held_rock) or not is_instance_valid(player):
		return
	
	var rock = held_rock
	held_rock = null
	if nearby_rock == rock:
		nearby_rock = null
	
	if hud_action:
		hud_action.text = ""

	# Determine throw direction from player facing
	var throw_dir = Vector3.FORWARD # Default facing North
	if "current_direction" in player:
		match player.current_direction:
			player.Direction.UP:
				throw_dir = Vector3(0, 0, -1)
			player.Direction.DOWN:
				throw_dir = Vector3(0, 0, 1)
			player.Direction.LEFT:
				throw_dir = Vector3(-1, 0, 0)
			player.Direction.RIGHT:
				throw_dir = Vector3(1, 0, 0)
	
	var start_pos = player.global_position + Vector3(0, 1.2, 0)
	var target_pos = start_pos + throw_dir * 6.5
	target_pos.y = 0.35

	# Smooth ballistic arc tween
	var tw = create_tween().set_parallel(true)
	tw.tween_property(rock, "global_position:x", target_pos.x, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(rock, "global_position:z", target_pos.z, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Parabolic height
	var height_tw = create_tween()
	height_tw.tween_property(rock, "global_position:y", start_pos.y + 1.2, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	height_tw.tween_property(rock, "global_position:y", target_pos.y, 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	height_tw.tween_callback(func():
		_on_rock_impact(rock)
	)

func _on_rock_impact(rock: Node3D) -> void:
	if not is_instance_valid(rock):
		return
	# Re-enable collision
	var col = rock.get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = false
	
	# Spawn dust particles
	var dust = rock.get_node_or_null("ImpactDust")
	if dust is CPUParticles3D:
		dust.restart()
		dust.emitting = true

# -------------------------------------------------------------------------
# Sacred Murti Blessing Reclaiming
# -------------------------------------------------------------------------
func _reclaim_blessing() -> void:
	blessing_in_progress = true
	blessing_claimed = true
	
	if altar_prompt:
		altar_prompt.visible = false
	
	# Divine visual sequence
	if divine_flash:
		divine_flash.visible = true
		divine_flash.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(divine_flash, "modulate:a", 0.9, 0.4)
		tw.tween_property(divine_flash, "modulate:a", 0.0, 0.8)
	
	if om_sprite:
		om_sprite.visible = true
		om_sprite.scale = Vector3(0.1, 0.1, 0.1)
		var om_tw = create_tween()
		om_tw.tween_property(om_sprite, "scale", Vector3(1.2, 1.2, 1.2), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		om_tw.tween_property(om_sprite, "rotation_degrees:y", 360.0, 3.0)
	
	if lotus_sprite:
		lotus_sprite.visible = true
		lotus_sprite.scale = Vector3(0.1, 0.1, 0.1)
		var lotus_tw = create_tween()
		lotus_tw.tween_property(lotus_sprite, "scale", Vector3(1.0, 1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if blessing_particles:
		blessing_particles.emitting = true

	# Dialogue & Victory Banner
	if dialogue_box and dialogue_label:
		dialogue_box.visible = true
		dialogue_label.text = "ॐ गं गणपतये नमः ...\nLord Ganesha's sacred blessing is reclaimed! The darkness retreats, and the divine Utsav is forever restored!"

	if hud_objective:
		hud_objective.text = "★ SACRED BLESSING RESTORED - UTSAV TRIUMPHANT! ★"
		hud_objective.modulate = Color(1.0, 0.85, 0.3)

# -------------------------------------------------------------------------
# Area Signal Callbacks
# -------------------------------------------------------------------------
func _on_altar_entered(body: Node3D) -> void:
	if body == player:
		player_near_altar = true
		if altar_prompt and not blessing_claimed:
			altar_prompt.visible = true

func _on_altar_exited(body: Node3D) -> void:
	if body == player:
		player_near_altar = false
		if altar_prompt:
			altar_prompt.visible = false

func _on_exit_entered(body: Node3D) -> void:
	if body == player:
		player_near_exit = true
		if exit_prompt:
			exit_prompt.visible = true

func _on_exit_exited(body: Node3D) -> void:
	if body == player:
		player_near_exit = false
		if exit_prompt:
			exit_prompt.visible = false

func _on_boss_trigger_entered(body: Node3D) -> void:
	if body == player and not boss_encounter_started:
		boss_encounter_started = true
		if hud_objective:
			hud_objective.text = "Boss Arena: Use Cover (Pillars & Walls) and Throw Rocks [E] to Stagger the Asur!"
			hud_objective.modulate = Color(1.0, 0.45, 0.35)

func _on_rock_area_entered(body: Node3D, rock: Node3D) -> void:
	if body == player and not is_instance_valid(held_rock):
		nearby_rock = rock
		var prompt = rock.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true

func _on_rock_area_exited(body: Node3D, rock: Node3D) -> void:
	if body == player:
		if nearby_rock == rock:
			nearby_rock = null
		var prompt = rock.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false

func _trigger_exit() -> void:
	if dialogue_box and dialogue_label:
		dialogue_box.visible = true
		dialogue_label.text = "The castle gates are open. Faith and courage have dispelled the Asur's shadow."
