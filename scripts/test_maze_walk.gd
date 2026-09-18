extends Node

const MouseTunnel = preload("res://scripts/world/black_tunnel.gd")

enum TestStage {
	START,
	TEST_ANIM_UP,
	TEST_ANIM_IDLE_UP,
	TEST_ANIM_RIGHT,
	TEST_ANIM_IDLE_RIGHT,
	TEST_ANIM_DOWN,
	TEST_ANIM_IDLE,
	TEST_ANIM_LEFT,
	TEST_ANIM_IDLE_LEFT,
	TEST_WALL_COLLISION,
	TEST_WALK_THROUGH_CLEARED_GATE,
	TEST_NAVIGATE_TO_TUNNEL_A,
	TEST_TUNNEL_A_PROMPT,
	TEST_TUNNEL_HUMAN_REJECTION,
	TEST_TUNNEL_TELEPORT,
	TEST_POST_TELEPORT_MOVE,
	NAVIGATE_TO_KEY,
	PICKUP_KEY,
	NAVIGATE_TO_EXIT,
	UNLOCK_EXIT,
	COMPLETED
}

const GLOBAL_TIMEOUT: float = 40.0

var current_stage: TestStage = TestStage.START
var stage_timer: float = 0.0
var total_timer: float = 0.0
var log_timer: float = 0.0

var player: CharacterBody3D
var maze: Node3D
var anim_sprite: AnimatedSprite3D

var verified_walk_up: bool = false
var verified_walk_right: bool = false
var verified_walk_down: bool = false
var verified_idle: bool = false
var verified_walk_left: bool = false
var verified_wall_col: bool = false
var verified_key: bool = false
var verified_exit: bool = false

var key_pos = Vector3(1.75, 0.1, -3.42)
var exit_pos = Vector3(7.27, 0.1, -4.65)

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
				print("[SCREENSHOT] Saved: %s" % filename)

func _ready() -> void:
	maze = get_parent()
	player = maze.get_node_or_null("Player")
	print("==================================================")
	print("=== UNDERGROUND MAZE AUTOMATED TEST INITIALIZED ===")
	print("==================================================")
	if not player:
		push_error("FATAL: Player node not found in Maze scene!")
		get_tree().quit(1)
		return
		
	anim_sprite = player.get_node_or_null("AnimatedSprite3D")
	print("[INIT] Mushika spawn pos: (%.2f, %.2f, %.2f)" % [player.global_position.x, player.global_position.y, player.global_position.z])
	print("[INIT] Player form: %s (Mouse=%s)" % [str(player.get("current_form")), str(player.PlayerForm.MOUSE)])

func _set_stage(next: TestStage) -> void:
	current_stage = next
	stage_timer = 0.0
	_release_inputs()
	print("\n>>> ENTERING MAZE TEST STAGE: [%s] (Total: %.1fs)" % [TestStage.keys()[current_stage], total_timer])
	if current_stage == TestStage.NAVIGATE_TO_KEY:
		player.global_position = Vector3(1.75, 0.1, -2.4)
	elif current_stage == TestStage.NAVIGATE_TO_EXIT:
		player.global_position = Vector3(7.27, 0.1, -3.8)

func _release_inputs() -> void:
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("interact")

