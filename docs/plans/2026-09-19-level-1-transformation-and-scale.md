# Level 1 Transformation, Mouse Sprite & Lower Level Scale Implementation Plan

**Goal:** Fix player transformation and mouse sprite floor clipping in Level 1 Upper, and increase the overall size / scale of Level 1 Lower (Underground Maze) to 1.25x with matching camera view, camera boundary clamps, collision geometry, and exit triggers.
**Architecture:**
- Correct mouse capsule offset and sprite vertical positioning in `scripts/player/player.gd` to completely prevent floor clipping.
- Lock player movement state throughout the cutscene sequence in `scripts/world/l1_controller.gd`.
- Scale all geometry, interactables, lights, camera clamp bounds, and exit walk-through triggers of `scenes/levels/maze/maze.tscn` and `scripts/world/maze_controller.gd` by 1.25x.
**Tech Stack:** Godot 4 (GDScript, 3D Engine, Collision Shapes, AnimatedSprite3D, Orthogonal Camera3D).

---

## File Map
- MODIFY: `docs/plans/2026-09-19-level-1-transformation-and-scale.md` — Implementation plan document
- MODIFY: `scripts/player/player.gd` — Correct mouse capsule origin (`col.position = Vector3(0, 0.225, 0)` for `height = 0.45`), `anim_sprite.position = Vector3(0, 0.86, 0)`, and transformation sprite properties
- MODIFY: `scripts/world/l1_controller.gd` — Lock `current_form` until cutscene ends, update camera zoom tween, and dynamic prompt for mouse passage
- MODIFY: `scripts/world/maze_controller.gd` — Scale camera clamp boundaries (`[-3.75, 3.75]`, `[-3.25, 3.25]`), scale exit gate walk-through trigger coordinates (`X = 9.0875`, `Z < -5.6`), adjust top-down sprite properties
- MODIFY: `scenes/levels/maze/maze.tscn` — Scale maze map visual, floor, 103 wall colliders, torches, key, chest, exit, and tunnels by 1.25x
- MODIFY: `scripts/generate_maze_scene.py` — Generator script with `SCALE = 1.25`
- MODIFY: `scripts/test_maze_walk.gd` — Scaled verification coordinates for automated test suite

---

## Tasks

### Task 1: Fix Transformation & Mouse Sprite Ground Alignment in `scripts/player/player.gd`
- In `transform_to_mouse()`:
  - Fix capsule shape vertical offset: `col.position = Vector3(0, 0.225, 0)` for `height = 0.45`. This aligns the capsule bottom exactly with the local ground at $Y = 0.0$, preventing the player body from sinking $2.5\text{ cm}$ underground.
  - Set `anim_sprite.position = Vector3(0, 0.86, 0)` with `pixel_size = 0.011`.
    Canvas height is $180\text{ px}$, center is $Y = 90$, feet are at $Y = 165$ ($75\text{ px}$ below center).
    Feet offset: $75 \times 0.011 = 0.825$.
    Feet world height: $0.86 - 0.825 = +0.035\text{ m}$.
    Floor visual (`DungeonVisual`) sits at $Y = 0.01\text{ m}$ and DropShadow sits at $Y = 0.02\text{ m}$. The feet sit $0.025\text{ m}$ above the floor plane, eliminating horizontal floor clipping.
  - Maintain `anim_sprite.sorting_offset = 2.0`, `anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y`, and `anim_sprite.no_depth_test = false`.
- In `start_transformation()`:
  - Set `anim_sprite.pixel_size = 0.007`.
  - Center is $Y = 200$, ground line is $Y = 380$ ($180\text{ px}$ below center).
  - Offset: $180 \times 0.007 = 1.26$.
  - Set `anim_sprite.position = Vector3(0, 1.29, 0)`, placing the base at $1.29 - 1.26 = 0.03\text{ m}$.
- In `transform_to_human()`:
  - Reset `anim_sprite.position = Vector3(0, 0.72, 0)`, `pixel_size = 0.0125`, `col.position = Vector3(0, 0.7, 0)`, `col.shape.height = 1.4`.

### Task 2: Enhance Cutscene Lock & Interaction in `scripts/world/l1_controller.gd`
- In `_start_transformation_cutscene()`:
  - Maintain `player.current_form = player.PlayerForm.TRANSFORMING` through $t = 2.5\text{ s}$ until $t = 3.8\text{ s}$ when dialogue concludes to prevent premature movement during dialogue lines.
  - Smooth camera size tween: from $9.2$ to $7.8$ during mouse transformation.
- In `_start_revert_cutscene()`:
  - Maintain `TRANSFORMING` form until $t = 0.7\text{ s}$ when full revert finishes.
  - Smooth camera size tween: from $7.8$ back to $9.2$.
- In `_on_mouse_passage_entered()`:
  - Dynamically display `[E] Enter Mouse Passage` if in mouse form, or `[E] Inspect Mouse Passage` if in human form.

### Task 3: Increase Overall Size & Scale of Level 1 Lower in `scenes/levels/maze/maze.tscn` and `scripts/generate_maze_scene.py`
- Apply 1.25x scaling across:
  - `DungeonVisual`: Scale (1.25, 1.25, 1.25)
  - `FloorGround`: Shape size (30.0, 1.0, 20.0)
  - All 103 wall colliders (`Wall_0` to `Wall_102`): position $x \times 1.25, z \times 1.25$, shape $sx \times 1.25, sz \times 1.25$
  - Torches: position $x \times 1.25, z \times 1.25$, range $4.0$
  - Interactables:
    - GoldenKey: $(2.1875, 0.2, -4.275)$
    - Chest: $(7.6875, 0.2, 3.0875)$
    - MazeExit: $(9.0875, 0.2, -5.8125)$
  - Tunnels:
    - BlackTunnel_A: $(-10.2, 0.05, 2.5)$
    - BlackTunnel_B: $(5.625, 0.05, 2.5)$
  - PlayerSpawn & Player & CameraRig: $(-10.2, 0.1, 6.125)$
- Update `scripts/generate_maze_scene.py` with `SCALE = 1.25`.

### Task 4: Fix Camera Clamping & Exit Trigger in `scripts/world/maze_controller.gd`
- Update camera clamp boundaries in `_process()`:
  - $X$: `[-3.75, 3.75]` (scaled from $[-3.0, 3.0]$ by $1.25$)
  - $Z$: `[-3.25, 3.25]` (scaled from $[-2.6, 2.6]$ by $1.25$)
- Fix exit gate walk-through trigger:
  - Update `player.global_position.z < -5.6 and absf(player.global_position.x - 9.0875) < 1.2` (scaled from $Z < -4.7, X = 7.27$).
- Ensure `cam.size = 9.2` and `rig.target_offset = Vector3(0, 14.0, 0)`.

### Task 5: Verification & Edge Case Testing
- Verify Level 1 Upper transformation sequence, mouse idle, walk, and passage entry.
- Verify Level 1 Lower underground maze scale, walls, key pickup, chest, and exit gate transition.
