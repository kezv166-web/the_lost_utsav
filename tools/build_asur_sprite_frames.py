#!/usr/bin/env python3
import os
import re

TRES_PATH = "scenes/enemy/asur_sprite_frames.tres"
FRAMES_DIR = "assets/asur/frames"
os.makedirs("scenes/enemy", exist_ok=True)

def get_uid(png_filename):
    import_path = os.path.join(FRAMES_DIR, png_filename + ".import")
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            for line in f:
                m = re.search(r'uid="(uid://[^"]+)"', line)
                if m:
                    return m.group(1)
    return None

anim_defs = [
    # Idles (2 frames each, gentle breathing stance)
    ("idle_down", [f"asur_idle_down_{i}.png" for i in range(2)], 3.0, "true"),
    ("idle_left", [f"asur_idle_left_{i}.png" for i in range(2)], 3.0, "true"),
    ("idle_right", [f"asur_idle_right_{i}.png" for i in range(2)], 3.0, "true"),
    ("idle_up", [f"asur_idle_up_{i}.png" for i in range(2)], 3.0, "true"),
    
    # Roars (6 frames each, battle roar yell)
    ("roar_down", [f"asur_roar_down_{i}.png" for i in range(6)], 8.0, "false"),
    ("roar_left", [f"asur_roar_left_{i}.png" for i in range(6)], 8.0, "false"),
    ("roar_right", [f"asur_roar_right_{i}.png" for i in range(6)], 8.0, "false"),
    ("roar_up", [f"asur_roar_up_{i}.png" for i in range(6)], 8.0, "false"),
    
    # Attacks (8 frames each, mace smash + earth shockwave spikes)
    ("attack_down", [f"asur_attack_down_{i}.png" for i in range(8)], 9.0, "false"),
    ("attack_left", [f"asur_attack_left_{i}.png" for i in range(8)], 9.0, "false"),
    ("attack_right", [f"asur_attack_right_{i}.png" for i in range(8)], 9.0, "false"),
]

all_textures = []
for anim_name, frames, speed, loop in anim_defs:
    for f in frames:
        if f not in all_textures:
            all_textures.append(f)

ext_resources = {}
ext_lines = []
for idx, tex_file in enumerate(all_textures, start=1):
    res_id = f"{idx}_{os.path.splitext(tex_file)[0]}"
    ext_resources[tex_file] = res_id
    uid = get_uid(tex_file)
    uid_str = f' uid="{uid}"' if uid else ""
    path_str = f"res://assets/asur/frames/{tex_file}"
    ext_lines.append(f'[ext_resource type="Texture2D"{uid_str} path="{path_str}" id="{res_id}"]')

anim_blocks = []
for anim_name, frames, speed, loop in anim_defs:
    frames_str_list = []
    for f in frames:
        res_id = ext_resources[f]
        frames_str_list.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{res_id}")\n}}')
    joined_frames = ", ".join(frames_str_list)
    block = f"""{{
"frames": [{joined_frames}],
"loop": {loop},
"name": &"{anim_name}",
"speed": {speed}
}}"""
    anim_blocks.append(block)

tres_content = f"""[gd_resource type="SpriteFrames" format=3]

{chr(10).join(ext_lines)}

[resource]
animations = [{', '.join(anim_blocks)}]
"""

with open(TRES_PATH, "w", encoding="utf-8") as f:
    f.write(tres_content)

print(f"Successfully created {TRES_PATH} with {len(anim_defs)} animations and {len(all_textures)} textures.")
