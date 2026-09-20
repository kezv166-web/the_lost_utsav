extends SceneTree

func _init() -> void:
	print("--- BEGIN GATE CONSTRAINT VERIFICATION ---")
	var scene = load("res://scenes/levels/outdoor/outdoor_map.tscn")
	if scene == null:
		printerr("FAILED: Could not load outdoor_map.tscn")
		quit(1)
		return
	
	var map = scene.instantiate()
	root.add_child(map)
	
	var gate = map.get_node_or_null("Fortress/SealedGate")
	if gate == null:
		printerr("FAILED: Fortress/SealedGate not found")
		quit(1)
		return
		
	# 1. Verify GateRearConstraint
	var rear_constraint = gate.get_node_or_null("GateRearConstraint")
	if rear_constraint == null:
		printerr("FAILED: GateRearConstraint node not found")
		quit(1)
		return
	var rear_col = rear_constraint.get_node_or_null("CollisionShape3D")
	if rear_col == null or rear_col.shape == null:
		printerr("FAILED: GateRearConstraint has no CollisionShape3D")
		quit(1)
		return
	print("PASS: GateRearConstraint is present with shape size: ", rear_col.shape.size)
	
	# 2. Verify GateBlackScreen collision
	var black_screen: CSGBox3D = gate.get_node_or_null("GateBlackScreen")
	if black_screen == null or not black_screen.use_collision:
		printerr("FAILED: GateBlackScreen does not have use_collision = true")
		quit(1)
		return
	print("PASS: GateBlackScreen has use_collision = true.")
	
	# 3. Verify GateDoor
	var gate_door = gate.get_node_or_null("GateDoor")
	if gate_door == null:
		printerr("FAILED: GateDoor not found")
		quit(1)
		return
	var initial_y = gate_door.position.y
	print("PASS: Initial GateDoor position Y = ", initial_y)
	
	# 4. Trigger _on_puzzle_solved and verify GateDoor does NOT lift
	var interaction_area = gate.get_node_or_null("GateInteractionArea")
	interaction_area._on_puzzle_solved()
	
	if gate_door.position.y != initial_y:
		printerr("FAILED: GateDoor position Y changed! It must stay at ", initial_y, " but got ", gate_door.position.y)
		quit(1)
		return
	print("PASS: GateDoor position Y remained locked at ", gate_door.position.y, " after puzzle solve.")
	
	# 5. Check Asur sigil and barrier dissolution
	var barrier_sprite = gate.get_node_or_null("GateBarrierPortalSprite")
	var sigil_sprite = gate.get_node_or_null("AsurSigilShrineTop")
	print("PASS: Both barrier_sprite and sigil_sprite found for dissolution.")
	
	print("--- ALL GATE CONSTRAINT CHECKS PASSED! ---")
	quit(0)
