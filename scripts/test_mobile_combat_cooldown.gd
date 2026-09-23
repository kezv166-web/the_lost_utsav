extends SceneTree

func _init() -> void:
	print("--- BEGIN TEST: Independent Mobile Combat Cooldown & Anti-Spam Verification ---")
	
	var actions = ["jump", "attack_axe", "attack_rope", "interact", "move_left", "move_right", "move_up", "move_down"]
	for a in actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
	
	# 1. Test MobileButton component: seconds display, low transparency & unclickable state
	var btn = MobileButton.new()
	btn.size = Vector2(80, 80)
	btn.button_radius = 36.0
	btn.action_name = "attack_axe"
	btn.button_label = "AXE"
	root.add_child(btn)
	
	assert(btn.cooldown_seconds == 0.0, "Initial cooldown_seconds must be 0.0")
	assert(btn.cooldown_ratio == 0.0, "Initial cooldown_ratio must be 0.0")
	assert(btn.is_on_cooldown() == false, "Button must initially not be on cooldown")
	assert(btn.modulate.a >= 0.99, "Button must initially have full opacity 1.0")
	
	# Set active cooldown on button (0.85s, 0.70 ratio)
	btn.set_cooldown(0.85, 0.70)
	assert(btn.cooldown_seconds == 0.85, "cooldown_seconds must be 0.85")
	assert(btn.cooldown_ratio == 0.70, "cooldown_ratio must be 0.70")
	assert(btn.is_on_cooldown() == true, "is_on_cooldown() must be true")
	assert(btn.modulate.a <= 0.55, "Button must have low transparency (<= 0.55) during cooldown")
	
	# Test unclickable behavior: clicks and touches must be rejected
	var touch_ev = InputEventScreenTouch.new()
	touch_ev.pressed = true
	btn._gui_input(touch_ev)
	assert(btn._is_pressed == false, "Button must be UNCLICKABLE during cooldown (touch rejected)")
	
	var click_ev = InputEventMouseButton.new()
	click_ev.button_index = MOUSE_BUTTON_LEFT
	click_ev.pressed = true
	btn._gui_input(click_ev)
	assert(btn._is_pressed == false, "Button must be UNCLICKABLE during cooldown (mouse click rejected)")
	
	# Simulate cooldown expiring
	btn.set_cooldown(0.0, 0.0)
	assert(btn.cooldown_seconds == 0.0, "cooldown_seconds must be 0.0")
	assert(btn.cooldown_ratio == 0.0, "cooldown_ratio must be 0.0")
	assert(btn.is_on_cooldown() == false, "Button must not be on cooldown after reset")
	assert(btn._flash_timer > 0.20, "Golden ready flash must trigger when cooldown hits 0")
	assert(btn.modulate.a >= 0.95, "Button opacity must restore to 1.0 upon cooldown completion")
	
	# Test flash countdown in process
	btn._process(0.10)
	assert(btn._flash_timer < 0.20 and btn._flash_timer > 0.05, "Flash timer must decrement in _process")
	btn._process(0.20)
	assert(btn._flash_timer == 0.0, "Flash timer must reach 0")
	
	print("[PASS] MobileButton seconds display, low transparency (0.50), and unclickable state verified.")
	
	# 2. Test Player Independent Cooldowns
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	player.position = Vector3(0, 0, 0)
	
	assert(player.get_attack_cooldown_remaining("axe") == 0.0, "Axe cooldown remaining must be 0.0 initially")
	assert(player.get_attack_cooldown_remaining("rope") == 0.0, "Rope cooldown remaining must be 0.0 initially")
	
	# Step A: Trigger Axe Attack
	var axe_success = player.attack("axe")
	assert(axe_success == true, "Axe attack must succeed")
	assert(player.current_state == player.State.ATTACKING, "Player state must be ATTACKING")
	assert(player.current_attack_type == "axe", "Attack type must be axe")
	
	var axe_rem = player.get_attack_cooldown_remaining("axe")
	var rope_rem = player.get_attack_cooldown_remaining("rope")
	assert(axe_rem > 0.0, "Axe cooldown remaining must be > 0.0 during axe attack")
	assert(rope_rem == 0.0, "Rope cooldown remaining must be 0.0 (Rope NOT affected by Axe attack!)")
	print("During Axe strike: Axe remaining = ", axe_rem, "s, Rope remaining = ", rope_rem, "s")
	
	# Step B: Finish Axe animation -> Axe enters recovery cooldown (0.38s)
	player._on_animation_finished()
	assert(player.current_state in [player.State.IDLE_WALK, player.State.JUMPING], "Player must return to walk/jump")
	assert(player.axe_cooldown_timer == player.COOLDOWN_AXE, "Axe cooldown timer must be 0.38s")
	assert(player.rope_cooldown_timer == 0.0, "Rope cooldown timer must remain 0.0")
	
	# Step C: Anti-spam test: Axe cannot attack during its cooldown
	var spam_axe = player.attack("axe")
	assert(spam_axe == false, "Axe attack during axe cooldown must be REJECTED")
	
	# Step D: INDEPENDENT ATTACK: Rope CAN attack immediately!
	var rope_success = player.attack("rope")
	assert(rope_success == true, "Rope attack MUST SUCCEED independently even while Axe is cooling down!")
	assert(player.current_state == player.State.ATTACKING, "Player is now executing Rope attack")
	assert(player.current_attack_type == "rope", "Current attack is rope")
	
	var rope_rem_now = player.get_attack_cooldown_remaining("rope")
	assert(rope_rem_now > 0.0, "Rope cooldown remaining must be > 0.0")
	print("During Rope strike: Rope remaining = ", rope_rem_now, "s")
	
	# Step E: Finish Rope animation -> Rope enters recovery cooldown (0.85s)
	player._on_animation_finished()
	assert(player.rope_cooldown_timer == player.COOLDOWN_ROPE, "Rope cooldown timer must be 0.85s")
	
	# Step F: Advance delta by 0.40s: Axe should finish (0.38s elapsed), Rope still cooling (0.85 - 0.40 = 0.45s left)
	player.axe_cooldown_timer = maxf(0.0, player.axe_cooldown_timer - 0.40)
	player.rope_cooldown_timer = maxf(0.0, player.rope_cooldown_timer - 0.40)
	assert(player.axe_cooldown_timer <= 0.0, "Axe cooldown must have finished after 0.40s")
	assert(player.rope_cooldown_timer > 0.35, "Rope must still be on cooldown (> 0.35s left of 0.85s)")
	
	# Now Axe can attack again while Rope is still cooling down!
	var axe_again = player.attack("axe")
	assert(axe_again == true, "Axe attack must succeed while Rope is still on cooldown!")
	
	# Clean up temporary player and button
	player.queue_free()
	btn.queue_free()
	
	print("[PASS] Independent weapon cooldowns, seconds tracking, and unclickable states fully verified!")
	
	# 3. Test MobileControls Scene Layout & Button Sizing
	print("[3] Testing MobileControls scene layout & enhanced button sizes...")
	var mobile_scene = load("res://scenes/ui/mobile_controls.tscn")
	var mobile_controls = mobile_scene.instantiate()
	root.add_child(mobile_controls)
	MobileControlsLayer.set_gamepad_mode(true)
	
	var axe_node: MobileButton = mobile_controls.get_node("RootControl/ButtonsZone/AxeButton")
	var pasa_node: MobileButton = mobile_controls.get_node("RootControl/ButtonsZone/PasaButton")
	var jump_node: MobileButton = mobile_controls.get_node("RootControl/ButtonsZone/JumpButton")
	var interact_node: MobileButton = mobile_controls.get_node("RootControl/ButtonsZone/InteractButton")
	var transform_node: MobileButton = mobile_controls.get_node("RootControl/ButtonsZone/TransformButton")
	
	assert(axe_node.button_radius == 48.0, "Axe button radius must be 48.0 (increased size)")
	assert(pasa_node.button_radius == 44.0, "Pasa button radius must be 44.0 (increased size)")
	assert(jump_node.button_radius == 44.0, "Jump button radius must be 44.0 (increased size)")
	assert(interact_node.button_radius == 41.0, "Interact button radius must be 41.0")
	assert(transform_node.button_radius == 39.0, "Transform button radius must be 39.0")
	print("[PASS] Button sizing verified: Axe 48px, Pasa 44px, Jump 44px, Interact 41px, Transform 39px.")
	
	# 4. Test Dynamic Interact Button Visuals (Rock Grab, Throw, Blessing, Exit)
	print("[4] Testing Dynamic Interact Button Visual States...")
	var mock_scene = Node.new()
	mock_scene.name = "MockLevel"
	var mock_script = GDScript.new()
	mock_script.source_code = "extends Node\nvar held_rock: Node3D = null\nvar nearby_rock: Node3D = null\nvar player_near_altar: bool = false\nvar player_near_exit: bool = false\nvar blessing_claimed: bool = false\nvar blessing_in_progress: bool = false\n"
	mock_script.reload()
	mock_scene.set_script(mock_script)
	root.add_child(mock_scene)
	
	var p2 = player_scene.instantiate()
	mock_scene.add_child(p2)
	mobile_controls._cached_player = p2
	
	# State 1: Default
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "INTERACT", "Default label must be INTERACT")
	assert(interact_node.is_special_glow == false, "Default interact must not have special glow")
	
	# State 2: Nearby Rock -> "GRAB"
	var dummy_rock = Node3D.new()
	mock_scene.add_child(dummy_rock)
	mock_scene.nearby_rock = dummy_rock
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "GRAB", "Interact button must switch to GRAB when near rock")
	assert(interact_node.is_special_glow == true, "GRAB button must have special glow")
	assert(interact_node.special_badge_text == "GRAB", "GRAB button badge must be GRAB")
	
	# State 3: Carrying Rock -> "THROW"
	mock_scene.nearby_rock = null
	p2.is_carrying = true
	mock_scene.held_rock = dummy_rock
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "THROW", "Interact button must switch to THROW when carrying rock")
	assert(interact_node.is_special_glow == true, "THROW button must have special glow")
	assert(interact_node.special_badge_text == "THROW!", "THROW button badge must be THROW!")
	assert(interact_node.icon_texture == mobile_controls.ICON_ROCK_THROW, "THROW button icon must be rock texture")
	
	# State 4: Post-Defeat Altar Blessing -> "BLESSING"
	p2.is_carrying = false
	mock_scene.held_rock = null
	mock_scene.player_near_altar = true
	mock_scene.blessing_claimed = false
	mock_scene.blessing_in_progress = false
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "BLESSING", "Interact button must switch to BLESSING at altar")
	assert(interact_node.is_special_glow == true, "BLESSING button must have special glow")
	assert(interact_node.special_badge_text == "CLAIM!", "BLESSING button badge must be CLAIM!")
	
	# State 5: South Exit -> "EXIT"
	mock_scene.player_near_altar = false
	mock_scene.player_near_exit = true
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "EXIT", "Interact button must switch to EXIT near exit")
	assert(interact_node.is_special_glow == true, "EXIT button must have special glow")
	assert(interact_node.special_badge_text == "ENTER", "EXIT button badge must be ENTER")
	
	# State 6: Back to normal
	mock_scene.player_near_exit = false
	mobile_controls.update_interact_visuals(mock_scene)
	assert(interact_node.button_label == "INTERACT", "Interact button must return to INTERACT")
	assert(interact_node.is_special_glow == false, "Interact button must not glow when clear")
	print("[PASS] Dynamic Interact button visual transformations (GRAB -> THROW -> BLESSING -> EXIT -> INTERACT) verified.")
	
	# 5. Test Rock Carrying, Attack Interception & Throw Mechanics (PC & Mobile)
	print("[5] Testing Rock Carry, Attack Redirection to Throw, and Mouse Throw...")
	var test_level_script = GDScript.new()
	test_level_script.source_code = """
extends Node
var held_rock: Node3D = null
var nearby_rock: Node3D = null
var throw_called: bool = false
var grab_called: bool = false

func throw_held_rock() -> void:
	throw_called = true
	held_rock = null
	var p = find_child("Player", true, false)
	if p:
		p.is_carrying = false

func grab_rock(rock: Node3D) -> void:
	grab_called = true
	held_rock = rock
	var p = find_child("Player", true, false)
	if p:
		p.is_carrying = true
"""
	test_level_script.reload()
	var test_level = Node.new()
	test_level.name = "TestLevel"
	test_level.set_script(test_level_script)
	root.add_child(test_level)
	current_scene = test_level
	
	var p3 = player_scene.instantiate()
	p3.name = "Player"
	test_level.add_child(p3)
	
	var r_dummy = Node3D.new()
	test_level.add_child(r_dummy)
	
	# Step 5A: Grab rock
	test_level.grab_rock(r_dummy)
	assert(test_level.held_rock == r_dummy, "held_rock must be r_dummy")
	assert(p3.is_carrying == true, "player.is_carrying must be true while holding rock")
	
	# Step 5B: PC Mouse Left-Click while carrying rock MUST throw rock instead of axe attack
	test_level.throw_called = false
	var mouse_left = InputEventMouseButton.new()
	mouse_left.button_index = MOUSE_BUTTON_LEFT
	mouse_left.pressed = true
	p3._unhandled_input(mouse_left)
	assert(test_level.throw_called == true, "Mouse left click while carrying must call throw_held_rock!")
	assert(p3.is_carrying == false, "player.is_carrying must be false after throw")
	assert(p3.current_state != p3.State.ATTACKING, "Player must NOT enter axe attacking state while throwing rock")
	print("[PASS] PC Mouse Left-Click while carrying rock properly triggers rock throw!")
	
	# Step 5C: PC Mouse Right-Click while carrying rock MUST throw rock instead of rope attack
	test_level.grab_rock(r_dummy)
	assert(p3.is_carrying == true, "player.is_carrying re-armed")
	test_level.throw_called = false
	var mouse_right = InputEventMouseButton.new()
	mouse_right.button_index = MOUSE_BUTTON_RIGHT
	mouse_right.pressed = true
	p3._unhandled_input(mouse_right)
	assert(test_level.throw_called == true, "Mouse right click while carrying must call throw_held_rock!")
	assert(p3.is_carrying == false, "player.is_carrying must be false after right-click throw")
	assert(p3.current_state != p3.State.ATTACKING, "Player must NOT enter rope attacking state while throwing rock")
	print("[PASS] PC Mouse Right-Click while carrying rock properly triggers rock throw!")
	
	# Step 5D: Calling player.attack("axe") or player.attack("rope") while carrying redirects to rock throw
	test_level.grab_rock(r_dummy)
	test_level.throw_called = false
	var atk_res = p3.attack("axe")
	assert(atk_res == false, "attack('axe') while carrying must return false")
	assert(test_level.throw_called == true, "attack('axe') while carrying must trigger throw_held_rock")
	assert(p3.is_carrying == false, "player.is_carrying must be false")
	print("[PASS] Attack actions while carrying properly intercepted and redirected to rock throw!")
	
	# Clean up
	r_dummy.queue_free()
	p3.queue_free()
	test_level.queue_free()
	dummy_rock.queue_free()
	p2.queue_free()
	mock_scene.queue_free()
	mobile_controls.queue_free()
	
	print("--- ALL TESTS PASSED SUCCESSFULLY ---")
	quit(0)
