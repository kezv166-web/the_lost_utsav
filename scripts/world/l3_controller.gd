extends Node3D

# --- Node References ---
@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var asur: CharacterBody3D = get_node_or_null("Asur")

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
var is_lifting_rock: bool = false
var rock_lift_tween: Tween = null
var is_restarting_level: bool = false

var blessing_claimed: bool = false
var blessing_in_progress: bool = false
var boss_encounter_started: bool = false
var torch_lights: Array[OmniLight3D] = []
var torch_base_energies: Array[float] = []

var time_passed: float = 0.0
var _interact_debounce_timer: float = 0.0

# GLB collision helper
var _glb_collision: Node = null
var _rock_template: Node3D = null

# Chota Asur Minions System
var chota_asur_scene: PackedScene = preload("res://scenes/enemy/chota_asur.tscn")
var active_chota_asurs: Array[Node3D] = []
var max_chota_asurs: int = 4
var minion_spawn_timer: float = 6.0
var minion_spawn_interval: float = 12.0
var current_attacker: Node3D = null
var spawn_point_index: int = 0

const MINION_SPAWN_POINTS: Array[Vector3] = [
	Vector3(-5.8, 0.1, 2.5),  # West Colonnade Flank
	Vector3(5.8, 0.1, 2.5),   # East Colonnade Flank
	Vector3(-4.5, 0.1, 9.5),  # South-West Gate Flank
	Vector3(4.5, 0.1, 9.5)    # South-East Gate Flank
]

func _ready() -> void:
	var music_mgr = get_node_or_null("/root/MusicManager")
	if music_mgr and music_mgr.has_method("play"):
		music_mgr.play("l3_boss")
		
	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		if not grm.is_run_active:
			grm.start_new_run()
		grm.set_current_level(3)
		
	_ensure_l3_textures_cleaned()
	_setup_player()
	_setup_camera()
	_setup_torches()
	_setup_interactables()
	_setup_rocks()
	_setup_glb_collisions()
	_setup_asur()
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

	# Ensure ground cracks procedural texture exists
	var cracks_script = load("res://scripts/enemy/asur_ground_cracks.gd")
	if cracks_script and cracks_script.has_method("ensure_ground_cracks_texture"):
		cracks_script.ensure_ground_cracks_texture()

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

	if player.has_signal("player_damaged") and not player.player_damaged.is_connected(_on_player_damaged):
		player.player_damaged.connect(_on_player_damaged)
	if player.has_signal("player_died") and not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

# -------------------------------------------------------------------------
# Camera Rig Setup (Perspective 2.5D, -12.5 deg tilt, outdoor perspective)
# -------------------------------------------------------------------------
func _setup_camera() -> void:
	if camera_rig:
		camera_rig.target = player
		camera_rig.target_offset = Vector3(0, 1.35, -2.0)
		camera_rig.follow_speed = 5.0
		camera_rig.min_x = -5.0
		camera_rig.max_x = 5.0
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
		if rocks_parent.get_child_count() > 0:
			var first_rock = rocks_parent.get_child(0)
			_rock_template = first_rock.duplicate()
		for rock in rocks_parent.get_children():
			var area = rock.get_node_or_null("InteractArea")
			if area:
				area.body_entered.connect(_on_rock_area_entered.bind(rock))
				area.body_exited.connect(_on_rock_area_exited.bind(rock))

# -------------------------------------------------------------------------
# GLB 3D Model Collision Setup
# -------------------------------------------------------------------------
func _setup_glb_collisions() -> void:
	var script_res = load("res://scripts/world/l3_glb_collision.gd")
	if not script_res:
		push_warning("[L3] Could not load l3_glb_collision.gd")
		return
	_glb_collision = Node.new()
	_glb_collision.set_script(script_res)
	add_child(_glb_collision)
	var arena_props = get_node_or_null("ArenaProps")
	if arena_props:
		_glb_collision.setup_glb_collisions(arena_props)

