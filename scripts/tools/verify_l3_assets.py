import os
from PIL import Image
import numpy as np

project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
l3_dir = os.path.join(project_root, "assets", "environment", "l3")

if not os.path.exists(l3_dir):
    print("Error: l3_dir does not exist")
    exit(1)

# Check tileset
tileset_path = os.path.join(project_root, "scenes", "levels", "l3", "3rd-lvl-tileset.png")
if os.path.exists(tileset_path):
    timg = Image.open(tileset_path).convert("RGBA")
    tarr = np.array(timg)
    talpha = tarr[:, :, 3]
    th, tw = talpha.shape
    print(f"\n[3rd-lvl-tileset.png] {tw}x{th} | Trans: {np.count_nonzero(talpha == 0)}/{tw*th} ({np.count_nonzero(talpha == 0)/(tw*th)*100:.1f}%)")
files = sorted([f for f in os.listdir(l3_dir) if f.endswith(".png")])
for f in files:
    path = os.path.join(l3_dir, f)
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    alpha = arr[:, :, 3]
    h, w = alpha.shape
    
    # Check borders (top row, bottom row, left col, right col)
    top_opaque = np.count_nonzero(alpha[0, :] > 0)
    bottom_opaque = np.count_nonzero(alpha[-1, :] > 0)
    left_opaque = np.count_nonzero(alpha[:, 0] > 0)
    right_opaque = np.count_nonzero(alpha[:, -1] > 0)
    border_opaque = top_opaque + bottom_opaque + left_opaque + right_opaque
    
    # Total transparent vs opaque
    total_px = w * h
    trans_px = np.count_nonzero(alpha == 0)
    opaque_px = np.count_nonzero(alpha == 255)
    semi_px = total_px - trans_px - opaque_px
    
    print(f"[{f}] {w}x{h} | Trans: {trans_px}/{total_px} ({trans_px/total_px*100:.1f}%) | Semi: {semi_px} | Border non-zero: {border_opaque} (T:{top_opaque} B:{bottom_opaque} L:{left_opaque} R:{right_opaque})")
    
    if border_opaque > 0:
        # Sample non-zero border pixels
        edge_samples = []
        for x in range(w):
            if alpha[0, x] > 0 and len(edge_samples) < 3: edge_samples.append(('Top', 0, x, arr[0, x].tolist()))
            if alpha[-1, x] > 0 and len(edge_samples) < 5: edge_samples.append(('Bottom', h-1, x, arr[-1, x].tolist()))
        for y in range(h):
            if alpha[y, 0] > 0 and len(edge_samples) < 7: edge_samples.append(('Left', y, 0, arr[y, 0].tolist()))
            if alpha[y, -1] > 0 and len(edge_samples) < 9: edge_samples.append(('Right', y, w-1, arr[y, -1].tolist()))
        print(f"    Sample edge non-zero pixels: {edge_samples}")
