from PIL import Image
import numpy as np
from collections import deque

def remove_black_bg_flood(img_rgb, tol=25):
    arr = np.array(img_rgb)
    h, w, _ = arr.shape
    
    # Distance from black [0, 0, 0]
    black_dist = np.sqrt(np.sum(arr.astype(float)**2, axis=2))
    is_bg_candidate = black_dist <= tol
    
    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    
    queue = deque()
    # Seed border pixels
    for x in range(w):
        if is_bg_candidate[0, x]:
            queue.append((0, x))
            visited[0, x] = True
        if is_bg_candidate[h-1, x]:
            queue.append((h-1, x))
            visited[h-1, x] = True
    for y in range(h):
        if is_bg_candidate[y, 0]:
            queue.append((y, 0))
            visited[y, 0] = True
        if is_bg_candidate[y, w-1]:
            queue.append((y, w-1))
            visited[y, w-1] = True
            
    while queue:
        cy, cx = queue.popleft()
        bg_mask[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_bg_candidate[ny, nx]:
                    queue.append((ny, nx))
                    
    # Create RGBA
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr[:, :, :3]
    # Soft alpha around edges
    alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
    rgba[:, :, 3] = alpha
    return Image.fromarray(rgba)

im_test = Image.open("assets/temp/idle_row_0.png")
res = remove_black_bg_flood(im_test)
res.save("assets/temp/test_flood_idle_down.png")
print("Saved test_flood_idle_down.png")
