from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character_jumping_animation(4-direction).png")
arr = np.array(im)

bands_jump = [(14, 247), (259, 492), (508, 730), (743, 946)]
# Let's save each of the 8 frames of row 0 with and without the bottom 35 pixels to check visually!
for f_idx in range(8):
    # From earlier col detection:
    cols = [(224, 338), (375, 496), (529, 656), (697, 828), (874, 1003), (1050, 1166), (1210, 1338), (1393, 1488)]
    x1, x2 = cols[f_idx]
    frame_crop = arr[14:247, x1:x2]
    
    # Save full frame
    Image.fromarray(frame_crop).save(f"assets/temp/jump_r0_f{f_idx}_full.png")
    # Save trimmed (cut off bottom 32 pixels where tag is)
    Image.fromarray(frame_crop[:-32, :]).save(f"assets/temp/jump_r0_f{f_idx}_trimmed.png")

print("Saved jump frames for inspection.")
