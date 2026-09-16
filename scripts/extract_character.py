"""
Extracts character animation frames from assets/character-tileset.png
with zero background residue and torso-centered, ground-locked alignment.
"""

import os
import sys
from PIL import Image
import numpy as np
from scipy.ndimage import label, binary_fill_holes

def extract_character_frames():
    source_path = "assets/character-tileset.png"
    out_dir = "assets/character/frames"
    os.makedirs(out_dir, exist_ok=True)
    
    if not os.path.exists(source_path):
        print(f"Error: {source_path} not found")
        sys.exit(1)
        
    im_full = Image.open(source_path).convert("RGB")
    # Walk cycle table bounds: x in [80..950], y in [40..520]
    im_walk = im_full.crop((80, 40, 950, 520))
    arr = np.array(im_walk)
    
    r = arr[:, :, 0].astype(int)
    g = arr[:, :, 1].astype(int)
    b = arr[:, :, 2].astype(int)
    mean_val = (r + g + b) // 3
    color_diff = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])
    char_candidate = (mean_val < 110) | (color_diff > 25)
    
    # Standard frame canvas
    CW, CH = 80, 115
    TARGET_HEAD_X = 40
    GROUND_Y = 111
    
    directions = ["down", "up", "left", "right"]
    total_saved = 0
    
    for r_idx, dname in enumerate(directions):
        y_start = r_idx * 120 + 3
        y_end = (r_idx + 1) * 120 - 3
        
        row_mask = char_candidate[y_start:y_end, :]
        labeled, num_features = label(row_mask, structure=np.ones((3, 3)))
        
        comps = []
        for i in range(1, num_features + 1):
            sz = np.sum(labeled == i)
            if sz > 2000:
                ys, xs = np.where(labeled == i)
                if (xs.max() - xs.min() > 35) and (ys.max() - ys.min() > 70):
                    comps.append((i, xs.min(), xs.max(), ys.min() + y_start, ys.max() + y_start))
                    
        comps.sort(key=lambda x: x[1])
        print(f"Direction {dname}: found {len(comps)} frames")
        
        for f_idx, (lbl, x1, x2, y1, y2) in enumerate(comps):
            c_mask = binary_fill_holes(labeled == lbl)
            h_char = y2 - y1 + 1
            w_char = x2 - x1 + 1
            
            char_rgba = np.zeros((h_char, w_char, 4), dtype=np.uint8)
            char_rgba[:, :, :3] = arr[y1:y2+1, x1:x2+1]
            char_rgba[:, :, 3] = np.where(c_mask[y1-y_start:y2-y_start+1, x1:x2+1], 255, 0)
            
            # Torso/head centerline anchor (top 15% to 50% of sprite)
            torso_y1 = int(h_char * 0.15)
            torso_y2 = int(h_char * 0.50)
            torso_mask = char_rgba[torso_y1:torso_y2, :, 3] > 100
            t_ys, t_xs = np.where(torso_mask)
            if len(t_xs) > 0:
                center_x = float(np.mean(t_xs))
            else:
                center_x = w_char / 2.0
                
            # Ground foot anchor
            f_ys, _ = np.where(char_rgba[:, :, 3] > 100)
            max_y = f_ys.max() if len(f_ys) > 0 else (h_char - 1)
            
            canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            img = Image.fromarray(char_rgba)
            
            paste_x = int(round(TARGET_HEAD_X - center_x))
            paste_y = int(round(GROUND_Y - max_y))
            canvas.paste(img, (paste_x, paste_y), img)
            
            # Save walk frame
            walk_file = os.path.join(out_dir, f"walk_{dname}_{f_idx}.png")
            canvas.save(walk_file)
            total_saved += 1
            
            # Frame 0 is also the standing idle frame
            if f_idx == 0:
                idle_file = os.path.join(out_dir, f"idle_{dname}_0.png")
                canvas.save(idle_file)
                total_saved += 1

    print(f"Successfully extracted {total_saved} torso-anchored frames to {out_dir}")

if __name__ == "__main__":
    extract_character_frames()
