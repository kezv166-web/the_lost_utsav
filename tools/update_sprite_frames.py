#!/usr/bin/env python3
"""
Rebuilds scenes/player/player_sprite_frames.tres with:
- 4-direction, 4-frame idle animations (breathing/prayer pose)
- 4-direction, 8-frame jump animations (crouch, launch, apex, fall, landing)
- All existing walk and attack animations preserved
- Automatic UID extraction from Godot .import files
"""

import os
import re

TRES_PATH = "scenes/player/player_sprite_frames.tres"
FRAMES_DIR = "assets/character/frames"

def get_uid(png_filename):
    import_path = os.path.join(FRAMES_DIR, png_filename + ".import")
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            for line in f:
                m = re.search(r'uid="(uid://[^"]+)"', line)
                if m:
                    return m.group(1)
    return None

# Define all animations and their frame files
anim_defs = [
    # Attacks (Left and Right for Axe attack)
    ("attack_axe_left", [f"attack_axe_left_{i}.png" for i in range(6)], 12.0, 0),
    ("attack_axe_right", [f"attack_axe_right_{i}.png" for i in range(6)], 12.0, 0),
    
    # Attacks (Left and Right for Rope attack)
    ("attack_rope_left", [f"attack_rope_left_{i}.png" for i in range(6)], 13.0, 0),
    ("attack_rope_right", [f"attack_rope_right_{i}.png" for i in range(6)], 13.0, 0),
    
    # Rock carry / lift pose
    ("carry_rock", ["carry_rock.png"], 5.0, 1),
    
    # Idle (3 frames: 0, 1, 2; non-looping, holds 3rd frame prayer pose until movement)
    ("idle_down", [f"idle_down_{i}.png" for i in range(3)], 5.0, 0),
    ("idle_left", [f"idle_left_{i}.png" for i in range(3)], 5.0, 0),
    ("idle_right", [f"idle_right_{i}.png" for i in range(3)], 5.0, 0),
    ("idle_up", [f"idle_up_{i}.png" for i in range(3)], 5.0, 0),
    
    # Jump (8 frames each)
    ("jump_down", [f"jump_down_{i}.png" for i in range(8)], 10.0, 0),
    ("jump_left", [f"jump_left_{i}.png" for i in range(8)], 10.0, 0),
    ("jump_right", [f"jump_right_{i}.png" for i in range(8)], 10.0, 0),
    ("jump_up", [f"jump_up_{i}.png" for i in range(8)], 10.0, 0),
    
    # Walk (8 frames each)
    ("walk_down", [f"walk_down_{i}.png" for i in range(8)], 10.0, 1),
    ("walk_left", [f"walk_left_{i}.png" for i in range(8)], 10.0, 1),
    ("walk_right", [f"walk_right_{i}.png" for i in range(8)], 10.0, 1),
    ("walk_up", [f"walk_up_{i}.png" for i in range(8)], 10.0, 1),
]

# Collect all unique texture files in order
all_textures = []
for anim_name, frames, speed, loop in anim_defs:
    for f in frames:
        if f not in all_textures:
            all_textures.append(f)

# Assign ext_resource IDs
ext_resources = {}
ext_lines = []
for idx, tex_file in enumerate(all_textures, start=1):
    res_id = f"{idx}_{os.path.splitext(tex_file)[0]}"
    ext_resources[tex_file] = res_id
    uid = get_uid(tex_file)
    uid_str = f' uid="{uid}"' if uid else ""
    path_str = f"res://assets/character/frames/{tex_file}"
    ext_lines.append(f'[ext_resource type="Texture2D"{uid_str} path="{path_str}" id="{res_id}"]')

# Build animation blocks
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

# Combine everything
tres_content = f"""[gd_resource type="SpriteFrames" format=3 uid="uid://dg6rpgp5hq6fk"]

{chr(10).join(ext_lines)}

[resource]
animations = [{", ".join(anim_blocks)}]
"""

with open(TRES_PATH, "w", encoding="utf-8") as f:
    f.write(tres_content)

print(f"Successfully generated {TRES_PATH} with {len(anim_defs)} animations and {len(all_textures)} texture resources.")
