extends Node

func _ready() -> void:
	print("========================================")
	print("--- ASUR GADHA, STOMP & SCALING TEST SUITE ---")
	print("========================================")
	
	# Ensure ground cracks procedural texture exists
	var cracks_script = load("res://scripts/enemy/asur_ground_cracks.gd")
	if cracks_script and cracks_script.has_method("ensure_ground_cracks_texture"):
		cracks_script.ensure_ground_cracks_texture()

	# Wait for physics frames so everything is initialized
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var root = get_parent()
	var l3_map = root.get_node_or_null("L3Map")
	if not l3_map:
		push_error("FAIL: L3Map not found!")
		get_tree().quit(1)
		return
	
	var asur = l3_map.get_node_or_null("Asur")
	if not asur:
		push_error("FAIL: Asur node not found in L3Map!")
		get_tree().quit(1)
		return
	
	var player = l3_map.get_node_or_null("Player")
	assert(player != null, "Player must exist in L3Map")
	
	print("[1] Asur instance found. Position: ", asur.global_position)
	assert(asur.visible, "Asur must be visible")
	
	var asur_anim: AnimatedSprite3D = asur.get_node_or_null("AnimatedSprite3D")
	assert(asur_anim != null, "Asur AnimatedSprite3D must exist")
	
	# -------------------------------------------------------------
	# Test 0: Level 3 South Gate & Rear Arena Boundary Constraints
	# -------------------------------------------------------------
	print("[1b] Checking South Gate and Rear Arena boundary collision constraints...")
	var boundaries = l3_map.get_node_or_null("Boundaries")
	assert(boundaries != null, "Boundaries container must exist")
	var south_gate = boundaries.get_node_or_null("WallSouthGate")
	assert(south_gate != null, "WallSouthGate collision boundary must exist to prevent falling off south gate")
	assert(abs(south_gate.position.z - 15.5) < 0.1, "WallSouthGate must seal the gap at Z = 15.5")
	print("PASSED: WallSouthGate verified at position: ", south_gate.position)
	
	var rear_barrier = boundaries.get_node_or_null("AsurRearBarrier")
	assert(rear_barrier != null, "AsurRearBarrier must exist to prevent player from going behind Asur")
	assert(abs(rear_barrier.position.z - (-2.6)) < 0.1, "AsurRearBarrier must seal the area behind Asur at Z = -2.6")
	var rear_col = rear_barrier.get_node_or_null("CollisionShape3D")
	assert(rear_col != null and not rear_col.disabled, "AsurRearBarrier must be active while Asur is alive")
	print("PASSED: AsurRearBarrier verified at position: ", rear_barrier.position)
	
	# Verify CameraRig has shake method
	var camera_rig = l3_map.get_node_or_null("CameraRig")
	assert(camera_rig != null, "CameraRig must exist in L3Map")
	assert(camera_rig.has_method("shake"), "CameraRig must implement shake method")
	camera_rig.shake(0.2, 10.0)
	assert(camera_rig._shake_timer > 0.0, "CameraRig shake timer must activate on shake()")
	print("PASSED: CameraRig shake method verified")
	
	# -------------------------------------------------------------
	# Test 0b: Character & Boss Health Bar UI Components
	# -------------------------------------------------------------
	print("[1c] Checking Character & Boss Health Bar UI and Numeric Readouts...")
	var hud = l3_map.get_node_or_null("UI/HUD")
	assert(hud != null, "UI/HUD must exist in L3Map")
	var char_bar = hud.get_node_or_null("CharacterHealthBar")
	assert(char_bar != null, "CharacterHealthBar must exist in UI/HUD")
	assert(char_bar.get_node_or_null("BarTexture") != null, "CharacterHealthBar must have BarTexture")
	var char_label = char_bar.get_node_or_null("HPText")
	assert(char_label != null, "CharacterHealthBar must have HPText numerical readout")
	assert("250" in char_label.text, "HPText must display 250 HP")
	
	var boss_bar = hud.get_node_or_null("AsurBossBar")
	assert(boss_bar != null, "AsurBossBar must exist in UI/HUD")
	assert(boss_bar.get_node_or_null("BarTexture") != null, "AsurBossBar must have BarTexture")
	var boss_label = boss_bar.get_node_or_null("BossHPText")
	assert(boss_label != null, "AsurBossBar must have BossHPText numerical readout")
	assert("1000" in boss_label.text, "BossHPText must display 1000 HP")
	print("PASSED: Both CharacterHealthBar and AsurBossBar instantiated with clean numerical text readouts")

	# Reset player health
	player.reset_health()
	assert(player.health == 250, "Player starts with 250 health")
	assert(asur.health == 1000, "Asur starts with 1000 health")
	print("PASSED: Scaled HP verified: Player 250 HP, Asur 1000 HP")
	
	# -------------------------------------------------------------
	# Test 1: Asur Gadha Attack and Ground Spikes Spawn
	# -------------------------------------------------------------
	print("[2] Testing Asur attack_down and ground spikes spawn...")
	asur.attack_cooldown = 0.0
	player.global_position = Vector3(0, 0.05, -0.5) # South of Asur (at Z = -2.23)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	assert(asur.current_state == asur.State.ATTACK, "Asur must trigger ATTACK when player is in range")
	print("Asur animation: ", asur_anim.animation)
	assert(asur_anim.animation == "attack_down", "Asur must play attack_down for frontal player")
	assert(asur.active_telegraph != null, "Asur must spawn a telegraph indicator during attack windup")
	assert(asur.active_telegraph.shape_type == asur.active_telegraph.ShapeType.RECTANGLE, "Gadha attack must use RECTANGLE telegraph lane")
	assert(asur.active_telegraph.fill_mesh != null, "Telegraph must contain dynamic FillMesh")
	assert(asur.active_telegraph.base_mesh != null, "Telegraph must contain static BaseFootprint")
	assert(asur.active_telegraph.fill_mat.albedo_color.r >= 0.75, "Telegraph fill must have deep dark danger red")
	assert(asur.active_telegraph.fill_mat.albedo_color.a >= 0.55, "Telegraph fill must be high contrast (alpha >= 0.55)")
	assert(asur.active_telegraph.duration >= 0.90, "Telegraph duration must be readable (>= 0.90s)")
	print("PASSED: Gadha attack telegraph lane verified (Width: ", asur.active_telegraph.width, " Length: ", asur.active_telegraph.length, ", Dark red fill: albedo=", asur.active_telegraph.fill_mat.albedo_color, ")")
	
	# Complete telegraph and advance to frame 3 (gadha impacts floor)
	asur._on_telegraph_completed()
	asur_anim.frame = 3
	asur._on_anim_frame_changed()
	await get_tree().physics_frame
	
	# Verify State.RECOVERY punish window
	assert(asur.current_state == asur.State.RECOVERY, "Asur must enter RECOVERY state after gadha slam impact")
	assert(asur.recovery_timer > 0.0, "Recovery timer must be active")
	print("PASSED: Asur entered RECOVERY punish window (Timer: ", asur.recovery_timer, "s)")
	
	# Check if AsurSpikes was instantiated in the map
	var spawned_spikes = null
	for child in l3_map.get_children():
		if child.name.begins_with("AsurSpikes") or child.is_in_group("enemy_attack"):
			spawned_spikes = child
			break
			
	assert(spawned_spikes != null, "AsurSpikes must be spawned in the arena on gadha impact!")
	print("[3] AsurSpikes successfully spawned at: ", spawned_spikes.global_position)
	assert(spawned_spikes.global_position.z > asur.global_position.z, "Spikes must spawn in front of Asur towards the player")
	
	# Test spikes traveling forward
	var initial_spikes_z = spawned_spikes.global_position.z
	for i in range(8):
		await get_tree().physics_frame
	assert(is_instance_valid(spawned_spikes), "Spikes should still be active during initial travel")
	var moved_spikes_z = spawned_spikes.global_position.z
	print("Spikes initial Z: ", initial_spikes_z, " -> Moved Z: ", moved_spikes_z)
	assert(moved_spikes_z > initial_spikes_z, "Spikes must travel forward along the floor!")
	print("SUCCESS: Ground spikes travel forward across the floor!")
	
	# -------------------------------------------------------------
	# Test 2: Damage from traveling spikes
	# -------------------------------------------------------------
	print("[4] Testing player damage from ground spikes (32 damage)...")
	# Reset player health and i-frames from previous slam strike
	player.reset_health()
	player.is_invulnerable = false
	# Position player directly in the path of the traveling spikes
	player.global_position = spawned_spikes.global_position + Vector3(0, 0, 0.5)
	spawned_spikes.has_damaged_player = false
	spawned_spikes._on_body_entered(player)
	
	print("Player health after spikes contact: ", player.health)
	assert(player.health == 218, "Player should take 32 damage from ground spikes! (250 - 32 = 218)")
	assert(player.is_invulnerable, "Player should get i-frames after taking spikes damage")
	print("SUCCESS: Spikes deal 32 damage to player and trigger i-frames!")
	
	# -------------------------------------------------------------
	# Test 3: Attack / Punish Window Interruption by Hit & Hurt Animation
	# -------------------------------------------------------------
	print("[5] Testing punish window / attack interruption when Asur takes damage...")
	asur.current_state = asur.State.RECOVERY
	asur.recovery_timer = 1.0
	asur.take_damage(40)
	assert(asur.recovery_timer == 0.0, "Damage must clear recovery timer")
	assert(asur.current_state in [asur.State.HURT, asur.State.STAGGER, asur.State.ROAR], "Taking damage must enter HURT state")
	assert(asur_anim.animation == "hurt", "Asur must play hurt animation when hit by melee")
	print("SUCCESS: Melee hurt animation and attack interruption verified!")

	# -------------------------------------------------------------
	# Test 4: New Attack - Mega Earthquake Stomp Slam & Ground Cracks VFX
	# -------------------------------------------------------------
	print("[6] Testing Stomp Attack with snappy 0.95s windup and ground cracks...")
	player.reset_health()
	asur.current_state = asur.State.IDLE
	asur.attack_cooldown = 0.0
	# Position player at 4.2m South of Asur (in stomp range between attack_range 3.2m and stomp_range 5.5m)
	player.global_position = asur.global_position + Vector3(0, 0.05, 4.2)
	
	for i in range(4):
		await get_tree().physics_frame
		
	print("Asur state after far player positioning: ", asur.current_state)
	print("Asur animation: ", asur_anim.animation)
	assert(asur.current_state == asur.State.ATTACK, "Asur must trigger big range attack when player is in stomp range")
	assert(asur_anim.animation == "stomp_down", "Asur must play stomp_down for long range frontal attack")
	assert(asur.active_telegraph != null, "Asur must spawn a circular telegraph indicator during stomp windup")
	assert(asur.active_telegraph.shape_type == asur.active_telegraph.ShapeType.CIRCLE, "Mega Stomp must use CIRCLE telegraph")
	assert(asur.active_telegraph.radius >= 4.5, "Stomp telegraph must cover radius >= 4.5m")
	assert(asur.active_telegraph.duration <= 1.0, "Stomp telegraph duration must be snappy (0.95s)")
	assert(asur.active_telegraph.fill_mesh != null, "Stomp telegraph must contain dynamic FillMesh")
	assert(asur.active_telegraph.fill_mat.albedo_color.r >= 0.75, "Stomp telegraph fill must have deep dark danger red")
	assert(asur.active_telegraph.fill_mat.albedo_color.a >= 0.55, "Stomp telegraph fill must be high contrast (alpha >= 0.55)")
	print("PASSED: Mega Stomp circular telegraph zone verified (Radius: ", asur.active_telegraph.radius, ", Dark red fill: albedo=", asur.active_telegraph.fill_mat.albedo_color, ")")
	
	# Complete telegraph and advance to Frame 4 (earth slam impact)
	asur._on_telegraph_completed()
	asur_anim.frame = 4
	asur._on_anim_frame_changed()
	await get_tree().physics_frame
	
	# Verify recovery punish window on stomp impact
	assert(asur.current_state == asur.State.RECOVERY, "Asur must enter RECOVERY state after stomp impact")
	print("PASSED: Asur entered RECOVERY punish window after stomp impact")
	
	# Check for AsurGroundCracks decal in the map
	var spawned_cracks = null
	for child in l3_map.get_children():
		if child.name.begins_with("AsurGroundCracks") or child.get_node_or_null("CracksDecal") != null:
			spawned_cracks = child
			break
	assert(spawned_cracks != null, "AsurGroundCracks decal must be stamped on stomp floor impact!")
	print("PASSED: AsurGroundCracks decal successfully stamped at epicenter!")

	# Check for AsurQuake in the map
	var spawned_quake = null
	for child in l3_map.get_children():
		if child.name.begins_with("AsurQuake") or "max_radius" in child:
			spawned_quake = child
			break
				
	assert(spawned_quake != null, "AsurQuake must be spawned on stomp impact frame!")
	assert(spawned_quake.max_radius <= 5.5 and spawned_quake.max_radius >= 4.0, "Stomp quake must have balanced range")
	
	# Test jump evasion vs grounded hit
	# Expand quake radius to encompass player position at 4.2m
	spawned_quake.current_radius = 4.8
	
	# Case A: Jumping player (airborne) evades the ground tremor
	player.reset_health()
	player.velocity.y = 5.0
	player.global_position.y = 1.5
	spawned_quake.has_damaged_player = false
	spawned_quake._try_damage_player(player)
	assert(player.health == 250, "Jumping/airborne player should EVADE the ground earthquake shockwave!")
	print("SUCCESS: Airborne player safely evades ground tremor!")
	
	# Case B: Grounded player takes 50 damage from the massive quake
	player.global_position.y = 0.05
	player.velocity.y = 0.0
	spawned_quake.has_damaged_player = false
	spawned_quake._try_damage_player(player)
	print("Player health after grounded quake hit: ", player.health)
	assert(player.health == 200, "Grounded player must take 50 damage from the massive earthquake! (250 - 50 = 200)")
	print("SUCCESS: Grounded player takes 50 damage from big-range earthquake!")

	# -------------------------------------------------------------
	# Test 5: Uninterrupted Recovery to Idle and Cooldown
	# -------------------------------------------------------------
	print("[8] Testing uninterrupted recovery back to IDLE with cooldown...")
	asur.current_state = asur.State.RECOVERY
	asur.recovery_timer = 0.05
	for i in range(5):
		await get_tree().physics_frame
	assert(asur.current_state == asur.State.IDLE, "Asur must return to IDLE after recovery finishes")
	assert(asur.attack_cooldown > 0.0, "Asur must enter attack cooldown after recovery finishes")
	print("SUCCESS: Recovery to IDLE with attack cooldown verified!")

	# -------------------------------------------------------------
	# Test 6: Rock Throw Stunned Animation with Dizzy Stars & 85 Damage
	# -------------------------------------------------------------
	print("[9] Testing Rock Hit Stunned Animation and 85 Damage...")
	var hp_before_rock = asur.health
	asur.take_rock_hit(85)
	assert(asur.health == hp_before_rock - 85, "Rock hit must deal 85 damage to Asur!")
	assert(asur.current_state == asur.State.STUN, "Rock hit must put Asur into STUN state")
	assert(asur_anim.animation == "stunned", "Asur must play stunned animation with dizzy stars")
	assert(asur.stun_timer > 0.0 and asur.stun_timer <= 2.3, "Stun timer must be running during stun (~2.2s)")
	print("SUCCESS: Rock stun animation and 85 damage verified (Timer: ", asur.stun_timer, "s)")

	# -------------------------------------------------------------
	# Test 6b: Player 4-Direction Rock Carry Animations
	# -------------------------------------------------------------
	print("[9b] Testing Player 4-Direction Rock Carry Animations...")
	var player_anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	assert(player_anim != null, "Player AnimatedSprite3D must exist")
	player.is_carrying = true
	player.is_walking = false
	player.is_jumping = false
	
	# Direction DOWN
	player.current_direction = player.Direction.DOWN
	player._update_animation()
	assert(player_anim.animation == "carry_down", "Player must play carry_down when facing DOWN")
	
	# Direction UP
	player.current_direction = player.Direction.UP
	player._update_animation()
	assert(player_anim.animation == "carry_up", "Player must play carry_up when facing UP")
	
	# Direction LEFT
	player.current_direction = player.Direction.LEFT
	player._update_animation()
	assert(player_anim.animation == "carry_left", "Player must play carry_left when facing LEFT")
	
	# Direction RIGHT
	player.current_direction = player.Direction.RIGHT
	player._update_animation()
	assert(player_anim.animation == "carry_right", "Player must play carry_right when facing RIGHT")
	
	player.is_carrying = false
	player._update_animation()
	print("SUCCESS: 4-Direction Rock Carry animations verified (carry_down, carry_up, carry_left, carry_right)!")

	# -------------------------------------------------------------
	# Test 6c: Asur Nerfed Balance Stats
	# -------------------------------------------------------------
	print("[9c] Testing Asur Pacing & Balance Stats...")
	assert(asur.attack_range <= 3.5, "Asur attack range must be reasonable (<= 3.5)")
	assert(asur.stomp_range <= 6.0, "Asur stomp range must be reasonable (<= 6.0)")
	assert(asur.attack_cooldown_duration >= 2.5, "Asur attack cooldown must be >= 2.5")
	assert(asur.telegraph_duration <= 1.0 and asur.telegraph_duration >= 0.9, "Asur telegraph duration must be 0.95s")
	assert(asur.recovery_duration >= 1.8, "Asur recovery duration must be >= 1.8")
	assert(asur.stun_duration <= 2.5 and asur.stun_duration >= 2.0, "Asur stun duration must be 2.2s")
	print("SUCCESS: Asur combat balance verified for responsive gameplay!")

	# -------------------------------------------------------------
	# Test 6d: Player Attack Impact and 40 Damage to Asur
	# -------------------------------------------------------------
	print("[9d] Testing Player Attack Impact and 40 Damage to Asur...")
	asur.current_state = asur.State.IDLE
	asur.health = 1000
	asur.hurt_grace_timer = 0.0
	# Position player facing Asur within axe reach (player at Z = -0.5, Asur at Z = -2.23)
	player.global_position = Vector3(0, 0.05, -0.5)
	player.current_direction = player.Direction.UP
	player.current_state = player.State.ATTACKING
	player.current_attack_type = "axe"
	player.has_hit_in_current_attack = false
	player._execute_attack_hit()
	await get_tree().physics_frame
	
	print("Asur HP after player axe strike: ", asur.health)
	assert(asur.health == 960, "Player axe attack must deal 40 damage to Asur! (1000 - 40 = 960)")
	assert(asur.current_state == asur.State.HURT, "Asur must enter HURT state upon being struck")
	assert(asur_anim.animation == "hurt", "Asur must play hurt animation when hit by player")
	print("SUCCESS: Player attack 40 damage and hurt reaction verified!")

	# -------------------------------------------------------------
	# Test 6e: Destructible Pillars and Falling Rock Drops (Point A)
	# -------------------------------------------------------------
	print("[9e] Testing Destructible Pillars and Falling Rock Ammunition...")
	var rocks_container = l3_map.get_node_or_null("ArenaProps/MovableRocks")
	var initial_rock_count = rocks_container.get_child_count() if rocks_container else 0
	
	var col1_l = l3_map.get_node_or_null("ArenaProps/Pillars/Col1_L")
	assert(col1_l != null, "Col1_L pillar must exist in ArenaProps/Pillars")
	
	# Trigger smash near Col1_L
	l3_map.smash_nearby_pillars(col1_l.global_position, 3.5)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	assert(col1_l.get_meta("is_broken", false) == true, "Col1_L pillar must be marked as broken")
	assert(rocks_container.get_child_count() > initial_rock_count, "Smashing pillar must drop new falling rock into MovableRocks!")
	print("SUCCESS: Destructible pillar fracture and falling rock replenishment verified!")

	# -------------------------------------------------------------
	# Test 6f: Asur Hurt Loop Prevention and Stomp Cooldown
	# -------------------------------------------------------------
	print("[9f] Testing Asur Hurt Grace Window & Stomp Cooldown...")
	asur.health = 960
	asur.current_state = asur.State.HURT
	asur.hurt_grace_timer = 0.35
	# Rapid second hit while in hurt grace window
	asur.take_damage(40)
	assert(asur.health == 960, "Rapid hit during hurt grace window must not apply damage loop!")
	
	# Finish hurt animation
	asur._on_animation_finished()
	assert(asur.current_state == asur.State.IDLE, "Asur must return to IDLE after hurt animation finishes")
	assert(asur.hurt_timer == 0.0, "hurt_timer must reset upon animation finished")
	
	# Check stomp cooldown
	asur.attack_stomp()
	assert(asur.stomp_cooldown >= 6.0, "Mega Stomp must incur stomp_cooldown >= 6.0s")
	print("SUCCESS: Hurt grace window and stomp cooldown verified!")

	# -------------------------------------------------------------
	# Test 6g: Chota Asur Minions System & Attack Arbitration
	# -------------------------------------------------------------
	print("[9g] Testing Chota Asur Spawning, Health Bar & Attack Arbitration...")
	l3_map.minion_spawn_timer = 999.0
	for old_m in l3_map.active_chota_asurs.duplicate():
		l3_map._on_minion_died(old_m)
		old_m.queue_free()
	l3_map.active_chota_asurs.clear()
	var minion = l3_map.spawn_chota_asur(Vector3(0, 0, 5.0))
	assert(minion != null, "spawn_chota_asur must instantiate minion")
	assert(minion.max_health == 60, "Chota Asur max health must be 60")
	assert(minion.health == 60, "Chota Asur health must start at 60")
	assert(minion.assigned_slot == 0, "First minion must be assigned slot 0")
	assert(l3_map.active_chota_asurs.size() == 1, "active_chota_asurs must have 1 minion")
	
	# Test Attack Token Arbitration
	var token1 = l3_map.request_attack_token(minion)
	assert(token1 == true, "First requester must be granted attack token")
	
	# Fake peer requester
	var dummy_peer = Node3D.new()
	var token2 = l3_map.request_attack_token(dummy_peer)
	assert(token2 == false, "Arbitration must deny second attacker while token is held!")
	
	# Release token
	l3_map.release_attack_token(minion)
	var token3 = l3_map.request_attack_token(dummy_peer)
	assert(token3 == true, "Arbitration must grant token after release")
	l3_map.release_attack_token(dummy_peer)
	dummy_peer.queue_free()
	
	# Test damage to minion and health bar update
	minion.take_damage(40)
	assert(minion.health == 20, "Minion taking 40 damage should have 20 HP left (60 - 40 = 20)")
	assert(minion.health_bar != null, "Minion must have HealthBar Sprite3D")
	print("PASSED: Minion health reduced to 20/60 and health bar updated!")
	
	# Kill minion
	minion.take_damage(20)
	assert(minion.health == 0, "Minion health must reach 0")
	assert(minion.current_state == minion.State.DEAD, "Minion must enter DEAD state on 0 HP")
	print("SUCCESS: Chota Asur tactical slot, health, and arbitration verified!")

	# -------------------------------------------------------------
	# Test 6h: Key Remappings (F/G Attack, E Grab & Interact)
	# -------------------------------------------------------------
	print("[9h] Testing Key Remappings (F=Axe, G=Rope, E=Interact/Grab)...")
	var axe_events = InputMap.action_get_events("attack_axe")
	var has_f = false
	for ev in axe_events:
		if ev is InputEventKey and (ev.physical_keycode == KEY_F or ev.keycode == KEY_F):
			has_f = true
	assert(has_f, "attack_axe action must include KEY_F")

	var rope_events = InputMap.action_get_events("attack_rope")
	var has_g = false
	for ev in rope_events:
		if ev is InputEventKey and (ev.physical_keycode == KEY_G or ev.keycode == KEY_G):
			has_g = true
	assert(has_g, "attack_rope action must include KEY_G")

	var interact_events = InputMap.action_get_events("interact")
	var has_e = false
	for ev in interact_events:
		if ev is InputEventKey and (ev.physical_keycode == KEY_E or ev.keycode == KEY_E):
			has_e = true
	assert(has_e, "interact action must include KEY_E")
	print("PASSED: Key remappings verified (F for Axe, G for Rope, E for Interact/Grab)!")

	# -------------------------------------------------------------
	# Test 6i: Player Attack Loop Safety and Cooldown
	# -------------------------------------------------------------
	print("[9i] Testing Player Attack Loop Safety & Cooldown...")
	player.current_state = player.State.IDLE_WALK
	player.attack_cooldown_timer = 0.0
	player.attack("axe")
	assert(player.current_state == player.State.ATTACKING, "Player should enter ATTACKING state")
	assert(player.attack_duration_timer > 0.0, "attack_duration_timer must be active as safety timeout")
	
	# Simulate animation finish
	player._on_animation_finished()
	assert(player.current_state == player.State.IDLE_WALK, "Player must return to IDLE_WALK without loop lock")
	assert(player.attack_cooldown_timer > 0.0, "Player must enter attack cooldown to prevent spam")
	
	# Attempt spam attack while on cooldown
	player.attack("axe")
	assert(player.current_state == player.State.IDLE_WALK, "Attack spam while on cooldown must be rejected")
	print("PASSED: Player attack loop safely breaks and attack cooldown prevents spam!")

	# -------------------------------------------------------------
	# Test 6j: Asur Dynamic Aggression Scaling (Phases 1, 2, 3)
	# -------------------------------------------------------------
	print("[9j] Testing Asur Dynamic Aggression Scaling...")
	asur.health = 1000
	asur._update_aggression_phase()
	assert(asur.current_phase == 1, "Asur must start at Phase 1 at full health")
	assert(asur.attack_cooldown_duration == 2.8, "Phase 1 attack cooldown must be 2.8s")
	assert(asur.stomp_cooldown_duration == 7.0, "Phase 1 stomp cooldown must be 7.0s")
	assert(asur.telegraph_duration == 0.95, "Phase 1 telegraph duration must be 0.95s")

	# Damage to 650 (Phase 2: <= 70% HP = <= 700)
	asur.hurt_grace_timer = 0.0
	asur.take_damage(350)
	assert(asur.health == 650, "Asur HP should be 650")
	assert(asur.current_phase == 2, "Asur must transition to Phase 2 at 65% HP")
	assert(asur.attack_cooldown_duration == 1.8, "Phase 2 attack cooldown must be 1.8s (35% faster)")
	assert(asur.stomp_cooldown_duration == 4.8, "Phase 2 stomp cooldown must be 4.8s")
	assert(asur.telegraph_duration == 0.75, "Phase 2 telegraph duration must be 0.75s")

	# Damage to 300 (Phase 3: <= 35% HP = <= 350)
	asur.hurt_grace_timer = 0.0
	asur.take_damage(350)
	assert(asur.health == 300, "Asur HP should be 300")
	assert(asur.current_phase == 3, "Asur must transition to Phase 3 Frenzy at 30% HP")
	assert(asur.attack_cooldown_duration == 1.15, "Phase 3 attack cooldown must be 1.15s (frenzy)")
	assert(asur.stomp_cooldown_duration == 3.2, "Phase 3 stomp cooldown must be 3.2s")
	assert(asur.telegraph_duration == 0.55, "Phase 3 telegraph duration must be 0.55s")
	print("PASSED: Asur scales aggression dynamically across all 3 HP phases!")

	# -------------------------------------------------------------
	# Test 6k: Smooth Health Bar Numeric & Visual Animations
	# -------------------------------------------------------------
	print("[9k] Testing Smooth Health Bar Animations...")
	char_bar.current_hp = 250
	char_bar.displayed_hp = 250.0
	char_bar.update_health(180, 250)
	assert(char_bar.current_hp == 180, "char_bar current_hp must update to target 180")
	# Check smooth tween interpolation during progress
	await get_tree().create_timer(0.12).timeout
	assert(char_bar.displayed_hp < 250.0 and char_bar.displayed_hp >= 180.0, "char_bar displayed_hp must smoothly interpolate towards target HP")
	await get_tree().create_timer(0.35).timeout
	assert(abs(char_bar.displayed_hp - 180.0) < 1.0, "char_bar displayed_hp must reach 180 upon tween completion")
	print("PASSED: Smooth health bar interpolation verified!")

	# -------------------------------------------------------------
	# Test 7: Defeat and Rear Arena Barrier Unlocking
	# -------------------------------------------------------------
	print("[10] Testing Asur Defeat and Rear Arena Barrier Unlocking...")
	asur.health = 40
	asur.hurt_grace_timer = 0.0
	asur.take_damage(40)
	assert(asur.health == 0, "Asur HP must reach 0 on final blow")
	await get_tree().physics_frame
	var defeat_rear_col = boundaries.get_node_or_null("AsurRearBarrier/CollisionShape3D")
	assert(defeat_rear_col != null, "AsurRearBarrier CollisionShape3D must exist")
	assert(defeat_rear_col.disabled == true, "AsurRearBarrier collision must be disabled upon defeat so player can reach the Sacred Murti!")
	print("SUCCESS: Defeat and rear barrier unlocking verified!")

	print("========================================")
	print("ALL ASUR COMBAT, HURT RECOVERY, STOMP COOLDOWN, CHOTA ASUR & PILLAR SMASH TESTS PASSED!")
	print("========================================")
	get_tree().quit(0)
