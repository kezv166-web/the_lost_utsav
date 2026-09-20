@tool
extends SceneTree

func _init():
	print("==================================================")
	print("=== GODOT MAZE CLEANUP & WIDENING INITIALIZED  ===")
	print("==================================================")
	
	var map_path = "res://assets/environment/maze/maze_map_clean.png"
	var backup_path = "res://assets/environment/maze/maze_map_clean_pre_widen.png"
	var walkable_path = "res://assets/temp/walkable_clean.png"
	var boxes_path = "res://assets/temp/wall_boxes.json"
	var torches_path = "res://assets/temp/torches.json"
	var scene_path = "res://scenes/levels/maze/maze.tscn"
	
	var map_global = ProjectSettings.globalize_path(map_path)
	var backup_global = ProjectSettings.globalize_path(backup_path)
	var walkable_global = ProjectSettings.globalize_path(walkable_path)
	var boxes_global = ProjectSettings.globalize_path(boxes_path)
	var torches_global = ProjectSettings.globalize_path(torches_path)
	var scene_global = ProjectSettings.globalize_path(scene_path)
	
	# ---------------------------------------------------------
	# 1. SAFETY BACKUP
	# ---------------------------------------------------------
	if not FileAccess.file_exists(backup_path):
		var src_file = FileAccess.open(map_path, FileAccess.READ)
		if src_file:
			var data = src_file.get_buffer(src_file.get_length())
			src_file.close()
			var dst_file = FileAccess.open(backup_path, FileAccess.WRITE)
			if dst_file:
				dst_file.store_buffer(data)
				dst_file.close()
				print("[BACKUP] Created safety backup: " + backup_path)
	else:
		print("[BACKUP] Safety backup already exists: " + backup_path)

	# ---------------------------------------------------------
	# 2. LOAD IMAGES
	# ---------------------------------------------------------
	var maze_img = Image.load_from_file(map_global)
	if not maze_img:
		push_error("Failed to load maze_map_clean.png!")
		quit(1)
		return
	print("[LOAD] Loaded maze_map_clean.png: %dx%d" % [maze_img.get_width(), maze_img.get_height()])
	
	var walk_img = Image.load_from_file(walkable_global)
	if not walk_img:
		push_error("Failed to load walkable_clean.png!")
		quit(1)
		return
	print("[LOAD] Loaded walkable_clean.png: %dx%d" % [walk_img.get_width(), walk_img.get_height()])

	# ---------------------------------------------------------
	# 3. INPAINT ALL CORRIDOR CLUTTER ELEMENTS
	# ---------------------------------------------------------
	var clutter_list = [
		# Screenshot area
		["crate_1", 870, 465, 56, 56, Vector2i(770, 465)],
		["crate_2", 830, 615, 56, 56, Vector2i(830, 545)],
		["barrel_debris", 845, 750, 68, 76, Vector2i(770, 750)],
		["bone_cage", 1295, 765, 70, 92, Vector2i(1220, 765)],
		["floor_pit", 1165, 635, 42, 42, Vector2i(1220, 635)],
		["debris_topright", 1240, 390, 68, 64, Vector2i(1240, 320)],
		["rubble_farright", 1415, 495, 48, 48, Vector2i(1415, 440)],
		
		# Center & North
		["crate_center_1", 575, 465, 58, 58, Vector2i(510, 465)],
		["crate_center_2", 405, 620, 58, 58, Vector2i(340, 620)],
		["debris_north", 440, 185, 68, 64, Vector2i(440, 260)],
		["spiderweb_north", 440, 70, 68, 55, Vector2i(440, 260)],
		["crate_north_1", 365, 95, 58, 58, Vector2i(300, 95)],
		["crate_north_2", 395, 145, 58, 54, Vector2i(300, 95)],
		["grate_center_bottom", 405, 775, 62, 58, Vector2i(340, 775)],

		# West & South-West
		["crate_west_top", 195, 255, 58, 58, Vector2i(195, 190)],
		["debris_west_top", 95, 325, 64, 64, Vector2i(95, 260)],
		["grate_west_mid", 115, 525, 58, 54, Vector2i(115, 460)],
		["barrel_west_mid", 185, 595, 58, 64, Vector2i(185, 530)],
		["crate_west_mid", 235, 600, 58, 58, Vector2i(235, 530)],
		["debris_west_mid", 185, 685, 64, 64, Vector2i(185, 530)],
		["barrel_west_bottom", 245, 775, 58, 64, Vector2i(245, 710)],
		["debris_west_bottom", 225, 845, 64, 64, Vector2i(160, 845)]
	]
	
	for item in clutter_list:
		var item_name = item[0]
		var x = item[1]
		var y = item[2]
		var w = item[3]
		var h = item[4]
		var src_pos = item[5]
		
		# Sample clean floor from adjacent corridor tile
		var sample_rect = Rect2i(src_pos.x, src_pos.y, w, h)
		maze_img.blit_rect(maze_img, sample_rect, Vector2i(x, y))
		walk_img.fill_rect(Rect2i(x, y, w, h), Color(1, 1, 1, 1))
		print("  [INPAINT] Replaced %s with seamless stone floor at (%d, %d, %dx%d)" % [item_name, x, y, w, h])

	# ---------------------------------------------------------
	# 4. CARVE BACK PROTRUDING WALL BLOCKS AT T-JUNCTION
	# ---------------------------------------------------------
	# Wall_62 is at px [1056..1088], py [544..576] (col 33, row 17)
	# Wall_25 bottom corner is at px [1024..1056], py [544..576] (col 32, row 17)
	# Sample floor from adjacent open floor at px=1088..1152, py=544..576
	var tj_sample_pos = Vector2i(1088, 544)
	maze_img.blit_rect(maze_img, Rect2i(tj_sample_pos.x, tj_sample_pos.y, 64, 32), Vector2i(1024, 544))
	walk_img.fill_rect(Rect2i(1024, 544, 64, 32), Color(1, 1, 1, 1))
	print("  [WALL CARVE] Carved Wall_62 and Wall_25 bottom block at (1024, 544, 64x32)")

	# Save updated textures
	maze_img.save_png(map_global)
	print("[SAVE] Saved updated map texture: " + map_global)
	walk_img.save_png(walkable_global)
	print("[SAVE] Saved updated walkable mask: " + walkable_global)

	# ---------------------------------------------------------
	# 5. UPDATE wall_boxes.json
	# ---------------------------------------------------------
	var b_file = FileAccess.open(boxes_path, FileAccess.READ)
	if not b_file:
		push_error("Could not read wall_boxes.json!")
		quit(1)
		return
	var orig_boxes = JSON.parse_string(b_file.get_as_text())
	b_file.close()

	var new_boxes = []
	var new_idx = 0
	for b in orig_boxes:
		if (b.get("x") == 3.8 and b.get("z") == 0.6) or (b.get("name") == "Wall_62" and b.get("x") == 3.8):
			print("  [BOXES] Deleted Wall_62 (T-junction protrusion removed)")
			continue
		elif b.get("x") == 3.4 and (b.get("sz") == 4.0 or b.get("z") == -1.2):
			# Carve back bottom 0.4m block: sz was 4.0 -> 3.6, z was -1.2 -> -1.4
			var mod_b = {
				"name": "Wall_" + str(new_idx),
				"x": b["x"],
				"z": -1.4,
				"sx": b["sx"],
				"sz": 3.6
			}
			new_boxes.append(mod_b)
			print("  [BOXES] Modified Wall_25 -> sz=3.6, z=-1.4 (bottom corner carved)")
			new_idx += 1
		else:
			var mod_b = {
				"name": "Wall_" + str(new_idx),
				"x": b["x"],
				"z": b["z"],
				"sx": b["sx"],
				"sz": b["sz"]
			}
			new_boxes.append(mod_b)
			new_idx += 1

	print("[BOXES] Total wall boxes: %d (reduced from %d)" % [new_boxes.size(), orig_boxes.size()])
	var out_b_file = FileAccess.open(boxes_path, FileAccess.WRITE)
	out_b_file.store_string(JSON.stringify(new_boxes, "\t"))
	out_b_file.close()
	print("[SAVE] Saved updated assets/temp/wall_boxes.json")

	# ---------------------------------------------------------
	# 6. REGENERATE maze.tscn AT SCALE = 2.0
	# ---------------------------------------------------------
	var t_file = FileAccess.open(torches_path, FileAccess.READ)
	var torches = JSON.parse_string(t_file.get_as_text())
	t_file.close()

	var SCALE: float = 2.0
	var total_steps: int = 13 + new_boxes.size()
	var lines: Array[String] = []

	lines.append('[gd_scene load_steps=%d format=3]' % total_steps)
	lines.append('')
	lines.append('[ext_resource type="Script" path="res://scripts/world/maze_controller.gd" id="1_controller"]')
	lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/maze_map_clean.png" id="2_map_tex"]')
	lines.append('[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="3_player"]')
	lines.append('[ext_resource type="PackedScene" path="res://scenes/world/camera_rig.tscn" id="4_camera"]')
	lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/key_gold.png" id="5_key_tex"]')
	lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/chest_gold.png" id="6_chest_tex"]')
	lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/gate_iron_large.png" id="7_gate_tex"]')
	lines.append('[ext_resource type="PackedScene" path="res://scenes/world/black_tunnel.tscn" id="8_tunnel_scene"]')
	lines.append('')
	lines.append('[sub_resource type="Environment" id="Environment_maze"]')
	lines.append('background_mode = 1')
	lines.append('background_color = Color(0.02, 0.015, 0.03, 1)')
	lines.append('ambient_light_source = 2')
	lines.append('ambient_light_color = Color(0.28, 0.20, 0.26, 1)')
	lines.append('ambient_light_energy = 0.65')
	lines.append('tonemap_mode = 2')
	lines.append('')
	lines.append('[sub_resource type="BoxShape3D" id="Shape_Floor"]')
	lines.append('size = Vector3(%.1f, 1, %.1f)' % [24.0 * SCALE, 16.0 * SCALE])
	lines.append('')
	lines.append('[sub_resource type="BoxShape3D" id="Shape_KeyTrigger"]')
	lines.append('size = Vector3(%.4f, 1.5, %.4f)' % [1.2 * SCALE, 1.2 * SCALE])
	lines.append('')
	lines.append('[sub_resource type="BoxShape3D" id="Shape_ChestTrigger"]')
	lines.append('size = Vector3(%.4f, 1.5, %.4f)' % [1.4 * SCALE, 1.4 * SCALE])
	lines.append('')
	lines.append('[sub_resource type="BoxShape3D" id="Shape_ExitTrigger"]')
	lines.append('size = Vector3(%.4f, 2.0, %.4f)' % [2.2 * SCALE, 2.0 * SCALE])
	lines.append('')

	for i in range(new_boxes.size()):
		var b = new_boxes[i]
		lines.append('[sub_resource type="BoxShape3D" id="Shape_Wall_%d"]' % i)
		lines.append('size = Vector3(%.4f, 2.5, %.4f)' % [b["sx"] * SCALE, b["sz"] * SCALE])
		lines.append('')

	# Root node
	lines.append('[node name="Maze" type="Node3D"]')
	lines.append('script = ExtResource("1_controller")')
	lines.append('')
	lines.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
	lines.append('environment = SubResource("Environment_maze")')
	lines.append('')
	lines.append('[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]')
	lines.append('transform = Transform3D(0.866025, -0.25, 0.433013, 0, 0.866025, 0.5, -0.5, -0.433013, 0.75, 0, 15, 0)')
	lines.append('light_color = Color(0.7, 0.65, 0.8, 1)')
	lines.append('light_energy = 0.35')
	lines.append('shadow_enabled = false')
	lines.append('')

	# Map visual
	lines.append('[node name="DungeonVisual" type="Sprite3D" parent="."]')
	lines.append('transform = Transform3D(%.1f, 0, 0, 0, 0, %.1f, 0, %.1f, 0, 0, 0.01, 0)' % [SCALE, SCALE, -SCALE])
	lines.append('pixel_size = 0.0125')
	lines.append('texture_filter = 0')
	lines.append('sorting_offset = -10.0')
	lines.append('texture = ExtResource("2_map_tex")')
	lines.append('')

	# Floor ground
	lines.append('[node name="FloorGround" type="StaticBody3D" parent="."]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)')
	lines.append('')
	lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="FloorGround"]')
	lines.append('shape = SubResource("Shape_Floor")')
	lines.append('')

	# Wall Collisions
	lines.append('[node name="MazeWalls" type="Node3D" parent="."]')
	lines.append('')
	for i in range(new_boxes.size()):
		var b = new_boxes[i]
		lines.append('[node name="%s" type="StaticBody3D" parent="MazeWalls"]' % b["name"])
		lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 1.25, %.4f)' % [b["x"] * SCALE, b["z"] * SCALE])
		lines.append('')
		lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="MazeWalls/%s"]' % b["name"])
		lines.append('shape = SubResource("Shape_Wall_%d")' % i)
		lines.append('')

	# Torches
	lines.append('[node name="MazeDecorations" type="Node3D" parent="."]')
	lines.append('')
	lines.append('[node name="Torches" type="Node3D" parent="MazeDecorations"]')
	lines.append('')
	for t in torches:
		lines.append('[node name="TorchLight_%s" type="OmniLight3D" parent="MazeDecorations/Torches"]' % str(t["id"]))
		lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.5, %.4f)' % [t["x"] * SCALE, t["z"] * SCALE])
		lines.append('light_color = Color(1, 0.65, 0.28, 1)')
		lines.append('light_energy = 1.6')
		lines.append('omni_range = %.2f' % (3.2 * SCALE))
		lines.append('omni_attenuation = 1.2')
		lines.append('')

	# Interactables
	lines.append('[node name="Interactables" type="Node3D" parent="."]')
	lines.append('')

	# Golden Key
	lines.append('[node name="GoldenKey" type="Area3D" parent="Interactables"]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.2, %.4f)' % [1.75 * SCALE, -3.42 * SCALE])
	lines.append('')
	lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/GoldenKey"]')
	lines.append('shape = SubResource("Shape_KeyTrigger")')
	lines.append('')
	lines.append('[node name="KeyVisual" type="Sprite3D" parent="Interactables/GoldenKey"]')
	lines.append('transform = Transform3D(%.1f, 0, 0, 0, 0, %.1f, 0, %.1f, 0, 0, 0.25, 0)' % [SCALE, SCALE, -SCALE])
	lines.append('pixel_size = 0.0125')
	lines.append('texture_filter = 0')
	lines.append('texture = ExtResource("5_key_tex")')
	lines.append('')
	lines.append('[node name="KeyLight" type="OmniLight3D" parent="Interactables/GoldenKey"]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)')
	lines.append('light_color = Color(1, 0.85, 0.3, 1)')
	lines.append('light_energy = 1.2')
	lines.append('omni_range = %.2f' % (1.8 * SCALE))
	lines.append('')

	# Chest
	lines.append('[node name="Chest" type="Area3D" parent="Interactables"]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.2, %.4f)' % [6.15 * SCALE, 2.47 * SCALE])
	lines.append('')
	lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/Chest"]')
	lines.append('shape = SubResource("Shape_ChestTrigger")')
	lines.append('')
	lines.append('[node name="ChestVisual" type="Sprite3D" parent="Interactables/Chest"]')
	lines.append('transform = Transform3D(%.1f, 0, 0, 0, 0, %.1f, 0, %.1f, 0, 0, 0.15, 0)' % [SCALE, SCALE, -SCALE])
	lines.append('pixel_size = 0.0125')
	lines.append('texture_filter = 0')
	lines.append('texture = ExtResource("6_chest_tex")')
	lines.append('')

	# Exit Gate
	lines.append('[node name="MazeExit" type="Area3D" parent="Interactables"]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.2, %.4f)' % [7.27 * SCALE, -4.65 * SCALE])
	lines.append('')
	lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/MazeExit"]')
	lines.append('shape = SubResource("Shape_ExitTrigger")')
	lines.append('')
	lines.append('[node name="GateVisual" type="Sprite3D" parent="Interactables/MazeExit"]')
	lines.append('transform = Transform3D(%.1f, 0, 0, 0, 0, %.1f, 0, %.1f, 0, 0, 0.15, 0)' % [SCALE, SCALE, -SCALE])
	lines.append('pixel_size = 0.0125')
	lines.append('texture_filter = 0')
	lines.append('texture = ExtResource("7_gate_tex")')
	lines.append('')
	lines.append('[node name="Prompt" type="Label3D" parent="Interactables/MazeExit"]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.6, %.2f)' % (0.5 * SCALE))
	lines.append('billboard = 1')
	lines.append('text = "[E] Unlock Exit Gate"')
	lines.append('font_size = 24')
	lines.append('')

	# MouseTunnels
	lines.append('[node name="MouseTunnels" type="Node3D" parent="."]')
	lines.append('')
	lines.append('[node name="BlackTunnel_A" parent="MouseTunnels" instance=ExtResource("8_tunnel_scene")]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.05, %.4f)' % [-8.16 * SCALE, 2.0 * SCALE])
	lines.append('tunnel_id = "BlackTunnel_A"')
	lines.append('destination_id = "BlackTunnel_B"')
	lines.append('emergence_offset = Vector3(0, 0, %.2f)' % (0.4 * SCALE))
	lines.append('')
	lines.append('[node name="BlackTunnel_B" parent="MouseTunnels" instance=ExtResource("8_tunnel_scene")]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.05, %.4f)' % [4.5 * SCALE, 2.0 * SCALE])
	lines.append('tunnel_id = "BlackTunnel_B"')
	lines.append('destination_id = "BlackTunnel_A"')
	lines.append('emergence_offset = Vector3(0, 0, %.2f)' % (0.4 * SCALE))
	lines.append('')

	# PlayerSpawn
	lines.append('[node name="PlayerSpawn" type="Marker3D" parent="."]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.1, %.4f)' % [-8.16 * SCALE, 4.9 * SCALE])
	lines.append('')

	# Player instance
	lines.append('[node name="Player" parent="." groups=["player"] instance=ExtResource("3_player")]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.1, %.4f)' % [-8.16 * SCALE, 4.9 * SCALE])
	lines.append('')

	# CameraRig instance
	lines.append('[node name="CameraRig" parent="." instance=ExtResource("4_camera")]')
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, 0.1, %.4f)' % [-8.16 * SCALE, 4.9 * SCALE])
	lines.append('')

	# MazeHUD (CanvasLayer)
	lines.append('[node name="MazeHUD" type="CanvasLayer" parent="."]')
	lines.append('')
	lines.append('[node name="Margin" type="MarginContainer" parent="MazeHUD"]')
	lines.append('anchors_preset = 15')
	lines.append('anchor_right = 1.0')
	lines.append('anchor_bottom = 1.0')
	lines.append('grow_horizontal = 2')
	lines.append('grow_vertical = 2')
	lines.append('theme_override_constants/margin_left = 20')
	lines.append('theme_override_constants/margin_top = 16')
	lines.append('theme_override_constants/margin_right = 20')
	lines.append('theme_override_constants/margin_bottom = 16')
	lines.append('')
	lines.append('[node name="VBox" type="VBoxContainer" parent="MazeHUD/Margin"]')
	lines.append('layout_mode = 2')
	lines.append('size_flags_vertical = 0')
	lines.append('')
	lines.append('[node name="TopBar" type="HBoxContainer" parent="MazeHUD/Margin/VBox"]')
	lines.append('layout_mode = 2')
	lines.append('')
	lines.append('[node name="FormBadge" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
	lines.append('layout_mode = 2')
	lines.append('theme_override_colors/font_color = Color(1, 0.85, 0.3, 1)')
	lines.append('theme_override_font_sizes/font_size = 18')
	lines.append('text = "FORM: MUSHIKA"')
	lines.append('')
	lines.append('[node name="Spacer1" type="Control" parent="MazeHUD/Margin/VBox/TopBar"]')
	lines.append('layout_mode = 2')
	lines.append('size_flags_horizontal = 3')
	lines.append('')
	lines.append('[node name="ObjectiveLabel" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
	lines.append('layout_mode = 2')
	lines.append('theme_override_colors/font_color = Color(0.9, 0.85, 0.95, 1)')
	lines.append('theme_override_font_sizes/font_size = 16')
	lines.append('text = "Objective: Search the maze for the Golden Key"')
	lines.append('')
	lines.append('[node name="Spacer2" type="Control" parent="MazeHUD/Margin/VBox/TopBar"]')
	lines.append('layout_mode = 2')
	lines.append('size_flags_horizontal = 3')
	lines.append('')
	lines.append('[node name="KeyTracker" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
	lines.append('layout_mode = 2')
	lines.append('theme_override_colors/font_color = Color(1, 0.8, 0.2, 1)')
	lines.append('theme_override_font_sizes/font_size = 18')
	lines.append('text = "Keys: 0 / 1"')
	lines.append('')
	lines.append('[node name="MessageBanner" type="Label" parent="MazeHUD/Margin"]')
	lines.append('layout_mode = 2')
	lines.append('size_flags_horizontal = 4')
	lines.append('size_flags_vertical = 8')
	lines.append('theme_override_colors/font_color = Color(1, 0.95, 0.85, 1)')
	lines.append('theme_override_font_sizes/font_size = 20')
	lines.append('horizontal_alignment = 1')
	lines.append('vertical_alignment = 1')
	lines.append('')

	var scn_file = FileAccess.open(scene_path, FileAccess.WRITE)
	scn_file.store_string("\n".join(lines))
	scn_file.close()
	print("[SAVE] Successfully regenerated: " + scene_path)

	print("==================================================")
	print("=== ALL MAZE CLEANUP & REGENERATION COMPLETED! ===")
	print("==================================================")
	quit(0)
