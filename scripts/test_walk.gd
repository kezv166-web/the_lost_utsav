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

const GLOBAL_TIMEOUT: float = 20.0
var log_timer: float = 0.0
var current_test_name: String = "INIT"

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

func _physics_process(delta: float) -> void:
	timer += delta
	log_timer += delta
	
	if not player:
		return

	if timer > GLOBAL_TIMEOUT:
		push_error("FATAL TIMEOUT: Outdoor test runner exceeded global timeout of %.1fs in stage [%s]! Position: (%.2f, %.2f)" % [
			GLOBAL_TIMEOUT, current_test_name, player.global_position.x, player.global_position.z
		])
		get_tree().quit(1)
		return

	var is_moving = player.velocity.length() > 0.1
	var collision_count = player.get_slide_collision_count()
	var is_blocked = collision_count > 0 and player.velocity.length() < 0.2

	if log_timer >= 0.5:
		log_timer = 0.0
		var col_info = "NONE"
		if collision_count > 0:
			var col = player.get_slide_collision(0)
			if col and col.get_collider():
				col_info = col.get_collider().name
		print("[%s] Elapsed: %.1fs | Pos: (%.2f, %.2f) | Moving: %s (vel=%.2f) | Blocked: %s (Col: %s)" % [
			current_test_name, timer, player.global_position.x, player.global_position.z,
			str(is_moving), player.velocity.length(), str(is_blocked), col_info
		])
		
	var anim_node: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	
	# Initial frame: Capture starting Overlook view
	if timer >= 0.5 and not screenshot_overlook_taken:
		screenshot_overlook_taken = true
		_save_screenshot("screenshot_overlook.png")

	# Phase 0: Test all 4 directional animations on the overlook (0.5s to 3.0s)
	# 0.5 - 1.0s: Walk UP
	if timer >= 0.5 and timer < 1.0:
		current_test_name = "TEST_ANIM_WALK_UP"
		Input.action_press("move_up")
		if anim_node and anim_node.animation == "walk_up" and not verified_walk_up:
			verified_walk_up = true
			print("PASSED: Walk UP animation verified ('walk_up')")

	# 1.0 - 1.5s: Walk RIGHT
	elif timer >= 1.0 and timer < 1.5:
		current_test_name = "TEST_ANIM_WALK_RIGHT"
		Input.action_release("move_up")
		Input.action_press("move_right")
		if anim_node and anim_node.animation == "walk_right" and not verified_walk_right:
			verified_walk_right = true
			print("PASSED: Walk RIGHT animation verified ('walk_right')")

	# 1.5 - 2.0s: Walk DOWN
	elif timer >= 1.5 and timer < 2.0:
		current_test_name = "TEST_ANIM_WALK_DOWN"
		Input.action_release("move_right")
		Input.action_press("move_down")
		if anim_node and anim_node.animation == "walk_down" and not verified_walk_down:
			verified_walk_down = true
			print("PASSED: Walk DOWN animation verified ('walk_down')")

	# 2.0 - 2.5s: IDLE after walking down
	elif timer >= 2.0 and timer < 2.5:
		current_test_name = "TEST_ANIM_IDLE"
		Input.action_release("move_down")
		if anim_node and anim_node.animation == "idle_down" and not verified_idle:
			verified_idle = true
			print("PASSED: Idle transition verified ('idle_down')")

	# 2.5 - 3.0s: Walk LEFT
	elif timer >= 2.5 and timer < 3.0:
		current_test_name = "TEST_ANIM_WALK_LEFT"
		Input.action_press("move_left")
		if anim_node and anim_node.animation == "walk_left" and not verified_walk_left:
			verified_walk_left = true
			print("PASSED: Walk LEFT animation verified ('walk_left')")

	# Phase 1: Walk from Overlook onto Bridge (3.0s to 6.0s)
	elif timer >= 3.0 and timer < 6.0:
		current_test_name = "TEST_WALK_OVERLOOK_TO_BRIDGE"
		Input.action_release("move_left")
		Input.action_press("move_up")
		if timer >= 4.0 and timer < 4.1:
			print("VERIFY SPEED: Outdoor player velocity: %.2f m/s (target 4.0)" % player.velocity.length())
			assert(player.velocity.length() >= 3.8, "Outdoor human speed should be ~4.0 m/s!")

	# Phase 2: Test Bridge Balustrade collision (6.0s to 7.5s) - Try walking Left into balustrade!
	elif timer >= 6.0 and timer < 7.5:
		current_test_name = "TEST_BRIDGE_BALUSTRADE_COLLISION"
		Input.action_release("move_up")
		Input.action_press("move_left")
		if not balustrade_tested and timer > 7.0:
			balustrade_tested = true
			print("Balustrade collision check: Player X=%.2f (Stopped by balustrade at X > -2.2m)" % player.global_position.x)
			assert(player.global_position.x > -2.2, "Player should be blocked by bridge balustrade!")

	# Phase 3: Resume walking North across Bridge into Plaza and Gate (7.5s to 14.0s)
	elif timer >= 7.5 and timer < 14.0:
		current_test_name = "TEST_WALK_BRIDGE_TO_GATE"
		Input.action_release("move_left")
		Input.action_press("move_up")
		if timer >= 9.0 and not screenshot_bridge_taken:
			screenshot_bridge_taken = true
			_save_screenshot("screenshot_bridge.png")

	# Phase 4: Push against Sealed Gate
	elif timer >= 14.0:
		current_test_name = "TEST_SEALED_GATE_COLLISION"
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
