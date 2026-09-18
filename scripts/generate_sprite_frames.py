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
        'walk_right': [(f'walk_right_{i}.png', 1.0) for i in range(8)],
        'jump_down': [(f'jump_down_{i}.png', 1.0) for i in range(4)],
        'jump_up': [(f'jump_up_{i}.png', 1.0) for i in range(4)],
        'jump_left': [(f'jump_left_{i}.png', 1.0) for i in range(4)],
        'jump_right': [(f'jump_right_{i}.png', 1.0) for i in range(4)],
        'attack_axe_right': [(f'attack_axe_right_{i}.png', 1.0) for i in range(6)],
        'attack_axe_left': [(f'attack_axe_left_{i}.png', 1.0) for i in range(6)],
        'attack_rope_right': [(f'attack_rope_right_{i}.png', 1.0) for i in range(6)],
        'attack_rope_left': [(f'attack_rope_left_{i}.png', 1.0) for i in range(6)]
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
        if 'walk' in anim_name:
            speed = 10.5
            is_loop = True
        elif 'jump' in anim_name:
            speed = 8.0
            is_loop = False
        elif 'attack' in anim_name:
            speed = 13.0
            is_loop = False
        else:
            speed = 5.0
            is_loop = True

        frame_objs = []
        for f, d in frames:
            frame_objs.append('{\n"duration": ' + f'{d:.1f}' + ',\n"texture": ExtResource("' + ext_map[f] + '")\n}')
        
        frames_str = ',\n'.join(frame_objs)
        loop_str = 'true' if is_loop else 'false'
        block = f'{{\n"frames": [\n{frames_str}\n],\n"loop": {loop_str},\n"name": &"{anim_name}",\n"speed": {speed}\n}}'
        anim_blocks.append(block)

    lines.append(',\n'.join(anim_blocks))
    lines.append(']')

    content = '\n'.join(lines)
    with open('scenes/player/player_sprite_frames.tres', 'w') as out_f:
        out_f.write(content)

    print('Generated scenes/player/player_sprite_frames.tres with speed=10.5 FPS')

if __name__ == '__main__':
    generate()
