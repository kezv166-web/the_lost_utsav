extends Node

var player: CharacterBody3D
var step: int = 0
var timer: float = 0.0
var screenshot_overlook_taken: bool = false
var screenshot_bridge_taken: bool = false
var screenshot_gate_taken: bool = false
var balustrade_tested: bool = false

var verified_walk_up: bool = false
var verified_walk_left: bool = false
var verified_walk_right: bool = false
var verified_walk_down: bool = false
var verified_idle: bool = false
var verified_jump_up: bool = false
var verified_jump_right: bool = false
var screenshot_jump_taken: bool = false
var verified_attack_axe: bool = false
var verified_attack_rope: bool = false
var screenshot_axe_taken: bool = false
var screenshot_rope_taken: bool = false
var screenshot_jump_rail_taken: bool = false
var screenshot_rock_taken: bool = false
var screenshot_firebox_taken: bool = false
var verified_firebox_collision: bool = false
var verified_rock_collision: bool = false
var screenshot_spikes_taken: bool = false
var screenshot_side_map_taken: bool = false
var screenshot_plaza_south_balustrade_taken: bool = false

func _save_screenshot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var vp = get_viewport()
	if vp:
		var tex = vp.get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("res://assets/temp/" + filename)

const AssetExtractor = preload("res://scripts/extract_assets.gd")

func _ready() -> void:
	AssetExtractor.extract_assets_now()
	player = get_parent().get_node_or_null("Player")
	print("--- TEST HARNESS INITIALIZED ---")
	if player:
		print("Player start position: ", player.global_position)
		if player.has_node("AnimatedSprite3D"):
			var anim_node: AnimatedSprite3D = player.get_node("AnimatedSprite3D")
			print("Player AnimatedSprite3D found, initial anim: ", anim_node.animation)
		else:
			push_error("FAIL: AnimatedSprite3D not found on Player!")

	# Verify Animated Braziers in the Outdoor Map
	var overlook_brazier = get_parent().get_node_or_null("Overlook/OverlookBrazierL/Sprite")
	if overlook_brazier is AnimatedSprite3D:
		assert(overlook_brazier.billboard == 2, "Brazier must use Y-Billboard (2)")
		assert(overlook_brazier.texture_filter == 0, "Brazier must use nearest texture filtering (0)")
		assert(overlook_brazier.sprite_frames != null, "Brazier sprite_frames must not be null")
		assert(overlook_brazier.sprite_frames.get_frame_count("default") == 8, "Brazier must have 8 animated frames")
		print("PASSED: Overlook brazier AnimatedSprite3D verified (8 frames, billboard=2, filter=0)")
	else:
		push_error("FAIL: OverlookBrazierL/Sprite is not an AnimatedSprite3D!")

	var bridge_torch = get_parent().get_node_or_null("Bridge/PostsAndTorches/TorchL1/FlameSprite")
	if bridge_torch is AnimatedSprite3D:
		assert(bridge_torch.billboard == 2, "Bridge torch must use Y-Billboard (2)")
		assert(bridge_torch.texture_filter == 0, "Bridge torch must use nearest texture filtering (0)")
		assert(bridge_torch.sprite_frames != null, "Bridge torch sprite_frames must not be null")
		assert(bridge_torch.sprite_frames.get_frame_count("default") == 8, "Bridge torch must have 8 animated frames")
		print("PASSED: Bridge torch FlameSprite AnimatedSprite3D verified (8 frames, billboard=2, filter=0)")
	else:
		push_error("FAIL: TorchL1/FlameSprite is not an AnimatedSprite3D!")

	var keep_brazier = get_parent().get_node_or_null("Fortress/CitadelKeepSanctum/KeepBrazierCenter")
	if keep_brazier is AnimatedSprite3D:
		assert(keep_brazier.billboard == 2, "Keep brazier must use Y-Billboard (2)")
		assert(keep_brazier.texture_filter == 0, "Keep brazier must use nearest texture filtering (0)")
		assert(keep_brazier.sprite_frames != null, "Keep brazier sprite_frames must not be null")
		assert(keep_brazier.sprite_frames.get_frame_count("default") == 8, "Keep brazier must have 8 animated frames")
		print("PASSED: Citadel Keep brazier AnimatedSprite3D verified (8 frames, billboard=2, filter=0)")
	# Verify 2D Object Constraints in Outdoor Map
	var required_constraints = [
		"Overlook/RockClusterL",
		"Overlook/RockClusterR",
		"Overlook/RockSmall",
		"Overlook/DeadTree",
		"Overlook/OverlookBrazierL",
		"Overlook/OverlookBrazierR",
		"Overlook/OverlookSpikesL",
		"Overlook/OverlookSpikesR",
		"Bridge/PostsAndTorches/TorchL1",
		"Bridge/PostsAndTorches/TorchR1",
		"Bridge/PostsAndTorches/TorchL2",
		"Bridge/PostsAndTorches/TorchR2",
		"Bridge/PostsAndTorches/PostMidL",
		"Bridge/PostsAndTorches/PostMidR",
		"Plaza/PlazaBrazierL",
		"Plaza/PlazaBrazierR",
		"Plaza/PlazaRockCornerL",
		"Plaza/PlazaRockCornerR",
		"Plaza/PlazaSpikesL",
		"Plaza/PlazaSpikesR",
		"Plaza/PlazaLeftBalustrade",
		"Plaza/PlazaRightBalustrade",
		"Fortress/SealedGate/GateDoor",
		"Fortress/SealedGate/StatueBarrierL",
		"Fortress/SealedGate/StatueBarrierR",
		"Fortress/SealedGate/GateBrazierL",
		"Fortress/SealedGate/GateBrazierR"
	]
	for path in required_constraints:
		var node = get_parent().get_node_or_null(path)
		assert(node != null, "Constraint node must exist: " + path)
		assert(node is StaticBody3D, "Node must be StaticBody3D: " + path)
		assert(node.has_node("CollisionShape3D"), "Node must have CollisionShape3D: " + path)
		var col: CollisionShape3D = node.get_node("CollisionShape3D")
		assert(col.shape != null, "CollisionShape3D shape must not be null: " + path)
	print("PASSED: All 27 2D object & balustrade constraints verified!")

	var gate_black_screen = get_parent().get_node_or_null("Fortress/SealedGate/GateBlackScreen")
	assert(gate_black_screen != null, "GateBlackScreen node must exist behind GateDoor!")
	assert(gate_black_screen is CSGBox3D, "GateBlackScreen must be a CSGBox3D!")
	assert(gate_black_screen.size.x <= 4.5 and gate_black_screen.size.y <= 6.0, "GateBlackScreen must be sized specifically to door opening (width <= 4.5, height <= 6.0)")
	assert(get_parent().get_node_or_null("Plaza/LeftOccluder") == null, "Plaza/LeftOccluder must be removed so sky and background are visible")
	assert(get_parent().get_node_or_null("Plaza/RightOccluder") == null, "Plaza/RightOccluder must be removed so sky and background are visible")
	print("PASSED: GateBlackScreen occlusion backdrop verified strictly behind door portal, and side occluders removed!")

