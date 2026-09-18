import os
from PIL import Image
import numpy as np
from collections import deque
from scipy.ndimage import label, binary_fill_holes

frames_dir = "assets/character/mushika/frames"
trans_dir = "assets/character/mushika/transformation"
os.makedirs(frames_dir, exist_ok=True)
os.makedirs(trans_dir, exist_ok=True)

# =========================================================================
# 1. EXTRACT AND NORMALIZE THE 8 TRANSFORMATION FRAMES
# =========================================================================
print("Extracting 8 transformation frames from mouse_tranformation.png...")
img_trans = Image.open("assets/character/mushika/mouse_tranformation.png")
arr_trans = np.array(img_trans)

# Cuts between the 8 frames (ensuring zero bleed between neighboring auras)
# Boundaries determined by vertical valley analysis:
cuts = [0, 297, 588, 868, 1162, 1404, 1649, 1882, 2172]

# Standard canvas for transformation animation
# Large enough to hold the tallest frame (lotus aura, h~370) and widest frame (w~285)
CANVAS_TW = 320
CANVAS_TH = 400
# Baseline Y where ground/feet sit on the canvas
GROUND_TY = 380

for i in range(8):
    x1, x2 = cuts[i], cuts[i+1]
    raw_frame = arr_trans[:, x1:x2].copy()
    
    # Soft fade at the cut edge if touching neighbor to guarantee zero cut artifact
    if i > 0:
        # fade in left 4 pixels
        for dx in range(min(4, raw_frame.shape[1])):
            raw_frame[:, dx, 3] = (raw_frame[:, dx, 3].astype(float) * (dx / 4.0)).astype(np.uint8)
    if i < 7:
        # fade out right 4 pixels
        for dx in range(min(4, raw_frame.shape[1])):
            rx = raw_frame.shape[1] - 1 - dx
            raw_frame[:, rx, 3] = (raw_frame[:, rx, 3].astype(float) * (dx / 4.0)).astype(np.uint8)
            
    # Find active bounding box (alpha > 15)
    alpha = raw_frame[:, :, 3]
    ys, xs = np.where(alpha > 15)
    if len(ys) == 0:
        ys, xs = np.where(alpha > 0)
        
    min_y, max_y = ys.min(), ys.max()
    min_x, max_x = xs.min(), xs.max()
    
    crop = raw_frame[min_y:max_y+1, min_x:max_x+1]
    ch, cw = crop.shape[:2]
    
    # Place on standardized canvas
    # Center horizontally, anchor bottom to GROUND_TY
    canvas = np.zeros((CANVAS_TH, CANVAS_TW, 4), dtype=np.uint8)
    target_x = (CANVAS_TW - cw) // 2
    target_y = GROUND_TY - ch
    
    canvas[target_y:target_y+ch, target_x:target_x+cw] = crop
    
    out_path = f"{trans_dir}/mushika_transform_{i}.png"
    Image.fromarray(canvas).save(out_path)
    print(f"  Frame {i}: cropped ({cw}x{ch}) -> canvas ({CANVAS_TW}x{CANVAS_TH}) at ({target_x}, {target_y}) -> {out_path}")

print("All 8 transformation frames extracted and aligned cleanly!\n")

# =========================================================================
# 2. EXTRACT AND NORMALIZE THE 40 DIRECTIONAL MOUSE FRAMES
# =========================================================================
print("Extracting 40 mouse frames from mouse_tileset.png...")
img_tiles = Image.open("assets/character/mushika/mouse_tileset.png")
arr_tiles = np.array(img_tiles)

idle_boxes = [(9, 157), (167, 311), (321, 471), (481, 630)]
walk_boxes = [(664, 804), (814, 945), (955, 1086), (1096, 1230), (1240, 1375), (1385, 1520)]

row_configs = [
    ("down", 130, 285),
    ("up", 370, 525),
    ("left", 605, 735),
    ("right", 810, 940)
]

CANVAS_MW = 160
CANVAS_MH = 180
GROUND_MY = 165

