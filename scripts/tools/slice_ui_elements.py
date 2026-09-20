"""
The Lost Utsav - UI Elements Slicer
Extracts modular UI assets, crowns, character avatars, buttons, and clean backdrops
from 'assets/start-pages/leaderboard_elements.png' and 'assets/start-pages/start_page_elements.png'.
Strips transparency checkerboards using flood-fill alpha masking.
"""

import os
import sys
from PIL import Image

def remove_checkerboard_flood(img: Image.Image, tolerance: int = 14) -> Image.Image:
    """
    Replaces the outer checkerboard pattern with true transparency (alpha=0)
    using BFS flood-fill from the outer image borders.
    """
    rgba = img.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    
    # Typical checkerboard shades in graphic mockups: ~#BCBCBC (188), ~#808080 (128), ~#FFFFFF (255)
    def is_checkerboard(color):
        r, g, b, a = color
        # Neutral gray check (r approx equal to g approx equal to b)
        if abs(r - g) <= tolerance and abs(g - b) <= tolerance and abs(r - b) <= tolerance:
            # Gray values around 110-210 or pure white border
            if (110 <= r <= 215) or (r >= 240 and g >= 240 and b >= 240):
                return True
        return False

    visited = set()
    queue = []

    # Initialize queue with boundary pixels that match checkerboard
    for x in range(width):
        for y in (0, height - 1):
            if is_checkerboard(pixels[x, y]):
                queue.append((x, y))
                visited.add((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if (x, y) not in visited and is_checkerboard(pixels[x, y]):
                queue.append((x, y))
                visited.add((x, y))

    # BFS flood fill
    while queue:
        cx, cy = queue.pop(0)
        pixels[cx, cy] = (0, 0, 0, 0)
        
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < width and 0 <= ny < height:
                if (nx, ny) not in visited:
                    visited.add((nx, ny))
                    if is_checkerboard(pixels[nx, ny]):
                        queue.append((nx, ny))

    return rgba

def slice_all_ui_elements():
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    out_dir = os.path.join(base_dir, "assets", "start-pages", "slices")
    os.makedirs(out_dir, exist_ok=True)
    
    lb_sheet_path = os.path.join(base_dir, "assets", "start-pages", "leaderboard_elements.png")
    sp_sheet_path = os.path.join(base_dir, "assets", "start-pages", "start_page_elements.png")
    
    if not os.path.exists(lb_sheet_path):
        print(f"Error: {lb_sheet_path} does not exist.")
        return
    if not os.path.exists(sp_sheet_path):
        print(f"Error: {sp_sheet_path} does not exist.")
        return

    lb_sheet = Image.open(lb_sheet_path)
    sp_sheet = Image.open(sp_sheet_path)
    print(f"Leaderboard sheet: {lb_sheet.size}")
    print(f"Start Page sheet: {sp_sheet.size}")

    # 1. Clean Leaderboard Background (Left panel)
    # Box: x=16 to 653, y=40 to 742
    bg_lb = lb_sheet.crop((16, 40, 653, 742))
    bg_lb.save(os.path.join(out_dir, "bg_leaderboard_clean.png"))
    print("Saved bg_leaderboard_clean.png")

    # 2. Clean Start Page Background (Left panel)
    # Box: x=14 to 784, y=50 to 998
    bg_sp = sp_sheet.crop((14, 50, 784, 998))
    bg_sp.save(os.path.join(out_dir, "bg_start_page_clean.png"))
    print("Saved bg_start_page_clean.png")

    # 2b. Start Page Title / Logo (with checkerboard removed)
    sp_title = sp_sheet.crop((810, 70, 1260, 308))
    sp_title_clean = remove_checkerboard_flood(sp_title)
    sp_title_clean.save(os.path.join(out_dir, "sp_title_logo.png"))
    print("Saved sp_title_logo.png")

    # 3. Leaderboard Title / Logo (with checkerboard removed)
    title_logo = lb_sheet.crop((675, 40, 1085, 290))
    title_logo_clean = remove_checkerboard_flood(title_logo)
    title_logo_clean.save(os.path.join(out_dir, "title_logo.png"))
    print("Saved title_logo.png")

    # 4. Leaderboard Header Banner (Horns + Trishul + Banner)
    lb_header = lb_sheet.crop((1105, 40, 1520, 290))
    lb_header_clean = remove_checkerboard_flood(lb_header)
    lb_header_clean.save(os.path.join(out_dir, "leaderboard_header.png"))
    print("Saved leaderboard_header.png")

    # 5. Table Frame
    table_frame = lb_sheet.crop((885, 412, 1520, 726))
    table_frame.save(os.path.join(out_dir, "table_frame.png"))
    print("Saved table_frame.png")

    # 6. Tabs Bar
    tabs_bar = lb_sheet.crop((885, 330, 1315, 398))
    tabs_bar_clean = remove_checkerboard_flood(tabs_bar)
    tabs_bar_clean.save(os.path.join(out_dir, "tabs_bar.png"))
    print("Saved tabs_bar.png")

    # 7. Level Dropdown
    lvl_dropdown = lb_sheet.crop((1325, 330, 1520, 398))
    lvl_dropdown_clean = remove_checkerboard_flood(lvl_dropdown)
    lvl_dropdown_clean.save(os.path.join(out_dir, "level_dropdown.png"))
    print("Saved level_dropdown.png")

    # 8. Scroll Note ("COURAGE INSPIRES OTHERS")
    scroll_note = lb_sheet.crop((915, 770, 1125, 945))
    scroll_note_clean = remove_checkerboard_flood(scroll_note)
    scroll_note_clean.save(os.path.join(out_dir, "scroll_note.png"))
    print("Saved scroll_note.png")

    # 9. Crowns & Avatars
    # Gold, Silver, Bronze crowns
    crown_boxes = [
        ("crown_gold.png", (18, 780, 82, 850)),
        ("crown_silver.png", (86, 780, 150, 850)),
        ("crown_bronze.png", (154, 780, 218, 850)),
    ]
    for filename, box in crown_boxes:
        c_img = lb_sheet.crop(box)
        c_clean = remove_checkerboard_flood(c_img)
        c_clean.save(os.path.join(out_dir, filename))
        print(f"Saved {filename}")

    # 10 Avatars
    avatar_names = [
        "avatar_keshav.png",
        "avatar_aryan.png",
        "avatar_ritvik.png",
        "avatar_aditya.png",
        "avatar_ishaan.png",
        "avatar_sneha.png",
        "avatar_harshal.png",
        "avatar_zyaan.png",
        "avatar_dev.png",
        "avatar_meera.png"
    ]
    for i, a_name in enumerate(avatar_names):
        x0 = 222 + i * 68
        x1 = x0 + 64
        a_img = lb_sheet.crop((x0, 780, x1, 850))
        a_clean = remove_checkerboard_flood(a_img)
        a_clean.save(os.path.join(out_dir, a_name))
        print(f"Saved {a_name}")

    # 10. Decorative Lines
    div_gold = lb_sheet.crop((1150, 790, 1515, 840))
    div_gold_clean = remove_checkerboard_flood(div_gold)
    div_gold_clean.save(os.path.join(out_dir, "divider_gold.png"))

    div_red = lb_sheet.crop((1150, 848, 1515, 898))
    div_red_clean = remove_checkerboard_flood(div_red)
    div_red_clean.save(os.path.join(out_dir, "divider_red.png"))
    print("Saved decorative dividers")

    # 11. Start Page Icons (CONTROLS, CREDITS, HELP)
    sp_icons = [
        ("icon_controls.png", (825, 630, 925, 740)),
        ("icon_credits.png", (935, 630, 1035, 740)),
        ("icon_help.png", (1045, 630, 1145, 740))
    ]
    for filename, box in sp_icons:
        icon_img = sp_sheet.crop(box)
        icon_clean = remove_checkerboard_flood(icon_img)
        icon_clean.save(os.path.join(out_dir, filename))
        print(f"Saved {filename}")

    print("\n--- ALL MODULAR UI SLICES GENERATED SUCCESSFULLY ---")

if __name__ == "__main__":
    slice_all_ui_elements()
