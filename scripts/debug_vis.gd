extends SceneTree

func _init():
	var s = load('res://scenes/levels/l1/l1_map.tscn').instantiate()
	root.add_child(s)
	var p = s.get_node('Player')
	var a = p.get_node('AnimatedSprite3D')
	var d = s.get_node('DungeonVisual')
	var c = s.get_node('CameraRig/Pivot/Camera3D')
	print('Player: ', p.global_position)
	print('AnimPos: ', a.global_position)
	print('AnimRot: ', a.global_rotation_degrees)
	print('DungRot: ', d.global_rotation_degrees)
	print('CamPos: ', c.global_position)
	print('CamRot: ', c.global_rotation_degrees)
	print('InFrustum: ', c.is_position_in_frustum(a.global_position))
	print('AnimScale: ', a.scale)
	quit(0)