func _setup_asur() -> void:
	if asur:
		if asur.has_method("set_player"):
			asur.set_player(player)
		if asur.has_signal("boss_roared"):
			asur.boss_roared.connect(_on_asur_roared)
		if asur.has_signal("boss_damaged"):
			asur.boss_damaged.connect(_on_asur_damaged)
		if asur.has_signal("boss_defeated"):
			asur.boss_defeated.connect(_on_asur_defeated)

func _on_boss_trigger_entered(body: Node3D) -> void:
	if body == player and not boss_encounter_started:
		boss_encounter_started = true
		if asur and asur.has_method("roar"):
			asur.roar()
		if hud_objective:
			hud_objective.text = "Boss Arena: Defeat the Asur General! Watch for minion flanks and ground shockwaves!"
			hud_objective.modulate = Color(1.0, 0.45, 0.35)

func request_attack_token(requester: Node3D) -> bool:
	if current_attacker == null or not is_instance_valid(current_attacker):
		current_attacker = requester
		return true
	if current_attacker == requester:
		return true
	return false

func release_attack_token(requester: Node3D) -> void:
	if current_attacker == requester:
		current_attacker = null

func spawn_chota_asur(pos: Vector3 = Vector3.ZERO) -> Node3D:
	if active_chota_asurs.size() >= max_chota_asurs:
		return null
	if not chota_asur_scene:
		return null
		
	var minion = chota_asur_scene.instantiate()
	add_child(minion)
	
	if pos == Vector3.ZERO:
		pos = MINION_SPAWN_POINTS[spawn_point_index % MINION_SPAWN_POINTS.size()]
		spawn_point_index += 1
		
	minion.global_position = pos
	minion.assigned_slot = active_chota_asurs.size() % 4
	if is_instance_valid(player):
		minion.set_player(player)
	minion.minion_died.connect(_on_minion_died)
	
	active_chota_asurs.append(minion)
	print("[L3] Spawned Chota Asur #%d at %s (Slot %d)" % [active_chota_asurs.size(), pos, minion.assigned_slot])
	return minion

func _on_minion_died(minion: Node3D) -> void:
	if current_attacker == minion:
		current_attacker = null
	active_chota_asurs.erase(minion)
	_reassign_minion_slots()

func _reassign_minion_slots() -> void:
	for i in range(active_chota_asurs.size()):
		var m = active_chota_asurs[i]
		if is_instance_valid(m):
			m.assigned_slot = i % 4

func _on_asur_roared() -> void:
	if camera_rig:
		var tw = create_tween()
		tw.tween_property(camera_rig, "target_offset", Vector3(0.15, 1.35, -2.0), 0.05)
		tw.tween_property(camera_rig, "target_offset", Vector3(-0.15, 1.35, -2.0), 0.05)
		tw.tween_property(camera_rig, "target_offset", Vector3(0, 1.35, -2.0), 0.08)
	# Roar summons reinforcements if below cap
	if active_chota_asurs.size() < max_chota_asurs:
		spawn_chota_asur()

func _on_asur_damaged(new_hp: int) -> void:
	if camera_rig:
		var tw = create_tween()
		tw.tween_property(camera_rig, "target_offset", Vector3(0.2, 1.35, -1.9), 0.06)
		tw.tween_property(camera_rig, "target_offset", Vector3(-0.2, 1.35, -2.1), 0.06)
		tw.tween_property(camera_rig, "target_offset", Vector3(0, 1.35, -2.0), 0.08)
		
	# Summon reinforcements on boss damage milestones if under cap
	if (new_hp in [750, 500, 250] or active_chota_asurs.is_empty()) and active_chota_asurs.size() < max_chota_asurs:
		spawn_chota_asur()

func _on_asur_defeated() -> void:
	# Defeat all active minions when boss falls
	for m in active_chota_asurs:
		if is_instance_valid(m) and m.has_method("take_damage"):
			m.take_damage(999)
	active_chota_asurs.clear()
	current_attacker = null

	# Unlock path to the Sacred Murti by disabling rear barrier
	var rear_barrier_col = get_node_or_null("Boundaries/AsurRearBarrier/CollisionShape3D")
	if rear_barrier_col and rear_barrier_col is CollisionShape3D:
		rear_barrier_col.set_deferred("disabled", true)
		
	if hud_objective:
		hud_objective.text = "★ ASUR GENERAL DEFEATED! Proceed to the Sacred Murti to claim the blessing! ★"
		hud_objective.modulate = Color(1.0, 0.85, 0.3)

