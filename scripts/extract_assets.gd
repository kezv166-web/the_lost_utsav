@tool
extends SceneTree

func _init() -> void:
	extract_assets_now()
	quit(0)

static func extract_assets_now() -> void:
	print("--- EXTRACTING ASSETS FROM outdoor-elements-tilesets.png ---")
	var sheet_path = "res://assets/outdoor-elements-tilesets.png"
	var img = Image.load_from_file(sheet_path)
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

		# Waterfalls
		"waterfall_fall_01.png": Rect2i(715, 51, 79, 134),
		"waterfall_fall_02.png": Rect2i(807, 54, 74, 126),
		"waterfall_fall_03.png": Rect2i(894, 47, 90, 140),
		"waterfall_splash_01.png": Rect2i(715, 194, 83, 115),
		"waterfall_splash_02.png": Rect2i(804, 225, 57, 90),
		"waterfall_splash_03.png": Rect2i(923, 195, 83, 119),

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

