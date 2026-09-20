import json
import numpy as np
from PIL import Image

def check_boxes_vs_walkable():
    walk = np.array(Image.open('assets/temp/walkable_clean.png'))
    with open('assets/temp/wall_boxes.json') as f:
        boxes = json.load(f)

    # Render boxes onto an image of size 1536 x 1024
    # pixel_size = 0.0125
    # x = (px - 768) * 0.0125  =>  px = x / 0.0125 + 768
    # z = (py - 512) * 0.0125  =>  py = z / 0.0125 + 512
    # box has x, z, sx, sz
    # box x_min = x - sx/2, x_max = x + sx/2
    # box z_min = z - sz/2, z_max = z + sz/2
    
    box_mask = np.zeros_like(walk)
    for b in boxes:
        x_min = b['x'] - b['sx'] / 2.0
        x_max = b['x'] + b['sx'] / 2.0
        z_min = b['z'] - b['sz'] / 2.0
        z_max = b['z'] + b['sz'] / 2.0
        
        px_min = int(round(x_min / 0.0125 + 768))
        px_max = int(round(x_max / 0.0125 + 768))
        py_min = int(round(z_min / 0.0125 + 512))
        py_max = int(round(z_max / 0.0125 + 512))
        
        box_mask[py_min:py_max, px_min:px_max] = 255

    wall_mask = (walk == 0).astype(np.uint8) * 255
    diff = np.abs(box_mask.astype(int) - wall_mask.astype(int))
    print(f"Total box mask pixels: {np.sum(box_mask > 0)}")
    print(f"Total wall mask pixels: {np.sum(wall_mask > 0)}")
    print(f"Difference pixels: {np.sum(diff > 0)} ({(np.sum(diff > 0)/diff.size)*100:.2f}%)")

    # Also check if boxes are aligned to a grid (e.g. 32px or 16px)
    grid_alignments = set()
    for b in boxes:
        px_min = round((b['x'] - b['sx']/2.0) / 0.0125 + 768)
        px_max = round((b['x'] + b['sx']/2.0) / 0.0125 + 768)
        py_min = round((b['z'] - b['sz']/2.0) / 0.0125 + 512)
        py_max = round((b['z'] + b['sz']/2.0) / 0.0125 + 512)
        grid_alignments.add(px_min % 32)
        grid_alignments.add(px_max % 32)
        grid_alignments.add(py_min % 32)
        grid_alignments.add(py_max % 32)
    print(f"Grid alignment remainder modulo 32: {sorted(list(grid_alignments))}")

if __name__ == '__main__':
    check_boxes_vs_walkable()
