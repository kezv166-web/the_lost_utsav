import json
import numpy as np
from PIL import Image

def analyze_diff():
    walk = np.array(Image.open('assets/temp/walkable_clean.png'))
    with open('assets/temp/wall_boxes.json') as f:
        boxes = json.load(f)

    box_mask = np.zeros_like(walk)
    for b in boxes:
        px_min = int(round((b['x'] - b['sx'] / 2.0) / 0.0125 + 768))
        px_max = int(round((b['x'] + b['sx'] / 2.0) / 0.0125 + 768))
        py_min = int(round((b['z'] - b['sz'] / 2.0) / 0.0125 + 512))
        py_max = int(round((b['z'] + b['sz'] / 2.0) / 0.0125 + 512))
        box_mask[py_min:py_max, px_min:px_max] = 255

    wall_mask = (walk == 0).astype(np.uint8) * 255
    # Where wall_mask has wall but box_mask does NOT:
    extra_walls_in_walk = (wall_mask == 255) & (box_mask == 0)
    # Where box_mask has wall but wall_mask has walkable:
    extra_walls_in_box = (box_mask == 255) & (wall_mask == 0)

    print(f"Extra walls in walk (not in boxes): {np.sum(extra_walls_in_walk)}")
    print(f"Extra walls in boxes (marked walkable in walk): {np.sum(extra_walls_in_box)}")

    # Let's save a visualization of the difference
    diff_vis = np.zeros((1024, 1536, 3), dtype=np.uint8)
    diff_vis[box_mask == 255] = [100, 100, 100]  # gray: boxes
    diff_vis[extra_walls_in_walk] = [255, 0, 0]   # red: extra wall in walkable_clean
    diff_vis[extra_walls_in_box] = [0, 0, 255]   # blue: extra box over walkable
    Image.fromarray(diff_vis).save('assets/temp/box_walk_diff.png')
    print("Saved assets/temp/box_walk_diff.png")

if __name__ == '__main__':
    analyze_diff()
