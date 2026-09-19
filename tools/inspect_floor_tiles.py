from PIL import Image

sheet = Image.open('scenes/levels/l3/3d-3rd-lvl.png').convert('RGBA')

# Under FLOOR TILES (MODULAR):
# Let's crop the entire FLOOR TILES area from x=310 to x=810, y=835 to y=1005
floor_area = sheet.crop((310, 835, 810, 1005))
floor_area.save('assets/environment/l3_3d/all_floor_tiles_overview.png')

# Let's crop tile 1 (top-left of floor tiles)
tile_tl = sheet.crop((315, 850, 375, 915))
tile_tl.save('assets/environment/l3_3d/tile_tl.png')

# Let's crop tile bl (bottom-left of floor tiles)
tile_bl = sheet.crop((315, 925, 375, 995))
tile_bl.save('assets/environment/l3_3d/tile_bl.png')

print("Overview and sample tiles saved.")
