extends Node

func _ready() -> void:
	print("========================================")
	print("--- ASUR GADHA & SPIKES TEST SUITE ---")
	print("========================================")
	
	# Wait for first physics frame so everything is initialized
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
	
	# -------------------------------------------------------------
	# Test 0b: Character & Boss Health Bar UI Components
	# -------------------------------------------------------------
	print("[1c] Checking Character & Boss Health Bar UI...")
	var hud = l3_map.get_node_or_null("UI/HUD")
	assert(hud != null, "UI/HUD must exist in L3Map")
	var char_bar = hud.get_node_or_null("CharacterHealthBar")
	assert(char_bar != null, "CharacterHealthBar must exist in UI/HUD")
	assert(char_bar.get_node_or_null("BarTexture") != null, "CharacterHealthBar must have BarTexture")
	
	var boss_bar = hud.get_node_or_null("AsurBossBar")
	assert(boss_bar != null, "AsurBossBar must exist in UI/HUD")
	assert(boss_bar.get_node_or_null("BarTexture") != null, "AsurBossBar must have BarTexture")
	print("PASSED: Both CharacterHealthBar and AsurBossBar instantiated in HUD")

	# Reset player health
	player.reset_health()
	assert(player.health == 3, "Player starts with 3 health")
	
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
	assert(asur.active_telegraph.duration >= 0.95, "Telegraph duration must be readable (>= 0.95s)")
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
	print("[4] Testing player damage from ground spikes...")
	# Position player directly in the path of the traveling spikes
	player.global_position = spawned_spikes.global_position + Vector3(0, 0, 0.5)
	spawned_spikes.has_damaged_player = false
	spawned_spikes._on_body_entered(player)
	
	print("Player health after spikes contact: ", player.health)
	assert(player.health == 2, "Player should take 1 damage from ground spikes!")
	assert(player.is_invulnerable, "Player should get i-frames after taking spikes damage")
	print("SUCCESS: Spikes damage player and trigger i-frames!")
	
	# -------------------------------------------------------------
	# Test 3: Attack / Punish Window Interruption by Hit & Hurt Animation
	# -------------------------------------------------------------
	print("[5] Testing punish window / attack interruption when Asur takes damage...")
	asur.current_state = asur.State.RECOVERY
	asur.recovery_timer = 1.0
	asur.take_damage(1)
	assert(asur.recovery_timer == 0.0, "Damage must clear recovery timer")
	assert(asur.current_state in [asur.State.HURT, asur.State.STAGGER, asur.State.ROAR], "Taking damage must enter HURT state")
	assert(asur_anim.animation == "hurt", "Asur must play hurt animation when hit by melee")
	print("SUCCESS: Melee hurt animation and attack interruption verified!")

	# -------------------------------------------------------------
	# Test 4: New Attack - Mega Earthquake Stomp Slam (Big Range)
	# -------------------------------------------------------------
	print("[6] Testing New Stomp Attack with MID-LONG RANGE (4.2m away)...")
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
	
	# Check for AsurQuake in the map
	var spawned_quake = null
	for child in l3_map.get_children():
		if child.name.begins_with("AsurQuake") or "max_radius" in child:
			spawned_quake = child
			break
				
	assert(spawned_quake != null, "AsurQuake must be spawned on stomp impact frame!")
	assert(spawned_quake.max_radius <= 5.5 and spawned_quake.max_radius >= 4.0, "Stomp quake must have balanced nerfed range")
	
	# Test jump evasion vs grounded hit
	# Expand quake radius to encompass player position at 4.2m
	spawned_quake.current_radius = 4.8
	
	# Case A: Jumping player (airborne) evades the ground tremor
	player.reset_health()
	player.velocity.y = 5.0
	player.global_position.y = 1.5
	spawned_quake.has_damaged_player = false
	spawned_quake._try_damage_player(player)
	assert(player.health == 3, "Jumping/airborne player should EVADE the ground earthquake shockwave!")
	print("SUCCESS: Airborne player safely evades ground tremor!")
	
	# Case B: Grounded player takes damage from the massive quake
	player.global_position.y = 0.05
	player.velocity.y = 0.0
	spawned_quake.has_damaged_player = false
	spawned_quake._try_damage_player(player)
	print("Player health after grounded quake hit: ", player.health)
	assert(player.health == 2, "Grounded player must take damage from the massive earthquake!")
	print("SUCCESS: Grounded player takes damage from big-range earthquake!")

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
	# Test 6: Rock Throw Stunned Animation with Dizzy Stars
	# -------------------------------------------------------------
	print("[9] Testing Rock Hit Stunned Animation (dizzy stars)...")
	asur.take_rock_hit(1)
	assert(asur.current_state == asur.State.STUN, "Rock hit must put Asur into STUN state")
	assert(asur_anim.animation == "stunned", "Asur must play stunned animation with dizzy stars")
	assert(asur.stun_timer > 0.0, "Stun timer must be running during stun")
	print("SUCCESS: Rock stun animation verified (Timer: ", asur.stun_timer, "s)")

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
	print("[9c] Testing Asur Nerfed Balance Stats...")
	assert(asur.attack_range <= 3.5, "Asur attack range must be nerfed (<= 3.5)")
	assert(asur.stomp_range <= 6.0, "Asur stomp range must be nerfed (<= 6.0)")
	assert(asur.attack_cooldown_duration >= 3.0, "Asur attack cooldown must be increased (>= 3.0)")
	assert(asur.telegraph_duration >= 1.2, "Asur telegraph duration must be increased (>= 1.2)")
	assert(asur.recovery_duration >= 1.8, "Asur recovery duration must be increased (>= 1.8)")
	assert(asur.stun_duration >= 2.8, "Asur stun duration must be increased (>= 2.8)")
	print("SUCCESS: Asur combat balance nerfed for fair and readable gameplay!")

	# -------------------------------------------------------------
	# Test 6d: Player Attack Impact and Damage to Asur
	# -------------------------------------------------------------
	print("[9d] Testing Player Attack Impact and Damage to Asur...")
	asur.current_state = asur.State.IDLE
	asur.health = 4
	# Position player facing Asur within axe reach (player at Z = -0.5, Asur at Z = -2.23)
	player.global_position = Vector3(0, 0.05, -0.5)
	player.current_direction = player.Direction.UP
	player.current_state = player.State.ATTACKING
	player.current_attack_type = "axe"
	player.has_hit_in_current_attack = false
	player._execute_attack_hit()
	await get_tree().physics_frame
	
	print("Asur HP after player axe strike: ", asur.health)
	assert(asur.health == 3, "Player axe attack must deal 1 damage to Asur!")
	assert(asur.current_state == asur.State.HURT, "Asur must enter HURT state upon being struck")
	assert(asur_anim.animation == "hurt", "Asur must play hurt animation when hit by player")
	print("SUCCESS: Player attack damage and hurt reaction verified!")

	# -------------------------------------------------------------
	# Test 7: Defeat and Rear Arena Barrier Unlocking
	# -------------------------------------------------------------
	print("[10] Testing Asur Defeat and Rear Arena Barrier Unlocking...")
	asur.health = 1
	asur.take_damage(1)
	assert(asur.health == 0, "Asur HP must reach 0 on final blow")
	await get_tree().physics_frame
	var defeat_rear_col = boundaries.get_node_or_null("AsurRearBarrier/CollisionShape3D")
	assert(defeat_rear_col != null, "AsurRearBarrier CollisionShape3D must exist")
	assert(defeat_rear_col.disabled == true, "AsurRearBarrier collision must be disabled upon defeat so player can reach the Sacred Murti!")
	print("SUCCESS: Defeat and rear barrier unlocking verified!")

	print("========================================")
	print("ALL ASUR COMBAT, STUN, CARRY & BARRIER TESTS PASSED!")
	print("========================================")
	get_tree().quit(0)
