from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character-atk-alldirection.png")
arr = np.array(im)

# Let's inspect a crop of row 0, frame 4 (with slash effect and character)
# Row 0: Y ~ 0..220, Col 4: X ~ 950..1200
crop = arr[10:215, 950:1220]
r = crop[:, :, 0].astype(int)
g = crop[:, :, 1].astype(int)
b = crop[:, :, 2].astype(int)

mean_val = (r + g + b) // 3
color_diff = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])

# Background checkerboard is neutral grey/white
is_checker = (color_diff < 15) & (mean_val > 140)

# But wait, does character have any white/grey? The whites of the eyes!
# Eyes are high up on the head and have color_diff < 15, but are inside the face!
# So an exterior flood fill or connected background will NOT touch the eyes!

h, w = crop.shape[:2]
rgba = np.zeros((h, w, 4), dtype=np.uint8)
rgba[:, :, :3] = crop
rgba[:, :, 3] = np.where(is_checker, 0, 255)

Image.fromarray(rgba).save("assets/temp/test_atk_crop.png")
print("Saved test_atk_crop.png")
