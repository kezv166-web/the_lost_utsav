import os
import json
from collections import deque

def build_25d_maze():
    print("=== BUILDING 2.5D MAZE: UPSTREAM 3D WALLS, BILLBOARD SPRITES & ENTITIES ===")

    # 37 cols x 21 rows
    # Tile size = 2.0m x 2.0m -> World: 74.0m x 42.0m
    # World origin (0, 0) at center (col=18, row=10)
    blueprint = [
        "#####################################", # 0
        "#...............#.......#.......E...#", # 1
        "#...#########...#...#...#...........#", # 2
        "#...#.......#...#...#...#########...#", # 3
        "#...#.......#...#...#...........#...#", # 4
        "#...#####.###...#...#########...#...#", # 5
        "#.......#...#.......#.......#...#...#", # 6
        "#######.#...#########...#...#...#...#", # 7
        "#.......#...#.......#...#...#.......#", # 8
        "#.A.#####...#...#...#...#...#####.B.#", # 9
        "#...#.......#...#.K.#...#...#.......#", # 10
        "#...#...#####...#...#...#...#...#...#", # 11
        "#...#...#.......#...#...#...#...#...#", # 12
        "#...#...#...#####...#...#...#...#...#", # 13
        "#.......#.......#...#...#...#...#...#", # 14
        "#####.###...#...#...#...#...#...#...#", # 15
        "#.......#...#...#...#...#.......#...#", # 16
        "#...#...#...#####...#...#####...#.C.#", # 17
        "#...#...#.......#.......#...........#", # 18
        "#S..#...#.......#.......#...........#", # 19
        "#####################################", # 20
    ]

    H = len(blueprint)
    W = len(blueprint[0])
    tile_size = 2.0
    half_w = (W - 1) / 2.0
    half_h = (H - 1) / 2.0

    def tile_to_world(col, row):
        return round((col - half_w) * tile_size, 3), round((row - half_h) * tile_size, 3)

    # 1. BFS Verification of 100% Reachability
    entity_coords = {}
    for r in range(H):
        for c in range(W):
            ch = blueprint[r][c]
            if ch in ['S', 'K', 'E', 'C', 'A', 'B']:
                entity_coords[ch] = (c, r)

    start = entity_coords['S']
    q = deque([start])
    visited = {start}
    while q:
        cx, cy = q.popleft()
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < W and 0 <= ny < H:
                if (nx, ny) not in visited and blueprint[ny][nx] != '#':
                    visited.add((nx, ny))
                    q.append((nx, ny))

    walkable_count = sum(blueprint[r][c] != '#' for r in range(H) for c in range(W))
    print(f"Total walkable tiles: {walkable_count}, Reachable from Spawn: {len(visited)}")
    assert len(visited) == walkable_count, "Error: disconnected tiles in maze blueprint!"
    for name, pos in entity_coords.items():
        assert pos in visited, f"Error: Entity {name} is unreachable from Spawn!"
    print("[VERIFICATION PASSED] All 489 walkable tiles and all 5 objectives are 100% reachable!")

    # 2. Decompose solid '#' wall tiles into merged rectangular 3D boxes
    wall_grid = [[1 if blueprint[r][c] == '#' else 0 for c in range(W)] for r in range(H)]
    wall_visited = [[0 for _ in range(W)] for _ in range(H)]
    wall_boxes = []

    for r in range(H):
        for c in range(W):
            if wall_grid[r][c] == 1 and not wall_visited[r][c]:
                c2 = c
                while c2 < W and wall_grid[r][c2] == 1 and not wall_visited[r][c2]:
                    c2 += 1
                
                r2 = r
                can_expand = True
                while r2 + 1 < H and can_expand:
                    for test_c in range(c, c2):
                        if wall_grid[r2 + 1][test_c] == 0 or wall_visited[r2 + 1][test_c] == 1:
                            can_expand = False
                            break
                    if can_expand:
                        r2 += 1

                for vr in range(r, r2 + 1):
                    for vc in range(c, c2):
                        wall_visited[vr][vc] = 1

                num_cols = c2 - c
                num_rows = r2 - r + 1
                center_col = (c + c2 - 1) / 2.0
                center_row = (r + r2) / 2.0

                wx, wz = tile_to_world(center_col, center_row)
                sx = round(num_cols * tile_size, 3)
                sz = round(num_rows * tile_size, 3)

                wall_boxes.append({
                    "name": f"Wall_{len(wall_boxes)}",
                    "x": wx,
                    "z": wz,
                    "sx": sx,
                    "sz": sz
                })

    print(f"[DECOMPOSITION] Merged walls into {len(wall_boxes)} clean, solid 3D wall boxes!")

    # 3. Interactive Entities Positions
    sp_x, sp_z = tile_to_world(*entity_coords['S'])
    key_x, key_z = tile_to_world(*entity_coords['K'])
    exit_x, exit_z = tile_to_world(*entity_coords['E'])
    chest_x, chest_z = tile_to_world(*entity_coords['C'])
    ta_x, ta_z = tile_to_world(*entity_coords['A'])
    tb_x, tb_z = tile_to_world(*entity_coords['B'])

    entities = {
        "player_spawn": {"x": sp_x, "y": 0.1, "z": sp_z},
        "golden_key": {"x": key_x, "y": 0.65, "z": key_z},
        "exit_gate": {"x": exit_x, "y": 1.4, "z": exit_z},
        "chest": {"x": chest_x, "y": 0.4, "z": chest_z},
        "tunnel_a": {"x": ta_x, "y": 0.35, "z": ta_z},
        "tunnel_b": {"x": tb_x, "y": 0.35, "z": tb_z}
    }

    # 4. Flaming Braziers & Torches
    torches = [
        # Spawn antechamber
        {"name": "Torch_Spawn", "x": sp_x + 2.0, "y": 1.2, "z": sp_z, "energy": 2.0, "range": 7.0},
        # Golden Key sanctuary (flanking stone altar)
        {"name": "Brazier_Key_L", "x": key_x - 2.2, "y": 0.8, "z": key_z, "energy": 2.4, "range": 8.0, "is_brazier": True},
        {"name": "Brazier_Key_R", "x": key_x + 2.2, "y": 0.8, "z": key_z, "energy": 2.4, "range": 8.0, "is_brazier": True},
        # Exit Gate (flanking iron portcullis)
        {"name": "Brazier_Exit_L", "x": exit_x - 2.4, "y": 1.0, "z": exit_z + 0.4, "energy": 2.6, "range": 8.5, "is_brazier": True},
        {"name": "Brazier_Exit_R", "x": exit_x + 2.4, "y": 1.0, "z": exit_z + 0.4, "energy": 2.6, "range": 8.5, "is_brazier": True},
        # Asur supply chest
        {"name": "Torch_Chest", "x": chest_x, "y": 1.2, "z": chest_z - 2.0, "energy": 2.0, "range": 7.0},
        # Mouse tunnels
        {"name": "Torch_TunnelA", "x": ta_x, "y": 1.2, "z": ta_z + 2.0, "energy": 1.8, "range": 6.0},
        {"name": "Torch_TunnelB", "x": tb_x, "y": 1.2, "z": tb_z + 2.0, "energy": 1.8, "range": 6.0},
        # Corridor junctions
        {"name": "Torch_Junction_1", "x": 0.0, "y": 1.2, "z": 0.0, "energy": 2.0, "range": 7.5},
        {"name": "Torch_Junction_2", "x": -16.0, "y": 1.2, "z": 8.0, "energy": 1.8, "range": 6.5},
        {"name": "Torch_Junction_3", "x": 16.0, "y": 1.2, "z": -8.0, "energy": 1.8, "range": 6.5},
        {"name": "Torch_Junction_4", "x": -8.0, "y": 1.2, "z": -8.0, "energy": 1.8, "range": 6.5},
        {"name": "Torch_Junction_5", "x": 8.0, "y": 1.2, "z": 8.0, "energy": 1.8, "range": 6.5},
    ]

    # Save temp metadata
    os.makedirs('assets/temp', exist_ok=True)
    with open('assets/temp/wall_boxes.json', 'w') as f:
        json.dump(wall_boxes, f, indent=4)
    with open('assets/temp/entities_2k.json', 'w') as f:
        json.dump(entities, f, indent=4)
    with open('assets/temp/torches.json', 'w') as f:
        json.dump(torches, f, indent=4)

    # 5. GENERATE scenes/levels/maze/maze.tscn
    print("\n=== GENERATING 2.5D scenes/levels/maze/maze.tscn ===")
    lines = []
    # Total external resources:
    # 1: script maze_controller.gd
    # 2: texture stone_floor_tile.png (Floor)
    # 3: texture castle_brick_tile.png (Walls)
    # 4: packedscene player.tscn
    # 5: packedscene camera_rig.tscn
    # 6: texture key_gold.png
    # 7: texture chest_gold.png
    # 8: texture gate_iron_large.png
    # 9: packedscene black_tunnel.tscn
    # 10: texture brazier_flaming.png
    # 11: texture relief_ganesha.png
    # 12: texture relief_om.png
    # 13: texture relief_lotus.png

    total_load_steps = 14 + len(wall_boxes) * 2 + 7 # 13 ext + (2 mats + 4 shapes + 1 mesh + len(boxes)*2 shapes/meshes) + 1
    lines.append(f'[gd_scene load_steps={total_load_steps} format=3]')
    lines.append('')
    lines.append('[ext_resource type="Script" path="res://scripts/world/maze_controller.gd" id="1_controller"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/stone_floor_tile.png" id="2_floor_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/castle_brick_tile.png" id="3_brick_tex"]')
    lines.append('[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="4_player"]')
    lines.append('[ext_resource type="PackedScene" path="res://scenes/world/camera_rig.tscn" id="5_camera"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/key_gold.png" id="6_key_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/chest_gold.png" id="7_chest_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/gate_iron_large.png" id="8_gate_tex"]')
    lines.append('[ext_resource type="PackedScene" path="res://scenes/world/black_tunnel.tscn" id="9_tunnel_scene"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/brazier_flaming.png" id="10_brazier_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/relief_ganesha.png" id="11_ganesha_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/relief_om.png" id="12_om_tex"]')
    lines.append('[ext_resource type="Texture2D" path="res://assets/environment/maze/relief_lotus.png" id="13_lotus_tex"]')
    lines.append('')

    # Sub-resources
    lines.append('[sub_resource type="Environment" id="Environment_maze"]')
    lines.append('background_mode = 1')
    lines.append('background_color = Color(0.04, 0.03, 0.05, 1)')
    lines.append('ambient_light_source = 2')
    lines.append('ambient_light_color = Color(0.55, 0.50, 0.58, 1)')
    lines.append('ambient_light_energy = 1.1')
    lines.append('tonemap_mode = 2')
    lines.append('')

    # Wall Material (Triplanar dark slate stone fortress walls)
    lines.append('[sub_resource type="StandardMaterial3D" id="Mat_MazeBrick"]')
    lines.append('albedo_color = Color(0.42, 0.40, 0.50, 1)')
    lines.append('albedo_texture = ExtResource("3_brick_tex")')
    lines.append('roughness = 0.9')
    lines.append('uv1_scale = Vector3(1.2, 1.2, 1.2)')
    lines.append('uv1_triplanar = true')
    lines.append('uv1_world_triplanar = true')
    lines.append('texture_filter = 0')
    lines.append('')

    # Floor Material (Triplanar warm bright sandstone walkable path)
    lines.append('[sub_resource type="StandardMaterial3D" id="Mat_StoneFloor"]')
    lines.append('albedo_color = Color(0.96, 0.90, 0.82, 1)')
    lines.append('albedo_texture = ExtResource("2_floor_tex")')
    lines.append('roughness = 0.85')
    lines.append('uv1_scale = Vector3(1.0, 1.0, 1.0)')
    lines.append('uv1_triplanar = true')
    lines.append('uv1_world_triplanar = true')
    lines.append('texture_filter = 0')
    lines.append('')

    lines.append('[sub_resource type="BoxShape3D" id="Shape_Floor"]')
    lines.append('size = Vector3(78.0, 1.0, 46.0)')
    lines.append('')

    lines.append('[sub_resource type="BoxMesh" id="Mesh_Floor"]')
    lines.append('material = SubResource("Mat_StoneFloor")')
    lines.append('size = Vector3(78.0, 1.0, 46.0)')
    lines.append('')

    lines.append('[sub_resource type="BoxShape3D" id="Shape_KeyTrigger"]')
    lines.append('size = Vector3(2.4, 2.0, 2.4)')
    lines.append('')

    lines.append('[sub_resource type="BoxShape3D" id="Shape_ChestTrigger"]')
    lines.append('size = Vector3(2.8, 2.0, 2.8)')
    lines.append('')

    lines.append('[sub_resource type="BoxShape3D" id="Shape_ExitTrigger"]')
    lines.append('size = Vector3(4.5, 3.0, 3.5)')
    lines.append('')

    # Shapes and Meshes for each Wall Box (Height 1.2m so paths are fully visible)
    for i, box in enumerate(wall_boxes):
        lines.append(f'[sub_resource type="BoxShape3D" id="Shape_Wall_{i}"]')
        lines.append(f'size = Vector3({box["sx"]}, 1.2, {box["sz"]})')
        lines.append('')
        lines.append(f'[sub_resource type="BoxMesh" id="Mesh_Wall_{i}"]')
        lines.append('material = SubResource("Mat_MazeBrick")')
        lines.append(f'size = Vector3({box["sx"]}, 1.2, {box["sz"]})')
        lines.append('')

    # Root Node
    lines.append('[node name="Maze" type="Node3D"]')
    lines.append('script = ExtResource("1_controller")')
    lines.append('')
    lines.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
    lines.append('environment = SubResource("Environment_maze")')
    lines.append('')
    lines.append('[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]')
    lines.append('transform = Transform3D(0.866025, -0.433013, 0.25, 0, 0.5, 0.866025, -0.5, -0.75, 0.433013, 0, 20, 0)')
    lines.append('light_color = Color(0.92, 0.88, 0.98, 1)')
    lines.append('light_energy = 0.85')
    lines.append('shadow_enabled = true')
    lines.append('shadow_bias = 0.05')
    lines.append('')

    # Floor Ground
    lines.append('[node name="FloorGround" type="StaticBody3D" parent="."]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)')
    lines.append('metadata/_edit_lock_ = true')
    lines.append('')
    lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="FloorGround"]')
    lines.append('shape = SubResource("Shape_Floor")')
    lines.append('')
    lines.append('[node name="MeshInstance3D" type="MeshInstance3D" parent="FloorGround"]')
    lines.append('mesh = SubResource("Mesh_Floor")')
    lines.append('')

    # 3D Solid Maze Walls (Height 1.2m, center at Y=0.6m)
    lines.append('[node name="MazeWalls" type="Node3D" parent="."]')
    lines.append('')
    for i, box in enumerate(wall_boxes):
        lines.append(f'[node name="{box["name"]}" type="StaticBody3D" parent="MazeWalls"]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {box["x"]}, 0.6, {box["z"]})')
        lines.append('')
        lines.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="MazeWalls/{box["name"]}"]')
        lines.append(f'shape = SubResource("Shape_Wall_{i}")')
        lines.append('')
        lines.append(f'[node name="MeshInstance3D" type="MeshInstance3D" parent="MazeWalls/{box["name"]}"]')
        lines.append(f'mesh = SubResource("Mesh_Wall_{i}")')
        lines.append('')

    # Wall Embellishments (Stone Relief Plaques on south-facing wall facades)
    lines.append('[node name="WallDecorations" type="Node3D" parent="."]')
    lines.append('')
    # Ganesha Relief in starting corridor wall
    lines.append('[node name="ReliefGanesha" type="Sprite3D" parent="WallDecorations"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {sp_x}, 0.6, {sp_z - 2.0 + 0.05})')
    lines.append('pixel_size = 0.007')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("11_ganesha_tex")')
    lines.append('')

    # Om Relief in Golden Key sanctuary north wall
    lines.append('[node name="ReliefOm" type="Sprite3D" parent="WallDecorations"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {key_x}, 0.6, {key_z - 2.0 + 0.05})')
    lines.append('pixel_size = 0.008')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("12_om_tex")')
    lines.append('')

    # Lotus Relief in Exit Gate wall
    lines.append('[node name="ReliefLotus" type="Sprite3D" parent="WallDecorations"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {exit_x}, 0.6, {exit_z - 1.0 + 0.05})')
    lines.append('pixel_size = 0.008')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("13_lotus_tex")')
    lines.append('')

    # Braziers and Torches
    lines.append('[node name="Torches" type="Node3D" parent="."]')
    lines.append('')
    for i, t in enumerate(torches):
        b_node = f'Torch_{i}'
        lines.append(f'[node name="{b_node}" type="Node3D" parent="Torches"]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {t["x"]}, {t["y"]}, {t["z"]})')
        lines.append('')
        if t.get("is_brazier", False):
            # Upright 2.5D Flaming Brazier (matching outdoor firebox!)
            lines.append(f'[node name="BrazierVisual" type="Sprite3D" parent="Torches/{b_node}"]')
            lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)')
            lines.append('billboard = 2') # BILLBOARD_FIXED_Y
            lines.append('pixel_size = 0.0125')
            lines.append('texture_filter = 0')
            lines.append('texture = ExtResource("10_brazier_tex")')
            lines.append('')
        lines.append(f'[node name="Light" type="OmniLight3D" parent="Torches/{b_node}"]')
        lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)')
        lines.append('light_color = Color(1.0, 0.62, 0.22, 1)')
        lines.append(f'light_energy = {t.get("energy", 2.0)}')
        lines.append(f'omni_range = {t.get("range", 7.0)}')
        lines.append('omni_attenuation = 1.1')
        lines.append('')

    # Interactables
    lines.append('[node name="Interactables" type="Node3D" parent="."]')
    lines.append('')

    # 1. Golden Key (Upright 3D/2.5D floating key)
    lines.append('[node name="GoldenKey" type="Area3D" parent="Interactables"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {key_x}, {entities["golden_key"]["y"]}, {key_z})')
    lines.append('')
    lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/GoldenKey"]')
    lines.append('shape = SubResource("Shape_KeyTrigger")')
    lines.append('')
    lines.append('[node name="KeyVisual" type="Sprite3D" parent="Interactables/GoldenKey"]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)')
    lines.append('billboard = 1') # BILLBOARD_ENABLED
    lines.append('pixel_size = 0.015')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("6_key_tex")')
    lines.append('')
    lines.append('[node name="KeyLight" type="OmniLight3D" parent="Interactables/GoldenKey"]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, 0)')
    lines.append('light_color = Color(1.0, 0.85, 0.3, 1)')
    lines.append('light_energy = 2.2')
    lines.append('omni_range = 4.5')
    lines.append('')

    # 2. Chest (Upright 2.5D treasure chest)
    lines.append('[node name="Chest" type="Area3D" parent="Interactables"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {chest_x}, {entities["chest"]["y"]}, {chest_z})')
    lines.append('')
    lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/Chest"]')
    lines.append('shape = SubResource("Shape_ChestTrigger")')
    lines.append('')
    lines.append('[node name="ChestVisual" type="Sprite3D" parent="Interactables/Chest"]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)')
    lines.append('billboard = 1')
    lines.append('pixel_size = 0.013')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("7_chest_tex")')
    lines.append('')

    # 3. Exit Gate (Upright large iron portcullis)
    lines.append('[node name="MazeExit" type="Area3D" parent="Interactables"]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {exit_x}, {entities["exit_gate"]["y"]}, {exit_z})')
    lines.append('')
    lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/MazeExit"]')
    lines.append('shape = SubResource("Shape_ExitTrigger")')
    lines.append('')
    lines.append('[node name="GateVisual" type="Sprite3D" parent="Interactables/MazeExit"]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, 0)')
    lines.append('pixel_size = 0.016')
    lines.append('texture_filter = 0')
    lines.append('texture = ExtResource("8_gate_tex")')
    lines.append('')
    lines.append('[node name="Prompt" type="Label3D" parent="Interactables/MazeExit"]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0.5)')
    lines.append('billboard = 1')
    lines.append('text = "[E] Unlock Exit Gate"')
    lines.append('font_size = 26')
    lines.append('outline_size = 5')
    lines.append('')

    # 4. Mouse Tunnels (Tunnel A & Tunnel B)
    lines.append('[node name="MouseTunnels" type="Node3D" parent="."]')
    lines.append('')
    lines.append('[node name="BlackTunnel_A" parent="MouseTunnels" instance=ExtResource("9_tunnel_scene")]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {ta_x}, {entities["tunnel_a"]["y"]}, {ta_z})')
    lines.append('tunnel_id = "BlackTunnel_A"')
    lines.append('destination_id = "BlackTunnel_B"')
    lines.append('emergence_offset = Vector3(0, 0, 1.2)')
    lines.append('')
    lines.append('[node name="BlackTunnel_B" parent="MouseTunnels" instance=ExtResource("9_tunnel_scene")]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {tb_x}, {entities["tunnel_b"]["y"]}, {tb_z})')
    lines.append('tunnel_id = "BlackTunnel_B"')
    lines.append('destination_id = "BlackTunnel_A"')
    lines.append('emergence_offset = Vector3(0, 0, 1.2)')
    lines.append('')

    # Player Spawn Marker
    lines.append('[node name="PlayerSpawn" type="Marker3D" parent="."]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {sp_x}, {entities["player_spawn"]["y"]}, {sp_z})')
    lines.append('')

    # Player Instance
    lines.append('[node name="Player" parent="." groups=["player"] instance=ExtResource("4_player")]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {sp_x}, {entities["player_spawn"]["y"]}, {sp_z})')
    lines.append('')

    # Camera Rig Instance
    lines.append('[node name="CameraRig" parent="." instance=ExtResource("5_camera")]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {sp_x}, {entities["player_spawn"]["y"]}, {sp_z})')
    lines.append('')

    # HUD CanvasLayer
    lines.append('[node name="MazeHUD" type="CanvasLayer" parent="."]')
    lines.append('')
    lines.append('[node name="Margin" type="MarginContainer" parent="MazeHUD"]')
    lines.append('anchors_preset = 15')
    lines.append('anchor_right = 1.0')
    lines.append('anchor_bottom = 1.0')
    lines.append('grow_horizontal = 2')
    lines.append('grow_vertical = 2')
    lines.append('theme_override_constants/margin_left = 24')
    lines.append('theme_override_constants/margin_top = 18')
    lines.append('theme_override_constants/margin_right = 24')
    lines.append('theme_override_constants/margin_bottom = 18')
    lines.append('')
    lines.append('[node name="VBox" type="VBoxContainer" parent="MazeHUD/Margin"]')
    lines.append('layout_mode = 2')
    lines.append('size_flags_vertical = 0')
    lines.append('')
    lines.append('[node name="TopBar" type="HBoxContainer" parent="MazeHUD/Margin/VBox"]')
    lines.append('layout_mode = 2')
    lines.append('')
    lines.append('[node name="FormBadge" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
    lines.append('layout_mode = 2')
    lines.append('theme_override_colors/font_color = Color(1, 0.85, 0.3, 1)')
    lines.append('theme_override_font_sizes/font_size = 18')
    lines.append('text = "FORM: MUSHIKA"')
    lines.append('')
    lines.append('[node name="Spacer1" type="Control" parent="MazeHUD/Margin/VBox/TopBar"]')
    lines.append('layout_mode = 2')
    lines.append('size_flags_horizontal = 3')
    lines.append('')
    lines.append('[node name="ObjectiveLabel" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
    lines.append('layout_mode = 2')
    lines.append('theme_override_colors/font_color = Color(0.9, 0.85, 0.95, 1)')
    lines.append('theme_override_font_sizes/font_size = 16')
    lines.append('text = "Objective: Search the fortress labyrinth for the Golden Key"')
    lines.append('')
    lines.append('[node name="Spacer2" type="Control" parent="MazeHUD/Margin/VBox/TopBar"]')
    lines.append('layout_mode = 2')
    lines.append('size_flags_horizontal = 3')
    lines.append('')
    lines.append('[node name="KeyTracker" type="Label" parent="MazeHUD/Margin/VBox/TopBar"]')
    lines.append('layout_mode = 2')
    lines.append('theme_override_colors/font_color = Color(1, 0.8, 0.2, 1)')
    lines.append('theme_override_font_sizes/font_size = 18')
    lines.append('text = "Keys: 0 / 1"')
    lines.append('')
    lines.append('[node name="MessageBanner" type="Label" parent="MazeHUD/Margin"]')
    lines.append('layout_mode = 2')
    lines.append('size_flags_horizontal = 4')
    lines.append('size_flags_vertical = 8')
    lines.append('theme_override_colors/font_color = Color(1, 0.95, 0.85, 1)')
    lines.append('theme_override_font_sizes/font_size = 20')
    lines.append('horizontal_alignment = 1')
    lines.append('vertical_alignment = 1')
    lines.append('')

    out_scene_path = 'scenes/levels/maze/maze.tscn'
    with open(out_scene_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"[SUCCESS] Successfully generated true 2.5D level: {out_scene_path}!")
    print(f"  Solid 3D Wall Boxes: {len(wall_boxes)}")
    print(f"  Torches / Braziers: {len(torches)}")
    print(f"  Player Spawn: ({sp_x}, {sp_z})")
    print(f"  Golden Key: ({key_x}, {key_z})")
    print(f"  Exit Gate: ({exit_x}, {exit_z})")
    print(f"  Chest: ({chest_x}, {chest_z})")
    print(f"  Tunnels: A=({ta_x}, {ta_z}), B=({tb_x}, {tb_z})")

if __name__ == '__main__':
    build_25d_maze()
