"""
Clean extraction script for fire_animation.png into Godot game assets.
Removes dark smoky gradients/halos and outer sheet borders for zero-residue alpha.
"""
import os
from PIL import Image
import numpy as np

def extract_all():
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sheet_path = os.path.join(base_dir, "assets", "fire_animation.png")
    if not os.path.exists(sheet_path):
        print("Sheet not found:", sheet_path)
        return

    sheet = Image.open(sheet_path).convert("RGBA")
    sheet_arr = np.array(sheet)

    brazier_dir = os.path.join(base_dir, "assets", "environment", "fire", "brazier")
    flame_dir = os.path.join(base_dir, "assets", "environment", "fire", "flame_only")
    torch_dir = os.path.join(base_dir, "assets", "environment", "fire", "torch")
    part_dir = os.path.join(base_dir, "assets", "environment", "fire", "particles")

    for d in [brazier_dir, flame_dir, torch_dir, part_dir]:
        os.makedirs(d, exist_ok=True)

    brazier_boxes = [
        (30, 150, 122, 190),
        (169, 150, 120, 190),
        (306, 150, 121, 190),
        (443, 150, 122, 190),
        (582, 150, 121, 190),
        (719, 150, 115, 190),
        (851, 150, 118, 190),
        (985, 150, 124, 190)
    ]

    CW, CH = 120, 190
    TARGET_GROUND_Y = 184
    TARGET_CENTER_X = 60.0

    for i, (bx, by, bw, bh) in enumerate(brazier_boxes):
        crop = sheet_arr[by:by+bh, bx:bx+bw].copy()
        h_crop, w_crop = crop.shape[:2]

        r = crop[:, :, 0].astype(float) / 255.0
        g = crop[:, :, 1].astype(float) / 255.0
        b = crop[:, :, 2].astype(float) / 255.0
        max_v = np.maximum(r, np.maximum(g, b))

        # Upper flame zone: zero residue, keep flame and embers only
        is_flame = ((r >= 0.40) & ((r > b * 1.3) | (g >= 0.20))) | (r >= 0.60)
        is_ember = (r >= 0.42) & (r > b * 1.2) & ((g >= 0.12) | (r >= 0.52))
        upper_keep = is_flame | is_ember

        for cy in range(h_crop):
            if cy < 78:
                crop[cy, ~upper_keep[cy], 3] = 0
                crop[cy, upper_keep[cy], 3] = 255
            else:
                stone_keep = max_v[cy] >= 0.12
                crop[cy, ~stone_keep, 3] = 0
                crop[cy, stone_keep, 3] = 255

        # Clear left/right background in stone zone
        for cy in range(78, h_crop):
            lx = 0
            while lx < w_crop and crop[cy, lx, 3] > 0 and max_v[cy, lx] < 0.13:
                crop[cy, lx, 3] = 0
                lx += 1
            rx = w_crop - 1
            while rx >= 0 and crop[cy, rx, 3] > 0 and max_v[cy, rx] < 0.13:
                crop[cy, rx, 3] = 0
                rx -= 1

        # Ground lock
        bottom_y = 0
        xs_at_bottom = []
        for cy in range(h_crop - 1, 75, -1):
            opaque_xs = np.where(crop[cy, :, 3] > 0)[0]
            if len(opaque_xs) > 0:
                if bottom_y == 0:
                    bottom_y = cy
                if cy >= bottom_y - 15:
                    xs_at_bottom.extend(opaque_xs)
            elif bottom_y > 0 and cy < bottom_y - 15:
                break

        center_x = w_crop / 2.0
        if len(xs_at_bottom) > 0:
            center_x = float(np.mean(xs_at_bottom))

        canvas = np.zeros((CH, CW, 4), dtype=np.uint8)
        paste_x = int(round(TARGET_CENTER_X - center_x))
        paste_y = int(round(float(TARGET_GROUND_Y) - float(bottom_y)))

        # Blit crop onto canvas
        src_y0 = max(0, -paste_y)
        src_y1 = min(h_crop, CH - paste_y)
        dst_y0 = max(0, paste_y)
        dst_y1 = dst_y0 + (src_y1 - src_y0)

        src_x0 = max(0, -paste_x)
        src_x1 = min(w_crop, CW - paste_x)
        dst_x0 = max(0, paste_x)
        dst_x1 = dst_x0 + (src_x1 - src_x0)

        if dst_y1 > dst_y0 and dst_x1 > dst_x0:
            canvas[dst_y0:dst_y1, dst_x0:dst_x1] = crop[src_y0:src_y1, src_x0:src_x1]

        out_img = Image.fromarray(canvas, "RGBA")
        b_path = os.path.join(brazier_dir, f"brazier_anim_{i}.png")
        out_img.save(b_path)
        print("Saved brazier:", b_path)

        if i == 0:
            leg_path = os.path.join(base_dir, "assets", "environment", "brazier_flaming.png")
            out_img.save(leg_path)

        # Pure Flame Only (without stone base, zero residue)
        flame_canvas = np.zeros((96, CW, 4), dtype=np.uint8)
        for f_y in range(min(76, CH)):
            for f_x in range(CW):
                if canvas[f_y, f_x, 3] > 0:
                    fc = canvas[f_y, f_x].astype(float) / 255.0
                    if f_y >= 70 and (fc[2] > fc[0] * 0.7 or fc[0] < 0.40):
                        continue
                    flame_canvas[f_y + 12, f_x] = canvas[f_y, f_x]

        f_out = Image.fromarray(flame_canvas, "RGBA")
        f_path = os.path.join(flame_dir, f"flame_anim_{i}.png")
        f_out.save(f_path)
        print("Saved flame:", f_path)

    # Wall Torch (8 frames)
    torch_boxes = [
        (30, 430, 122, 230),
        (169, 430, 120, 230),
        (306, 430, 121, 230),
        (443, 430, 122, 230),
        (582, 430, 121, 230),
        (719, 430, 115, 230),
        (851, 430, 118, 230),
        (985, 430, 124, 230)
    ]
    TW, TH = 80, 220
    TORCH_GROUND_Y = 214
    TORCH_CENTER_X = 40.0

    for ti, (tx, ty, tw, th) in enumerate(torch_boxes):
        t_crop = sheet_arr[ty:ty+th, tx:tx+tw].copy()
        r = t_crop[:, :, 0].astype(float) / 255.0
        g = t_crop[:, :, 1].astype(float) / 255.0
        b = t_crop[:, :, 2].astype(float) / 255.0
        max_v = np.maximum(r, np.maximum(g, b))

        is_flame = ((r >= 0.40) & ((r > b * 1.3) | (g >= 0.20))) | (r >= 0.60)
        is_ember = (r >= 0.42) & (r > b * 1.2) & ((g >= 0.12) | (r >= 0.52))
        flame_keep = is_flame | is_ember

        for cy in range(th):
            if cy < 75:
                t_crop[cy, ~flame_keep[cy], 3] = 0
                t_crop[cy, flame_keep[cy], 3] = 255
            else:
                sconce_keep = max_v[cy] >= 0.12
                t_crop[cy, ~sconce_keep, 3] = 0
                t_crop[cy, sconce_keep, 3] = 255

        t_bottom_y = 0
        t_xs = []
        for cy in range(th - 1, 70, -1):
            op = np.where(t_crop[cy, :, 3] > 0)[0]
            if len(op) > 0:
                if t_bottom_y == 0:
                    t_bottom_y = cy
                if cy >= t_bottom_y - 15:
                    t_xs.extend(op)
            elif t_bottom_y > 0 and cy < t_bottom_y - 15:
                break

        t_cx = tw / 2.0
        if len(t_xs) > 0:
            t_cx = float(np.mean(t_xs))

        t_canvas = np.zeros((TH, TW, 4), dtype=np.uint8)
        t_px = int(round(TORCH_CENTER_X - t_cx))
        t_py = int(round(float(TORCH_GROUND_Y) - float(t_bottom_y)))

        src_y0 = max(0, -t_py)
        src_y1 = min(th, TH - t_py)
        dst_y0 = max(0, t_py)
        dst_y1 = dst_y0 + (src_y1 - src_y0)

        src_x0 = max(0, -t_px)
        src_x1 = min(tw, TW - t_px)
        dst_x0 = max(0, t_px)
        dst_x1 = dst_x0 + (src_x1 - src_x0)

        if dst_y1 > dst_y0 and dst_x1 > dst_x0:
            t_canvas[dst_y0:dst_y1, dst_x0:dst_x1] = t_crop[src_y0:src_y1, src_x0:src_x1]

        t_img = Image.fromarray(t_canvas, "RGBA")
        t_path = os.path.join(torch_dir, f"torch_anim_{ti}.png")
        t_img.save(t_path)
        print("Saved torch:", t_path)

    # Static variations
    variations = [
        ("brazier_lit.png", (1149, 150, 110, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78),
        ("brazier_low.png", (1277, 150, 110, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78),
        ("brazier_unlit.png", (1402, 150, 107, 190), brazier_dir, CW, CH, TARGET_CENTER_X, TARGET_GROUND_Y, 78),
        ("torch_lit.png", (1149, 430, 110, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75),
        ("torch_low.png", (1277, 430, 110, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75),
        ("torch_unlit.png", (1402, 430, 107, 230), torch_dir, TW, TH, TORCH_CENTER_X, TORCH_GROUND_Y, 75)
    ]
    for v_name, (vx, vy, vw, vh), v_dir, v_cw, v_ch, v_tcx, v_tgy, v_rim in variations:
        v_crop = sheet_arr[vy:vy+vh, vx:vx+vw].copy()
        r = v_crop[:, :, 0].astype(float) / 255.0
        g = v_crop[:, :, 1].astype(float) / 255.0
        b = v_crop[:, :, 2].astype(float) / 255.0
        max_v = np.maximum(r, np.maximum(g, b))

        is_flame = ((r >= 0.40) & ((r > b * 1.3) | (g >= 0.20))) | (r >= 0.60)
        is_ember = (r >= 0.42) & (r > b * 1.2) & ((g >= 0.12) | (r >= 0.52))
        f_keep = is_flame | is_ember

        for cy in range(vh):
            if cy < v_rim:
                v_crop[cy, ~f_keep[cy], 3] = 0
                v_crop[cy, f_keep[cy], 3] = 255
            else:
                st_keep = max_v[cy] >= 0.12
                v_crop[cy, ~st_keep, 3] = 0
                v_crop[cy, st_keep, 3] = 255

        b_y = 0
        xs = []
        for cy in range(vh - 1, v_rim, -1):
            op = np.where(v_crop[cy, :, 3] > 0)[0]
            if len(op) > 0:
                if b_y == 0:
                    b_y = cy
                if cy >= b_y - 15:
                    xs.extend(op)
            elif b_y > 0 and cy < b_y - 15:
                break

        c_x = vw / 2.0
        if len(xs) > 0:
            c_x = float(np.mean(xs))

        v_canvas = np.zeros((v_ch, v_cw, 4), dtype=np.uint8)
        px = int(round(v_tcx - c_x))
        py = int(round(float(v_tgy) - float(b_y)))

        src_y0 = max(0, -py)
        src_y1 = min(vh, v_ch - py)
        dst_y0 = max(0, py)
        dst_y1 = dst_y0 + (src_y1 - src_y0)

        src_x0 = max(0, -px)
        src_x1 = min(vw, v_cw - px)
        dst_x0 = max(0, px)
        dst_x1 = dst_x0 + (src_x1 - src_x0)

        if dst_y1 > dst_y0 and dst_x1 > dst_x0:
            v_canvas[dst_y0:dst_y1, dst_x0:dst_x1] = v_crop[src_y0:src_y1, src_x0:src_x1]

        v_img = Image.fromarray(v_canvas, "RGBA")
        v_out = os.path.join(v_dir, v_name)
        v_img.save(v_out)
        print("Saved variation:", v_out)

    # Flame particles (8 frames)
    particle_boxes = [
        (30, 785, 122, 126),
        (169, 785, 120, 126),
        (306, 785, 121, 126),
        (443, 785, 122, 126),
        (582, 785, 121, 126),
        (719, 785, 115, 126),
        (851, 785, 118, 126),
        (985, 785, 124, 126)
    ]
    for pi, (px, py, pw, ph) in enumerate(particle_boxes):
        p_crop = sheet_arr[py:py+ph, px:px+pw].copy()
        max_v = np.max(p_crop[:, :, :3], axis=2)
        p_crop[max_v <= int(255 * 0.08), 3] = 0
        p_crop[max_v > int(255 * 0.08), 3] = 255
        p_img = Image.fromarray(p_crop, "RGBA")
        p_path = os.path.join(part_dir, f"particle_anim_{pi}.png")
        p_img.save(p_path)

    print("--- EXTRACTION OF ALL ASSETS COMPLETED CLEANLY ---")

if __name__ == "__main__":
    extract_all()
