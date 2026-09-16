@tool
extends SceneTree

func _init() -> void:
	extract_assets_now()
	quit(0)

static func extract_assets_now() -> void:
	print("--- EXTRACTING ASSETS FROM outdoor-elements-tilesets.png ---")
	var sheet_path = "res://assets/outdoor-elements-tilesets.png"
	var img = Image.load_from_file(sheet_path)
	var fire_path = "res://assets/fire_animation.png"
	var fire_img = Image.load_from_file(fire_path)
	if fire_img:
		extract_fire_sheet(fire_img)
	else:
		printerr("FAILED to load fire sheet: ", fire_path)
	if not img:
		printerr("FAILED to load sheet: ", sheet_path)
		return

	var sprites = {
		# Background & Sky
		"bg_parallax_mountains_castle.png": Rect2i(15, 874, 1039, 131),
		"moon_blood_red.png": Rect2i(1073, 633, 64, 65),
		"cloud_dark_01.png": Rect2i(1141, 634, 86, 67),
		"cloud_dark_02.png": Rect2i(1223, 633, 125, 63),
		"cloud_dark_03.png": Rect2i(1354, 633, 96, 68),
		"mist_fog_01.png": Rect2i(1074, 712, 45, 118),
		"mist_fog_02.png": Rect2i(1140, 710, 57, 108),
		"mist_fog_03.png": Rect2i(1225, 708, 41, 122),
		"mist_fog_04.png": Rect2i(1281, 709, 49, 123),

		# Cliffs & Rocks
		"cliff_tall_01.png": Rect2i(388, 45, 93, 115),
		"cliff_block_02.png": Rect2i(490, 44, 89, 93),
		"cliff_massive_03.png": Rect2i(588, 40, 115, 115),
		"cliff_overhang_04.png": Rect2i(384, 160, 90, 110),
		"cliff_tiered_05.png": Rect2i(482, 138, 109, 75),
		"rock_cluster_mossy.png": Rect2i(604, 166, 59, 61),
		"rock_sharp_cluster.png": Rect2i(620, 217, 87, 97),
		"rock_spire_01.png": Rect2i(478, 215, 61, 96),
		"rock_spire_02.png": Rect2i(547, 218, 71, 92),
		"rock_small_01.png": Rect2i(374, 274, 50, 44),
		"rock_small_02.png": Rect2i(435, 279, 40, 37),

		# Waterfalls & Chutes & Rock Shelves
		"waterfall_fall_01.png": Rect2i(715, 51, 79, 134),
		"waterfall_fall_02.png": Rect2i(807, 54, 74, 126),
		"waterfall_fall_03.png": Rect2i(894, 47, 90, 140),
		"waterfall_splash_01.png": Rect2i(715, 194, 83, 115),
		"waterfall_splash_02.png": Rect2i(804, 225, 57, 90),
		"waterfall_splash_03.png": Rect2i(923, 195, 83, 119),
		"waterfall_rock_shelf.png": Rect2i(800, 227, 56, 85),
		"waterfall_chute_narrow.png": Rect2i(875, 227, 43, 84),
		"water_stream_surface.png": Rect2i(797, 192, 97, 20),

		# Castle Towers & Ramparts
		"tower_spire_brazier.png": Rect2i(12, 365, 61, 212),
		"tower_banner_brazier.png": Rect2i(83, 364, 64, 215),
		"tower_roofed.png": Rect2i(152, 369, 76, 160),
		"tower_spiked.png": Rect2i(235, 369, 86, 179),
		"rampart_modular_wall.png": Rect2i(1034, 47, 46, 96),
		"rampart_battlement_segment.png": Rect2i(1101, 53, 104, 83),

		# Bridge & Railings & Chains
		"bridge_balustrade_posts.png": Rect2i(485, 458, 163, 129),
		"bridge_post_tall.png": Rect2i(664, 444, 65, 141),
		"bridge_post_banner.png": Rect2i(735, 453, 58, 130),
		"hanging_chain.png": Rect2i(278, 774, 107, 66),

		# Statues & Monuments
		"asur_guard_spear.png": Rect2i(843, 370, 74, 209),
		"asur_guard_weapon.png": Rect2i(921, 374, 67, 205),
		"asur_statue_seated.png": Rect2i(992, 370, 70, 207),
		"asur_sigil_shrine.png": Rect2i(1065, 367, 89, 148),

		# Sealed Gate Components
		"sealed_gate_pillar_left.png": Rect2i(1180, 369, 33, 147),
		"sealed_gate_portal_barrier.png": Rect2i(1254, 367, 101, 210),
		"gate_door_closed.png": Rect2i(1396, 469, 128, 106),

		# Banners
		"asur_hanging_banner_large.png": Rect2i(14, 634, 65, 162),
		"asur_hanging_banner_sigil.png": Rect2i(87, 633, 66, 161),
		"asur_banner_medium.png": Rect2i(160, 634, 65, 128),
		"asur_banner_narrow.png": Rect2i(231, 634, 47, 113),
		"asur_banner_draped.png": Rect2i(95, 735, 70, 80),

		# Props & Dressing
		"brazier_flaming.png": Rect2i(299, 632, 49, 83),
		"torch_sconce.png": Rect2i(374, 632, 42, 85),
		"wooden_post_fence.png": Rect2i(399, 786, 88, 54),
		"crates_stacked.png": Rect2i(498, 798, 67, 42),
		"barrel_wood.png": Rect2i(580, 801, 56, 39),
		"broken_cart.png": Rect2i(576, 703, 125, 88),
		"cage_hanging.png": Rect2i(646, 794, 53, 42),
		"skulls_pile.png": Rect2i(348, 725, 45, 45),

		# Vegetation
		"dead_tree_gnarled.png": Rect2i(728, 637, 129, 208),
		"mossy_boulder.png": Rect2i(865, 631, 94, 85),
		"bush_corrupted_red.png": Rect2i(975, 632, 71, 101),
		"bush_spiked_red.png": Rect2i(903, 756, 67, 89),
		"shrub_small_green.png": Rect2i(861, 719, 57, 47)
	}

	var out_dir = "res://assets/environment/"
	for file_name in sprites:
		var rect: Rect2i = sprites[file_name]
		var crop = img.get_region(rect)
		var cw = crop.get_width()
		var ch = crop.get_height()
		for cy in range(ch):
			for cx in range(cw):
				var px = crop.get_pixel(cx, cy)
				if px.a < 0.04:
					crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
		var used = crop.get_used_rect()
		if used.size.x > 0 and used.size.y > 0 and file_name in ["sealed_gate_portal_barrier.png", "cliff_massive_03.png", "asur_sigil_shrine.png"]:
			crop = crop.get_region(used)
		var target_path = out_dir + file_name
		var err = crop.save_png(target_path)
		if err == OK:
			print("Saved: ", file_name, " (", crop.get_size().x, "x", crop.get_size().y, ")")
		else:
			printerr("Error saving ", file_name, ": ", err)

	print("--- EXTRACTION COMPLETED SUCCESSFULLY ---")

