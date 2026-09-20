import cv2
import numpy as np
import json
import os

def main():
    print("=== STEP 2: GENERATING 2K MAZE COLLISION & WALKABLE MASK ===")
    map_path = 'assets/environment/maze/maze_map_clean.png'
    arena = cv2.imread(map_path)
    h, w = arena.shape[:2]
    print(f"Arena size: {w}x{h}")

    # World mapping:
    # Set scale = 0.045 m/px so corridors (40px) are guaranteed 1.8m - 2.2m wide!
    # World width = 1640 * 0.045 = 73.8m
    # World height = 920 * 0.045 = 41.4m
    scale_x = 0.045
    scale_z = 0.045

    # 1. Floor vs Wall segmentation
    # Dirt floor has distinctive warm brownish hue: R > G > B
    # Walls have cool slate grey hue: R, G, B close, or B > R
    b, g, r = cv2.split(arena)
    
    # Floor detection: warm tones
    is_floor = (r.astype(int) > b.astype(int) + 16) & (r.astype(int) > 55)
    
    # Outer 12px border is definitely outer wall
    is_floor[:25, :] = False
    is_floor[-25:, :] = False
    is_floor[:, :25] = False
    is_floor[:, -25:] = False

    # Clean morphological operations to close small gaps and smooth wall edges
    kernel = np.ones((7, 7), np.uint8)
    floor_mask = cv2.morphologyEx(is_floor.astype(np.uint8) * 255, cv2.MORPH_OPEN, kernel)
    floor_mask = cv2.morphologyEx(floor_mask, cv2.MORPH_CLOSE, kernel)

    # Save binary walkable mask
    walkable_path = 'assets/temp/walkable_clean.png'
    cv2.imwrite(walkable_path, floor_mask)
    print(f"[SUCCESS] Saved walkable mask: {walkable_path}")

    # 2. Wall mask is inverse of walkable floor
    wall_mask = (floor_mask == 0).astype(np.uint8) * 255

    # 3. Find connected wall components and bounding boxes
    # We will decompose the wall mask into rectangular collision boxes
    # First, let's find wall contours and fit bounding boxes
    # To avoid tiny fragmented boxes, we use a grid approximation (32x32 blocks)
    grid_h = 46  # 920 / 20 = 46
    grid_w = 82  # 1640 / 20 = 82
    
    grid = cv2.resize(wall_mask, (grid_w, grid_h), interpolation=cv2.INTER_AREA)
    grid_walls = (grid > 128).astype(np.uint8)

    # Greedy 2D rectangular decomposition of grid_walls
    visited = np.zeros_like(grid_walls)
    boxes = []
    
    for y in range(grid_h):
        for x in range(grid_w):
            if grid_walls[y, x] == 1 and visited[y, x] == 0:
                # Find max width
                x2 = x
                while x2 < grid_w and grid_walls[y, x2] == 1 and visited[y, x2] == 0:
                    x2 += 1
                # Find max height for this width
                y2 = y
                can_expand = True
                while y2 + 1 < grid_h and can_expand:
                    for test_x in range(x, x2):
                        if grid_walls[y2 + 1, test_x] == 0 or visited[y2 + 1, test_x] == 1:
                            can_expand = False
                            break
                    if can_expand:
                        y2 += 1
                
                # Mark as visited
                visited[y:y2+1, x:x2] = 1
                
                # Convert grid coords (x..x2, y..y2) to pixel coords
                px1 = (x / grid_w) * w
                px2 = (x2 / grid_w) * w
                py1 = (y / grid_h) * h
                py2 = ((y2 + 1) / grid_h) * h
                
                # Convert pixel coords to world coords:
                # World origin (0, 0) is at map center (w/2, h/2)
                wx1 = (px1 - w / 2.0) * scale_x
                wx2 = (px2 - w / 2.0) * scale_x
                wz1 = (py1 - h / 2.0) * scale_z
                wz2 = (py2 - h / 2.0) * scale_z
                
                box_x = (wx1 + wx2) / 2.0
                box_z = (wz1 + wz2) / 2.0
                box_sx = abs(wx2 - wx1)
                box_sz = abs(wz2 - wz1)
                
                # Filter out microscopic boxes (< 0.3m)
                if box_sx >= 0.3 and box_sz >= 0.3:
                    boxes.append({
                        "name": f"Wall_{len(boxes)}",
                        "x": round(float(box_x), 3),
                        "z": round(float(box_z), 3),
                        "sx": round(float(box_sx), 3),
                        "sz": round(float(box_sz), 3)
                    })

    print(f"[SUCCESS] Decomposed walls into {len(boxes)} clean axis-aligned collision boxes")
    
    with open('assets/temp/wall_boxes.json', 'w') as f:
        json.dump(boxes, f, indent=4)
    print("Saved assets/temp/wall_boxes.json")

    # 4. Compute precise positions for all interactive entities
    # In pixel space of 1640x920:
    # START: bottom-left corridor (px ~ 136, py ~ 830)
    # EXIT: top-right archway (px ~ 1380, py ~ 100)
    # KEY: north-central alcove (px ~ 770, py ~ 150)
    # CHEST: eastern alcove (px ~ 1440, py ~ 660)
    # TUNNEL A: west loop (px ~ 136, py ~ 390)
    # TUNNEL B: east loop (px ~ 1160, py ~ 390)
    
    entities = {
        "player_spawn": {
            "x": round((136 - w / 2.0) * scale_x, 3),
            "y": 0.1,
            "z": round((830 - h / 2.0) * scale_z, 3)
        },
        "exit_gate": {
            "x": round((1380 - w / 2.0) * scale_x, 3),
            "y": 0.2,
            "z": round((100 - h / 2.0) * scale_z, 3)
        },
        "golden_key": {
            "x": round((770 - w / 2.0) * scale_x, 3),
            "y": 0.2,
            "z": round((150 - h / 2.0) * scale_z, 3)
        },
        "chest": {
            "x": round((1440 - w / 2.0) * scale_x, 3),
            "y": 0.2,
            "z": round((660 - h / 2.0) * scale_z, 3)
        },
        "tunnel_a": {
            "x": round((136 - w / 2.0) * scale_x, 3),
            "y": 0.05,
            "z": round((390 - h / 2.0) * scale_z, 3)
        },
        "tunnel_b": {
            "x": round((1160 - w / 2.0) * scale_x, 3),
            "y": 0.05,
            "z": round((390 - h / 2.0) * scale_z, 3)
        }
    }

    # Detect Torches from blueprint
    # In blueprint, torches are marked with flame icons on pedestals:
    # Let's locate torch flames (bright yellow/white pixels surrounded by warm red glow)
    hsv_arena = cv2.cvtColor(arena, cv2.COLOR_BGR2HSV)
    flame_mask = cv2.inRange(hsv_arena, (10, 180, 200), (30, 255, 255))
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(flame_mask)
    
    torches = []
    for i in range(1, num_labels):
        area = stats[i, cv2.CC_STAT_AREA]
        if 8 <= area <= 150:
            cx, cy = centroids[i]
            tx = round((cx - w / 2.0) * scale_x, 3)
            tz = round((cy - h / 2.0) * scale_z, 3)
            # Filter out UI areas or duplicates
            if abs(tx) < 22.0 and abs(tz) < 12.0:
                torches.append({
                    "name": f"Torch_{len(torches)}",
                    "x": float(tx),
                    "y": 1.2,
                    "z": float(tz),
                    "energy": 1.6,
                    "range": 6.5
                })

    print(f"Detected {len(torches)} torch locations from blueprint")
    with open('assets/temp/torches.json', 'w') as f:
        json.dump(torches, f, indent=4)
        
    print("\nEntity Placements in World Coordinates:")
    for k, v in entities.items():
        print(f"  {k:<15}: pos=({v['x']}, {v['y']}, {v['z']})")

    # Save entities metadata for generator
    with open('assets/temp/entities_2k.json', 'w') as f:
        json.dump(entities, f, indent=4)

if __name__ == '__main__':
    main()
