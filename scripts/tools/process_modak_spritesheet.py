import os
from PIL import Image
import numpy as np
from collections import deque

def process_modak():
    src_path = "assets/modak.png"
    out_dir = "assets/collectibles/modak"
    os.makedirs(out_dir, exist_ok=True)

    im = Image.open(src_path).convert("RGB")
    arr = np.array(im)

    # 6 directional segments identified:
    # 0: FRONT: (47, 337)
    # 1: FRONT-RIGHT: (389, 683)
    # 2: RIGHT: (732, 1012)
    # 3: BACK: (1061, 1344)
    # 4: LEFT: (1392, 1672)
    # 5: FRONT-LEFT: (1726, 2018)
    segments = [(47, 337), (389, 683), (732, 1012), (1061, 1344), (1392, 1672), (1726, 2018)]
    y_min, y_max = 185, 558

    extracted_frames = []

    for idx, (x_min, x_max) in enumerate(segments):
        # Add 5px padding
        x0 = max(0, x_min - 5)
        x1 = min(arr.shape[1], x_max + 5)
        y0 = max(0, y_min - 5)
        y1 = min(arr.shape[0], y_max + 5)

        sub = arr[y0:y1, x0:x1].copy()
        h, w, _ = sub.shape

        # Create RGBA
        rgba = np.zeros((h, w, 4), dtype=np.uint8)
        rgba[:, :, :3] = sub
        rgba[:, :, 3] = 255

        # Flood fill from all 4 borders to remove neutral dark background
        visited = np.zeros((h, w), dtype=bool)
        queue = deque()

        for r in range(h):
            queue.append((r, 0))
            queue.append((r, w - 1))
        for c in range(w):
            queue.append((0, c))
            queue.append((h - 1, c))

        while queue:
            r, c = queue.popleft()
            if visited[r, c]:
                continue
            visited[r, c] = True

            pixel = sub[r, c]
            red, green, blue = int(pixel[0]), int(pixel[1]), int(pixel[2])

            # Background condition: dark and low saturation (neutral grey/black)
            is_dark = (red < 30 and green < 30 and blue < 30)
            is_neutral = (abs(red - green) <= 8 and abs(green - blue) <= 8 and abs(red - blue) <= 8)
            
            if is_dark or (red < 45 and green < 35 and blue < 35 and is_neutral):
                rgba[r, c, 3] = 0 # Transparent
                for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < h and 0 <= nc < w and not visited[nr, nc]:
                        queue.append((nr, nc))

        frame_img = Image.fromarray(rgba, "RGBA")
        
        # Crop tight to non-transparent bounding box
        bbox = frame_img.getbbox()
        if bbox:
            cropped = frame_img.crop(bbox)
        else:
            cropped = frame_img
            
        extracted_frames.append(cropped)

    # Determine maximum dimension to make all frames uniform square
    max_w = max(f.width for f in extracted_frames)
    max_h = max(f.height for f in extracted_frames)
    max_dim = max(max_w, max_h) + 16 # Add 16px breathing room

    uniform_frames = []
    for idx, f in enumerate(extracted_frames):
        # Create centered square image
        sq = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        # Center horizontally, align bottom with 8px margin
        off_x = (max_dim - f.width) // 2
        off_y = max_dim - f.height - 8
        sq.paste(f, (off_x, off_y), f)
        
        # Save individual frame (high res)
        sq.save(os.path.join(out_dir, f"modak_{idx}.png"))
        
        # Also save crisp pixel-scaled version (64x64) for HUD icon and crisp rendering
        scaled_64 = sq.resize((64, 64), Image.NEAREST)
        scaled_64.save(os.path.join(out_dir, f"modak_{idx}_64.png"))
        
        uniform_frames.append(sq)

    # Save front icon (modak_0_64.png as modak_icon.png)
    front_icon = uniform_frames[0].resize((48, 48), Image.NEAREST)
    front_icon.save(os.path.join(out_dir, "modak_icon.png"))

    # Save combined horizontal spritesheet (6 frames)
    sheet = Image.new("RGBA", (max_dim * 6, max_dim), (0, 0, 0, 0))
    for idx, f in enumerate(uniform_frames):
        sheet.paste(f, (idx * max_dim, 0), f)
    sheet.save(os.path.join(out_dir, "modak_spritesheet.png"))

    print(f"Successfully processed {len(uniform_frames)} modak frames of size ({max_dim}x{max_dim}) into {out_dir}")

if __name__ == "__main__":
    process_modak()