func _setup_ui() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if hud_action:
		hud_action.text = ""
	
	var hud = get_node_or_null("UI/HUD")
	if hud:
		var char_bar = hud.get_node_or_null("CharacterHealthBar")
		if char_bar and char_bar.has_method("set_player"):
			char_bar.set_player(player)

		var boss_bar = hud.get_node_or_null("AsurBossBar")
		if boss_bar and boss_bar.has_method("set_boss") and asur:
			boss_bar.set_boss(asur)

	_update_hp_display(player.health if (player and "health" in player) else 250)

	var hud_scene = preload("res://scenes/ui/speedrun_hud.tscn")
	var ui = get_node_or_null("UI")
	if ui and not ui.get_node_or_null("SpeedrunHUD"):
		var speed_hud = hud_scene.instantiate()
		ui.add_child(speed_hud)

func _on_player_damaged(hp: int) -> void:
	if camera_rig:
		var tw = create_tween()
		tw.tween_property(camera_rig, "target_offset", Vector3(0.25, 1.35, -1.8), 0.05)
		tw.tween_property(camera_rig, "target_offset", Vector3(-0.25, 1.35, -2.2), 0.05)
		tw.tween_property(camera_rig, "target_offset", Vector3(0, 1.35, -2.0), 0.08)
	_update_hp_display(hp)

func _on_player_died() -> void:
	if is_restarting_level:
		return
	is_restarting_level = true

	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_method("record_level_3_death"):
		grm.record_level_3_death()

	Engine.time_scale = 1.0
	_update_hp_display(0)

	if hud_action:
		hud_action.text = "The Asur struck you down!"
	if hud_objective:
		hud_objective.text = "★ DEFEATED - Restarting Level 3... ★"
		hud_objective.modulate = Color(1.0, 0.25, 0.25)

	# Disable player physics and fade sprite on defeat
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
		var spr = player.get_node_or_null("AnimatedSprite3D")
		if spr:
			var tw = create_tween()
			tw.tween_property(spr, "modulate", Color(1.0, 0.2, 0.2, 0.0), 1.0)

	# Restart Level 3 after defeat pause
	var tree = get_tree()
	if tree:
		tree.create_timer(1.2).timeout.connect(func():
			Engine.time_scale = 1.0
			var active_tree = get_tree()
			if active_tree:
				var err = active_tree.reload_current_scene()
				if err != OK:
					active_tree.change_scene_to_file("res://scenes/levels/l3/l3_map.tscn")
		)

func _update_hp_display(hp: int) -> void:
	var hud = get_node_or_null("UI/HUD")
	if hud:
		var char_bar = hud.get_node_or_null("CharacterHealthBar")
		if char_bar and char_bar.has_method("update_health"):
			var max_val = player.max_health if (player and "max_health" in player) else 250
			char_bar.update_health(hp, max_val)

