extends Node

func _ready() -> void:
	print("========================================")
	print("--- ASUR COLLISION & DEPTH TEST SUITE ---")
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
	
	print("[1] Asur instance found. Position: ", asur.global_position)
	assert(asur.visible, "Asur must be visible")
	assert(asur.global_position.y >= 0.0, "Asur must not fall below floor level")
	
	# Verify feet collider
	var body_col = asur.get_node_or_null("CollisionShape3D")
	assert(body_col != null, "Body CollisionShape3D must exist")
	assert(body_col.shape is CylinderShape3D, "Body shape must be CylinderShape3D")
	var feet_shape: CylinderShape3D = body_col.shape
	print("[2] Feet collider radius: ", feet_shape.radius, " height: ", feet_shape.height)
	assert(is_equal_approx(feet_shape.radius, 0.5), "Feet collider radius must be 0.5")
	assert(is_equal_approx(feet_shape.height, 0.8), "Feet collider height must be 0.8")
	
	# Verify solid obstacle
	var solid_col = asur.get_node_or_null("SolidObstacle/SolidCollision")
	assert(solid_col != null, "SolidObstacle/SolidCollision must exist")
	assert(solid_col.shape is CylinderShape3D, "SolidObstacle shape must be CylinderShape3D")
	var solid_shape: CylinderShape3D = solid_col.shape
	assert(is_equal_approx(solid_shape.radius, 0.5), "SolidObstacle radius must be 0.5")
	
	# Verify separate Hurtbox
	var hurtbox = asur.get_node_or_null("Hurtbox")
	assert(hurtbox != null and hurtbox is Area3D, "Hurtbox Area3D must exist")
	assert(hurtbox.collision_layer == 4, "Hurtbox collision layer must be 4")
	var hurt_col = asur.get_node_or_null("Hurtbox/HurtCollision")
	assert(hurt_col != null and hurt_col.shape is CylinderShape3D, "HurtCollision must be CylinderShape3D")
	var hurt_shape: CylinderShape3D = hurt_col.shape
	print("[3] Hurtbox radius: ", hurt_shape.radius, " height: ", hurt_shape.height)
	assert(is_equal_approx(hurt_shape.radius, 1.4), "Hurtbox radius must be 1.4")
	assert(is_equal_approx(hurt_shape.height, 3.6), "Hurtbox height must be 3.6")
	
	# Verify Asur depth settings
	var asur_anim: AnimatedSprite3D = asur.get_node_or_null("AnimatedSprite3D")
	assert(asur_anim != null, "Asur AnimatedSprite3D must exist")
	print("[4] Asur AnimatedSprite3D: alpha_cut=", asur_anim.alpha_cut, " render_priority=", asur_anim.render_priority, " sorting_offset=", asur_anim.sorting_offset)
	assert(asur_anim.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "Asur alpha_cut must be ALPHA_CUT_DISCARD")
	assert(asur_anim.render_priority == 0, "Asur render_priority must be 0")
	assert(is_equal_approx(asur_anim.sorting_offset, 0.0), "Asur sorting_offset must be 0.0")
	
	# Verify Player depth settings
	var player = l3_map.get_node_or_null("Player")
	assert(player != null, "Player must exist in L3Map")
	var player_anim: AnimatedSprite3D = player.get_node_or_null("AnimatedSprite3D")
	assert(player_anim != null, "Player AnimatedSprite3D must exist")
	print("[5] Player AnimatedSprite3D: alpha_cut=", player_anim.alpha_cut, " render_priority=", player_anim.render_priority, " sorting_offset=", player_anim.sorting_offset)
	assert(player_anim.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "Player alpha_cut must be ALPHA_CUT_DISCARD")
	assert(player_anim.render_priority == 0, "Player render_priority must be 0")
	assert(is_equal_approx(player_anim.sorting_offset, 0.0), "Player sorting_offset must be 0.0")
	
	# Test Player walking directly towards Asur
	print("[6] Testing Player collision distance against Asur...")
	player.global_position = Vector3(0, 0.05, 1.0) # In front of Asur (South)
	await get_tree().physics_frame
	
	for i in range(60):
		player.velocity = Vector3(0, 0, -5.0) # Walk North toward Asur
		player.move_and_slide()
		await get_tree().physics_frame
	
	var player_final_z = player.global_position.z
	var asur_z = asur.global_position.z
	var distance_z = player_final_z - asur_z
	print("Player final Z: ", player_final_z, " Asur Z: ", asur_z, " Distance Z: ", distance_z)
	# Player radius is 0.35, feet collider is 0.5 -> expected contact distance ~0.85 (Z ~ -1.38)
	# Previously was stopped at Z ~ -0.716 (distance ~ 1.51)
	assert(player_final_z < -1.1, "Player should be able to walk past Z = -1.1 towards Asur feet!")
	assert(player_final_z > asur_z, "Player must not walk through Asur feet!")
	print("SUCCESS: Player stopped at contact distance: ", distance_z, "m (comfortably close to feet)")
	
	# Test Asur damage reaction
	print("[7] Testing damage reaction on Asur...")
	var initial_hp = asur.health
	asur.take_damage(1)
	assert(asur.health == initial_hp - 1, "Asur health must decrement by 1")
	print("SUCCESS: Asur health successfully decremented to ", asur.health)
	
	print("========================================")
	print("ALL ASUR COLLISION & DEPTH TESTS PASSED!")
	print("========================================")
	get_tree().quit(0)
