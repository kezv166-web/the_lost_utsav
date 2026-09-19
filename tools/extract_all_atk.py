#!/usr/bin/env python3
"""
Tuned attack extraction with zero tag residue
"""

import os
import shutil
import time
from PIL import Image
import numpy as np

CW, CH = 300, 205
TARGET_BODY_X = 150
GROUND_Y = 156

OUT_DIR = "assets/character/frames"
STAGE_DIR = "assets/temp/atk_staged"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(STAGE_DIR, exist_ok=True)

def safe_save(img, filepath):
    for attempt in range(5):
        try:
            img.save(filepath)
            return
        except OSError:
            time.sleep(0.15)
    img.save(filepath)

def remove_checkerboard_and_tags(crop_rgb):
    arr = crop_rgb.copy()
    h, w, _ = arr.shape
    
    r = arr[:, :, 0].astype(int)
    g = arr[:, :, 1].astype(int)
    b = arr[:, :, 2].astype(int)
    
    mean_val = (r + g + b) // 3
    color_diff = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])
    
    # Neutral grey/white checkerboard
    is_checker = (color_diff < 16) & (mean_val > 135)
    
    # Also dark tag box: black box with gold/white number in the bottom 22% of the crop
    is_tag = (mean_val < 45) & (np.arange(h)[:, None] > int(h * 0.82))
    # And text inside tag (gold/white in bottom 18%)
    is_tag_text = (np.arange(h)[:, None] > int(h * 0.85)) & (r > 100) & (b < 80) & (color_diff > 30)
    
    bg_mask = is_checker | is_tag
    
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr[:, :, :3]
    rgba[:, :, 3] = np.where(bg_mask, 0, 255).astype(np.uint8)
    return rgba

FRAME_BOUNDS = {
    "down": [
        (205, 415),
        (420, 645),
        (650, 890),
        (890, 1175),
        (1175, 1475),
        (1480, 1755),
    ],
    "right": [
        (205, 415),
        (420, 645),
        (650, 885),
        (885, 1175),
        (1175, 1475),
        (1480, 1755),
    ],
    "left": [
        (205, 415),
        (420, 645),
        (650, 885),
        (885, 1175),
        (1175, 1475),
        (1480, 1755),
    ],
    "up": [
        (205, 415),
        (420, 645),
        (650, 885),
        (885, 1175),
        (1175, 1475),
        (1480, 1755),
    ],
}

# Adjusted Y ranges to terminate right above the number tag
ROW_Y = {
    "right": (235, 416),
    "left": (460, 636),
}

def extract_all():
    im = Image.open("assets/character/frames/character-atk-alldirection.png").convert("RGB")
    arr_full = np.array(im)
    scale = 104.0 / 146.0
    
    for dname, (y1, y2) in ROW_Y.items():
        bounds_list = FRAME_BOUNDS[dname]
        for f_idx, (x1, x2) in enumerate(bounds_list):
            crop_rgb = arr_full[y1:y2, x1:x2]
            crop_rgba = remove_checkerboard_and_tags(crop_rgb)
            
            alpha = crop_rgba[:, :, 3] > 20
            if not np.any(alpha):
                continue
            ys, xs = np.where(alpha)
            char_crop = crop_rgba[ys.min():ys.max()+1, xs.min():xs.max()+1]
            h_crop, w_crop = char_crop.shape[:2]
            
            new_w = max(1, int(round(w_crop * scale)))
            new_h = max(1, int(round(h_crop * scale)))
            
            resized_img = Image.fromarray(char_crop).resize((new_w, new_h), Image.LANCZOS)
            canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            
            if dname in ["right", "down", "up"]:
                if f_idx in [3, 4]:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.38))
                else:
                    paste_x = int(round(TARGET_BODY_X - new_w / 2.0))
            else: # left
                if f_idx in [3, 4]:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.62))
                else:
                    paste_x = int(round(TARGET_BODY_X - new_w / 2.0))
                    
            paste_y = int(round(GROUND_Y - new_h))
            paste_x = max(0, min(paste_x, CW - new_w))
            paste_y = max(0, min(paste_y, CH - new_h))
            
            canvas.paste(resized_img, (paste_x, paste_y), resized_img)
            
            stage_file = os.path.join(STAGE_DIR, f"attack_axe_{dname}_{f_idx}.png")
            safe_save(canvas, stage_file)
            print(f"Staged {dname}_{f_idx}: w={new_w}, h={new_h}, x={paste_x}, y={paste_y}")

    count = 0
    for filename in os.listdir(STAGE_DIR):
        if filename.endswith(".png"):
            src = os.path.join(STAGE_DIR, filename)
            dst = os.path.join(OUT_DIR, filename)
            for attempt in range(5):
                try:
                    shutil.copyfile(src, dst)
                    count += 1
                    break
                except OSError:
                    time.sleep(0.15)
    print(f"Copied {count} tag-free attack frames.")

if __name__ == "__main__":
    extract_all()
