extends Node

var player: CharacterBody3D
var step: int = 0
var timer: float = 0.0
var screenshot_overlook_taken: bool = false
var screenshot_bridge_taken: bool = false
var balustrade_tested: bool = false

var verified_walk_up: bool = false
var verified_walk_left: bool = false
var verified_walk_right: bool = false
var verified_walk_down: bool = false
var verified_idle: bool = false

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
	else:
		push_error("FAIL: KeepBrazierCenter is not an AnimatedSprite3D!")

func _physics_process(delta: float) -> void:
	timer += delta
	
	if not player:
		return
		
	var anim_node: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	
	# Initial frame: Capture starting Overlook view
	if timer >= 0.5 and not screenshot_overlook_taken:
		screenshot_overlook_taken = true
		_save_screenshot("screenshot_overlook.png")

	# Phase 0: Test all 4 directional animations on the overlook (0.5s to 3.0s)
	# 0.5 - 1.0s: Walk UP
	if timer >= 0.5 and timer < 1.0:
		Input.action_press("move_up")
		if anim_node and anim_node.animation == "walk_up" and not verified_walk_up:
			verified_walk_up = true
			print("PASSED: Walk UP animation verified ('walk_up')")

	# 1.0 - 1.5s: Walk RIGHT
	elif timer >= 1.0 and timer < 1.5:
		Input.action_release("move_up")
		Input.action_press("move_right")
		if anim_node and anim_node.animation == "walk_right" and not verified_walk_right:
			verified_walk_right = true
			print("PASSED: Walk RIGHT animation verified ('walk_right')")

	# 1.5 - 2.0s: Walk DOWN
	elif timer >= 1.5 and timer < 2.0:
		Input.action_release("move_right")
		Input.action_press("move_down")
		if anim_node and anim_node.animation == "walk_down" and not verified_walk_down:
			verified_walk_down = true
			print("PASSED: Walk DOWN animation verified ('walk_down')")

	# 2.0 - 2.5s: IDLE after walking down
	elif timer >= 2.0 and timer < 2.5:
		Input.action_release("move_down")
		if anim_node and anim_node.animation == "idle_down" and not verified_idle:
			verified_idle = true
			print("PASSED: Idle transition verified ('idle_down')")

	# 2.5 - 3.0s: Walk LEFT
	elif timer >= 2.5 and timer < 3.0:
		Input.action_press("move_left")
		if anim_node and anim_node.animation == "walk_left" and not verified_walk_left:
			verified_walk_left = true
			print("PASSED: Walk LEFT animation verified ('walk_left')")

	# Phase 1: Walk from Overlook onto Bridge (3.0s to 6.0s)
	elif timer >= 3.0 and timer < 6.0:
		Input.action_release("move_left")
		Input.action_press("move_up")

	# Phase 2: Test Bridge Balustrade collision (6.0s to 7.5s) - Try walking Left into balustrade!
	elif timer >= 6.0 and timer < 7.5:
		Input.action_release("move_up")
		Input.action_press("move_left")
		if not balustrade_tested and timer > 7.0:
			balustrade_tested = true
			print("Balustrade collision check: Player X=%.2f (Stopped by balustrade at X > -2.2m)" % player.global_position.x)
			assert(player.global_position.x > -2.2, "Player should be blocked by bridge balustrade!")

	# Phase 3: Resume walking North across Bridge into Plaza and Gate (7.5s to 14.0s)
	elif timer >= 7.5 and timer < 14.0:
		Input.action_release("move_left")
		Input.action_press("move_up")
		if timer >= 9.0 and not screenshot_bridge_taken:
			screenshot_bridge_taken = true
			_save_screenshot("screenshot_bridge.png")

	# Phase 4: Push against Sealed Gate
	elif timer >= 14.0:
		print("Pushing against sealed gate door: (Z=%.2f)" % player.global_position.z)
		Input.action_release("move_up")
		_save_screenshot("screenshot_gate.png")
		assert(player.global_position.z > -24.8, "Player should be blocked by the sealed gate!")
		
		assert(verified_walk_up, "walk_up should be verified")
		assert(verified_walk_right, "walk_right should be verified")
		assert(verified_walk_down, "walk_down should be verified")
		assert(verified_walk_left, "walk_left should be verified")
		assert(verified_idle, "idle should be verified")
		
		print("--- ALL TESTS (ALL 4-DIR ANIMATIONS + IDLE + BRIDGE RAILS + GATE COLLISION) PASSED ---")
		get_tree().quit(0)
