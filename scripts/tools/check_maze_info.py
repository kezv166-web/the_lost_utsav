import re

with open('scenes/levels/maze/maze.tscn', 'r') as f:
    text = f.read()

shapes = dict(re.findall(r'\[sub_resource type="BoxShape3D" id="([^"]+)"\]\nsize = Vector3\(([^)]+)\)', text))
walls = re.findall(r'\[node name="(Wall_\d+)" type="StaticBody3D" parent="MazeWalls"\]\ntransform = Transform3D\([^,]+, [^,]+, [^,]+, [^,]+, [^,]+, [^,]+, [^,]+, [^,]+, [^,]+, ([^,]+), ([^,]+), ([^)]+)\)', text)

print("Walls near (0, 0):")
for w, x, y, z in walls:
    shape_id = f"Shape_{w}"
    sx, sy, sz = [float(v) for v in shapes[shape_id].split(',')]
    wx, wy, wz = float(x), float(y), float(z)
    if abs(wx) < 10 and abs(wz) < 10:
        print(f"{w} at ({wx}, {wz}) size: ({sx}, {sz}) -> X:[{wx - sx/2}, {wx + sx/2}], Z:[{wz - sz/2}, {wz + sz/2}]")
