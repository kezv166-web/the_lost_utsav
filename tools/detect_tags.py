from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character-atk-alldirection.png")
arr = np.array(im)

# Let's find the frames in row 0 (Down) and row 3 (Up) by detecting the number tags at the bottom!
# Each frame has a number tag [1], [2], [3], [4], [5], [6] at the bottom!
# The number tags are dark boxes with numbers, perfectly centered under each frame!

for r_idx, (dname, y1, y2) in enumerate([("down", 10, 218), ("right", 230, 438), ("left", 450, 658), ("up", 670, 878)]):
    band = arr[y1:y2, :]
    # The number tag is near the bottom of each band (y in band ~ y2-y1-28 to y2-y1)
    tag_region = band[-25:, 200:]
    tag_dark = (tag_region.mean(axis=2) < 40).astype(np.uint8)
    tag_h = tag_dark.sum(axis=0) > 5
    
    # Find contiguous dark segments in tag_h
    tags = []
    in_t = False
    tx1 = 0
    for x in range(len(tag_h)):
        if tag_h[x] and not in_t:
            in_t = True
            tx1 = x
        elif not tag_h[x] and in_t:
            in_t = False
            if x - tx1 > 15:
                tags.append((200 + tx1, 200 + x, 200 + (tx1 + x) // 2))
    if in_t and len(tag_h) - tx1 > 15:
        tags.append((200 + tx1, 200 + len(tag_h), 200 + (tx1 + len(tag_h)) // 2))
        
    print(f"Row {r_idx} ({dname}): detected {len(tags)} tags at centers:")
    for t_idx, (t1, t2, tc) in enumerate(tags):
        print(f"  Tag {t_idx+1}: X=[{t1}, {t2}], center={tc}")
