import json
import numpy as np
from PIL import Image

def inspect_grid():
    # Load wall_boxes.json
    with open('assets/temp/wall_boxes.json') as f:
        boxes = json.load(f)

    # Each box in grid coords (0..48, 0..32)
    # gx_min = (x_min / 0.0125 + 768) / 32
    grid_occupancy = np.zeros((32, 48), dtype=int)
    for b in boxes:
        gx0 = int(round(((b['x'] - b['sx']/2.0) / 0.0125 + 768) / 32))
        gx1 = int(round(((b['x'] + b['sx']/2.0) / 0.0125 + 768) / 32))
        gz0 = int(round(((b['z'] - b['sz']/2.0) / 0.0125 + 512) / 32))
        gz1 = int(round(((b['z'] + b['sz']/2.0) / 0.0125 + 512) / 32))
        grid_occupancy[gz0:gz1, gx0:gx1] += 1

    print(f"Grid occupancy min: {grid_occupancy.min()}, max: {grid_occupancy.max()}")
    print("Boxes form a clean binary 32x48 grid?" , np.all((grid_occupancy == 0) | (grid_occupancy == 1)))
    
    # Check overlaps if any
    overlaps = np.sum(grid_occupancy > 1)
    print(f"Number of overlapping grid cells: {overlaps}")

if __name__ == '__main__':
    inspect_grid()
