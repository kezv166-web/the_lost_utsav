"""
Clean L3 tileset transparency and extract individual sliced assets.
Eliminates fake baked-in checkerboard backgrounds (white and light-gray squares)
with true RGBA alpha transparency (A = 0 around all edges), defringing, and padding.
"""

import os
import sys
from PIL import Image
import numpy as np

def clean_tileset():
    # Locate project root
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    tileset_path = os.path.join(project_root, "scenes", "levels", "l3", "3rd-lvl-tileset.png")
    out_dir = os.path.join(project_root, "assets", "environment", "l3")
    os.makedirs(out_dir, exist_ok=True)

    if not os.path.exists(tileset_path):
        print(f"Error: {tileset_path} not found")
        return

    img = Image.open(tileset_path).convert("RGBA")
    arr = np.array(img)

    r = arr[:, :, 0].astype(int)
    g = arr[:, :, 1].astype(int)
    b = arr[:, :, 2].astype(int)

    # 1. Checkerboard identification:
    # Achromatic (low color saturation) and high brightness
    c_max = np.maximum.reduce([r, g, b])
    c_min = np.minimum.reduce([r, g, b])
    c_diff = c_max - c_min
    brightness = (r + g + b) // 3

    # Checkerboard squares are ~215-225 (light gray) and ~255 (white)
    # Saturation diff is <= 14, brightness >= 195
    is_checker = (brightness >= 195) & (c_diff <= 14)

    # Defringing pass: transition pixels on the edge of the checkerboard
    # that have brightness >= 180 and c_diff <= 10
    is_fringe = (brightness >= 180) & (c_diff <= 10)

    # Apply initial transparency
    arr[is_checker, 3] = 0
    arr[is_fringe, 3] = 0

    # Second defringing pass: dilate alpha=0 into adjacent pixels with brightness >= 170 and c_diff <= 8
    # (removes subtle white halo around dark stone edges)
    alpha_zero = (arr[:, :, 3] == 0)
    fringe_candidates = (brightness >= 170) & (c_diff <= 8)
    
    # Pure numpy 3x3 neighborhood dilation
    dilated = np.zeros_like(alpha_zero)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            dilated |= np.roll(np.roll(alpha_zero, dy, axis=0), dx, axis=1)
    
    arr[dilated & fringe_candidates, 3] = 0

    # Save cleaned tileset image
    clean_tileset_img = Image.fromarray(arr)
    clean_tileset_img.save(tileset_path)
    print(f"Successfully cleaned and saved tileset to {tileset_path}")

    # 2. Extract individual sliced assets with guaranteed true alpha transparency
    # (A = 0 around all edges, 2px transparent padding)
    assets = {
        "l3_carpet.png": (215, 260, 255, 140),
        "l3_mandala.png": (215, 15, 255, 245),
        "l3_pillar.png": (705, 104, 83, 210),
        "l3_broken_wall_1.png": (316, 560, 136, 82),
        "l3_broken_wall_2.png": (208, 560, 90, 92),
        "l3_rock_1.png": (15, 455, 165, 125),
        "l3_rock_2.png": (185, 455, 120, 83),
        "l3_rock_3.png": (310, 460, 110, 78),
        "l3_rock_4.png": (15, 655, 85, 110),
        "l3_rock_5.png": (100, 680, 95, 85),
        "l3_rock_6.png": (200, 645, 95, 75),
        "l3_debris_1.png": (300, 645, 95, 70),
        "l3_debris_2.png": (410, 685, 90, 70),
        "l3_debris_3.png": (75, 600, 65, 50),
        "l3_banner_tall.png": (1120, 10, 100, 236),
        "l3_banner_shield.png": (1240, 215, 135, 170),
        "l3_banner_drape.png": (1390, 255, 115, 140),
        "l3_brazier_tall.png": (22, 775, 74, 200),
        "l3_brazier_medium.png": (130, 805, 62, 170),
        "l3_hanging_fire.png": (585, 780, 85, 185),
    }

    for filename, (x, y, w, h) in assets.items():
        crop_arr = arr[y:y+h, x:x+w].copy()
        
        # Add 2-pixel transparent padding around the crop
        pad = 2
        padded = np.zeros((h + 2 * pad, w + 2 * pad, 4), dtype=np.uint8)
        padded[pad:pad+h, pad:pad+w] = crop_arr
        
        # Ensure the outer 2-pixel border is 100% transparent (A = 0)
        padded[:pad, :, 3] = 0
        padded[-pad:, :, 3] = 0
        padded[:, :pad, 3] = 0
        padded[:, -pad:, 3] = 0
        
        # Edge defringing and checkerboard residue cleanup:
        pr = padded[:, :, 0].astype(int)
        pg = padded[:, :, 1].astype(int)
        pb = padded[:, :, 2].astype(int)
        p_diff = np.maximum.reduce([pr, pg, pb]) - np.minimum.reduce([pr, pg, pb])
        p_bright = (pr + pg + pb) // 3
        
        # Clear any checkerboard residue (achromatic high-brightness)
        checker_residue = (padded[:, :, 3] > 0) & (p_bright >= 180) & (p_diff <= 16)
        padded[checker_residue, 3] = 0
        
        # Clear edge fringe within 4 pixels of borders
        edge_zone = np.zeros((h + 2 * pad, w + 2 * pad), dtype=bool)
        edge_zone[:pad+3, :] = True
        edge_zone[-(pad+3):, :] = True
        edge_zone[:, :pad+3] = True
        edge_zone[:, -(pad+3):] = True
        edge_fringe = (p_bright >= 165) & (p_diff <= 20)
        padded[edge_zone & edge_fringe, 3] = 0

        crop_img = Image.fromarray(padded)
        target_file = os.path.join(out_dir, filename)
        crop_img.save(target_file)
        print(f"Extracted {filename} ({w + 2*pad}x{h + 2*pad}) -> {target_file}")

    print("All L3 tileset assets successfully processed with clean alpha borders!")

if __name__ == "__main__":
    clean_tileset()
