import os
from PIL import Image, ImageDraw

def extract_puzzle_assets():
    src_path = 'assets/vfx/gate-1-puzzle.png'
    out_dir = 'assets/vfx/puzzle'
    os.makedirs(out_dir, exist_ok=True)
    
    img = Image.open(src_path)
    print(f"Loaded {src_path}: size {img.size}")
    
    # 1. Right Scene Background (1145 x 941)
    right_x_start = 527
    bg_orig = img.crop((right_x_start, 0, img.width, img.height))
    
    # Resize master background to 1020 x 720 (Project viewport standard)
    SCREEN_W, SCREEN_H = 1020, 720
    scale_x = SCREEN_W / bg_orig.width
    scale_y = SCREEN_H / bg_orig.height
    
    bg_screen = bg_orig.resize((SCREEN_W, SCREEN_H), Image.Resampling.LANCZOS)
    
    # Original grid coordinates in 1145 x 941
    orig_x_bounds = [250, 415, 611, 775]
    orig_y_bounds = [202, 371, 546, 708]
    
    # Scaled coordinates in 1020 x 720
    x_bounds = [round(x * scale_x) for x in orig_x_bounds]
    y_bounds = [round(y * scale_y) for y in orig_y_bounds]
    print(f"Scaled grid X: {x_bounds}, Y: {y_bounds}")
    
    socket_w = x_bounds[3] - x_bounds[0]
    socket_h = y_bounds[3] - y_bounds[0]
    print(f"Socket size: {socket_w} x {socket_h} at ({x_bounds[0]}, {y_bounds[0]})")
    
    # Complete Bappa Disc (assembled image without empty socket)
    complete_disc = bg_screen.crop((x_bounds[0], y_bounds[0], x_bounds[3], y_bounds[3]))
    complete_disc.save(os.path.join(out_dir, 'complete_bappa_disc.png'))
    print(f"Saved complete_bappa_disc.png ({complete_disc.size})")
    
    # Generate 9 individual piece textures from the solved disc
    for r in range(3):
        for c in range(3):
            idx = r * 3 + c
            x0 = x_bounds[c]
            x1 = x_bounds[c+1]
            y0 = y_bounds[r]
            y1 = y_bounds[r+1]
            piece = bg_screen.crop((x0, y0, x1, y1))
            piece_filename = f'piece_{idx}.png'
            piece.save(os.path.join(out_dir, piece_filename))
            print(f"Saved {piece_filename}: size {piece.size}")
            
    # Generate Empty Socket Background
    bg_empty = bg_screen.copy()
    stone_socket = Image.new('RGB', (socket_w, socket_h), (26, 24, 20))
    sdraw = ImageDraw.Draw(stone_socket)
    sdraw.rectangle([0, 0, socket_w-1, socket_h-1], outline=(15, 12, 10), width=4)
    
    col_xs = [0, x_bounds[1] - x_bounds[0], x_bounds[2] - x_bounds[0], socket_w]
    row_ys = [0, y_bounds[1] - y_bounds[0], y_bounds[2] - y_bounds[0], socket_h]
    
    for r in range(3):
        for c in range(3):
            x0 = col_xs[c]
            x1 = col_xs[c+1]
            y0 = row_ys[r]
            y1 = row_ys[r+1]
            sdraw.rectangle([x0+2, y0+2, x1-2, y1-2], fill=(22, 20, 16), outline=(42, 36, 28), width=2)
            sdraw.line([x0+3, y0+3, x1-3, y0+3], fill=(12, 10, 8), width=2)
            sdraw.line([x0+3, y0+3, x0+3, y1-3], fill=(12, 10, 8), width=2)
            
    bg_empty.paste(stone_socket, (x_bounds[0], y_bounds[0]))
    bg_empty.save(os.path.join(out_dir, 'gate_puzzle_bg_empty.png'))
    print("Saved gate_puzzle_bg_empty.png")
    
    # 5. Wooden Tray Frame for Left Panel ('PIECES')
    tray_w, tray_h = 205, 470
    tray = Image.new('RGBA', (tray_w, tray_h), (38, 26, 18, 248))
    tdraw = ImageDraw.Draw(tray)
    tdraw.rectangle([0, 0, tray_w-1, tray_h-1], outline=(106, 68, 38, 255), width=4)
    tdraw.rectangle([4, 4, tray_w-5, tray_h-5], outline=(168, 112, 60, 255), width=2)
    tdraw.rectangle([6, 6, tray_w-7, tray_h-7], outline=(60, 36, 20, 255), width=2)
    # Corner rivets
    for cx, cy in [(4, 4), (tray_w-8, 4), (4, tray_h-8), (tray_w-8, tray_h-8)]:
        tdraw.rectangle([cx, cy, cx+4, cy+4], fill=(210, 150, 70, 255), outline=(90, 50, 20, 255))
    tdraw.line([10, 38, tray_w-10, 38], fill=(80, 48, 28, 255), width=2)
    tdraw.line([10, 40, tray_w-10, 40], fill=(140, 90, 50, 255), width=1)
    tray.save(os.path.join(out_dir, 'tray_bg.png'))
    print("Saved tray_bg.png")

if __name__ == '__main__':
    extract_puzzle_assets()
