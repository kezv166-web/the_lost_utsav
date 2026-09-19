from PIL import Image
import numpy as np

def check_directions():
    # Check Idle
    im_idle = Image.open("assets/character/frames/character-idle-animation.png")
    bands_idle = [(97, 284), (331, 507), (551, 726), (767, 969)]
    for i, (y1, y2) in enumerate(bands_idle):
        crop = im_idle.crop((200, y1, 400, y2))
        crop.save(f"assets/temp/idle_row_{i}.png")
        print(f"Saved idle_row_{i}.png")

    # Check Jump
    im_jump = Image.open("assets/character/frames/character_jumping_animation(4-direction).png")
    bands_jump = [(14, 247), (259, 492), (508, 730), (743, 946)]
    for i, (y1, y2) in enumerate(bands_jump):
        # Save frame 0 (X: 18..181) and frame 1 (X: 200..340)
        crop0 = im_jump.crop((10, y1, 190, y2))
        crop0.save(f"assets/temp/jump_row_{i}_f0.png")
        crop1 = im_jump.crop((200, y1, 350, y2))
        crop1.save(f"assets/temp/jump_row_{i}_f1.png")
        print(f"Saved jump_row_{i}_f0.png and f1.png")

check_directions()
