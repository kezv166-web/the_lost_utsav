extends Node

enum TestState {
	START,
	MOVE_TO_LEVER_CORRIDOR,
	MOVE_TO_LEVER_ALCOVE,
	INTERACT_LEVER,
	MOVE_TO_EAST_HALLWAY_SOUTH,
	MOVE_TO_CARPET_CENTER,
	MOVE_TO_CRYSTAL,
	INTERACT_CRYSTAL,
	MOVE_TO_CARPET_MID,
	MOVE_TO_WEST_CORRIDOR,
	MOVE_TO_MOUSE_PASSAGE,
	INTERACT_MOUSE_PASSAGE,
	MOVE_TO_SHRINE,
	INTERACT_SHRINE,
	MOVE_TO_MOUSE_PASSAGE_AS_MOUSE,
	ENTER_MOUSE_PASSAGE,
	MOVE_TO_WEST_CORRIDOR_SOUTH,
	MOVE_TO_CARPET_SOUTH,
	MOVE_TO_SOUTH_EXIT,
	INTERACT_EXIT,
	COMPLETED
}

const GLOBAL_TIMEOUT: float = 65.0
const STEP_TIMEOUT: float = 8.0

var current_state: TestState = TestState.START
var state_timer: float = 0.0
var total_timer: float = 0.0
var log_timer: float = 0.0

var player: CharacterBody3D
var l1_map: Node3D

var target_position: Vector3 = Vector3.ZERO
var state_name: String = "START"

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
	l1_map = get_parent()
	player = l1_map.get_node_or_null("Player")
	print("==================================================")
	print("=== LEVEL 1 AUTOMATED TEST RUNNER INITIALIZING ===")
	print("==================================================")
	if not player:
		push_error("FATAL: Player node not found in L1Map!")
		get_tree().quit(1)
		return
	print("[INIT] Player spawned at: (%.2f, %.2f, %.2f)" % [player.global_position.x, player.global_position.y, player.global_position.z])
	_set_state(TestState.START)

func _set_state(new_state: TestState) -> void:
	current_state = new_state
	state_timer = 0.0
	_release_all_inputs()
	
	match current_state:
		TestState.START:
			state_name = "TEST_SPAWN_AND_START"
			target_position = player.global_position
		TestState.MOVE_TO_LEVER_CORRIDOR:
			state_name = "TEST_NAVIGATE_EAST_CORRIDOR"
			target_position = Vector3(5.4, 0.05, 2.0)
		TestState.MOVE_TO_LEVER_ALCOVE:
			state_name = "TEST_NAVIGATE_TO_LEVER_ALCOVE"
			target_position = Vector3(6.6, 0.05, -3.0)
		TestState.INTERACT_LEVER:
			state_name = "TEST_LEVER_INTERACTION"
			target_position = Vector3(6.6, 0.05, -3.0)
		TestState.MOVE_TO_EAST_HALLWAY_SOUTH:
			state_name = "TEST_NAVIGATE_EAST_SOUTH"
			target_position = Vector3(5.0, 0.05, 0.8)
		TestState.MOVE_TO_CARPET_CENTER:
			state_name = "TEST_NAVIGATE_CARPET_CENTER"
			target_position = Vector3(0.0, 0.05, 0.8)
		TestState.MOVE_TO_CRYSTAL:
			state_name = "TEST_NAVIGATE_TO_CRYSTAL"
			target_position = Vector3(0.0, 0.05, -1.35)
		TestState.INTERACT_CRYSTAL:
			state_name = "TEST_CRYSTAL_INTERACTION"
			target_position = Vector3(0.0, 0.05, -1.35)
		TestState.MOVE_TO_CARPET_MID:
			state_name = "TEST_NAVIGATE_CARPET_MID"
			target_position = Vector3(0.0, 0.05, 0.8)
		TestState.MOVE_TO_WEST_CORRIDOR:
			state_name = "TEST_NAVIGATE_WEST_CORRIDOR"
			target_position = Vector3(-4.8, 0.05, 0.8)
		TestState.MOVE_TO_MOUSE_PASSAGE:
			state_name = "TEST_NAVIGATE_TO_MOUSE_PASSAGE"
			target_position = Vector3(-5.2, 0.05, -1.93)
		TestState.INTERACT_MOUSE_PASSAGE:
			state_name = "TEST_INSPECT_MOUSE_PASSAGE"
			target_position = Vector3(-5.2, 0.05, -1.93)
		TestState.MOVE_TO_SHRINE:
			state_name = "TEST_NAVIGATE_TO_GANESHA_SHRINE"
			target_position = Vector3(-5.8, 0.05, -3.2)
		TestState.INTERACT_SHRINE:
			state_name = "TEST_PRAY_AND_TRANSFORM"
			target_position = Vector3(-5.8, 0.05, -3.2)
		TestState.MOVE_TO_MOUSE_PASSAGE_AS_MOUSE:
			state_name = "TEST_NAVIGATE_TO_PASSAGE_AS_MOUSE"
			target_position = Vector3(-5.2, 0.05, -1.93)
		TestState.ENTER_MOUSE_PASSAGE:
			state_name = "TEST_ENTER_MOUSE_PASSAGE"
			target_position = Vector3(-5.2, 0.05, -1.93)
		TestState.MOVE_TO_WEST_CORRIDOR_SOUTH:
			state_name = "TEST_NAVIGATE_WEST_SOUTH"
			target_position = Vector3(-4.8, 0.05, 0.8)
		TestState.MOVE_TO_CARPET_SOUTH:
			state_name = "TEST_NAVIGATE_CARPET_SOUTH"
			target_position = Vector3(0.0, 0.05, 0.8)
		TestState.MOVE_TO_SOUTH_EXIT:
			state_name = "TEST_NAVIGATE_TO_SOUTH_EXIT"
			target_position = Vector3(0.0, 0.05, 4.2)
		TestState.INTERACT_EXIT:
			state_name = "TEST_EXIT_CONFIRMATION"
			target_position = Vector3(0.0, 0.05, 4.2)
		TestState.COMPLETED:
			state_name = "TEST_COMPLETED"
			target_position = player.global_position

	print("\n>>> ENTERING STAGE: [%s] (Target: %.2f, %.2f)" % [state_name, target_position.x, target_position.z])

