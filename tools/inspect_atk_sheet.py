import numpy as np
from PIL import Image

im = Image.open('assets/character/frames/character-atk-alldirection.png')
print("Image size:", im.size, "mode:", im.mode)
arr = np.array(im)

# Check alpha channel
alpha = arr[:, :, 3]
print("Alpha min/max/unique:", alpha.min(), alpha.max(), np.unique(alpha)[:10])

# Check non-transparent pixels or bounding boxes of content
# Let's project alpha along Y axis (sum across X)
y_proj = (alpha > 20).sum(axis=1)
# Find row regions where content exists
in_row = False
row_start = 0
rows = []
for y in range(len(y_proj)):
    if y_proj[y] > 50 and not in_row:
        in_row = True
        row_start = y
    elif y_proj[y] <= 50 and in_row:
        in_row = False
        if y - row_start > 30:
            rows.append((row_start, y))
if in_row:
    rows.append((row_start, len(y_proj)))

print(f"Found {len(rows)} row bands:")
for i, (r1, r2) in enumerate(rows):
    print(f"Row {i}: Y=[{r1}, {r2}], height={r2 - r1}")
    band = alpha[r1:r2, :]
    x_proj = band.sum(axis=0) > 20
    cols = []
    in_col = False
    col_start = 0
    for x in range(len(x_proj)):
        if x_proj[x] and not in_col:
            in_col = True
            col_start = x
        elif not x_proj[x] and in_col:
            in_col = False
            if x - col_start > 30:
                cols.append((col_start, x))
    if in_col:
        cols.append((col_start, len(x_proj)))
    print(f"  Cols ({len(cols)}): {cols}")
