from PIL import Image
import numpy as np

im = Image.open("assets/character/frames/character_jumping_animation(4-direction).png")
arr = np.array(im)

# Let's inspect row 0 (FRONT JUMP)
# X frames approx centers:
x_frames = [
    (224, 338),
    (375, 496),
    (529, 656),
    (697, 828),
    (874, 1003),
    (1050, 1166),
    (1210, 1338),
    (1393, 1488)
]

print("Row 0 Frame inspection:")
for i, (x1, x2) in enumerate(x_frames):
    crop = arr[14:247, x1:x2]
    alpha = crop[:, :, 3] > 20
    ys, xs = np.where(alpha)
    # The number tag is near the bottom
    # Let's see the histogram of Y to separate the character from the number tag
    y_hist = alpha.sum(axis=1)
    # Find the gap or lowest row of character
    print(f"Frame {i+1}: total Y=[{ys.min()}, {ys.max()}] (h={ys.max()-ys.min()+1}), X=[{xs.min()}, {xs.max()}] (w={xs.max()-xs.min()+1})")
