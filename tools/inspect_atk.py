from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character-atk-alldirection.png")
arr = np.array(im)
print("Image shape:", arr.shape)
print("Corner (0,0):", arr[0, 0])
print("Corner (0,-1):", arr[0, -1])
print("Corner (-1,0):", arr[-1, 0])
print("Corner (-1,-1):", arr[-1, -1])

# Check background
edge_pixels = np.concatenate([arr[0, :, :], arr[-1, :, :], arr[:, 0, :], arr[:, -1, :]])
bg_mean = np.median(edge_pixels, axis=0)
print("Background median:", bg_mean)

diff = np.abs(arr[:, :, :3] - bg_mean).sum(axis=2)
mask = (diff > 30).astype(np.uint8)

# Vertical projection to find row bands
v_proj = mask.sum(axis=1) > 20
bands = []
in_band = False
start_y = 0
for y in range(len(v_proj)):
    if v_proj[y] and not in_band:
        in_band = True
        start_y = y
    elif not v_proj[y] and in_band:
        in_band = False
        if y - start_y > 40:
            bands.append((start_y, y))
if in_band and len(v_proj) - start_y > 40:
    bands.append((start_y, len(v_proj)))

print(f"\nFound {len(bands)} bands:")
for idx, (y1, y2) in enumerate(bands):
    band_mask = mask[y1:y2, :]
    h_proj = band_mask.sum(axis=0) > 10
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
    print(f"Band {idx}: Y=[{y1}, {y2}] (h={y2-y1}) -> {len(cols)} frames")
    for c_idx, (x1, x2) in enumerate(cols):
        print(f"  Frame {c_idx}: X=[{x1}, {x2}] (w={x2-x1})")
