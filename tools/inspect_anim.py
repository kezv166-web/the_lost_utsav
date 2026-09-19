from PIL import Image
import numpy as np

def inspect_image(path):
    im = Image.open(path)
    print(f"\n==============================")
    print(f"ANALYZING: {path} ({im.size}, {im.mode})")
    arr = np.array(im)
    
    if im.mode == "RGBA":
        alpha = arr[:, :, 3]
        mask = (alpha > 30).astype(np.uint8)
    else:
        # Check background color around edges
        edge_pixels = np.concatenate([arr[0, :, :], arr[-1, :, :], arr[:, 0, :], arr[:, -1, :]])
        bg_mean = np.median(edge_pixels, axis=0)
        print("Detected background color:", bg_mean)
        diff = np.abs(arr[:, :, :3] - bg_mean).sum(axis=2)
        mask = (diff > 30).astype(np.uint8)

    # Horizontal and vertical projections
    v_proj = mask.sum(axis=1) # per row (Y)
    h_proj = mask.sum(axis=0) # per col (X)
    
    # Rows with sprites
    row_has_sprite = v_proj > 20
    print("Non-empty rows count:", row_has_sprite.sum())
    
    # Find contiguous row bands (animation directions)
    bands = []
    in_band = False
    start_y = 0
    for y in range(len(v_proj)):
        if row_has_sprite[y] and not in_band:
            in_band = True
            start_y = y
        elif not row_has_sprite[y] and in_band:
            in_band = False
            if y - start_y > 40:
                bands.append((start_y, y))
    if in_band and len(v_proj) - start_y > 40:
        bands.append((start_y, len(v_proj)))
        
    print(f"Found {len(bands)} row bands:")
    for idx, (y1, y2) in enumerate(bands):
        # In this band, find column segments
        band_mask = mask[y1:y2, :]
        band_h_proj = band_mask.sum(axis=0) > 10
        cols = []
        in_col = False
        start_x = 0
        for x in range(len(band_h_proj)):
            if band_h_proj[x] and not in_col:
                in_col = True
                start_x = x
            elif not band_h_proj[x] and in_col:
                in_col = False
                if x - start_x > 25:
                    cols.append((start_x, x))
        if in_col and len(band_h_proj) - start_x > 25:
            cols.append((start_x, len(band_h_proj)))
            
        print(f"  Band {idx}: Y=[{y1}, {y2}] (h={y2-y1}) -> {len(cols)} frames")
        for c_idx, (x1, x2) in enumerate(cols):
            print(f"    Frame {c_idx}: X=[{x1}, {x2}] (w={x2-x1})")

inspect_image("assets/character/frames/character_jumping_animation(4-direction).png")
inspect_image("assets/character/frames/character-idle-animation.png")