# -------------------------------------------------------------------------
# Physics Process & Dynamic Loop
# -------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	time_passed += delta

	# Periodic Chota Asur summoning during boss encounter
	if boss_encounter_started and is_instance_valid(asur) and asur.health > 0:
		minion_spawn_timer -= delta
		if minion_spawn_timer <= 0.0:
			minion_spawn_timer = minion_spawn_interval
			if active_chota_asurs.size() < max_chota_asurs:
				spawn_chota_asur()

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

	# 3. Update held rock position overhead
	if is_instance_valid(held_rock) and is_instance_valid(player):
		if not is_lifting_rock:
			var bob_offset_x: float = 0.0
			var bob_offset_y: float = 1.70
			if "anim_sprite" in player and is_instance_valid(player.anim_sprite):
				bob_offset_x = player.anim_sprite.position.x
				bob_offset_y = 1.70 + (player.anim_sprite.position.y - 0.72) * 1.2
			held_rock.global_position = player.global_position + Vector3(bob_offset_x, bob_offset_y, 0)
		if "is_carrying" in player and not player.is_carrying:
			player.is_carrying = true

	# 4. Proximity detection for nearby rocks
	if not is_instance_valid(held_rock) and is_instance_valid(player):
		var player_holding_minion = ("held_chota_asur" in player and is_instance_valid(player.held_chota_asur))
		var closest_rock: Node3D = null
		var min_dist: float = 2.4
		if not player_holding_minion:
			var rocks_parent = get_node_or_null("ArenaProps/MovableRocks")
			if rocks_parent:
				for rock in rocks_parent.get_children():
					if rock is Node3D and rock != held_rock and not rock.is_queued_for_deletion():
						# Boss Danger Zone check: do not allow grabbing rocks inside Asur's inner melee radius
						if asur and is_instance_valid(asur) and asur.visible and ("health" in asur and asur.health > 0):
							if rock.global_position.distance_to(asur.global_position) < 1.8:
								continue
						var dist = player.global_position.distance_to(rock.global_position)
						if dist < min_dist:
							min_dist = dist
							closest_rock = rock

		if closest_rock != nearby_rock:
			if is_instance_valid(nearby_rock):
				var old_prompt = nearby_rock.get_node_or_null("Prompt")
				if old_prompt:
					old_prompt.visible = false
			nearby_rock = closest_rock
			if is_instance_valid(nearby_rock):
				var new_prompt = nearby_rock.get_node_or_null("Prompt")
				if new_prompt:
					new_prompt.visible = true
					new_prompt.text = "[E] Grab Rock"

	# Decrement interact debounce
	if _interact_debounce_timer > 0.0:
		_interact_debounce_timer -= delta

	# 5. Direct polling for mobile/gamepad interact trigger
	if _interact_debounce_timer <= 0.0:
		if Input.is_action_just_pressed("interact"):
			_handle_interact()
		elif is_instance_valid(held_rock) and (Input.is_action_just_pressed("attack_axe") or Input.is_action_just_pressed("attack_rope")):
			_throw_held_rock()

# -------------------------------------------------------------------------
# Input Handling & Public API
# -------------------------------------------------------------------------
func grab_rock(rock: Node3D) -> void:
	_grab_rock(rock)

func throw_held_rock() -> void:
	_throw_held_rock()

func _handle_interact() -> void:
	if _interact_debounce_timer > 0.0:
		return

	# If carrying rock, throw it with interact!
	if is_instance_valid(held_rock):
		_interact_debounce_timer = 0.25
		_throw_held_rock()
		return
	# If holding minion, throw it with interact!
	if is_instance_valid(player) and "held_chota_asur" in player and is_instance_valid(player.held_chota_asur):
		if player.has_method("throw_held_chota_asur"):
			_interact_debounce_timer = 0.25
			player.throw_held_chota_asur()
		return
	# If near rock, grab it with interact!
	elif is_instance_valid(nearby_rock):
		_interact_debounce_timer = 0.25
		_grab_rock(nearby_rock)
		return
	# Pray at Altar
	elif player_near_altar and not blessing_in_progress:
		_interact_debounce_timer = 0.50
		_reclaim_blessing()
		return
	# South Exit
	elif player_near_exit:
		_interact_debounce_timer = 0.50
		_trigger_exit()
		return

func _unhandled_input(event: InputEvent) -> void:
	# Check if interact (E or C fallback) is pressed
	var is_interact = event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode in [KEY_E, KEY_C] or event.keycode in [KEY_E, KEY_C]))
	
	if is_interact:
		_handle_interact()
		get_viewport().set_input_as_handled()
		return

	# Throw with attack key while carrying rock (F, G, K, L, Space)
	if is_instance_valid(held_rock):
		if event.is_action_pressed("attack_axe") or event.is_action_pressed("attack_rope") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.physical_keycode in [KEY_F, KEY_G, KEY_K, KEY_L, KEY_SPACE] or event.keycode in [KEY_F, KEY_G, KEY_K, KEY_L, KEY_SPACE])):
			_interact_debounce_timer = 0.25
			_throw_held_rock()
			get_viewport().set_input_as_handled()