func _physics_process(delta: float) -> void:
	timer += delta
	
	if not player:
		return
		
	var anim_node: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	
	# Initial frame: Capture starting Overlook view
	if timer >= 0.3 and not screenshot_overlook_taken:
		screenshot_overlook_taken = true
		_save_screenshot("screenshot_overlook.png")

	# Phase 0a (0.5s - 1.5s): Walk UP & LEFT into RockSmall to verify Rock constraint
	if timer >= 0.5 and timer < 1.5:
		Input.action_press("move_left")
		if timer < 0.9:
			Input.action_press("move_up")
		else:
			Input.action_release("move_up")
		if anim_node and anim_node.animation == "walk_left" and not verified_walk_left:
			verified_walk_left = true
			print("PASSED: Walk LEFT animation verified ('walk_left')")
		if timer >= 1.3 and not verified_rock_collision:
			verified_rock_collision = true
			print("Rock collision check: Player pos=(%.2f, %.2f, %.2f) (Blocked by RockSmall)" % [player.global_position.x, player.global_position.y, player.global_position.z])
			assert(player.global_position.x > -3.3, "Player should be blocked by RockSmall constraint!")
			_save_screenshot("screenshot_rock_collision.png")
			print("PASSED: Rock constraint verified!")

	# Phase 0b (1.5s - 2.5s): Walk UP directly into OverlookBrazierL (Fire Box)
	elif timer >= 1.5 and timer < 2.5:
		Input.action_release("move_left")
		Input.action_press("move_up")
		if anim_node and anim_node.animation == "walk_up" and not verified_walk_up:
			verified_walk_up = true
			print("PASSED: Walk UP animation verified ('walk_up')")
		if timer >= 2.3 and not verified_firebox_collision:
			verified_firebox_collision = true
			print("Fire box collision check: Player pos=(%.2f, %.2f, %.2f) (Blocked by OverlookBrazierL)" % [player.global_position.x, player.global_position.y, player.global_position.z])
			assert(player.global_position.z > 14.1, "Player should be blocked by OverlookBrazierL fire box constraint!")
			_save_screenshot("screenshot_firebox_collision.png")
			print("PASSED: Fire box constraint verified!")

	# Phase 0c (2.5s - 3.5s): Walk LEFT into OverlookSpikesL (Spikes Barrier)
	elif timer >= 2.5 and timer < 3.5:
		Input.action_release("move_up")
		Input.action_press("move_left")
		if timer >= 3.2 and not screenshot_spikes_taken:
			screenshot_spikes_taken = true
			print("Spikes collision check: Player pos=(%.2f, %.2f, %.2f) (Blocked by OverlookSpikesL)" % [player.global_position.x, player.global_position.y, player.global_position.z])
			assert(player.global_position.x > -4.2, "Player should be blocked by OverlookSpikesL spike constraint!")
			_save_screenshot("screenshot_spikes_collision.png")
			print("PASSED: Spikes constraint verified!")

	# Phase 0d (3.5s - 4.5s): Walk RIGHT + Jump RIGHT towards Overlook center
	elif timer >= 3.5 and timer < 4.5:
		Input.action_release("move_left")
		Input.action_press("move_right")
		if anim_node and anim_node.animation == "walk_right" and not verified_walk_right:
			verified_walk_right = true
			print("PASSED: Walk RIGHT animation verified ('walk_right')")
		if timer >= 3.8 and timer < 3.9:
			Input.action_press("jump")
		elif timer >= 3.9:
			Input.action_release("jump")
			if anim_node and anim_node.animation == "jump_right" and not verified_jump_right:
				verified_jump_right = true
				print("PASSED: Jump RIGHT animation verified ('jump_right', airborne Y=%.2f)" % player.global_position.y)
				if not screenshot_jump_taken:
					screenshot_jump_taken = true
					_save_screenshot("screenshot_jump.png")

	# Phase 0e (4.5s - 5.5s): Jump UP while walking UP
	elif timer >= 4.5 and timer < 5.5:
		Input.action_release("move_right")
		Input.action_press("move_up")
		if timer >= 4.7 and timer < 4.8:
			Input.action_press("jump")
		elif timer >= 4.8:
			Input.action_release("jump")
			if anim_node and anim_node.animation == "jump_up" and not verified_jump_up:
				verified_jump_up = true
				print("PASSED: Jump UP animation verified ('jump_up', airborne Y=%.2f)" % player.global_position.y)

	# Phase 0f (5.5s - 6.5s): Walk DOWN & IDLE
	elif timer >= 5.5 and timer < 6.5:
		Input.action_release("move_up")
		if timer < 6.0:
			Input.action_press("move_down")
			if anim_node and anim_node.animation == "walk_down" and not verified_walk_down:
				verified_walk_down = true
				print("PASSED: Walk DOWN animation verified ('walk_down')")
		else:
			Input.action_release("move_down")
			if anim_node and anim_node.animation == "idle_down" and not verified_idle:
				verified_idle = true
				print("PASSED: Idle transition verified ('idle_down')")

	# Phase 1 (6.5s - 9.5s): Walk from Overlook onto Bridge
	elif timer >= 6.5 and timer < 9.5:
		Input.action_press("move_up")

	# Phase 2 (9.5s - 11.0s): Test Bridge Balustrade jump constraint (airborne collision)
	elif timer >= 9.5 and timer < 11.0:
		Input.action_release("move_up")
		Input.action_press("move_left")
		if timer >= 9.8 and timer < 9.9:
			Input.action_press("jump")
		elif timer >= 9.9:
			Input.action_release("jump")
			if timer >= 10.0 and not screenshot_jump_rail_taken:
				screenshot_jump_rail_taken = true
				_save_screenshot("screenshot_jump_rail.png")
		if not balustrade_tested and timer > 10.6:
			balustrade_tested = true
			print("Balustrade collision check (ground + airborne jump): Player X=%.2f, Y=%.2f (Stopped by balustrade at X > -2.2m)" % [player.global_position.x, player.global_position.y])
			assert(player.global_position.x > -2.2, "Player should be blocked by bridge balustrade even when jumping!")

	# Phase 3 (11.0s - 16.5s): Walk North across Bridge into Plaza and Gate
	elif timer >= 11.0 and timer < 16.5:
		Input.action_release("move_left")
		Input.action_press("move_up")
		if timer >= 13.0 and not screenshot_bridge_taken:
			screenshot_bridge_taken = true
			_save_screenshot("screenshot_bridge.png")
			_save_screenshot("screenshot_bridge_firebox.png")

	# Phase 4 (16.5s - 17.5s): Push against Sealed Gate Door
	elif timer >= 16.5 and timer < 17.5:
		if not screenshot_gate_taken:
			screenshot_gate_taken = true
			print("Pushing against sealed gate door: (Z=%.2f)" % player.global_position.z)
			Input.action_release("move_up")
			_save_screenshot("screenshot_gate.png")
			_save_screenshot("screenshot_gate_collision.png")
			_save_screenshot("screenshot_gate_blackscreen.png")
			assert(player.global_position.z > -23.2, "Player should be blocked by the sealed gate door at Z > -23.2!")
			print("PASSED: Sealed gate constraint verified!")

	# Phase 4b (17.5s - 18.2s): Back up into the open Gate Plaza
	elif timer >= 17.5 and timer < 18.2:
		Input.action_press("move_down")

	# Phase 5 (18.2s - 19.5s): Combat Attack - Parashu (Axe) on Q
	elif timer >= 18.2 and timer < 19.5:
		Input.action_release("move_down")
		if timer < 18.3:
			Input.action_press("attack_axe")
		else:
			Input.action_release("attack_axe")
			
		if anim_node and "attack_axe" in str(anim_node.animation):
			if not verified_attack_axe:
				verified_attack_axe = true
				print("PASSED: Parashu Axe attack verified ('%s', frame %d, pos=%s)" % [anim_node.animation, anim_node.frame, str(player.global_position)])
			if timer >= 18.45 and not screenshot_axe_taken:
				screenshot_axe_taken = true
				_save_screenshot("screenshot_attack_axe.png")

	# Phase 6 (19.5s - 21.0s): Combat Attack - Pāśa (Rope) on E
	elif timer >= 19.5 and timer < 21.0:
		if timer < 19.6:
			Input.action_press("attack_rope")
		else:
			Input.action_release("attack_rope")
			
		if anim_node and "attack_rope" in str(anim_node.animation):
			if not verified_attack_rope:
				verified_attack_rope = true
				print("PASSED: Pāśa Rope attack verified ('%s', frame %d, pos=%s)" % [anim_node.animation, anim_node.frame, str(player.global_position)])
			if timer >= 19.75 and not screenshot_rope_taken:
				screenshot_rope_taken = true
				_save_screenshot("screenshot_attack_rope.png")

	# Phase 6b (21.0s - 23.0s): Walk Right to test Plaza Side Wall enclosure & Camera X Clamp
	elif timer >= 21.0 and timer < 23.0:
		Input.action_press("move_right")
		if timer >= 22.4 and not screenshot_side_map_taken:
			screenshot_side_map_taken = true
			_save_screenshot("screenshot_side_map.png")
			var cam = get_parent().get_node_or_null("CameraRig")
			if cam:
				print("CameraRig global position at side test: ", cam.global_position)
				assert(abs(cam.global_position.x) <= 3.65, "Camera X must be clamped within +/-3.5m")
				print("PASSED: Camera X horizontal clamp verified (clamped at %.2f)" % cam.global_position.x)
			assert(player.global_position.x < 8.5, "Player must be constrained by Plaza RightWall at X < 8.5m")
			print("PASSED: Plaza side wall constraint verified (Player X=%.2f)" % player.global_position.x)

	# Phase 6c (23.0s - 25.5s): Walk South into Plaza Right Balustrade to verify chasm protection
	elif timer >= 23.0 and timer < 25.5:
		Input.action_release("move_right")
		Input.action_press("move_down")
		if timer >= 25.0 and not screenshot_plaza_south_balustrade_taken:
			screenshot_plaza_south_balustrade_taken = true
			_save_screenshot("screenshot_plaza_south_balustrade.png")
			print("Plaza south balustrade check: Player pos=(%.2f, %.2f, %.2f)" % [player.global_position.x, player.global_position.y, player.global_position.z])
			assert(player.global_position.z < -11.2, "Player must be constrained by Plaza south balustrade and not fall off (Z < -11.2m)")
			print("PASSED: Plaza south balustrade constraint verified!")

	# Phase 7 (25.5s+): Final verification & Exit
	elif timer >= 25.5:
		Input.action_release("move_down")
		assert(verified_walk_up, "walk_up should be verified")
		assert(verified_walk_right, "walk_right should be verified")
		assert(verified_walk_down, "walk_down should be verified")
		assert(verified_walk_left, "walk_left should be verified")
		assert(verified_idle, "idle should be verified")
		assert(verified_jump_up, "jump_up should be verified")
		assert(verified_jump_right, "jump_right should be verified")
		assert(verified_attack_axe, "attack_axe should be verified")
		assert(verified_attack_rope, "attack_rope should be verified")
		assert(verified_rock_collision, "rock_collision should be verified")
		assert(verified_firebox_collision, "firebox_collision should be verified")
		assert(screenshot_spikes_taken, "spikes_collision should be verified")
		assert(screenshot_side_map_taken, "screenshot_side_map should be taken")
		assert(screenshot_plaza_south_balustrade_taken, "screenshot_plaza_south_balustrade should be taken")
		
		print("--- ALL TESTS (4-DIR WALK + JUMP + COMBAT AXE (Q) + COMBAT ROPE (E) + RAILS + GATE COLLISION + 2D CONSTRAINTS + SIDE WALL ENCLOSURE + PLAZA SOUTH BALUSTRADE + CAMERA CLAMP) PASSED ---")
		get_tree().quit(0)
