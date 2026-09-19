#!/usr/bin/env python3
"""
Extracts character idle and jump animation frames with:
- Exterior flood-fill black background removal for Idle
- Automatic bottom number tag removal for Jump
- Exact torso-centered, ground-locked alignment on (80, 115) canvas
- Zero distortion and seamless scale matching with existing walk/attack frames
- Staged output to avoid editor file locks
"""

import os
import shutil
import time
from collections import deque
from PIL import Image
import numpy as np

CW, CH = 80, 115
TARGET_HEAD_X = 40
GROUND_Y = 111

OUT_DIR = "assets/character/frames"
STAGE_DIR = "assets/temp/extracted_frames"
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

# -------------------------------------------------------------------------
# 1. IDLE EXTRACTION
# -------------------------------------------------------------------------
def remove_black_bg_flood(arr_rgb, tol=28):
    h, w, _ = arr_rgb.shape
    black_dist = np.sqrt(np.sum(arr_rgb.astype(float)**2, axis=2))
    is_bg = black_dist <= tol
    
    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    queue = deque()
    
    for x in range(w):
        if is_bg[0, x]:
            queue.append((0, x))
            visited[0, x] = True
        if is_bg[h-1, x]:
            queue.append((h-1, x))
            visited[h-1, x] = True
    for y in range(h):
        if is_bg[y, 0]:
            queue.append((y, 0))
            visited[y, 0] = True
        if is_bg[y, w-1]:
            queue.append((y, w-1))
            visited[y, w-1] = True
            
    while queue:
        cy, cx = queue.popleft()
        bg_mask[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_bg[ny, nx]:
                    queue.append((ny, nx))
                    
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr_rgb[:, :, :3]
    rgba[:, :, 3] = np.where(bg_mask, 0, 255).astype(np.uint8)
    return rgba

def extract_idle():
    print("=== Extracting Idle Animations ===")
    im_idle = Image.open("assets/character/frames/character-idle-animation.png").convert("RGB")
    arr_full = np.array(im_idle)
    
    dir_bands = [
        ("down", 97, 284),
        ("left", 331, 507),
        ("right", 551, 726),
        ("up", 767, 969)
    ]
    
    for dname, y1, y2 in dir_bands:
        band_arr = arr_full[y1:y2, :]
        col_ranges = [
            (230, 400),
            (550, 710),
            (870, 1030),
            (1190, 1350)
        ]
        
        for f_idx, (x1, x2) in enumerate(col_ranges):
            crop_rgb = band_arr[:, x1:x2]
            crop_rgba = remove_black_bg_flood(crop_rgb, tol=28)
            
            alpha = crop_rgba[:, :, 3] > 20
            if not np.any(alpha):
                continue
            ys, xs = np.where(alpha)
            
            char_crop = crop_rgba[ys.min():ys.max()+1, xs.min():xs.max()+1]
            h_char, w_char = char_crop.shape[:2]
            
            # Match standing height ~104px
            scale = 104.0 / h_char
            new_w = max(1, int(round(w_char * scale)))
            new_h = max(1, int(round(h_char * scale)))
            
            char_img = Image.fromarray(char_crop).resize((new_w, new_h), Image.LANCZOS)
            
            canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            paste_x = int(round(TARGET_HEAD_X - new_w / 2.0))
            paste_y = int(round(GROUND_Y - new_h))
            canvas.paste(char_img, (paste_x, paste_y), char_img)
            
            stage_file = os.path.join(STAGE_DIR, f"idle_{dname}_{f_idx}.png")
            safe_save(canvas, stage_file)
            print(f"Staged: idle_{dname}_{f_idx}.png (orig h={h_char} -> {new_h})")

# -------------------------------------------------------------------------
# 2. JUMP EXTRACTION
# -------------------------------------------------------------------------
def extract_jump():
    print("\n=== Extracting Jump Animations ===")
    im_jump = Image.open("assets/character/frames/character_jumping_animation(4-direction).png").convert("RGBA")
    arr_full = np.array(im_jump)
    
    jump_bands = [
        ("down", 14, 247),
        ("right", 259, 492),
        ("left", 508, 730),
        ("up", 743, 946)
    ]
    
    TAG_CUTOFF = 34
    scale = 104.0 / 175.0
    
    for dname, y1, y2 in jump_bands:
        band_arr = arr_full[y1:y2, :]
        band_alpha = band_arr[:, :, 3] > 25
        h_proj = band_alpha.sum(axis=0) > 10
        
        cols = []
        in_col = False
        start_x = 0
        for x in range(len(h_proj)):
            if h_proj[x] and not in_col:
                in_col = True
                start_x = x
            elif not h_proj[x] and in_col:
                in_col = False
                if x - start_x > 30:
                    cols.append((start_x, x))
        if in_col and len(h_proj) - start_x > 30:
            cols.append((start_x, len(h_proj)))
            
        anim_cols = cols[1:9] if len(cols) >= 9 else cols[1:]
        print(f"Jump {dname}: found {len(anim_cols)} animation columns")
        
        for f_idx, (x1, x2) in enumerate(anim_cols):
            crop = band_arr[:-TAG_CUTOFF, x1:x2]
            alpha = crop[:, :, 3] > 20
            if not np.any(alpha):
                continue
            ys, xs = np.where(alpha)
            
            char_crop = crop[ys.min():ys.max()+1, xs.min():xs.max()+1]
            h_char, w_char = char_crop.shape[:2]
            
            row_ground = (y2 - y1) - TAG_CUTOFF - 2
            char_bottom = ys.max()
            elevation = max(0, row_ground - char_bottom)
            
            scaled_w = max(1, int(round(w_char * scale)))
            scaled_h = max(1, int(round(h_char * scale)))
            scaled_elevation = int(round(elevation * scale))
            
            char_img = Image.fromarray(char_crop).resize((scaled_w, scaled_h), Image.LANCZOS)
            
            canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            paste_x = int(round(TARGET_HEAD_X - scaled_w / 2.0))
            paste_y = int(round(GROUND_Y - scaled_elevation - scaled_h))
            paste_y = max(2, min(paste_y, CH - scaled_h))
            canvas.paste(char_img, (paste_x, paste_y), char_img)
            
            stage_file = os.path.join(STAGE_DIR, f"jump_{dname}_{f_idx}.png")
            safe_save(canvas, stage_file)
            print(f"Staged: jump_{dname}_{f_idx}.png (frame {f_idx}, h={scaled_h}, elev={scaled_elevation})")

def copy_staged_to_target():
    print("\n=== Copying Staged Frames to Target Directory ===")
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
    print(f"Successfully copied {count} animation frames to {OUT_DIR}.")

if __name__ == "__main__":
    extract_idle()
    extract_jump()
    copy_staged_to_target()
    print("\nAll frames successfully extracted!")