# -------------------------------------------------------------------------
# Rock Grab & Throw Mechanics (DODGE • GRAB • THROW • STRIKE)
# -------------------------------------------------------------------------
func _set_rock_collision_disabled(rock: Node3D, disabled: bool) -> void:
	if not is_instance_valid(rock):
		return
	if rock is CollisionObject3D:
		if disabled:
			rock.collision_layer = 0
			rock.collision_mask = 0
			if is_instance_valid(player) and player is CollisionObject3D:
				player.add_collision_exception_with(rock)
		else:
			rock.collision_layer = 1
			rock.collision_mask = 1
			if is_instance_valid(player) and player is CollisionObject3D:
				player.remove_collision_exception_with(rock)
	_disable_collision_shapes_recursive(rock, disabled)

func _disable_collision_shapes_recursive(node: Node, disabled: bool) -> void:
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", disabled)
		_disable_collision_shapes_recursive(child, disabled)

func _grab_rock(rock: Node3D) -> void:
	if not is_instance_valid(rock) or not is_instance_valid(player):
		return
	_interact_debounce_timer = 0.25
	held_rock = rock
	nearby_rock = null
	var prompt = rock.get_node_or_null("Prompt")
	if prompt:
		prompt.visible = false
	
	# Disable rock collision completely while holding
	_set_rock_collision_disabled(rock, true)
	
	# 1. Trigger dust puff at rock's initial base position
	var dust = rock.get_node_or_null("ImpactDust")
	if dust and dust is CPUParticles3D:
		dust.restart()
		dust.emitting = true
	
	# 2. Trigger player reach/lift crouch animation
	if player.has_method("play_grab_animation"):
		player.play_grab_animation(0.22)
	
	if "is_carrying" in player:
		player.is_carrying = true
	
	# 3. Smooth ballistic lift tween from ground to overhead hands
	if rock_lift_tween and rock_lift_tween.is_valid():
		rock_lift_tween.kill()
	
	is_lifting_rock = true
	var lift_start = rock.global_position
	var target_overhead = player.global_position + Vector3(0, 1.70, 0)
	
	rock_lift_tween = create_tween()
	rock_lift_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rock_lift_tween.tween_property(rock, "global_position", target_overhead, 0.22).from(lift_start)
	rock_lift_tween.finished.connect(func():
		is_lifting_rock = false
	)
	
	if hud_action:
		hud_action.text = "[E / Attack / Click] Throw Rock!"

