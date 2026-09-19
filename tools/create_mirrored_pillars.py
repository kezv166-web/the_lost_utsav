import os
from PIL import Image

out_dir = 'assets/environment/l3_3d'

left_banner = Image.open(os.path.join(out_dir, 'pillar_tall_banner_left.png'))
right_banner = left_banner.transpose(Image.FLIP_LEFT_RIGHT)
right_banner.save(os.path.join(out_dir, 'pillar_tall_banner_right.png'))

med_left_banner = Image.open(os.path.join(out_dir, 'pillar_medium_banner_left.png'))
med_right_banner = med_left_banner.transpose(Image.FLIP_LEFT_RIGHT)
med_right_banner.save(os.path.join(out_dir, 'pillar_medium_banner_right.png'))

print("Mirrored banner pillars created successfully")