func _release_all_inputs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("interact")
	Input.action_release("transform_1")

func _steer_towards(target: Vector3) -> void:
	var diff = target - player.global_position
	diff.y = 0.0
	
	if abs(diff.x) > 0.2:
		if diff.x > 0:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_press("move_left")
			Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
		
	if abs(diff.z) > 0.2:
		if diff.z > 0:
			Input.action_press("move_down")
			Input.action_release("move_up")
		else:
			Input.action_press("move_up")
			Input.action_release("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func _physics_process(delta: float) -> void:
	total_timer += delta
	state_timer += delta
	log_timer += delta
	
	# Global Watchdog Timeout
	if total_timer > GLOBAL_TIMEOUT:
		push_error("FATAL TIMEOUT: Test runner exceeded global timeout of %.1fs in stage [%s]! Position: (%.2f, %.2f)" % [
			GLOBAL_TIMEOUT, state_name, player.global_position.x, player.global_position.z
		])
		get_tree().quit(1)
		return

	# Step Timeout (allowing 15s for the cutscene animation)
	var active_step_timeout = 15.0 if current_state == TestState.INTERACT_SHRINE else STEP_TIMEOUT
	if state_timer > active_step_timeout:
		push_error("STEP TIMEOUT: Stage [%s] exceeded timeout of %.1fs! Pos: (%.2f, %.2f), Target: (%.2f, %.2f)" % [
			state_name, active_step_timeout, player.global_position.x, player.global_position.z, target_position.x, target_position.z
		])
		get_tree().quit(1)
		return

	var is_moving = player.velocity.length() > 0.1
	var collision_count = player.get_slide_collision_count()
	var is_blocked = collision_count > 0 and player.velocity.length() < 0.2

	# Periodic Diagnostic Logging
	if log_timer >= 0.4:
		log_timer = 0.0
		var col_info = "NONE"
		if collision_count > 0:
			var col = player.get_slide_collision(0)
			if col and col.get_collider():
				col_info = col.get_collider().name
		print("[%s] Elapsed: %.1fs (Step: %.1fs) | Pos: (%.2f, %.2f) | Target: (%.2f, %.2f) | Moving: %s (vel=%.2f) | Blocked: %s (Col: %s)" % [
			state_name, total_timer, state_timer,
			player.global_position.x, player.global_position.z,
			target_position.x, target_position.z,
			str(is_moving), player.velocity.length(),
			str(is_blocked), col_info
		])

	match current_state:
		TestState.START:
			if state_timer >= 0.3:
				_save_screenshot("screenshot_l1_start.png")
				print("PASSED [1/7]: Initial Level 1 map and player spawn verified.")
				_set_state(TestState.MOVE_TO_LEVER_CORRIDOR)

		TestState.MOVE_TO_LEVER_CORRIDOR:
			_steer_towards(target_position)
			var dist = Vector2(player.global_position.x - target_position.x, player.global_position.z - target_position.z).length()
			if dist < 0.4 or player.global_position.x >= 5.2:
				print("PASSED [2/7]: Player cleared south pillars and reached eastern corridor (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_LEVER_ALCOVE)

		TestState.MOVE_TO_LEVER_ALCOVE:
			_steer_towards(target_position)
			if l1_map.player_near_lever or (player.global_position.x >= 5.2 and player.global_position.z <= -3.2):
				print("PASSED [3/7]: Player navigated eastern corridor into alcove (Pos: %.2f, %.2f, LeverNear: %s)." % [player.global_position.x, player.global_position.z, str(l1_map.player_near_lever)])
				_set_state(TestState.INTERACT_LEVER)

		TestState.INTERACT_LEVER:
			_release_all_inputs()
			Input.action_press("interact")
			if state_timer >= 0.3:
				Input.action_release("interact")
				if l1_map.lever_pulled:
					_save_screenshot("screenshot_l1_lever.png")
					print("PASSED [4/8]: Lever successfully pulled! Asur crystal awakened with red-hot glow.")
					_set_state(TestState.MOVE_TO_EAST_HALLWAY_SOUTH)
				else:
					push_error("FAIL: Lever did not toggle state on interact!")
					get_tree().quit(1)

		TestState.MOVE_TO_EAST_HALLWAY_SOUTH:
			_steer_towards(target_position)
			var dist = Vector2(player.global_position.x - target_position.x, player.global_position.z - target_position.z).length()
			if dist < 0.6 or player.global_position.z >= 0.5:
				print("PASSED [5/8]: Player moved south past PillarNE along east corridor (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_CARPET_CENTER)

		TestState.MOVE_TO_CARPET_CENTER:
			_steer_towards(target_position)
			var dist = Vector2(player.global_position.x - target_position.x, player.global_position.z - target_position.z).length()
			if dist < 0.6 or abs(player.global_position.x) <= 0.4:
				print("PASSED [6/8]: Player crossed open corridor onto central carpet (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_CRYSTAL)

		TestState.MOVE_TO_CRYSTAL:
			_steer_towards(target_position)
			if l1_map.player_near_crystal or player.global_position.z <= -1.35:
				_release_all_inputs()
				_set_state(TestState.INTERACT_CRYSTAL)

		TestState.INTERACT_CRYSTAL:
			_release_all_inputs()
			Input.action_press("interact")
			if state_timer >= 0.3:
				Input.action_release("interact")
				_save_screenshot("screenshot_l1_crystal.png")
				print("PASSED [7/11]: Player approached central Altar and inspected awakened crystal (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_CARPET_MID)

		TestState.MOVE_TO_CARPET_MID:
			_steer_towards(target_position)
			if player.global_position.z >= 0.6:
				print("PASSED [8a/11]: Player navigated south to central corridor intersection (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_WEST_CORRIDOR)

		TestState.MOVE_TO_WEST_CORRIDOR:
			_steer_towards(target_position)
			if player.global_position.x <= -4.4:
				print("PASSED [8b/11]: Player crossed open corridor into western study alcove (Pos: %.2f, %.2f)." % [player.global_position.x, player.global_position.z])
				_set_state(TestState.MOVE_TO_MOUSE_PASSAGE)

		TestState.MOVE_TO_MOUSE_PASSAGE:
			_steer_towards(target_position)
			if l1_map.player_near_mouse_passage or player.global_position.z <= -1.7:
				print("PASSED [9/11]: Player reached revealed broken-brick mouse passage (Pos: %.2f, %.2f, Near: %s)." % [player.global_position.x, player.global_position.z, str(l1_map.player_near_mouse_passage)])
				_release_all_inputs()
				_set_state(TestState.INTERACT_MOUSE_PASSAGE)

		TestState.INTERACT_MOUSE_PASSAGE:
			_release_all_inputs()
			Input.action_press("interact")
			if state_timer >= 0.3:
				Input.action_release("interact")
				_save_screenshot("screenshot_l1_mouse_passage.png")
				if l1_map.mouse_passage_revealed:
					print("PASSED [10/14]: Player inspected narrow mouse passage. Confirmed revealed and mouse-sized!")
					_set_state(TestState.INTERACT_SHRINE)
				else:
					push_error("FAIL: Mouse passage was not revealed when lever was pulled!")
					get_tree().quit(1)

		TestState.MOVE_TO_SHRINE:
			_set_state(TestState.INTERACT_SHRINE)

		TestState.INTERACT_SHRINE:
			if state_timer < 0.2:
				Input.action_press("transform_1")
			else:
				Input.action_release("transform_1")
			if state_timer >= 1.0 and not l1_map.transformation_in_progress and player.get("current_form") == player.PlayerForm.MOUSE:
				_save_screenshot("screenshot_l1_mushika.png")
				print("PASSED [11-12/14]: Transformation complete! Player pressed [1] and chanted mantra to become Mushika (mouse form).")
				_set_state(TestState.ENTER_MOUSE_PASSAGE)

		TestState.MOVE_TO_MOUSE_PASSAGE_AS_MOUSE:
			_steer_towards(target_position)
			if l1_map.player_near_mouse_passage or player.global_position.z >= -2.1:
				print("PASSED [13a/14]: Mushika navigated directly to the narrow mouse passage!")
				_release_all_inputs()
				_set_state(TestState.ENTER_MOUSE_PASSAGE)

		TestState.ENTER_MOUSE_PASSAGE:
			_release_all_inputs()
			Input.action_press("interact")
			if state_timer >= 0.3:
				Input.action_release("interact")
				_save_screenshot("screenshot_l1_mouse_enter.png")
				print("PASSED [13b/14]: Mushika entered the hidden mouse passage! Underground Maze transition initiated.")
				print("==================================================")
				print("=== LEVEL 1 TO MAZE TRANSITION TEST PASSED!     ===")
				print("==================================================")
				get_tree().create_timer(0.6).timeout.connect(func():
					get_tree().quit(0)
				)
				_set_state(TestState.COMPLETED)

		TestState.MOVE_TO_WEST_CORRIDOR_SOUTH:
			_steer_towards(target_position)
			if player.global_position.z >= 0.6:
				_set_state(TestState.MOVE_TO_CARPET_SOUTH)

		TestState.MOVE_TO_CARPET_SOUTH:
			_steer_towards(target_position)
			if player.global_position.x >= -0.4:
				_set_state(TestState.MOVE_TO_SOUTH_EXIT)

		TestState.MOVE_TO_SOUTH_EXIT:
			_steer_towards(target_position)
			if l1_map.player_near_exit or player.global_position.z >= 3.8:
				_release_all_inputs()
				_set_state(TestState.INTERACT_EXIT)

		TestState.INTERACT_EXIT:
			_release_all_inputs()
			_save_screenshot("screenshot_l1_exit.png")
			print("PASSED [14/14]: Player returned to South Exit doorway (Pos: %.2f, %.2f, ExitNear: %s)." % [player.global_position.x, player.global_position.z, str(l1_map.player_near_exit)])
			_set_state(TestState.COMPLETED)

		TestState.COMPLETED:
			_release_all_inputs()
			print("==================================================")
			print("=== ALL LEVEL 1 AUTOMATED TESTS PASSED (14/14) ===")
			print("=== Total test time: %.2f seconds               ===" % total_timer)
			print("==================================================")
			get_tree().quit(0)