func _throw_held_rock() -> void:
	if not is_instance_valid(held_rock) or not is_instance_valid(player):
		return
	_interact_debounce_timer = 0.25
	
	if rock_lift_tween and rock_lift_tween.is_valid():
		rock_lift_tween.kill()
	is_lifting_rock = false
	
	var rock = held_rock
	held_rock = null
	if nearby_rock == rock:
		nearby_rock = null
	
	if "is_carrying" in player:
		player.is_carrying = false
		if "anim_sprite" in player and is_instance_valid(player.anim_sprite):
			player.anim_sprite.position.y = 0.72
			player.anim_sprite.position.x = 0.0
	
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
	
	var start_pos = player.global_position + Vector3(0, 1.45, 0)
	var target_pos = start_pos + throw_dir * 7.0
	target_pos.y = 0.35

	# If throwing towards Asur within range, target him directly to prevent overshooting at close distance
	if asur and is_instance_valid(asur) and asur.visible:
		var to_asur = asur.global_position - start_pos
		to_asur.y = 0.0
		var asur_dist = to_asur.length()
		if asur_dist <= 7.5:
			var dot = throw_dir.dot(to_asur.normalized())
			if dot >= 0.82:
				target_pos = asur.global_position
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
	
	# Check impact on Asur boss
	if asur and is_instance_valid(asur) and asur.visible:
		var dist = rock.global_position.distance_to(asur.global_position)
		if dist < 2.5:
			var grm = get_node_or_null("/root/GameRunManager")
			if grm and grm.has_method("record_boss_hit"):
				grm.record_boss_hit()
			if asur.has_method("take_rock_hit"):
				asur.take_rock_hit(85)
			elif asur.has_method("take_damage"):
				asur.take_damage(85)
			if hud_action:
				hud_action.text = "DIRECT HIT! The Asur is STUNNED by the rock!"
				get_tree().create_timer(2.5).timeout.connect(func():
					if is_instance_valid(hud_action) and hud_action.text == "DIRECT HIT! The Asur is STUNNED by the rock!":
						hud_action.text = ""
				)

			# Visceral stone impact feedback (Top game studio feel)
			_spawn_rubble_burst(rock.global_position)
			if camera_rig and camera_rig.has_method("shake"):
				camera_rig.shake(0.35, 18.0)

			# Clear interaction references
			if nearby_rock == rock:
				nearby_rock = null
			if held_rock == rock:
				held_rock = null

			# BOULDER SHATTERS ON IMPACT - consumed heavy ammunition!
			rock.queue_free()
			return

	# If the rock missed the boss and hit the ground intact
	_set_rock_collision_disabled(rock, false)
	
	# Spawn dust particles
	var dust = rock.get_node_or_null("ImpactDust")
	if dust is CPUParticles3D:
		dust.restart()
		dust.emitting = true

# -------------------------------------------------------------------------
# Destructible Pillars & Falling Rock Ammunition (Point A)
# -------------------------------------------------------------------------
var _dropped_rock_count: int = 0

func smash_pillar_direct(child: StaticBody3D) -> void:
	if not is_instance_valid(child):
		return
	if not ("Col1" in child.name or "Col3" in child.name or "Col5" in child.name):
		return
	if child.get_meta("is_broken", false):
		return
		
	child.set_meta("is_broken", true)
	if _glb_collision and _glb_collision.has_method("break_pillar"):
		_glb_collision.break_pillar(child)
	_spawn_rubble_burst(child.global_position)
	# Drop rock ammunition from the temple ceiling!
	_spawn_falling_rock(Vector3(child.global_position.x + randf_range(-0.4, 0.4), 4.5, child.global_position.z + 0.8))

func smash_nearby_pillars(epicenter: Vector3, radius: float = 7.5) -> void:
	var arena_props = get_node_or_null("ArenaProps")
	if not arena_props:
		return
	var pillars_node = arena_props.get_node_or_null("Pillars")
	if not pillars_node:
		return
		
	var smashed_any = false
	for child in pillars_node.get_children():
		if not (child is StaticBody3D):
			continue
		if child.get_meta("is_broken", false):
			continue
			
		var dist = Vector2(child.global_position.x - epicenter.x, child.global_position.z - epicenter.z).length()
		if dist <= radius:
			smash_pillar_direct(child)
			smashed_any = true

	# Boss Shockwave sweeps loose debris: crush any loose unheld rocks within slam radius
	var rocks_parent = get_node_or_null("ArenaProps/MovableRocks")
	var active_field_rock_count: int = 0
	if rocks_parent:
		for r in rocks_parent.get_children():
			if not (r is Node3D) or r.is_queued_for_deletion():
				continue
			if r == held_rock:
				continue
			var r_dist = r.global_position.distance_to(epicenter)
			if r_dist <= (radius * 0.7):
				_spawn_rubble_burst(r.global_position)
				if nearby_rock == r:
					nearby_rock = null
				r.queue_free()
			else:
				active_field_rock_count += 1

	# Robustness fallback: if fewer than 2 active rocks remain on the field and Asur is alive, drop ceiling tremor rock
	if active_field_rock_count < 2 and asur and is_instance_valid(asur) and asur.visible and ("health" in asur and asur.health > 0):
		_spawn_falling_rock(Vector3(randf_range(-2.5, 2.5), 4.5, randf_range(1.0, 5.0)))