static func extract_fire_sheet(fire_img: Image) -> void:
	print("--- EXTRACTING FIRE, BRAZIER & TORCH ANIMATIONS FROM fire_animation.png ---")
	fire_img.convert(Image.FORMAT_RGBA8)
	var brazier_dir = "res://assets/environment/fire/brazier/"
	var flame_dir = "res://assets/environment/fire/flame_only/"
	var torch_dir = "res://assets/environment/fire/torch/"
	var part_dir = "res://assets/environment/fire/particles/"

	var da = DirAccess.open("res://")
	if da:
		da.make_dir_recursive("assets/environment/fire/brazier")
		da.make_dir_recursive("assets/environment/fire/flame_only")
		da.make_dir_recursive("assets/environment/fire/torch")
		da.make_dir_recursive("assets/environment/fire/particles")

	# Inset brazier boxes by 2px to avoid outer border lines on the sprite sheet
	var brazier_boxes = [
		Rect2i(30, 150, 122, 190),
		Rect2i(169, 150, 120, 190),
		Rect2i(306, 150, 121, 190),
		Rect2i(443, 150, 122, 190),
		Rect2i(582, 150, 121, 190),
		Rect2i(719, 150, 115, 190),
		Rect2i(851, 150, 118, 190),
		Rect2i(985, 150, 124, 190)
	]

	var CW = 120
	var CH = 190
	var TARGET_GROUND_Y = 184
	var TARGET_CENTER_X = 60.0

	for i in range(brazier_boxes.size()):
		var box: Rect2i = brazier_boxes[i]
		var crop: Image = fire_img.get_region(box)
		var w_crop = crop.get_width()
		var h_crop = crop.get_height()

		# Zero residue / crisp alpha extraction
		for cy in range(h_crop):
			for cx in range(w_crop):
				var c: Color = crop.get_pixel(cx, cy)
				var max_v = maxf(c.r, maxf(c.g, c.b))
				if cy < 78:
					# Flame / ember zone above stone brazier rim
					var is_flame = (c.r >= 0.40 and (c.r > c.b * 1.3 or c.g >= 0.20)) or c.r >= 0.60
					var is_ember = (c.r >= 0.42 and c.r > c.b * 1.2 and (c.g >= 0.12 or c.r >= 0.52))
					if is_flame or is_ember:
						crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))
					else:
						# Dark smoky halo / background is stripped cleanly
						crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
				else:
					# Stone brazier zone
					if max_v < 0.12:
						crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
					else:
						crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))

		# Clear outer background from left and right edges in stone zone
		for cy in range(78, h_crop):
			var lx = 0
			while lx < w_crop and crop.get_pixel(lx, cy).a > 0.0 and maxf(crop.get_pixel(lx, cy).r, maxf(crop.get_pixel(lx, cy).g, crop.get_pixel(lx, cy).b)) < 0.13:
				crop.set_pixel(lx, cy, Color(0, 0, 0, 0))
				lx += 1
			var rx = w_crop - 1
			while rx >= 0 and crop.get_pixel(rx, cy).a > 0.0 and maxf(crop.get_pixel(rx, cy).r, maxf(crop.get_pixel(rx, cy).g, crop.get_pixel(rx, cy).b)) < 0.13:
				crop.set_pixel(rx, cy, Color(0, 0, 0, 0))
				rx -= 1

		# Ground lock alignment
		var bottom_y = 0
		var xs_at_bottom = []
		for cy in range(h_crop - 1, 75, -1):
			var row_has_stone = false
			for cx in range(w_crop):
				if crop.get_pixel(cx, cy).a > 0.0:
					row_has_stone = true
					if bottom_y == 0:
						bottom_y = cy
					if cy >= bottom_y - 15:
						xs_at_bottom.append(cx)
			if bottom_y > 0 and not row_has_stone and cy < bottom_y - 15:
				break

		var center_x = w_crop / 2.0
		if xs_at_bottom.size() > 0:
			var sum_x = 0.0
			for xv in xs_at_bottom:
				sum_x += xv
			center_x = sum_x / float(xs_at_bottom.size())

		var canvas: Image = Image.create(CW, CH, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		var paste_x = int(round(TARGET_CENTER_X - center_x))
		var paste_y = int(round(float(TARGET_GROUND_Y) - float(bottom_y)))
		canvas.blit_rect(crop, Rect2i(0, 0, w_crop, h_crop), Vector2i(paste_x, paste_y))

		var out_file = brazier_dir + "brazier_anim_" + str(i) + ".png"
		canvas.save_png(out_file)
		print("Saved brazier frame: ", out_file)

		if i == 0:
			canvas.save_png("res://assets/environment/brazier_flaming.png")

		# Extract pure Flame Only (without stone base, zero residue)
		var flame_canvas: Image = Image.create(CW, 96, false, Image.FORMAT_RGBA8)
		flame_canvas.fill(Color(0, 0, 0, 0))
		# Copy the flame from brazier canvas (y: 0 to 76)
		for f_y in range(min(76, CH)):
			for f_x in range(CW):
				var fc = canvas.get_pixel(f_x, f_y)
				if fc.a > 0.0:
					# Filter out any stone rim pixels
					if f_y >= 70 and (fc.b > fc.r * 0.7 or fc.r < 0.40):
						continue
					flame_canvas.set_pixel(f_x, f_y + 12, fc)
		flame_canvas.save_png(flame_dir + "flame_anim_" + str(i) + ".png")

	# Wall Torch (8 frames)
	var torch_boxes = [
		Rect2i(30, 430, 122, 230),
		Rect2i(169, 430, 120, 230),
		Rect2i(306, 430, 121, 230),
		Rect2i(443, 430, 122, 230),
		Rect2i(582, 430, 121, 230),
		Rect2i(719, 430, 115, 230),
		Rect2i(851, 430, 118, 230),
		Rect2i(985, 430, 124, 230)
	]
	var TW = 80
	var TH = 220
	var TORCH_GROUND_Y = 214
	var TORCH_CENTER_X = 40.0

	for ti in range(torch_boxes.size()):
		var t_box: Rect2i = torch_boxes[ti]
		var t_crop: Image = fire_img.get_region(t_box)
		var tw = t_crop.get_width()
		var th = t_crop.get_height()

		for cy in range(th):
			for cx in range(tw):
				var c: Color = t_crop.get_pixel(cx, cy)
				var max_v = maxf(c.r, maxf(c.g, c.b))
				if cy < 75:
					var is_flame = (c.r >= 0.40 and (c.r > c.b * 1.3 or c.g >= 0.20)) or c.r >= 0.60
					var is_ember = (c.r >= 0.42 and c.r > c.b * 1.2 and (c.g >= 0.12 or c.r >= 0.52))
					if is_flame or is_ember:
						t_crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))
					else:
						t_crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
				else:
					if max_v < 0.12:
						t_crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
					else:
						t_crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))

		var t_bottom_y = 0
		var t_xs_bottom = []
		for cy in range(th - 1, 70, -1):
			var has_torch = false
			for cx in range(tw):
				if t_crop.get_pixel(cx, cy).a > 0.0:
					has_torch = true
					if t_bottom_y == 0:
						t_bottom_y = cy
					if cy >= t_bottom_y - 15:
						t_xs_bottom.append(cx)
			if t_bottom_y > 0 and not has_torch and cy < t_bottom_y - 15:
				break

		var t_center_x = tw / 2.0
		if t_xs_bottom.size() > 0:
			var sx = 0.0
			for xv in t_xs_bottom:
				sx += xv
			t_center_x = sx / float(t_xs_bottom.size())

		var t_canvas: Image = Image.create(TW, TH, false, Image.FORMAT_RGBA8)
		t_canvas.fill(Color(0, 0, 0, 0))
		var t_px = int(round(TORCH_CENTER_X - t_center_x))
		var t_py = int(round(float(TORCH_GROUND_Y) - float(t_bottom_y)))
		t_canvas.blit_rect(t_crop, Rect2i(0, 0, tw, th), Vector2i(t_px, t_py))
		t_canvas.save_png(torch_dir + "torch_anim_" + str(ti) + ".png")
		print("Saved torch frame: ", torch_dir + "torch_anim_" + str(ti) + ".png")

	# Static variations
	var variations = [
		["brazier_lit.png", Rect2i(1149, 150, 110, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78],
		["brazier_low.png", Rect2i(1277, 150, 110, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78],
		["brazier_unlit.png", Rect2i(1402, 150, 107, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78],
		["torch_lit.png", Rect2i(1149, 430, 110, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75],
		["torch_low.png", Rect2i(1277, 430, 110, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75],
		["torch_unlit.png", Rect2i(1402, 430, 107, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75]
	]
	for v in variations:
		var v_name: String = v[0]
		var v_box: Rect2i = v[1]
		var v_dir: String = v[2]
		var v_cw: int = v[3]
		var v_ch: int = v[4]
		var v_tcx: float = v[5]
		var v_tgy: int = v[6]
		var v_rim_y: int = v[7]

		var v_crop: Image = fire_img.get_region(v_box)
		var vw = v_crop.get_width()
		var vh = v_crop.get_height()

		for cy in range(vh):
			for cx in range(vw):
				var c: Color = v_crop.get_pixel(cx, cy)
				var max_v = maxf(c.r, maxf(c.g, c.b))
				if cy < v_rim_y:
					var is_flame = (c.r >= 0.40 and (c.r > c.b * 1.3 or c.g >= 0.20)) or c.r >= 0.60
					var is_ember = (c.r >= 0.42 and c.r > c.b * 1.2 and (c.g >= 0.12 or c.r >= 0.52))
					if is_flame or is_ember:
						v_crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))
					else:
						v_crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
				else:
					if max_v < 0.12:
						v_crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
					else:
						v_crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))

		var b_y = 0
		var xs = []
		for cy in range(vh - 1, v_rim_y, -1):
			var has_pix = false
			for cx in range(vw):
				if v_crop.get_pixel(cx, cy).a > 0.0:
					has_pix = true
					if b_y == 0:
						b_y = cy
					if cy >= b_y - 15:
						xs.append(cx)
			if b_y > 0 and not has_pix and cy < b_y - 15:
				break

		var c_x = vw / 2.0
		if xs.size() > 0:
			var sx = 0.0
			for xv in xs:
				sx += xv
			c_x = sx / float(xs.size())

		var v_canvas: Image = Image.create(v_cw, v_ch, false, Image.FORMAT_RGBA8)
		v_canvas.fill(Color(0, 0, 0, 0))
		var px = int(round(v_tcx - c_x))
		var py = int(round(float(v_tgy) - float(b_y)))
		v_canvas.blit_rect(v_crop, Rect2i(0, 0, vw, vh), Vector2i(px, py))
		v_canvas.save_png(v_dir + v_name)
		print("Saved variation: ", v_dir + v_name)

	# Flame Particles (8 frames)
	var particle_boxes = [
		Rect2i(30, 785, 122, 126),
		Rect2i(169, 785, 120, 126),
		Rect2i(306, 785, 121, 126),
		Rect2i(443, 785, 122, 126),
		Rect2i(582, 785, 121, 126),
		Rect2i(719, 785, 115, 126),
		Rect2i(851, 785, 118, 126),
		Rect2i(985, 785, 124, 126)
	]
	for pi in range(particle_boxes.size()):
		var p_crop: Image = fire_img.get_region(particle_boxes[pi])
		for cy in range(p_crop.get_height()):
			for cx in range(p_crop.get_width()):
				var c = p_crop.get_pixel(cx, cy)
				if maxf(c.r, maxf(c.g, c.b)) <= 0.08:
					p_crop.set_pixel(cx, cy, Color(0, 0, 0, 0))
				else:
					p_crop.set_pixel(cx, cy, Color(c.r, c.g, c.b, 1.0))
		p_crop.save_png(part_dir + "particle_anim_" + str(pi) + ".png")

	print("--- FIRE, BRAZIER & TORCH ASSETS EXTRACTION COMPLETED SUCCESSFULLY ---")


