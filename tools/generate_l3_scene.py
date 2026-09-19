# Generates scenes/levels/l3/l3_map.tscn matching media_1789770005271.jpg
import os

tscn_content = """[gd_scene load_steps=58 format=3]

[ext_resource type="Script" path="res://scripts/world/l3_controller.gd" id="1_controller"]
[ext_resource type="Texture2D" path="res://scenes/levels/l3/3rdlvl-bg.png" id="2_bg_texture"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="3_player"]
[ext_resource type="PackedScene" path="res://scenes/world/camera_rig.tscn" id="4_camera"]
[ext_resource type="Texture2D" path="res://assets/environment/stone_floor_tile.png" id="5_stone_tile"]
[ext_resource type="Texture2D" path="res://assets/environment/castle_brick_tile.png" id="6_brick_tile"]
[ext_resource type="Texture2D" path="res://assets/character/drop_shadow.png" id="7_shadow"]
[ext_resource type="Texture2D" path="res://assets/vfx/golden_om.png" id="8_om"]
[ext_resource type="Texture2D" path="res://assets/vfx/golden_lotus.png" id="9_lotus"]
[ext_resource type="Texture2D" path="res://assets/vfx/divine_flash.png" id="10_flash"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/tile_floor_grid_clean.png" id="11_floor_tile"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/carpet_runner_sigil.png" id="12_carpet_sigil"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/carpet_runner_plain.png" id="13_carpet_plain"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/mandala_rug_round.png" id="14_mandala"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_tall_banner_left.png" id="15_pillar_tall_banner_left"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_tall_banner_right.png" id="16_pillar_tall_banner_right"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_tall_left.png" id="17_pillar_tall_left"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_tall_right.png" id="18_pillar_tall_right"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_medium_left.png" id="19_pillar_medium_left"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/pillar_medium_right.png" id="20_pillar_medium_right"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/broken_pillar_left_1.png" id="21_broken_pillar_left_1"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/broken_pillar_stub.png" id="22_broken_pillar_stub"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/broken_pillar_tall_rubble.png" id="23_broken_tall_rubble"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/broken_pillar_right_rubble.png" id="24_broken_right_rubble"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/broken_pillar_stub_right.png" id="25_broken_stub_right"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/brazier_square_fire.png" id="26_brazier_square"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/brazier_round_fire_1.png" id="27_brazier_round_1"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/brazier_round_fire_2.png" id="28_brazier_round_2"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/wall_torch_flame_1.png" id="29_wall_torch"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_double.png" id="30_cover_double"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_rubble.png" id="31_cover_rubble"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_stepped_1.png" id="32_cover_stepped"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_quad.png" id="33_cover_quad"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_tri.png" id="34_cover_tri"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/cover_blocks_high.png" id="35_cover_high"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/rock_boulder_large.png" id="36_rock_boulder"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/rock_medium_1.png" id="37_rock_medium"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/rock_tall_jagged.png" id="38_rock_tall"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/rock_cluster_1.png" id="39_rock_cluster_1"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/rock_cluster_2.png" id="40_rock_cluster_2"]

[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/plant_grass_tuft_1.png" id="41_grass_1"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/plant_grass_tuft_2.png" id="42_grass_2"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/stairs_4step.png" id="43_stairs_4step"]
[ext_resource type="Texture2D" path="res://assets/environment/l3_3d/banner_tall_sigil.png" id="44_banner_tall"]

[sub_resource type="Environment" id="Environment_castle"]
background_mode = 1
background_color = Color(0.025, 0.015, 0.035, 1)
ambient_light_source = 2
ambient_light_color = Color(0.24, 0.18, 0.32, 1)
ambient_light_energy = 0.65
tonemap_mode = 2
glow_enabled = true
glow_intensity = 0.65
glow_bloom = 0.18

[sub_resource type="StandardMaterial3D" id="Mat_ReflectiveFloor"]
albedo_color = Color(0.32, 0.28, 0.38, 1)
albedo_texture = ExtResource("11_floor_tile")
roughness = 0.28
metallic = 0.2
uv1_scale = Vector3(22, 24, 22)
uv1_triplanar = true
texture_filter = 0

[sub_resource type="StandardMaterial3D" id="Mat_TempleStone"]
albedo_color = Color(0.52, 0.46, 0.6, 1)
albedo_texture = ExtResource("5_stone_tile")
roughness = 0.65
metallic = 0.1
uv1_scale = Vector3(2, 2, 2)
uv1_triplanar = true
texture_filter = 0

[sub_resource type="StandardMaterial3D" id="Mat_DaisTrim"]
albedo_color = Color(0.68, 0.58, 0.42, 1)
albedo_texture = ExtResource("5_stone_tile")
roughness = 0.45
metallic = 0.25
uv1_scale = Vector3(2, 2, 2)
uv1_triplanar = true
texture_filter = 0

[sub_resource type="BoxShape3D" id="Shape_Floor"]
size = Vector3(26, 1, 26)

[sub_resource type="BoxShape3D" id="Shape_WallNorth"]
size = Vector3(24, 6, 1)

[sub_resource type="BoxShape3D" id="Shape_WallSide"]
size = Vector3(1, 6, 22)

[sub_resource type="BoxShape3D" id="Shape_WallSouthWing"]
size = Vector3(9, 6, 1)

[sub_resource type="BoxShape3D" id="Shape_Dais"]
size = Vector3(7.4, 0.9, 3.2)

[sub_resource type="BoxShape3D" id="Shape_PlinthLarge"]
size = Vector3(1.5, 0.6, 1.5)

[sub_resource type="BoxShape3D" id="Shape_PlinthMedium"]
size = Vector3(1.3, 0.5, 1.3)

[sub_resource type="BoxShape3D" id="Shape_PlinthBrazier"]
size = Vector3(0.65, 0.55, 0.65)

[sub_resource type="CylinderShape3D" id="Shape_PillarCol"]
height = 4.8
radius = 0.65

[sub_resource type="BoxShape3D" id="Shape_CoverBlock"]
size = Vector3(1.2, 0.8, 0.8)

[sub_resource type="SphereShape3D" id="Shape_Rock"]
radius = 0.45

[sub_resource type="StyleBoxFlat" id="StyleBox_Dialogue"]
bg_color = Color(0.08, 0.06, 0.12, 0.95)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 3
border_color = Color(0.92, 0.76, 0.32, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
shadow_color = Color(0, 0, 0, 0.65)
shadow_size = 5

[node name="L3Map" type="Node3D"]
script = ExtResource("1_controller")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_castle")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.965926, -0.0647048, 0.25, 0, 0.965926, 0.258819, -0.258819, -0.25, 0.933013, 0, 15, -4)
light_color = Color(0.7, 0.75, 0.9, 1)
light_energy = 0.3
shadow_enabled = true

[node name="SanctumBackdrop" type="Sprite3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.25, -10)
pixel_size = 0.0145
texture_filter = 0
sorting_offset = -15.0
double_sided = true
texture = ExtResource("2_bg_texture")

[node name="FloorGround" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="FloorGround"]
shape = SubResource("Shape_Floor")

[node name="FloorMesh" type="CSGBox3D" parent="FloorGround"]
size = Vector3(26, 1, 26)
material = SubResource("Mat_ReflectiveFloor")

[node name="Boundaries" type="Node3D" parent="."]

[node name="WallNorth" type="StaticBody3D" parent="Boundaries"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, -10.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Boundaries/WallNorth"]
shape = SubResource("Shape_WallNorth")

[node name="WallWest" type="StaticBody3D" parent="Boundaries"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -8.2, 3, 0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Boundaries/WallWest"]
shape = SubResource("Shape_WallSide")

[node name="WallEast" type="StaticBody3D" parent="Boundaries"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8.2, 3, 0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Boundaries/WallEast"]
shape = SubResource("Shape_WallSide")

[node name="WallSouthLeft" type="StaticBody3D" parent="Boundaries"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6.5, 3, 8.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Boundaries/WallSouthLeft"]
shape = SubResource("Shape_WallSouthWing")

[node name="WallSouthRight" type="StaticBody3D" parent="Boundaries"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6.5, 3, 8.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Boundaries/WallSouthRight"]
shape = SubResource("Shape_WallSouthWing")

[node name="Visuals3D" type="Node3D" parent="."]

[node name="FloorMarkings" type="Node3D" parent="Visuals3D"]

[node name="CarpetRunnerSouth" type="Sprite3D" parent="Visuals3D/FloorMarkings"]
transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.012, 5.2)
pixel_size = 0.022
texture_filter = 0
sorting_offset = -8.0
texture = ExtResource("12_carpet_sigil")

[node name="CarpetRunnerMidSouth" type="Sprite3D" parent="Visuals3D/FloorMarkings"]
transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.012, 2.6)
pixel_size = 0.022
texture_filter = 0
sorting_offset = -8.0
texture = ExtResource("13_carpet_plain")

[node name="MandalaRug" type="Sprite3D" parent="Visuals3D/FloorMarkings"]
transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.015, -0.2)
pixel_size = 0.024
texture_filter = 0
sorting_offset = -7.5
texture = ExtResource("14_mandala")

[node name="CarpetRunnerMidNorth" type="Sprite3D" parent="Visuals3D/FloorMarkings"]
transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.012, -3)
pixel_size = 0.022
texture_filter = 0
sorting_offset = -8.0
texture = ExtResource("13_carpet_plain")

[node name="CarpetRunnerNorthAltar" type="Sprite3D" parent="Visuals3D/FloorMarkings"]
transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0.012, -5.2)
pixel_size = 0.02
texture_filter = 0
sorting_offset = -8.0
texture = ExtResource("12_carpet_sigil")

[node name="AltarDais" type="Node3D" parent="Visuals3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.45, -7.5)

[node name="DaisBody" type="StaticBody3D" parent="Visuals3D/AltarDais"]

[node name="CollisionShape3D" type="CollisionShape3D" parent="Visuals3D/AltarDais/DaisBody"]
shape = SubResource("Shape_Dais")

[node name="DaisMesh" type="CSGBox3D" parent="Visuals3D/AltarDais/DaisBody"]
size = Vector3(7.4, 0.9, 3.2)
material = SubResource("Mat_TempleStone")

[node name="DaisStep1" type="CSGBox3D" parent="Visuals3D/AltarDais/DaisBody"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.3, 1.8)
size = Vector3(4.6, 0.3, 0.8)
material = SubResource("Mat_DaisTrim")

[node name="DaisStep2" type="CSGBox3D" parent="Visuals3D/AltarDais/DaisBody"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.15, 1.3)
size = Vector3(4.0, 0.3, 0.6)
material = SubResource("Mat_DaisTrim")

[node name="StairsVisual" type="Sprite3D" parent="Visuals3D/AltarDais"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.05, 1.7)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("43_stairs_4step")

[node name="MurtiAura" type="Sprite3D" parent="Visuals3D/AltarDais"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, -0.6)
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("9_lotus")
modulate = Color(1, 0.9, 0.4, 0.5)

[node name="DaisBrazierL" type="StaticBody3D" parent="Visuals3D/AltarDais"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.8, 0, 1.2)

[node name="Plinth" type="CSGBox3D" parent="Visuals3D/AltarDais/DaisBrazierL"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
size = Vector3(0.7, 0.6, 0.7)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="Visuals3D/AltarDais/DaisBrazierL"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="Visuals3D/AltarDais/DaisBrazierL"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
light_color = Color(1, 0.7, 0.25, 1)
light_energy = 2.6
omni_range = 8.0
shadow_enabled = true

[node name="DaisBrazierR" type="StaticBody3D" parent="Visuals3D/AltarDais"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2.8, 0, 1.2)

[node name="Plinth" type="CSGBox3D" parent="Visuals3D/AltarDais/DaisBrazierR"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
size = Vector3(0.7, 0.6, 0.7)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="Visuals3D/AltarDais/DaisBrazierR"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="Visuals3D/AltarDais/DaisBrazierR"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
light_color = Color(1, 0.7, 0.25, 1)
light_energy = 2.6
omni_range = 8.0
shadow_enabled = true

[node name="ArenaProps" type="Node3D" parent="."]

[node name="Pillars" type="Node3D" parent="ArenaProps"]

[node name="Col1_L" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 0, 5.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
size = Vector3(1.5, 0.6, 1.5)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
pixel_size = 0.02
texture_filter = 0
texture = ExtResource("15_pillar_tall_banner_left")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1.5, 0, 0, 0, 0, 1.5, 0, -1.5, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.2, 0, -0.4)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col1_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.5
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col1_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.2, 0, 1.0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col1_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("30_cover_double")

[node name="Col1_R" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.5, 0, 5.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
size = Vector3(1.5, 0.6, 1.5)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
pixel_size = 0.02
texture_filter = 0
texture = ExtResource("16_pillar_tall_banner_right")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1.5, 0, 0, 0, 0, 1.5, 0, -1.5, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.2, 0, -0.4)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col1_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.5
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col1_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.2, 0, 1.0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col1_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col1_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col1_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("30_cover_double")

[node name="Col2_L" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 0, 2.4)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
shape = SubResource("Shape_PlinthMedium")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("21_broken_pillar_left_1")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.2, 0, -0.4)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("27_brazier_round_1")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col2_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.3, 0, 0.9)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col2_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("31_cover_rubble")

[node name="Grass" type="Sprite3D" parent="ArenaProps/Pillars/Col2_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.8, 0.25, 0.2)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("41_grass_1")

[node name="Col2_R" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.5, 0, 2.4)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
shape = SubResource("Shape_PlinthMedium")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("24_broken_right_rubble")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.2, 0, -0.4)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("27_brazier_round_1")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col2_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.3, 0, 0.9)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col2_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col2_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col2_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("32_cover_stepped")

[node name="Grass" type="Sprite3D" parent="ArenaProps/Pillars/Col2_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.8, 0.25, 0.2)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("42_grass_2")

[node name="Col3_L" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 0, -0.4)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
shape = SubResource("Shape_PlinthMedium")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("23_broken_tall_rubble")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.2, 0, -0.3)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col3_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col3_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.2, 0, 0.9)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col3_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("33_cover_quad")

[node name="Col3_R" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.5, 0, -0.4)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
shape = SubResource("Shape_PlinthMedium")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("25_broken_stub_right")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.2, 0, -0.3)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("26_brazier_square")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col3_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col3_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.2, 0, 0.9)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col3_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col3_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col3_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("34_cover_tri")

[node name="Col4_L" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 0, -3.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
size = Vector3(1.5, 0.6, 1.5)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
pixel_size = 0.02
texture_filter = 0
texture = ExtResource("17_pillar_tall_left")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1.5, 0, 0, 0, 0, 1.5, 0, -1.5, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.2, 0, -0.3)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("28_brazier_round_2")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col4_L/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col4_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.2, 0, 0.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col4_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_L/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("35_cover_high")

[node name="Col4_R" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.5, 0, -3.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
size = Vector3(1.5, 0.6, 1.5)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.4, 0)
pixel_size = 0.02
texture_filter = 0
texture = ExtResource("18_pillar_tall_right")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1.5, 0, 0, 0, 0, 1.5, 0, -1.5, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Brazier" type="StaticBody3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.2, 0, -0.3)

[node name="Plinth" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.275, 0)
size = Vector3(0.65, 0.55, 0.65)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("28_brazier_round_2")

[node name="Light" type="OmniLight3D" parent="ArenaProps/Pillars/Col4_R/Brazier"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
light_color = Color(1, 0.65, 0.2, 1)
light_energy = 2.4
omni_range = 7.5
shadow_enabled = true

[node name="CoverBlock" type="StaticBody3D" parent="ArenaProps/Pillars/Col4_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.2, 0, 0.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col4_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Mesh3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col4_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)
size = Vector3(1.2, 0.8, 0.8)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col4_R/CoverBlock"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
pixel_size = 0.014
texture_filter = 0
texture = ExtResource("35_cover_high")

[node name="Col5_L" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 0, -5.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col5_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col5_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col5_L"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)
pixel_size = 0.019
texture_filter = 0
texture = ExtResource("19_pillar_medium_left")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col5_L"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="Col5_R" type="StaticBody3D" parent="ArenaProps/Pillars"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.5, 0, -5.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/Pillars/Col5_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)
shape = SubResource("Shape_PillarCol")

[node name="Plinth3D" type="CSGBox3D" parent="ArenaProps/Pillars/Col5_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 0)
size = Vector3(1.3, 0.5, 1.3)
material = SubResource("Mat_TempleStone")

[node name="Visual" type="Sprite3D" parent="ArenaProps/Pillars/Col5_R"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)
pixel_size = 0.019
texture_filter = 0
texture = ExtResource("20_pillar_medium_right")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/Pillars/Col5_R"]
transform = Transform3D(1.4, 0, 0, 0, 0, 1.4, 0, -1.4, 0, 0, 0.02, 0)
pixel_size = 0.01
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="WallBanners" type="Node3D" parent="ArenaProps"]

[node name="BannerWL" type="Sprite3D" parent="ArenaProps/WallBanners"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.8, 3.2, 5.0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("44_banner_tall")

[node name="BannerWR" type="Sprite3D" parent="ArenaProps/WallBanners"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5.8, 3.2, 5.0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("44_banner_tall")

[node name="BannerMidL" type="Sprite3D" parent="ArenaProps/WallBanners"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.8, 3.2, -1.0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("44_banner_tall")

[node name="BannerMidR" type="Sprite3D" parent="ArenaProps/WallBanners"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5.8, 3.2, -1.0)
pixel_size = 0.018
texture_filter = 0
texture = ExtResource("44_banner_tall")

[node name="MovableRocks" type="Node3D" parent="ArenaProps"]

[node name="Rock1" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.4, 0.4, 3.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock1"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock1"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("36_rock_boulder")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock1"]
transform = Transform3D(1.1, 0, 0, 0, 0, 1.1, 0, -1.1, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock1"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock1/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock1"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock1"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Rock2" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2.4, 0.4, 3.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock2"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock2"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("36_rock_boulder")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock2"]
transform = Transform3D(1.0, 0, 0, 0, 0, 1.0, 0, -1.0, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock2"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock2/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock2"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Rock3" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.4, 0.4, 0.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock3"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock3"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("37_rock_medium")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock3"]
transform = Transform3D(1.0, 0, 0, 0, 0, 1.0, 0, -1.0, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock3"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock3/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock3"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock3"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Rock4" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2.4, 0.4, 0.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock4"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock4"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("37_rock_medium")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock4"]
transform = Transform3D(1.0, 0, 0, 0, 0, 1.0, 0, -1.0, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock4"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock4/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock4"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock4"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Rock5" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.2, 0.4, -2.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock5"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock5"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("38_rock_tall")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock5"]
transform = Transform3D(1.0, 0, 0, 0, 0, 1.0, 0, -1.0, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock5"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock5/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock5"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock5"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Rock6" type="StaticBody3D" parent="ArenaProps/MovableRocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2.2, 0.4, -2.2)

[node name="CollisionShape3D" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock6"]
shape = SubResource("Shape_Rock")

[node name="Visual" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock6"]
pixel_size = 0.012
billboard = 2
texture_filter = 0
texture = ExtResource("38_rock_tall")

[node name="Shadow" type="Sprite3D" parent="ArenaProps/MovableRocks/Rock6"]
transform = Transform3D(1.0, 0, 0, 0, 0, 1.0, 0, -1.0, 0, 0, -0.38, 0)
pixel_size = 0.009
texture_filter = 0
texture = ExtResource("7_shadow")

[node name="InteractArea" type="Area3D" parent="ArenaProps/MovableRocks/Rock6"]

[node name="Col" type="CollisionShape3D" parent="ArenaProps/MovableRocks/Rock6/InteractArea"]
shape = SubResource("Shape_Rock")

[node name="Prompt" type="Label3D" parent="ArenaProps/MovableRocks/Rock6"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, 0)
visible = false
billboard = 1
text = "[E] Grab Rock"
font_size = 22
outline_size = 4

[node name="ImpactDust" type="CPUParticles3D" parent="ArenaProps/MovableRocks/Rock6"]
emitting = false
one_shot = true
explosiveness = 0.8
amount = 18
lifetime = 0.6
direction = Vector3(0, 1, 0)
spread = 60.0
initial_velocity_min = 1.0
initial_velocity_max = 2.5
color = Color(0.7, 0.6, 0.5, 0.8)

[node name="Lights" type="Node3D" parent="."]

[node name="DivineMurtiLight" type="OmniLight3D" parent="Lights"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.6, -8.0)
light_color = Color(1, 0.82, 0.45, 1)
light_energy = 3.4
omni_range = 11.0
shadow_enabled = true

[node name="HallTorchL1" type="OmniLight3D" parent="Lights"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.2, 2.5, 5.0)
light_color = Color(1, 0.62, 0.2, 1)
light_energy = 2.2
omni_range = 7.0

[node name="HallTorchR1" type="OmniLight3D" parent="Lights"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5.2, 2.5, 5.0)
light_color = Color(1, 0.62, 0.2, 1)
light_energy = 2.2
omni_range = 7.0

[node name="HallTorchL2" type="OmniLight3D" parent="Lights"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.2, 2.5, -1.0)
light_color = Color(1, 0.62, 0.2, 1)
light_energy = 2.2
omni_range = 7.0

[node name="HallTorchR2" type="OmniLight3D" parent="Lights"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5.2, 2.5, -1.0)
light_color = Color(1, 0.62, 0.2, 1)
light_energy = 2.2
omni_range = 7.0

[node name="Decorations" type="Node3D" parent="."]

[node name="Torches" type="Node3D" parent="Decorations"]

[node name="WallTorchL1" type="Sprite3D" parent="Decorations/Torches"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -7.6, 2.8, 4.2)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("29_wall_torch")

[node name="WallTorchR1" type="Sprite3D" parent="Decorations/Torches"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 7.6, 2.8, 4.2)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("29_wall_torch")

[node name="WallTorchL2" type="Sprite3D" parent="Decorations/Torches"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -7.6, 2.8, -1.5)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("29_wall_torch")

[node name="WallTorchR2" type="Sprite3D" parent="Decorations/Torches"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 7.6, 2.8, -1.5)
pixel_size = 0.016
texture_filter = 0
texture = ExtResource("29_wall_torch")

[node name="Interactables" type="Node3D" parent="."]

[node name="AltarBlessing" type="Area3D" parent="Interactables"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, -5.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/AltarBlessing"]
shape = SubResource("Shape_Dais")

[node name="Prompt" type="Label3D" parent="Interactables/AltarBlessing"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.2, 0)
visible = false
billboard = 1
text = "[E] Pray at Sacred Murti - Reclaim Blessing"
font_size = 28
outline_size = 5

[node name="SouthExit" type="Area3D" parent="Interactables"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 7.8)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/SouthExit"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
shape = SubResource("Shape_CoverBlock")

[node name="Prompt" type="Label3D" parent="Interactables/SouthExit"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)
visible = false
billboard = 1
text = "[E] Return to Castle Exterior"
font_size = 26
outline_size = 5

[node name="BossArenaTrigger" type="Area3D" parent="Interactables"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 1.5)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Interactables/BossArenaTrigger"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
shape = SubResource("Shape_WallNorth")

[node name="VFX" type="Node3D" parent="."]

[node name="DivineMurtiParticles" type="CPUParticles3D" parent="VFX"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.5, -8.2)
amount = 40
lifetime = 2.5
emission_shape = 2
emission_box_extents = Vector3(2.5, 2.0, 1.0)
direction = Vector3(0, 1, 0)
spread = 35.0
gravity = Vector3(0, 0.2, 0)
initial_velocity_min = 0.4
initial_velocity_max = 1.0
scale_amount_min = 0.08
scale_amount_max = 0.22
color = Color(1, 0.9, 0.45, 0.85)

[node name="AsurAuraParticles" type="CPUParticles3D" parent="VFX"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)
emitting = false
amount = 30
lifetime = 2.0
emission_shape = 1
emission_sphere_radius = 4.0
gravity = Vector3(0, 0.5, 0)
color = Color(0.65, 0.15, 0.15, 0.6)

[node name="BlessingVFX" type="Node3D" parent="VFX"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.5, -6.5)

[node name="OmSprite" type="Sprite3D" parent="VFX/BlessingVFX"]
visible = false
pixel_size = 0.012
billboard = 1
texture_filter = 0
texture = ExtResource("8_om")

[node name="LotusSprite" type="Sprite3D" parent="VFX/BlessingVFX"]
visible = false
pixel_size = 0.012
billboard = 1
texture_filter = 0
texture = ExtResource("9_lotus")

[node name="DivineFlash" type="Sprite3D" parent="VFX/BlessingVFX"]
visible = false
pixel_size = 0.03
billboard = 1
texture_filter = 0
texture = ExtResource("10_flash")

[node name="BlessingParticles" type="CPUParticles3D" parent="VFX/BlessingVFX"]
emitting = false
one_shot = true
explosiveness = 0.9
amount = 60
lifetime = 1.8
direction = Vector3(0, 1, 0)
spread = 180.0
gravity = Vector3(0, -0.2, 0)
initial_velocity_min = 2.0
initial_velocity_max = 4.5
scale_amount_min = 0.15
scale_amount_max = 0.4
color = Color(1, 0.92, 0.5, 0.9)

[node name="UI" type="CanvasLayer" parent="."]

[node name="HUD" type="Control" parent="UI"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="TitleBanner" type="Label" parent="UI/HUD"]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -280.0
offset_top = 18.0
offset_right = 280.0
offset_bottom = 54.0
grow_horizontal = 2
theme_override_colors/font_color = Color(1, 0.88, 0.45, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.85)
theme_override_font_sizes/font_size = 24
text = "LEVEL 3: SANCTUM OF LORD GANESHA"
horizontal_alignment = 1

[node name="ObjectiveBanner" type="Label" parent="UI/HUD"]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -350.0
offset_top = 54.0
offset_right = 350.0
offset_bottom = 82.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0.9, 0.85, 0.7, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.8)
theme_override_font_sizes/font_size = 17
text = "Approach the Sacred Murti to Reclaim Lord Ganesha's Divine Blessing"
horizontal_alignment = 1

[node name="ActionPrompt" type="Label" parent="UI/HUD"]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -200.0
offset_top = -90.0
offset_right = 200.0
offset_bottom = -55.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(1, 0.95, 0.5, 1)
theme_override_font_sizes/font_size = 20
horizontal_alignment = 1

[node name="DialogueBox" type="PanelContainer" parent="UI/HUD"]
visible = false
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -380.0
offset_top = -175.0
offset_right = 380.0
offset_bottom = -50.0
grow_horizontal = 2
grow_vertical = 0
theme_override_styles/panel = SubResource("StyleBox_Dialogue")

[node name="Margin" type="MarginContainer" parent="UI/HUD/DialogueBox"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 15
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 15

[node name="DialogueLabel" type="Label" parent="UI/HUD/DialogueBox/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.92, 0.85, 1)
theme_override_font_sizes/font_size = 18
text = ""
autowrap_mode = 2

[node name="Player" parent="." instance=ExtResource("3_player")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 6.2)

[node name="CameraRig" parent="." instance=ExtResource("4_camera")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 6.2)
"""

with open('scenes/levels/l3/l3_map.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn_content)

print("Generated scenes/levels/l3/l3_map.tscn successfully")
