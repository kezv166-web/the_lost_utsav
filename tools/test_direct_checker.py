from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character-atk-alldirection.png")
arr = np.array(im)

crop = arr[15:212, 890:1170].copy()
r = crop[:, :, 0].astype(int)
g = crop[:, :, 1].astype(int)
b = crop[:, :, 2].astype(int)

mean_val = (r + g + b) // 3
color_diff = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])
is_checker = (color_diff < 16) & (mean_val > 135)

h, w = crop.shape[:2]
rgba = np.zeros((h, w, 4), dtype=np.uint8)
rgba[:, :, :3] = crop
rgba[:, :, 3] = np.where(is_checker, 0, 255)

Image.fromarray(rgba).save("assets/temp/test_checker_direct.png")
print("Saved test_checker_direct.png")