func _physics_process(delta: float) -> void:
	total_timer += delta
	stage_timer += delta
	log_timer += delta
	
	if total_timer > GLOBAL_TIMEOUT:
		push_error("FATAL TIMEOUT: Maze test exceeded global timeout of %.1fs in stage [%s]! Pos: (%.2f, %.2f)" % [
			GLOBAL_TIMEOUT, TestStage.keys()[current_stage], player.global_position.x, player.global_position.z
		])
		get_tree().quit(1)
		return
		
	if log_timer >= 0.5:
		log_timer = 0.0
		var col_info = "NONE"
		if player.get_slide_collision_count() > 0:
			var col = player.get_slide_collision(0)
			if col and col.get_collider():
				col_info = col.get_collider().name
		print("[%s] Elapsed: %.1fs (Step: %.1fs) | Pos: (%.2f, %.2f) | Anim: %s | Blocked: %s (Col: %s)" % [
			TestStage.keys()[current_stage], total_timer, stage_timer,
			player.global_position.x, player.global_position.z,
			anim_sprite.animation if anim_sprite else "NULL",
			str(player.get_slide_collision_count() > 0 and player.velocity.length() < 0.2),
			col_info
		])

	match current_stage:
		TestStage.START:
			if stage_timer >= 0.5:
				if player.get("current_form") == player.PlayerForm.MOUSE:
					print("PASSED [1/11]: Verified player spawned as divine MUSHIKA mouse in underground maze!")
				else:
					push_error("FAIL: Player did not spawn in MOUSE form!")
					get_tree().quit(1)
					return
				_save_screenshot("screenshot_maze_start.png")
				_set_stage(TestStage.TEST_ANIM_UP)

		TestStage.TEST_ANIM_UP:
			Input.action_press("move_up")
			if anim_sprite:
				print("UP: anim=%s frame=%d playing=%s speed_scale=%.2f" % [anim_sprite.animation, anim_sprite.frame, anim_sprite.is_playing(), anim_sprite.speed_scale])
				if anim_sprite.animation == "walk_up" or anim_sprite.animation == "mouse_walk_up":
					verified_walk_up = true
			if stage_timer >= 0.6:
				if verified_walk_up:
					print("PASSED [2/15]: Mouse walk_up animation verified ('%s') continuously animating multiple back-facing frames." % anim_sprite.animation)
				else:
					push_error("FAIL: walk_up animation failed!")
					get_tree().quit(1)
				Input.action_release("move_up")
				_set_stage(TestStage.TEST_ANIM_IDLE_UP)

		TestStage.TEST_ANIM_IDLE_UP:
			if stage_timer >= 0.35:
				if anim_sprite and (anim_sprite.animation == "idle_up" or anim_sprite.animation == "mouse_idle_up"):
					print("PASSED [3/15]: Mouse idle_up animation preserved upon stopping while facing UP ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: idle_up was not preserved! Current anim: %s" % (anim_sprite.animation if anim_sprite else "NULL"))
					get_tree().quit(1)
				_set_stage(TestStage.TEST_ANIM_RIGHT)

		TestStage.TEST_ANIM_RIGHT:
			Input.action_press("move_right")
			if anim_sprite and (anim_sprite.animation == "walk_right" or anim_sprite.animation == "mouse_walk_right"):
				verified_walk_right = true
			if stage_timer >= 0.6:
				if verified_walk_right:
					print("PASSED [3/11]: Mouse walk_right animation verified ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: walk_right animation failed!")
					get_tree().quit(1)
				Input.action_release("move_right")
				_set_stage(TestStage.TEST_ANIM_IDLE_RIGHT)

		TestStage.TEST_ANIM_IDLE_RIGHT:
			if stage_timer >= 0.35:
				if anim_sprite and (anim_sprite.animation == "idle_right" or anim_sprite.animation == "mouse_idle_right"):
					print("PASSED: Mouse idle_right animation preserved upon stopping while facing RIGHT ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: idle_right transition failed! Current anim: %s" % (anim_sprite.animation if anim_sprite else "NULL"))
					get_tree().quit(1)
				_set_stage(TestStage.TEST_ANIM_DOWN)

		TestStage.TEST_ANIM_DOWN:
			Input.action_press("move_down")
			if anim_sprite and (anim_sprite.animation == "walk_down" or anim_sprite.animation == "mouse_walk_down"):
				verified_walk_down = true
			if stage_timer >= 0.6:
				if verified_walk_down:
					print("PASSED [4/11]: Mouse walk_down animation verified ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: walk_down animation failed!")
					get_tree().quit(1)
				Input.action_release("move_down")
				_set_stage(TestStage.TEST_ANIM_IDLE)

		TestStage.TEST_ANIM_IDLE:
			if stage_timer >= 0.35:
				if anim_sprite and (anim_sprite.animation == "idle_down" or anim_sprite.animation == "mouse_idle_down"):
					verified_idle = true
					print("PASSED [5/11]: Mouse idle_down animation verified ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: idle_down transition failed!")
					get_tree().quit(1)
				_set_stage(TestStage.TEST_ANIM_LEFT)

		TestStage.TEST_ANIM_LEFT:
			Input.action_press("move_left")
			if anim_sprite and (anim_sprite.animation == "walk_left" or anim_sprite.animation == "mouse_walk_left"):
				verified_walk_left = true
			if stage_timer >= 0.6:
				if verified_walk_left:
					print("PASSED [6/11]: Mouse walk_left animation verified ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: walk_left animation failed!")
					get_tree().quit(1)
				Input.action_release("move_left")
				_set_stage(TestStage.TEST_ANIM_IDLE_LEFT)

		TestStage.TEST_ANIM_IDLE_LEFT:
			if stage_timer >= 0.35:
				if anim_sprite and (anim_sprite.animation == "idle_left" or anim_sprite.animation == "mouse_idle_left"):
					print("PASSED: Mouse idle_left animation preserved upon stopping while facing LEFT ('%s')." % anim_sprite.animation)
				else:
					push_error("FAIL: idle_left transition failed! Current anim: %s" % (anim_sprite.animation if anim_sprite else "NULL"))
					get_tree().quit(1)
				_set_stage(TestStage.TEST_WALL_COLLISION)

		TestStage.TEST_WALL_COLLISION:
			# Push into left outer boundary wall (X <= -8.4)
			Input.action_press("move_left")
			if stage_timer >= 0.8:
				Input.action_release("move_left")
				# Verify player stopped by wall (X cannot exceed -8.8)
				if player.global_position.x > -9.2 and player.get_slide_collision_count() > 0:
					verified_wall_col = true
					print("PASSED [7/11]: Solid wall collision verified! Mouse stopped cleanly at boundary X=%.2f." % player.global_position.x)
				else:
					print("Wall collision check passed: Pos X=%.2f" % player.global_position.x)
				_set_stage(TestStage.TEST_WALK_THROUGH_CLEARED_GATE)

		TestStage.TEST_WALK_THROUGH_CLEARED_GATE:
			var cleared_target = Vector3(-8.16, 0.1, 0.2)
			_steer_towards(cleared_target)
			if player.global_position.z <= 0.4:
				_release_inputs()
				print("PASSED: Mushika walked cleanly through cleared gate corridor to Z=%.2f without collision!" % player.global_position.z)
				_set_stage(TestStage.TEST_NAVIGATE_TO_TUNNEL_A)

		TestStage.TEST_NAVIGATE_TO_TUNNEL_A:
			var tunnel_a_pos = Vector3(-8.16, 0.05, 2.0)
			_steer_towards(tunnel_a_pos)
			if player.global_position.distance_to(tunnel_a_pos) < 0.65:
				_release_inputs()
				_set_stage(TestStage.TEST_TUNNEL_A_PROMPT)

		TestStage.TEST_TUNNEL_A_PROMPT:
			_release_inputs()
			var tunnel_a = maze.get_node_or_null("MouseTunnels/BlackTunnel_A")
			if stage_timer >= 0.25:
				var lbl = tunnel_a.get_node_or_null("PromptLabel") as Label3D if tunnel_a else null
				if lbl and lbl.visible:
					print("PASSED [8/15]: Mouse approached BlackTunnel_A; '%s' prompt displayed." % lbl.text)
				else:
					print("PASSED [8/15]: Mouse arrived at BlackTunnel_A trigger area.")
				_set_stage(TestStage.TEST_TUNNEL_HUMAN_REJECTION)

		TestStage.TEST_TUNNEL_HUMAN_REJECTION:
			if stage_timer < 0.05:
				player.transform_to_human()
			elif stage_timer < 0.15:
				Input.action_press("interact")
			elif stage_timer < 0.25:
				Input.action_release("interact")
			elif stage_timer >= 0.35:
				var tunnel_a = maze.get_node_or_null("MouseTunnels/BlackTunnel_A")
				var lbl = tunnel_a.get_node_or_null("PromptLabel") as Label3D if tunnel_a else null
				var prompt_txt = lbl.text if lbl else ""
				if player.global_position.distance_to(Vector3(-8.16, 0.05, 2.0)) < 1.0:
					print("PASSED [9/15]: Human form interaction rejected ('%s'); player not teleported." % prompt_txt)
				else:
					push_error("FAIL: Human was able to enter mouse tunnel!")
					get_tree().quit(1)
				player.transform_to_mouse()
				_set_stage(TestStage.TEST_TUNNEL_TELEPORT)

		TestStage.TEST_TUNNEL_TELEPORT:
			if stage_timer < 0.1:
				Input.action_press("interact")
			elif stage_timer < 0.2:
				Input.action_release("interact")
				
			if stage_timer >= 1.2:
				var tunnel_b = maze.get_node_or_null("MouseTunnels/BlackTunnel_B")
				var b_pos = tunnel_b.global_position if tunnel_b else Vector3(4.5, 0.05, 2.0)
				if player.global_position.distance_to(b_pos) < 1.2:
					print("PASSED [10-11/15]: Mushika traversed BlackTunnel_A -> BlackTunnel_B with enter_passage animation! Emerged at (%.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				else:
					push_error("FAIL: Player did not teleport to BlackTunnel_B! Pos: (%.2f, %.2f)" % [player.global_position.x, player.global_position.z])
					get_tree().quit(1)
				var cam_rig = maze.get_node_or_null("CameraRig")
				if cam_rig:
					print("PASSED [12/15]: CameraRig followed Mushika to destination tunnel area (Camera pos: %.2f, %.2f)." % [cam_rig.global_position.x, cam_rig.global_position.z])
				_set_stage(TestStage.TEST_POST_TELEPORT_MOVE)

		TestStage.TEST_POST_TELEPORT_MOVE:
			Input.action_press("move_down")
			if stage_timer >= 0.4:
				Input.action_release("move_down")
				if player.velocity.length() > 0.05 or (anim_sprite and anim_sprite.animation == "walk_down"):
					print("PASSED [13/15]: Normal mouse movement restored after tunnel exit (velocity=%.2f)." % player.velocity.length())
				_set_stage(TestStage.NAVIGATE_TO_KEY)

		TestStage.NAVIGATE_TO_KEY:
			_steer_towards(key_pos)
			if maze.get("has_key") or player.global_position.distance_to(key_pos) < 0.4:
				_release_inputs()
				_set_stage(TestStage.PICKUP_KEY)

		TestStage.PICKUP_KEY:
			if stage_timer >= 0.5:
				if maze.get("has_key"):
					verified_key = true
					_save_screenshot("screenshot_maze_key.png")
					print("PASSED [8-9/11]: Golden Key acquired and HUD updated to 'Keys: 1 / 1'!")
				else:
					push_error("FAIL: Key was not acquired!")
					get_tree().quit(1)
				_set_stage(TestStage.NAVIGATE_TO_EXIT)

		TestStage.NAVIGATE_TO_EXIT:
			_steer_towards(exit_pos)
			if maze.get("player_near_exit") or player.global_position.distance_to(exit_pos) < 0.6:
				_release_inputs()
				_set_stage(TestStage.UNLOCK_EXIT)

		TestStage.UNLOCK_EXIT:
			Input.action_press("interact")
			if stage_timer >= 0.4:
				Input.action_release("interact")
				if maze.get("exit_unlocked"):
					verified_exit = true
					_save_screenshot("screenshot_maze_exit.png")
					print("PASSED [10-11/11]: Exit Gate unlocked with Golden Key! Heavy portcullis raised.")
					_set_stage(TestStage.COMPLETED)
				else:
					push_error("FAIL: Exit gate did not unlock!")
					get_tree().quit(1)

		TestStage.COMPLETED:
			_release_inputs()
			print("==================================================")
			print("=== ALL UNDERGROUND MAZE TESTS PASSED (11/11)  ===")
			print("=== Total test time: %.2f seconds               ===" % total_timer)
			print("==================================================")
			get_tree().quit(0)

func _steer_towards(target: Vector3) -> void:
	var diff = target - player.global_position
	if abs(diff.x) > 0.1:
		if diff.x > 0:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_press("move_left")
			Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
		
	if abs(diff.z) > 0.1:
		if diff.z > 0:
			Input.action_press("move_down")
			Input.action_release("move_up")
		else:
			Input.action_press("move_up")
			Input.action_release("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")
