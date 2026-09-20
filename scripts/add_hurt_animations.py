import os
import re

frames_dir = 'assets/asur/frames/hurt_stun'
tres_path = 'scenes/enemy/asur_sprite_frames.tres'

# Read UIDs
uids = {}
for f in os.listdir(frames_dir):
    if f.endswith('.png.import'):
        base = f[:-7]
        with open(os.path.join(frames_dir, f), 'r', encoding='utf-8') as fp:
            c = fp.read()
            m = re.search(r'uid="([^"]+)"', c)
            if m:
                uids[base] = m.group(1)

with open(tres_path, 'r', encoding='utf-8') as fp:
    tres_content = fp.read()

# Determine highest ext_resource id number
existing_ids = [int(m) for m in re.findall(r'id="(\d+)_', tres_content)]
next_id = max(existing_ids) + 1 if existing_ids else 69

frame_keys = [
    'asur_hurt_1_idle',
    'asur_hurt_2_impact',
    'asur_hurt_3_reaction',
    'asur_hurt_4_stagger',
    'asur_hurt_5_stagger_more',
    'asur_hurt_6_bend',
    'asur_hurt_7_dizzy_stars',
    'asur_hurt_8_getup',
    'asur_hurt_9_straighten',
    'asur_hurt_10_stance',
    'asur_hurt_11_shakeoff',
    'asur_hurt_12_ready'
]

ext_lines = []
id_map = {}
for k in frame_keys:
    fname = f'{k}.png'
    uid = uids.get(fname, '')
    res_id = f'{next_id}_{k}'
    id_map[k] = res_id
    ext_lines.append(f'[ext_resource type="Texture2D" uid="{uid}" path="res://assets/asur/frames/hurt_stun/{fname}" id="{res_id}"]')
    next_id += 1

# Insert ext_resource lines right before [resource]
parts = tres_content.split('[resource]')
header = parts[0].strip() + '\n' + '\n'.join(ext_lines) + '\n\n[resource]'
body = parts[1]

# Construct animation JSON-like entries in Godot .tres format
def make_anim(name, frame_list, speed, loop):
    frames_str = []
    for f in frame_list:
        frames_str.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{id_map[f]}")\n}}')
    frames_joined = ', '.join(frames_str)
    loop_str = 'true' if loop else 'false'
    return f'{{\n"frames": [{frames_joined}],\n"loop": {loop_str},\n"name": &"{name}",\n"speed": {speed}\n}}'

anim_hurt = make_anim('hurt', [
    'asur_hurt_2_impact',
    'asur_hurt_3_reaction',
    'asur_hurt_4_stagger',
    'asur_hurt_5_stagger_more',
    'asur_hurt_8_getup',
    'asur_hurt_9_straighten',
    'asur_hurt_10_stance'
], 9.0, False)

anim_stun = make_anim('stunned', [
    'asur_hurt_2_impact',
    'asur_hurt_3_reaction',
    'asur_hurt_4_stagger',
    'asur_hurt_5_stagger_more',
    'asur_hurt_6_bend',
    'asur_hurt_7_dizzy_stars'
], 8.0, True)

anim_recover = make_anim('recover_stun', [
    'asur_hurt_8_getup',
    'asur_hurt_9_straighten',
    'asur_hurt_11_shakeoff',
    'asur_hurt_12_ready'
], 8.0, False)

# Append animations inside animations = [...]
# Find last closing bracket of animations
last_bracket = body.rfind(']')
if last_bracket != -1:
    new_body = body[:last_bracket].rstrip() + ', ' + anim_hurt + ', ' + anim_stun + ', ' + anim_recover + '\n]\n'
    full_tres = header + new_body
    with open(tres_path, 'w', encoding='utf-8') as fp:
        fp.write(full_tres)
    print('Updated asur_sprite_frames.tres successfully with hurt, stunned, and recover_stun animations.')
else:
    print('Error: Could not find closing bracket in tres.')
