#!/usr/bin/env python3
"""
Extracts and cleans all 24 frames from assets/asur/asur_stomp-atk.png:
- 8 frames for down (front)
- 8 frames for left
- 8 frames for right
Removes dark background with flood-fill, cleans dark baseline,
and anchors onto standard 320x260 canvas matching existing Asur frames.
"""

import os
import shutil
import time
from collections import deque
from PIL import Image
import numpy as np
import scipy.ndimage as ndi

SRC_IMG = "assets/asur/asur_stomp-atk.png"
OUT_DIR = "assets/asur/frames"
STAGE_DIR = "assets/temp/stomp_staged"

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(STAGE_DIR, exist_ok=True)

ROW_BLOCKS = {
    "down": (106, 363),
    "left": (419, 660),
    "right": (708, 956)
}

DIVIDERS = {
    "down": [125, 289, 455, 665, 828, 1020, 1198, 1349, 1536],
    "left": [125, 281, 438, 633, 789, 995, 1205, 1377, 1536],
    "right": [125, 273, 428, 623, 771, 1020, 1202, 1373, 1536],
}

CW, CH = 320, 260
GROUND_Y = 245
TARGET_X = 160

def safe_save(img, filepath):
    for attempt in range(5):
        try:
            img.save(filepath)
            return
        except OSError:
            time.sleep(0.15)
    img.save(filepath)

def process_frame(crop):
    ch, cw, _ = crop.shape

    # 1. Flood fill dark background (RGB <= 28)
    is_dark = np.max(crop, axis=2) <= 28
    visited = np.zeros((ch, cw), dtype=bool)
    q = deque()
    for x in range(cw):
        if is_dark[0, x]: q.append((0, x)); visited[0, x] = True
        if is_dark[ch-1, x]: q.append((ch-1, x)); visited[ch-1, x] = True
    for y in range(ch):
        if is_dark[y, 0]: q.append((y, 0)); visited[y, 0] = True
        if is_dark[y, cw-1]: q.append((y, cw-1)); visited[y, cw-1] = True

    while q:
        cy, cx = q.popleft()
        for ny, nx in [(cy-1, cx), (cy+1, cx), (cy, cx-1), (cy, cx+1)]:
            if 0 <= ny < ch and 0 <= nx < cw:
                if not visited[ny, nx] and is_dark[ny, nx]:
                    visited[ny, nx] = True
                    q.append((ny, nx))

    mask = ~visited

    # 2. Clean dark baseline strip along bottom
    for by in range(max(0, ch-15), ch):
        for bx in range(cw):
            if mask[by, bx] and np.max(crop[by, bx]) < 45:
                mask[by, bx] = False

    # 3. Discard tiny disconnected corner artifacts from adjacent frames
    labeled, num_features = ndi.label(mask)
    if num_features > 1:
        comp_sizes = ndi.sum(mask, labeled, range(1, num_features+1))
        cleaned_mask = np.zeros_like(mask)
        for l in range(1, num_features+1):
            sl = ndi.find_objects(labeled == l)[0]
            size = comp_sizes[l-1]
            touch_border = (sl[1].start == 0 or sl[1].stop >= cw) and size < 700
            if not touch_border:
                cleaned_mask[labeled == l] = True
        mask = cleaned_mask

    ys, xs = np.where(mask)
    if len(ys) == 0:
        return None

    char_w = xs.max() - xs.min() + 1
    char_h = ys.max() - ys.min() + 1
    
    rgba = np.zeros((ch, cw, 4), dtype=np.uint8)
    rgba[:, :, :3] = crop
    rgba[:, :, 3] = np.where(mask, 255, 0).astype(np.uint8)
    
    char_sub = rgba[ys.min():ys.max()+1, xs.min():xs.max()+1]

    paste_y = GROUND_Y - char_h
    paste_x = TARGET_X - (char_w // 2)
    paste_x = max(0, min(paste_x, CW - char_w))
    paste_y = max(0, min(paste_y, CH - char_h))

    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    canvas.paste(Image.fromarray(char_sub), (paste_x, paste_y))
    return canvas

def extract_all():
    im = Image.open(SRC_IMG).convert("RGB")
    arr = np.array(im)

    extracted_files = []
    for dname, (y1, y2) in ROW_BLOCKS.items():
        divs = DIVIDERS[dname]
        for i in range(8):
            x1, x2 = divs[i], divs[i+1]
            crop = arr[y1:y2, x1:x2].copy()
            canvas = process_frame(crop)
            if canvas:
                filename = f"asur_stomp_{dname}_{i}.png"
                stage_file = os.path.join(STAGE_DIR, filename)
                safe_save(canvas, stage_file)
                extracted_files.append((stage_file, os.path.join(OUT_DIR, filename)))
                print(f"Extracted {filename}")

    # Copy to destination
    for src, dst in extracted_files:
        for attempt in range(5):
            try:
                shutil.copyfile(src, dst)
                break
            except OSError:
                time.sleep(0.15)

    print(f"Successfully exported {len(extracted_files)} clean stomp frames to {OUT_DIR}.")

if __name__ == "__main__":
    extract_all()
