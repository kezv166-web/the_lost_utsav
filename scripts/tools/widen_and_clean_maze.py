import os
import shutil
import json
import cv2
import numpy as np

def run_cleanup():
    print("=== STARTING MAZE WIDENING & CLUTTER CLEANUP ===")
    
    # 1. Safety Backup
    map_path = 'assets/environment/maze/maze_map_clean.png'
    backup_path = 'assets/environment/maze/maze_map_clean_pre_widen.png'
    if not os.path.exists(backup_path):
        shutil.copyfile(map_path, backup_path)
        print(f"[BACKUP] Created safety backup: {backup_path}")
    else:
        print(f"[BACKUP] Safety backup already exists: {backup_path}")

    # Load images
    maze_img = cv2.imread(map_path)
    walkable = cv2.imread('assets/temp/walkable_clean.png', cv2.IMREAD_GRAYSCALE)
    with open('assets/temp/wall_boxes.json') as f:
        wall_boxes = json.load(f)

    # 2. Source floor tile for inpainting
    # In maze_map_clean.png, x=128..192, y=896..960 is a pristine 64x64 stone floor tile
    clean_floor_src = maze_img[896:960, 128:192].copy()
    cv2.imwrite('assets/temp/clean_floor_sample.png', clean_floor_src)

    # List of all corridor clutter items to inpaint:
    # (name, x_min, x_max, y_min, y_max)
    clutter_items = [
        # Screenshot area
        ("crate_1", 870, 930, 465, 525),
        ("crate_2", 830, 890, 615, 675),
        ("barrel_debris", 845, 915, 750, 830),
        ("bone_cage", 1295, 1365, 765, 860),
        ("floor_pit", 1165, 1205, 635, 675),
        ("debris_topright", 1240, 1310, 390, 455),
        ("rubble_farright", 1415, 1465, 495, 545),
        
        # Center & North
        ("crate_center_1", 575, 635, 465, 525),
        ("crate_center_2", 405, 465, 620, 680),
        ("debris_north", 440, 510, 185, 250),
        ("spiderweb_north", 440, 510, 70, 125),
        ("crate_north_1", 365, 425, 95, 155),
        ("crate_north_2", 395, 455, 145, 200),
        ("grate_center_bottom", 405, 470, 775, 835),

        # West & South-West
        ("crate_west_top", 195, 255, 255, 315),
        ("debris_west_top", 95, 160, 325, 390),
        ("grate_west_mid", 115, 175, 525, 580),
        ("barrel_west_mid", 185, 245, 595, 660),
        ("crate_west_mid", 235, 295, 600, 660),
        ("debris_west_mid", 185, 250, 685, 750),
        ("barrel_west_bottom", 245, 305, 775, 840),
        ("debris_west_bottom", 225, 290, 845, 910),
    ]

    print(f"\n[INPAINT] Inpainting {len(clutter_items)} corridor clutter elements...")
    for name, x0, x1, y0, y1 in clutter_items:
        w = x1 - x0
        h = y1 - y0
        
        # Tile or resize clean floor tile to cover the area
        tile_patch = cv2.resize(clean_floor_src, (w, h))
        
        # Create mask with soft boundary for seamless clone
        mask = np.full((h, w), 255, dtype=np.uint8)
        # Erode mask border slightly so clone boundary blends with surrounding stone
        cv2.rectangle(mask, (0, 0), (w-1, h-1), 0, thickness=2)
        
        center = (x0 + w // 2, y0 + h // 2)
        try:
            maze_img = cv2.seamlessClone(tile_patch, maze_img, mask, center, cv2.NORMAL_CLONE)
            print(f"  Inpainted {name} at ({center[0]}, {center[1]}) using seamlessClone")
        except Exception as e:
            # Direct blend fallback
            print(f"  Fallback direct blend for {name}: {e}")
            maze_img[y0:y1, x0:x1] = tile_patch
            
        # Update walkable mask: clear obstacle footprints
        walkable[y0:y1, x0:x1] = 255

    # 3. Carve back protruding wall blocks at bottleneck intersections
    # Primary bottleneck: T-junction around mouse (1062, 579)
    # Wall_62 is at px [1056..1088], py [544..576] (col 33, row 17)
    # Wall_25 bottom block is at px [1024..1056], py [544..576] (col 32, row 17)
    print("\n[WALL CARVING] Carving back protruding wall blocks at T-junction bottleneck...")
    carve_boxes = [
        ("T-junction Wall_62", 1056, 1088, 544, 576),
        ("T-junction Wall_25 bottom corner", 1024, 1056, 544, 576),
    ]
    
    for name, x0, x1, y0, y1 in carve_boxes:
        w = x1 - x0
        h = y1 - y0
        tile_patch = cv2.resize(clean_floor_src, (w, h))
        mask = np.full((h, w), 255, dtype=np.uint8)
        cv2.rectangle(mask, (0, 0), (w-1, h-1), 0, thickness=2)
        center = (x0 + w // 2, y0 + h // 2)
        try:
            maze_img = cv2.seamlessClone(tile_patch, maze_img, mask, center, cv2.NORMAL_CLONE)
            print(f"  Carved wall block {name} at ({center[0]}, {center[1]})")
        except Exception as e:
            maze_img[y0:y1, x0:x1] = tile_patch
        # Mark as walkable in walkable_clean
        walkable[y0:y1, x0:x1] = 255

    # Save updated maze map and walkable clean
    cv2.imwrite(map_path, maze_img)
    print(f"[SAVE] Saved updated maze map: {map_path}")
    cv2.imwrite('assets/temp/walkable_clean.png', walkable)
    print("[SAVE] Saved updated walkable mask: assets/temp/walkable_clean.png")

    # 4. Update wall_boxes.json
    print("\n[COLLISION] Updating wall boxes to match carved boundaries...")
    new_wall_boxes = []
    box_idx = 0
    for b in wall_boxes:
        # Remove protruding wall block at x=3.8, z=0.6 (former Wall_62)
        if (b.get("name") == "Wall_62" and b.get("x") == 3.8 and b.get("z") == 0.6) or (b.get("x") == 3.8 and b.get("z") == 0.6):
            print(f"  [COLLISION] Deleted {b['name']} at x={b['x']}, z={b['z']} (T-junction protrusion removed)")
            continue
        elif b.get("x") == 3.4 and (b.get("sz") == 4.0 or b.get("z") == -1.2):
            mod_b = {
                "name": f"Wall_{box_idx}",
                "x": b["x"],
                "z": -1.4,
                "sx": b["sx"],
                "sz": 3.6
            }
            new_wall_boxes.append(mod_b)
            print(f"  [COLLISION] Carved {b['name']} -> sz=3.6, z=-1.4 (bottom corner carved)")
            box_idx += 1
        else:
            mod_b = {
                "name": f"Wall_{box_idx}",
                "x": b["x"],
                "z": b["z"],
                "sx": b["sx"],
                "sz": b["sz"]
            }
            new_wall_boxes.append(mod_b)
            box_idx += 1

    print(f"  Final wall boxes: {len(new_wall_boxes)} (was {len(wall_boxes)})")
    with open('assets/temp/wall_boxes.json', 'w') as f:
        json.dump(new_wall_boxes, f, indent=4)
    print("[SAVE] Saved updated assets/temp/wall_boxes.json")

    # 5. Distance Transform Clearance Verification
    print("\n[VERIFICATION] Computing distance transform across updated walkable map...")
    dist = cv2.distanceTransform(walkable, cv2.DIST_L2, 5)
    
    # Check T-junction clearance (row 17-18, col 31-35)
    tj_min_dist = dist[544:608, 992:1120].max()
    print(f"  T-junction max corridor clearance radius: {tj_min_dist:.1f} px ({tj_min_dist * 0.025:.2f} m)")
    
    # Check clearance at each former clutter location
    print("  Clearance at former clutter locations:")
    for name, x0, x1, y0, y1 in clutter_items[:8]:
        cx = (x0 + x1) // 2
        cy = (y0 + y1) // 2
        d = dist[cy, cx]
        print(f"    {name:<20}: center=({cx}, {cy}) -> radius {d:.1f} px ({d * 0.025:.2f} m, width={d*2*0.025:.2f} m)")

    # 6. Save a preview comparison screenshot of the user view region
    # User view region is roughly x in [700..1500], y in [200..900]
    user_view_after = maze_img[200:900, 700:1500]
    cv2.imwrite('assets/temp/user_view_after_cleanup.png', user_view_after)
    print("[SAVE] Saved visual comparison preview: assets/temp/user_view_after_cleanup.png")

if __name__ == '__main__':
    run_cleanup()
