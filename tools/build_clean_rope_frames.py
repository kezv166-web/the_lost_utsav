import os
import shutil
import time
from PIL import Image
import numpy as np
from collections import deque
from scipy.ndimage import label, binary_dilation

CW, CH = 300, 205
TARGET_BODY_X = 150
GROUND_Y = 155
SCALE = 110.0 / 168.0

STAGE_DIR = "assets/temp/atk_rope_staged"
OUT_DIR = "assets/character/frames"
os.makedirs(STAGE_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)

ROWS = {
    "right": (237, 435),
    "left": (455, 640),
}

BOUNDS = {
    "down": [
        (240, 395),
        (435, 605),
        (640, 920),
        (870, 1225),
        (1225, 1530),
        (1545, 1740),
    ],
    "right": [
        (240, 395),
        (435, 605),
        (640, 920),
        (870, 1225),
        (1225, 1530),
        (1545, 1740),
    ],
    "left": [
        (240, 395),
        (435, 615),
        (660, 900),
        (915, 1205),
        (1220, 1515),
        (1545, 1740),
    ],
    "up": [
        (240, 395),
        (435, 605),
        (640, 920),
        (870, 1225),
        (1225, 1530),
        (1545, 1740),
    ],
}

def remove_black_flood(arr_rgb, tol=20):
    h, w, _ = arr_rgb.shape
    dist = np.max(arr_rgb, axis=2)
    is_bg_candidate = dist <= tol
    
    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    
    queue = deque()
    for x in range(w):
        if is_bg_candidate[0, x]:
            queue.append((0, x))
            visited[0, x] = True
        if is_bg_candidate[h-1, x]:
            queue.append((h-1, x))
            visited[h-1, x] = True
    for y in range(h):
        if is_bg_candidate[y, 0]:
            queue.append((y, 0))
            visited[y, 0] = True
        if is_bg_candidate[y, w-1]:
            queue.append((y, w-1))
            visited[y, w-1] = True
            
    while queue:
        cy, cx = queue.popleft()
        bg_mask[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_bg_candidate[ny, nx]:
                    queue.append((ny, nx))
                    
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr_rgb[:, :, :3]
    rgba[:, :, 3] = np.where(bg_mask, 0, 255).astype(np.uint8)
    return rgba

def clean_cavities(rgba):
    r, g, b = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2]
    # Skin detector (peach tones on face/hands/feet)
    is_skin = (r > 190) & (g > 130) & (g < 235) & (b > 90) & (b < 205)
    
    # Internal dark components (alpha == 255 and max RGB <= 20)
    is_dark = (rgba[:, :, 3] == 255) & (np.max(rgba[:, :, :3], axis=2) <= 20)
    labeled, num_feats = label(is_dark)
    
    # Dilation of skin mask by 3 pixels to check adjacency
    skin_neighbor = binary_dilation(is_skin, iterations=3)
    
    out_rgba = rgba.copy()
    for i in range(1, num_feats + 1):
        comp_mask = (labeled == i)
        comp_size = np.sum(comp_mask)
        if comp_size < 10:
            continue
            
        # Large cavity (> 250 px) like crescent arc or loop
        if comp_size > 250:
            out_rgba[comp_mask, 3] = 0
            continue
            
        # Small cavity: keep if adjacent to skin (eyes/eyebrows), clear otherwise
        touches_skin = np.any(comp_mask & skin_neighbor)
        if not touches_skin:
            out_rgba[comp_mask, 3] = 0
            
    return out_rgba

def extract_all():
    sheet = Image.open("assets/character/frames/better-rope-frames.png").convert("RGB")
    arr_full = np.array(sheet)
    
    for dname, (y1, y2) in ROWS.items():
        bounds_list = BOUNDS[dname]
        for f_idx, (x1, x2) in enumerate(bounds_list):
            crop = arr_full[y1:y2, x1:x2].copy()
            h_crop, w_crop, _ = crop.shape
            
            # Disambiguate overlap between Col 2 and Col 3
            if dname in ["down", "right", "up"]:
                if f_idx == 2:
                    for r_y in range(130, h_crop):
                        for r_x in range(w_crop):
                            if x1 + r_x > 850:
                                crop[r_y, r_x] = [0, 0, 0]
                elif f_idx == 3:
                    for r_y in range(0, 130):
                        for r_x in range(w_crop):
                            if x1 + r_x < 920:
                                crop[r_y, r_x] = [0, 0, 0]
                                
            # Flood fill black background
            rgba = remove_black_flood(crop)
            # Clean cavities inside loop/crescents
            rgba = clean_cavities(rgba)
            
            alpha = rgba[:, :, 3] > 20
            if not np.any(alpha):
                print(f"Warning: empty sprite for {dname}_{f_idx}")
                continue
                
            ys, xs = np.where(alpha)
            trimmed = rgba[ys.min():ys.max()+1, xs.min():xs.max()+1]
            h_trim, w_trim = trimmed.shape[:2]
            
            new_w = max(1, int(round(w_trim * SCALE)))
            new_h = max(1, int(round(h_trim * SCALE)))
            
            resized = Image.fromarray(trimmed).resize((new_w, new_h), Image.LANCZOS)
            canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            
            paste_y = int(round(GROUND_Y - new_h))
            
            # Horizontal centering
            if dname in ["down", "up"]:
                if f_idx in [0, 1, 5]:
                    paste_x = int(round(TARGET_BODY_X - new_w / 2.0))
                elif f_idx == 2:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.35))
                elif f_idx in [3, 4]:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.40))
            elif dname == "right":
                if f_idx in [0, 1, 5]:
                    paste_x = int(round(TARGET_BODY_X - new_w / 2.0))
                elif f_idx == 2:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.32))
                elif f_idx in [3, 4]:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.40))
            else: # left
                if f_idx in [0, 1, 5]:
                    paste_x = int(round(TARGET_BODY_X - new_w / 2.0))
                elif f_idx == 2:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.68))
                elif f_idx in [3, 4]:
                    paste_x = int(round(TARGET_BODY_X - new_w * 0.60))
                    
            paste_x = max(0, min(paste_x, CW - new_w))
            paste_y = max(0, min(paste_y, CH - new_h))
            
            canvas.paste(resized, (paste_x, paste_y), resized)
            stage_file = os.path.join(STAGE_DIR, f"attack_rope_{dname}_{f_idx}.png")
            canvas.save(stage_file)
            print(f"Staged {dname}_{f_idx}: {new_w}x{new_h} at ({paste_x}, {paste_y})")

    # Copy all to OUT_DIR
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
    print(f"Successfully copied {count} clean rope attack frames to {OUT_DIR}.")

if __name__ == "__main__":
    extract_all()
