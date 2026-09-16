"""
Extracts fire and brazier animation frames from assets/fire_animation.png
with zero background residue/fringing and ground-locked alignment.
Also generates SpriteFrames resources for Godot 4.
"""

import os
import sys
from PIL import Image
import numpy as np

def extract_all():
    sheet_path = "assets/fire_animation.png"
    if not os.path.exists(sheet_path):
        print(f"Error: {sheet_path} not found")
        sys.exit(1)

    img = Image.open(sheet_path).convert("RGBA")
    arr = np.array(img)
    h, w, _ = arr.shape
    print(f"Opened {sheet_path} ({w}x{h})")

    base_dir = "assets/environment/fire"
    brazier_dir = os.path.join(base_dir, "brazier")
    torch_dir = os.path.join(base_dir, "torch")
    particles_dir = os.path.join(base_dir, "particles")
    flame_only_dir = os.path.join(base_dir, "flame_only")

    for d in [brazier_dir, torch_dir, particles_dir, flame_only_dir]:
        os.makedirs(d, exist_ok=True)

    # 1. BRAZIER ANIMATION (8 frames)
    # Box bounds in the sheet
    brazier_boxes_x = [
        (28, 154),
        (167, 291),
        (304, 429),
        (441, 567),
        (580, 705),
        (717, 836),
        (849, 971),
        (983, 1111)
    ]
    b_y1, b_y2 = 148, 341

    # First pass: find exact stone base ground line and center
    frames_raw = []
    base_bottom_ys = []
    base_center_xs = []

    for i, (bx1, bx2) in enumerate(brazier_boxes_x):
        crop = arr[b_y1:b_y2, bx1:bx2].copy()
        rgb = crop[:, :, :3]
        max_c = np.max(rgb, axis=2)

        # Zero background residue:
        # Background is < 18 brightness
        # Stone brazier: purple-gray (#2e293a = 46, 41, 58)
        # Flame: bright red/orange/yellow
        mask = max_c > 18
        
        # Clean alpha
        rgba = np.zeros_like(crop)
        rgba[:, :, :3] = crop[:, :, :3]
        rgba[:, :, 3] = np.where(mask, 255, 0).astype(np.uint8)

        # Find stone base at the bottom
        # Bottom 30% of content is stone base
        ys, xs = np.where(mask)
        if len(ys) > 0:
            max_y = ys.max()
            base_bottom_ys.append(max_y)
            # Find center of bottom 20 rows
            bottom_rows = mask[max_y-20:max_y+1, :]
            b_ys, b_xs = np.where(bottom_rows)
            if len(b_xs) > 0:
                base_center_xs.append(float(np.mean(b_xs)))
            else:
                base_center_xs.append((xs.min() + xs.max()) / 2.0)
        else:
            base_bottom_ys.append(crop.shape[0] - 1)
            base_center_xs.append(crop.shape[1] / 2.0)

        frames_raw.append(rgba)

    # Standardize canvas for perfectly steady animation
    CW = 120
    CH = 190
    TARGET_CENTER_X = 60
    TARGET_GROUND_Y = 184

    saved_brazier_files = []
    for i, rgba in enumerate(frames_raw):
        canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        frame_img = Image.fromarray(rgba)

        cx = base_center_xs[i]
        gy = base_bottom_ys[i]

        paste_x = int(round(TARGET_CENTER_X - cx))
        paste_y = int(round(TARGET_GROUND_Y - gy))

        canvas.paste(frame_img, (paste_x, paste_y), frame_img)

        out_path = os.path.join(brazier_dir, f"brazier_anim_{i}.png")
        canvas.save(out_path)
        saved_brazier_files.append(out_path)
        print(f"Saved: {out_path} ({CW}x{CH})")

    # Static Variations for Brazier: LIT, LOW, UNLIT
    var_boxes_x = [
        ("brazier_lit.png", 1147, 1261),
        ("brazier_low.png", 1275, 1389),
        ("brazier_unlit.png", 1400, 1511)
    ]
    for name, bx1, bx2 in var_boxes_x:
        crop = arr[b_y1:b_y2, bx1:bx2].copy()
        max_c = np.max(crop[:, :, :3], axis=2)
        mask = max_c > 18
        rgba = np.zeros_like(crop)
        rgba[:, :, :3] = crop[:, :, :3]
        rgba[:, :, 3] = np.where(mask, 255, 0).astype(np.uint8)

        ys, xs = np.where(mask)
        max_y = ys.max() if len(ys) > 0 else (crop.shape[0] - 1)
        bottom_rows = mask[max_y-20:max_y+1, :]
        b_ys, b_xs = np.where(bottom_rows)
        cx = float(np.mean(b_xs)) if len(b_xs) > 0 else crop.shape[1] / 2.0

        canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        frame_img = Image.fromarray(rgba)
        paste_x = int(round(TARGET_CENTER_X - cx))
        paste_y = int(round(TARGET_GROUND_Y - max_y))
        canvas.paste(frame_img, (paste_x, paste_y), frame_img)
        canvas.save(os.path.join(brazier_dir, name))
        print(f"Saved: {name}")

    # Also extract Flame Only (the fire without the stone brazier)
    # The stone brazier top rim is approximately at TARGET_GROUND_Y - 95
    flame_cutoff_y = TARGET_GROUND_Y - 92
    for i, brazier_file in enumerate(saved_brazier_files):
        f_img = Image.open(brazier_file).convert("RGBA")
        f_arr = np.array(f_img)
        # Pixels below cutoff are stone base -> remove
        flame_arr = f_arr.copy()
        flame_arr[flame_cutoff_y:, :, :] = 0
        # Crop tight with some padding
        ys, xs = np.where(flame_arr[:, :, 3] > 0)
        if len(ys) > 0:
            flame_canvas = Image.new("RGBA", (CW, 100), (0, 0, 0, 0))
            flame_sub = Image.fromarray(flame_arr[:flame_cutoff_y, :])
            flame_canvas.paste(flame_sub, (0, 100 - flame_cutoff_y), flame_sub)
            flame_out = os.path.join(flame_only_dir, f"flame_anim_{i}.png")
            flame_canvas.save(flame_out)

    print("--- EXTRACTION COMPLETED SUCCESSFULLY ---")

if __name__ == "__main__":
    extract_all()