def extract_mouse_from_cell(cell):
    h, w = cell.shape[:2]
    diff_rg = np.abs(cell[:, :, 0].astype(int) - cell[:, :, 1].astype(int))
    diff_rb = np.abs(cell[:, :, 0].astype(int) - cell[:, :, 2].astype(int))
    diff_gb = np.abs(cell[:, :, 1].astype(int) - cell[:, :, 2].astype(int))
    max_diff = np.maximum(np.maximum(diff_rg, diff_rb), diff_gb)
    brightness = cell.mean(axis=2)

    # Background checkerboard & shadow traversal
    # Shadow and checkerboard are neutral greys (max_diff <= 35) or bright (>190)
    can_traverse = ((brightness >= 95) & (max_diff <= 35)) | (brightness >= 190)

    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        if can_traverse[0, x]: q.append((0, x)); visited[0, x] = True
        if can_traverse[h-1, x]: q.append((h-1, x)); visited[h-1, x] = True
    for y in range(h):
        if can_traverse[y, 0] and not visited[y, 0]: q.append((y, 0)); visited[y, 0] = True
        if can_traverse[y, w-1] and not visited[y, w-1]: q.append((y, w-1)); visited[y, w-1] = True

    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if can_traverse[ny, nx]:
                    visited[ny, nx] = True
                    q.append((ny, nx))

    mouse_mask = ~visited

    # Keep only the main mouse body (largest connected component)
    labeled, num = label(mouse_mask)
    if num > 0:
        sizes = [np.sum(labeled == i) for i in range(1, num+1)]
        main_comp = 1 + np.argmax(sizes)
        final_mask = (labeled == main_comp)
    else:
        final_mask = mouse_mask

    # Preserve internal highlights (e.g. white eye glints enclosed in black eyes)
    filled = binary_fill_holes(final_mask)
    final_mask |= (filled & (brightness > 230))

    # Crop tightly to mouse
    ys, xs = np.where(final_mask)
    if len(ys) == 0:
        return np.zeros((CANVAS_MH, CANVAS_MW, 4), dtype=np.uint8)

    min_y, max_y = ys.min(), ys.max()
    min_x, max_x = xs.min(), xs.max()

    crop_mask = final_mask[min_y:max_y+1, min_x:max_x+1]
    crop_rgb = cell[min_y:max_y+1, min_x:max_x+1]

    out_crop = np.zeros((max_y - min_y + 1, max_x - min_x + 1, 4), dtype=np.uint8)
    out_crop[crop_mask, :3] = crop_rgb[crop_mask]
    out_crop[crop_mask, 3] = 255
    return out_crop

for dir_name, y1, y2 in row_configs:
    # 1. Idle frames (4)
    for i, (x1, x2) in enumerate(idle_boxes):
        cell = arr_tiles[y1:y2, x1:x2]
        sprite = extract_mouse_from_cell(cell)
        sh, sw = sprite.shape[:2]

        canvas = np.zeros((CANVAS_MH, CANVAS_MW, 4), dtype=np.uint8)
        tx = (CANVAS_MW - sw) // 2
        ty = GROUND_MY - sh
        canvas[ty:ty+sh, tx:tx+sw] = sprite

        path = f"{frames_dir}/mouse_idle_{dir_name}_{i}.png"
        Image.fromarray(canvas).save(path)

    # 2. Walk frames (6)
    for i, (x1, x2) in enumerate(walk_boxes):
        cell = arr_tiles[y1:y2, x1:x2]
        sprite = extract_mouse_from_cell(cell)
        sh, sw = sprite.shape[:2]

        if dir_name == "left":
            # In mouse_tileset.png, cells 3, 4, 5 were drawn facing right.
            # Mirror if facing right so ALL walk_left frames consistently face left.
            red = (sprite[:, :, 0] > 100) & (sprite[:, :, 1] < 50) & (sprite[:, :, 2] < 70)
            if red.any() and np.where(red)[1].mean() < sw / 2.0:
                sprite = np.fliplr(sprite)
        elif dir_name == "right":
            red = (sprite[:, :, 0] > 100) & (sprite[:, :, 1] < 50) & (sprite[:, :, 2] < 70)
            if red.any() and np.where(red)[1].mean() > sw / 2.0:
                sprite = np.fliplr(sprite)

        canvas = np.zeros((CANVAS_MH, CANVAS_MW, 4), dtype=np.uint8)
        tx = (CANVAS_MW - sw) // 2
        ty = GROUND_MY - sh
        canvas[ty:ty+sh, tx:tx+sw] = sprite

        path = f"{frames_dir}/mouse_walk_{dir_name}_{i}.png"
        Image.fromarray(canvas).save(path)

    print(f"  Processed {dir_name}: 4 idle + 6 walk frames")

print("\nAll 40 directional frames extracted, cleaned, and centered successfully!")
