import os

frames_dir = "assets/character/mushika/frames"
trans_dir = "assets/character/mushika/transformation"

# Animations map:
# name: (list_of_relative_paths, fps, loop)
animations = {
    "idle_down": ([f"{frames_dir}/mouse_idle_down_{i}.png" for i in range(4)], 6.0, True),
    "walk_down": ([f"{frames_dir}/mouse_walk_down_{i}.png" for i in range(6)], 8.0, True),
    "idle_up": ([f"{frames_dir}/mouse_idle_up_{i}.png" for i in range(4)], 6.0, True),
    "walk_up": ([f"{frames_dir}/mouse_walk_up_{i}.png" for i in range(6)], 8.0, True),
    "idle_left": ([f"{frames_dir}/mouse_idle_left_{i}.png" for i in range(4)], 6.0, True),
    "walk_left": ([f"{frames_dir}/mouse_walk_left_{i}.png" for i in range(6)], 8.0, True),
    "idle_right": ([f"{frames_dir}/mouse_idle_right_{i}.png" for i in range(4)], 6.0, True),
    "walk_right": ([f"{frames_dir}/mouse_walk_right_{i}.png" for i in range(6)], 8.0, True),
    "transform": ([f"{trans_dir}/mushika_transform_{i}.png" for i in range(8)], 5.0, False),
    "enter_passage": ([f"{frames_dir}/mouse_walk_up_{i}.png" for i in range(4)], 6.0, False)
}

# Collect all unique texture paths and assign ext_resource IDs
tex_to_id = {}
ext_resources = []
res_counter = 1

for anim_name, (tex_list, fps, loop) in animations.items():
    for tex_path in tex_list:
        if tex_path not in tex_to_id:
            res_id = f"{res_counter}_{os.path.splitext(os.path.basename(tex_path))[0]}"
            tex_to_id[tex_path] = res_id
            ext_resources.append((tex_path, res_id))
            res_counter += 1

lines = []
total_steps = len(ext_resources) + 1
lines.append(f'[gd_resource type="SpriteFrames" load_steps={total_steps} format=3]')
lines.append('')

for tex_path, res_id in ext_resources:
    lines.append(f'[ext_resource type="Texture2D" path="res://{tex_path}" id="{res_id}"]')

lines.append('')
lines.append('[resource]')
lines.append('animations = [')
anim_entries = []
for anim_name, (tex_list, fps, loop) in animations.items():
    entry_lines = []
    entry_lines.append('"frames": [')
    frame_lines = []
    for tex_path in tex_list:
        res_id = tex_to_id[tex_path]
        frame_lines.append('{\n"duration": 1.0,\n"texture": ExtResource("' + res_id + '")\n}')
    entry_lines.append(', '.join(frame_lines))
    entry_lines.append('],')
    entry_lines.append(f'"loop": {"true" if loop else "false"},')
    entry_lines.append(f'"name": &"{anim_name}",')
    entry_lines.append(f'"speed": {fps:.1f}')
    anim_entries.append('{\n' + '\n'.join(entry_lines) + '\n}')

lines.append(', '.join(anim_entries))
lines.append(']')

with open('scenes/player/mushika_sprite_frames.tres', 'w') as f:
    f.write('\n'.join(lines))

print(f"scenes/player/mushika_sprite_frames.tres created with {len(animations)} animations and {len(ext_resources)} unique textures!")
