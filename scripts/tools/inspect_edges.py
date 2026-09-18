import os
from PIL import Image
import numpy as np

project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
l3_dir = os.path.join(project_root, "assets", "environment", "l3")

# Inspect l3_broken_wall_1.png, l3_mandala.png, l3_banner_tall.png
for sample_name in ["l3_broken_wall_1.png", "l3_mandala.png", "l3_banner_tall.png", "l3_carpet.png", "l3_pillar.png"]:
    img = Image.open(os.path.join(l3_dir, sample_name))
    arr = np.array(img)
    print(f"\n=== {sample_name} ===")
    print("Top row colors (sample 5):", arr[0, :5].tolist())
    print("Bottom row colors (sample 5):", arr[-1, :5].tolist())
    print("Left col colors (sample 5):", arr[:5, 0].tolist())
    print("Right col colors (sample 5):", arr[:5, -1].tolist())
