import os

def generate():
    anims = {
        'idle_down': [('idle_down_0.png', 1.0)],
        'idle_up': [('idle_up_0.png', 1.0)],
        'idle_left': [('idle_left_0.png', 1.0)],
        'idle_right': [('idle_right_0.png', 1.0)],
        'walk_down': [(f'walk_down_{i}.png', 1.0) for i in range(8)],
        'walk_up': [(f'walk_up_{i}.png', 1.0) for i in range(8)],
        'walk_left': [(f'walk_left_{i}.png', 1.0) for i in range(8)],
        'walk_right': [(f'walk_right_{i}.png', 1.0) for i in range(8)]
    }

    tex_files = []
    for k, v in anims.items():
        for f, d in v:
            if f not in tex_files:
                tex_files.append(f)

    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(tex_files) + 1} format=3]\n']

    ext_map = {}
    for idx, f in enumerate(tex_files, 1):
        ext_id = f'{idx}_{f.split(".")[0]}'
        ext_map[f] = ext_id
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/character/frames/{f}" id="{ext_id}"]')

    lines.append('\n[resource]')
    lines.append('animations = [')

    anim_blocks = []
    for anim_name, frames in anims.items():
        # Set walk animation to 10.5 FPS for snappy, grounded footsteps at 4.5 m/s
        speed = 10.5 if 'walk' in anim_name else 5.0
        frame_objs = []
        for f, d in frames:
            frame_objs.append('{\n"duration": ' + f'{d:.1f}' + ',\n"texture": ExtResource("' + ext_map[f] + '")\n}')
        
        frames_str = ',\n'.join(frame_objs)
        block = f'{{\n"frames": [\n{frames_str}\n],\n"loop": true,\n"name": &"{anim_name}",\n"speed": {speed}\n}}'
        anim_blocks.append(block)

    lines.append(',\n'.join(anim_blocks))
    lines.append(']')

    content = '\n'.join(lines)
    with open('scenes/player/player_sprite_frames.tres', 'w') as out_f:
        out_f.write(content)

    print('Generated scenes/player/player_sprite_frames.tres with speed=10.5 FPS')

if __name__ == '__main__':
    generate()