func _spawn_rubble_burst(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 26
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.lifetime = 0.85
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 55.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 6.5
	particles.color = Color(0.78, 0.65, 0.5, 0.95)
	add_child(particles)
	particles.global_position = pos + Vector3(0, 0.5, 0)
	particles.emitting = true
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

func _spawn_falling_rock(spawn_pos: Vector3) -> void:
	var rocks_parent = get_node_or_null("ArenaProps/MovableRocks")
	if not rocks_parent:
		return
	if not _rock_template and rocks_parent.get_child_count() > 0:
		_rock_template = rocks_parent.get_child(0).duplicate()
	if not _rock_template:
		return
		
	_dropped_rock_count += 1
	var new_rock = _rock_template.duplicate()
	new_rock.name = "DroppedRock_%d" % _dropped_rock_count
	rocks_parent.add_child(new_rock)
	
	new_rock.global_position = spawn_pos
	
	if _glb_collision and _glb_collision.has_method("apply_rock_model"):
		_glb_collision.apply_rock_model(new_rock)
		
	var area = new_rock.get_node_or_null("InteractArea")
	if area:
		for conn in area.body_entered.get_connections():
			area.body_entered.disconnect(conn.callable)
		for conn in area.body_exited.get_connections():
			area.body_exited.disconnect(conn.callable)
		area.body_entered.connect(_on_rock_area_entered.bind(new_rock))
		area.body_exited.connect(_on_rock_area_exited.bind(new_rock))
		
	var prompt = new_rock.get_node_or_null("Prompt")
	if prompt:
		prompt.visible = false
		
	# Ballistic ceiling fall animation
	var tw = create_tween()
	tw.tween_property(new_rock, "global_position:y", 0.4, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var dust = new_rock.get_node_or_null("ImpactDust")
		if dust is CPUParticles3D:
			dust.restart()
			dust.emitting = true
		if camera_rig and camera_rig.has_method("shake"):
			camera_rig.shake(0.25, 14.0)
	)

# -------------------------------------------------------------------------
# Sacred Murti Blessing Reclaiming
# -------------------------------------------------------------------------
func _reclaim_blessing() -> void:
	blessing_in_progress = true
	blessing_claimed = true

	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_method("complete_level_3"):
		grm.complete_level_3()
	
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

	# Transition to End Storyline cutscene after divine celebration
	var tree = get_tree()
	if tree:
		tree.create_timer(3.2).timeout.connect(func():
			var end_storyline_path = "res://scenes/ui/end_storyline.tscn"
			if ResourceLoader.exists(end_storyline_path):
				var active_tree = get_tree()
				if active_tree:
					active_tree.change_scene_to_file(end_storyline_path)
		)

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

func _on_rock_area_entered(body: Node3D, rock: Node3D) -> void:
	if not is_instance_valid(player) or body != player:
		return
	if is_instance_valid(held_rock):
		return
	if "held_chota_asur" in player and is_instance_valid(player.held_chota_asur):
		return
	nearby_rock = rock
	var prompt = rock.get_node_or_null("Prompt")
	if prompt:
		prompt.visible = true
		prompt.text = "[E] Grab Rock"

func _on_rock_area_exited(body: Node3D, rock: Node3D) -> void:
	if not is_instance_valid(player) or body != player:
		return
	if nearby_rock == rock:
		nearby_rock = null
		var prompt = rock.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false

func _trigger_exit() -> void:
	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_method("complete_level_3") and not grm.level3_cleared:
		grm.complete_level_3()
	if dialogue_box and dialogue_label:
		dialogue_box.visible = true
		dialogue_label.text = "The castle gates are open. Faith and courage have dispelled the Asur's shadow."
	var end_storyline_path = "res://scenes/ui/end_storyline.tscn"
	if ResourceLoader.exists(end_storyline_path):
		var tree = get_tree()
		if tree:
			tree.create_timer(1.2).timeout.connect(func():
				var active_tree = get_tree()
				if active_tree:
					active_tree.change_scene_to_file(end_storyline_path)
			)
