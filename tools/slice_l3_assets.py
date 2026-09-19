import os
from PIL import Image
import numpy as np

sheet = Image.open('scenes/levels/l3/3d-3rd-lvl.png').convert('RGBA')
out_dir = 'assets/environment/l3_3d'
os.makedirs(out_dir, exist_ok=True)

# Precise dictionary of slices based on our clustering and verification
# bbox format: (xmin, ymin, xmax, ymax)
slices = {
    # Tall Pillars
    'pillar_tall_banner_left.png': (17, 47, 102, 273),
    'pillar_tall_front.png': (123, 47, 209, 273),
    'pillar_tall_left.png': (235, 34, 327, 274),
    'pillar_tall_center.png': (348, 34, 437, 274),
    'pillar_tall_right.png': (457, 34, 546, 274),

    # Medium Pillars
    'pillar_medium_banner_left.png': (583, 50, 664, 269),
    'pillar_medium_left.png': (677, 68, 752, 269),
    'pillar_medium_center.png': (768, 67, 849, 272),
    'pillar_medium_right.png': (868, 67, 944, 271),
    'pillar_medium_right2.png': (960, 68, 1035, 271),

    # Small Pillars / Pedestals
    'pillar_small_banner.png': (1069, 108, 1143, 267),
    'pillar_small_1.png': (1164, 100, 1232, 262),
    'pillar_small_2.png': (1251, 97, 1325, 267),
    'pillar_small_3.png': (1345, 98, 1415, 268),
    'pillar_small_4.png': (1435, 97, 1507, 267),

    # Broken Pillars
    'broken_pillar_left_1.png': (12, 315, 98, 474),
    'broken_pillar_left_2.png': (110, 322, 203, 474),
    'broken_pillar_tall_rubble.png': (216, 301, 318, 476),
    'broken_pillar_right_rubble.png': (329, 338, 421, 477),
    'broken_pillar_stub.png': (425, 338, 536, 466),
    'broken_pillar_fallen.png': (539, 357, 675, 482),
    'broken_pillar_stub_right.png': (670, 354, 766, 484),

    # Fire Buckets & Braziers
    'brazier_square_fire.png': (784, 311, 899, 488),
    'brazier_round_fire_1.png': (913, 321, 1000, 478),
    'brazier_round_fire_2.png': (1020, 358, 1088, 475),
    'brazier_wall_flame.png': (1106, 301, 1183, 454),
    'brazier_bucket_empty.png': (1198, 372, 1283, 473),

    # Wall Torches
    'wall_torch_flame_1.png': (1328, 312, 1395, 474),
    'wall_torch_flame_2.png': (1406, 322, 1449, 468),
    'wall_torch_unlit.png': (1474, 371, 1522, 477),

    # Platforms & Altars
    'platform_altar_large.png': (16, 492, 225, 639),
    'platform_altar_medium.png': (192, 538, 313, 640),
    'platform_altar_square.png': (321, 545, 431, 638),
    'platform_pedestal_cube.png': (442, 525, 535, 632),
    'platform_pedestal_cracked.png': (546, 526, 668, 639),
    'platform_pedestal_small.png': (682, 531, 771, 634),
    'platform_pillar_plinth.png': (786, 513, 858, 641),

    # Low Cover (Small Blocks)
    'cover_blocks_double.png': (895, 541, 982, 639),
    'cover_blocks_rubble.png': (997, 546, 1106, 631),
    'cover_blocks_stepped_1.png': (1115, 537, 1211, 626),
    'cover_blocks_quad.png': (1224, 529, 1329, 618),
    'cover_blocks_tri.png': (1339, 530, 1424, 624),
    'cover_blocks_high.png': (1441, 520, 1522, 620),

    # Rocks & Rubble
    'rock_boulder_large.png': (19, 691, 133, 790),
    'rock_medium_1.png': (147, 710, 244, 795),
    'rock_small_1.png': (236, 705, 309, 766),
    'rock_rubble_small.png': (277, 762, 330, 799),
    'rock_flat_slab.png': (319, 716, 441, 778),
    'rock_tall_jagged.png': (450, 653, 511, 775),
    'rock_cluster_1.png': (516, 703, 607, 779),
    'rock_cluster_2.png': (614, 704, 703, 778),
    'rock_cluster_bricks.png': (711, 703, 779, 764),

    # Stairs & Steps
    'stairs_4step.png': (800, 693, 927, 797),
    'stairs_3step_1.png': (935, 700, 1030, 793),
    'stairs_3step_2.png': (1039, 715, 1135, 797),
    'stairs_2step.png': (1147, 711, 1243, 793),

    # Plants & Decor
    'plant_grass_tuft_1.png': (1273, 693, 1327, 760),
    'plant_grass_tuft_2.png': (1333, 704, 1371, 757),
    'plant_grass_rock.png': (1375, 696, 1457, 801),
    'decor_gold_staff.png': (1469, 632, 1496, 799),
    'decor_small_rubble.png': (1292, 761, 1367, 804),

    # Banners & Flags
    'banner_tall_sigil.png': (18, 838, 113, 1003),
    'banner_medium_sigil.png': (104, 859, 182, 995),
    'banner_pennant_sigil.png': (177, 845, 236, 987),
    'banner_wide_sigil.png': (239, 848, 323, 995),
    'banner_drape_horizontal.png': (326, 847, 471, 909),
    'banner_cloth_tattered.png': (336, 917, 455, 997),

    # Floor Tiles & Carpet
    'tile_floor_grid_clean.png': (572, 853, 650, 926),
    'tile_floor_grid_stone.png': (566, 930, 647, 996),
    'tile_floor_pattern_1.png': (734, 852, 803, 927),
    'tile_floor_pattern_2.png': (735, 928, 804, 996),
    'mandala_rug_round.png': (814, 843, 964, 991),
    'carpet_runner_sigil.png': (969, 848, 1077, 988),
    'carpet_runner_plain.png': (1083, 848, 1180, 987),
    'carpet_corner_piece.png': (1186, 848, 1292, 988),
}

saved_count = 0
for filename, (x1, y1, x2, y2) in slices.items():
    crop = sheet.crop((x1, y1, x2, y2))
    c_arr = np.array(crop)
    
    # Check bounding box of actual visible content inside crop
    c_alpha = c_arr[:, :, 3]
    visible_y, visible_x = np.where(c_alpha > 5)
    if len(visible_y) == 0:
        continue
    
    min_vy, max_vy = visible_y.min(), visible_y.max() + 1
    min_vx, max_vx = visible_x.min(), visible_x.max() + 1
    
    tight_crop = crop.crop((min_vx, min_vy, max_vx, max_vy))
    tw, th = tight_crop.size
    
    # Create final image with 2px clean transparent padding around to completely prevent texture filtering bleed
    padded = Image.new('RGBA', (tw + 4, th + 4), (0, 0, 0, 0))
    padded.paste(tight_crop, (2, 2))
    
    save_path = os.path.join(out_dir, filename)
    padded.save(save_path, 'PNG')
    saved_count += 1
    print(f"Saved {filename}: {padded.size}")

print(f"Successfully sliced and padded {saved_count} assets into {out_dir}")
