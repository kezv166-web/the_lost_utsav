extends SceneTree

func _init():
	var vp = root
	var scene = load("res://scenes/levels/maze/maze.tscn").instantiate()
	vp.add_child(scene)
	var p = scene.get_node("Player")
	var a = p.get_node("AnimatedSprite3D")
	
	print("Initial anim: ", a.animation, " playing: ", a.is_playing(), " frames_res: ", a.sprite_frames.resource_path)
	
	# Simulate pressing UP
	Input.action_press("move_up")
	for i in range(25):
		p._physics_process(1.0/60.0)
		print("Step %d: anim=%s frame_idx=%d is_playing=%s speed_scale=%.2f vel=(%.2f, %.2f)" % [
			i, a.animation, a.frame, a.is_playing(), a.speed_scale, p.velocity.x, p.velocity.z
		])
	quit(0)
