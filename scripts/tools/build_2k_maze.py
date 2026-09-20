import os
import cv2
import numpy as np
from PIL import Image

def main():
    print("=== STEP 1: EXTRACTING & PROCESSING 2K MAZE ARENA ===")
    src_path = 'assets/environment/maze-2k.png'
    if not os.path.exists(src_path):
        raise FileNotFoundError(f"Source 2K sheet not found at {src_path}")

    img = cv2.imread(src_path)
    print(f"Loaded master sheet: {src_path}, shape: {img.shape}")

    # 1. Locate the 'FULL MAZE EXAMPLE' panel
    # In maze-2k.png (1024 x 1536):
    # The panel is roughly: Y from 500 to 1020, X from 260 to 1120
    # Let's crop the sub-panel
    sub = img[500:1020, 260:1120]
    
    # The maze arena inside this sub-panel:
    # Header is ~45px tall
    # Outer orange frame borders are at left ~15px, right ~835px, top ~45px, bottom ~505px
    arena = sub[45:505, 15:835]
    print(f"Extracted raw arena shape: {arena.shape}")
    
    # 2. Inpaint text annotations ("START" at bottom-left, "EXIT" at top-right)
    # START is at bottom left: around x: 30..80, y: 390..455
    # Let's inspect the yellow text mask
    hsv = cv2.cvtColor(arena, cv2.COLOR_BGR2HSV)
    yellow_text = cv2.inRange(hsv, (15, 100, 100), (35, 255, 255))
    
    # Clean floor sample from nearby floor (e.g. x: 80..130, y: 390..440)
    clean_floor_sample = arena[390:440, 80:130]
    
    # Inpaint START arrow and label
    start_mask = np.zeros(arena.shape[:2], dtype=np.uint8)
    start_mask[385:455, 25:85] = yellow_text[385:455, 25:85]
    # Dilate mask slightly for clean boundary
    start_mask = cv2.dilate(start_mask, np.ones((5, 5), np.uint8), iterations=1)
    arena_cleaned = cv2.inpaint(arena, start_mask, 5, cv2.INPAINT_TELEA)

    # Inpaint EXIT text label above the archway:
    # EXIT text is around x: 670..715, y: 15..45
    exit_mask = np.zeros(arena.shape[:2], dtype=np.uint8)
    exit_mask[10:45, 665:720] = yellow_text[10:45, 665:720]
    exit_mask = cv2.dilate(exit_mask, np.ones((5, 5), np.uint8), iterations=1)
    arena_cleaned = cv2.inpaint(arena_cleaned, exit_mask, 5, cv2.INPAINT_TELEA)

    # 3. Upscale arena to 2x resolution with high-quality nearest-neighbor / super-resolution
    # Raw is 820 x 460. Sizing to 1640 x 920 (or 2048 x 1150)
    target_w = 1640
    target_h = 920
    arena_hires = cv2.resize(arena_cleaned, (target_w, target_h), interpolation=cv2.INTER_LANCZOS4)
    
    # Add subtle unsharp mask to restore pixel-art sharpness
    gaussian = cv2.GaussianBlur(arena_hires, (0, 0), 1.5)
    arena_crisp = cv2.addWeighted(arena_hires, 1.35, gaussian, -0.35, 0)
    
    out_map_path = 'assets/environment/maze/maze_map_clean.png'
    cv2.imwrite(out_map_path, arena_crisp)
    print(f"[SUCCESS] Saved clean master arena map: {out_map_path} (Resolution: {target_w}x{target_h})")

    # 4. Extract temple wall relief embellishments for the project
    # Ganesha panel (WALL EMBELLISHMENTS: bottom-right x: 1130..1220, y: 600..760)
    ganesha = img[600:760, 1130:1220]
    cv2.imwrite('assets/environment/maze/relief_ganesha.png', ganesha)
    print(f"Saved Ganesha stone relief: assets/environment/maze/relief_ganesha.png ({ganesha.shape})")

    # Lotus panel (WALL EMBELLISHMENTS: x: 1290..1380, y: 600..680)
    lotus = img[600:680, 1290:1380]
    cv2.imwrite('assets/environment/maze/relief_lotus.png', lotus)
    print(f"Saved Lotus stone relief: assets/environment/maze/relief_lotus.png ({lotus.shape})")

    # Om panel (WALL OVERLAYS: x: 880..980, y: 230..325)
    om_panel = img[230:325, 880:980]
    cv2.imwrite('assets/environment/maze/relief_om.png', om_panel)
    print(f"Saved Om stone relief: assets/environment/maze/relief_om.png ({om_panel.shape})")

if __name__ == '__main__':
    main()
