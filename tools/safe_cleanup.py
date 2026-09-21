import os
import shutil

PROJECT_DIR = r"d:\last-utsav-main"
ARCHIVE_DIR = os.path.join(PROJECT_DIR, "archive_unused")

os.makedirs(ARCHIVE_DIR, exist_ok=True)

searchable_exts = {".tscn", ".tres", ".gd", ".godot"}
code_files = []
for root, dirs, files in os.walk(PROJECT_DIR):
    if "\\.godot" in root or "\\builds" in root or "\\.git" in root or "\\archive_unused" in root:
        continue
    for f in files:
        if os.path.splitext(f)[1] in searchable_exts:
            code_files.append(os.path.join(root, f))

all_content = []
for p in code_files:
    try:
        with open(p, "r", encoding="utf-8", errors="ignore") as f:
            all_content.append((p, f.read()))
    except Exception:
        pass

def is_referenced(filepath):
    base = os.path.basename(filepath)
    # Check if basename appears anywhere in any scene, resource or code file
    for p, content in all_content:
        if p == filepath:
            continue
        if base in content:
            return True, p
    return False, None

# Specific scratch subdirectories in assets/temp
scratch_subdirs = [
    os.path.join(PROJECT_DIR, "assets", "temp", "extracted_throw"),
    os.path.join(PROJECT_DIR, "assets", "temp", "pasa_inspect"),
    os.path.join(PROJECT_DIR, "assets", "temp", "right_crops"),
    os.path.join(PROJECT_DIR, "assets", "temp", "squares"),
]

# Explicit backup / example files that are known scratch files
explicit_scratch_files = [
    os.path.join(PROJECT_DIR, "assets", "temp", "diff_tileset_vs_orig.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "transformation_mouse_preview.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walkable_clean.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walkable_gate_crop.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "wall_sample.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "wider_top_right.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_screen_region.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_view_after_cleanup.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_view_exact.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_view_wall_boxes_overlay.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_floor_tiles.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_wall_tiles.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_decorations.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "user_full_maze_example.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "sample_left.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "sample_right.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "pasa_left_thumb.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "pasa_right_thumb.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walk_up_area.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walk_up_region.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walk_up_strip.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "walk_up_transparency_check.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "tunnel_a_loc.png"),
    os.path.join(PROJECT_DIR, "assets", "temp", "tunnel_b_loc.png"),
    os.path.join(PROJECT_DIR, "assets", "environment", "l1_map_clean_backup.png"),
    os.path.join(PROJECT_DIR, "assets", "environment", "l1_map_clean_pre_pillar.png"),
    os.path.join(PROJECT_DIR, "assets", "environment", "maze", "maze_map_clean_pre_widen.png"),
    os.path.join(PROJECT_DIR, "assets", "l1 map before.png"),
    os.path.join(PROJECT_DIR, "assets", "l1 map after.png"),
    os.path.join(PROJECT_DIR, "assets", "map-example.png"),
    os.path.join(PROJECT_DIR, "scenes", "levels", "l3", "3rd-lvl-example.png"),
]

# Old 285MB web.zip in builds
old_zip = os.path.join(PROJECT_DIR, "builds", "web.zip")
if os.path.exists(old_zip):
    explicit_scratch_files.append(old_zip)

files_to_archive = []

# Process scratch subdirectories
for sdir in scratch_subdirs:
    if os.path.exists(sdir):
        for root, dirs, files in os.walk(sdir):
            for f in files:
                full_p = os.path.join(root, f)
                files_to_archive.append(full_p)

# Process explicit scratch files
for ef in explicit_scratch_files:
    if os.path.exists(ef):
        files_to_archive.append(ef)
        # Also include corresponding .import file if exists
        imp = ef + ".import"
        if os.path.exists(imp):
            files_to_archive.append(imp)

# Verify each file is NOT referenced
verified_to_archive = []
skipped_due_to_reference = []

for fpath in files_to_archive:
    if fpath.endswith(".import"):
        # Import files follow their main file
        base_asset = fpath[:-7]
        if base_asset in verified_to_archive:
            verified_to_archive.append(fpath)
        continue

    ref, where = is_referenced(fpath)
    if ref:
        skipped_due_to_reference.append((fpath, where))
    else:
        verified_to_archive.append(fpath)

print(f"Verified safe to archive: {len(verified_to_archive)} files")
if skipped_due_to_reference:
    print(f"WARNING: Kept {len(skipped_due_to_reference)} files because they ARE referenced:")
    for f, w in skipped_due_to_reference:
        print(f"  KEPT: {os.path.basename(f)} (used in {w})")

# Move verified files to archive_unused/ preserving relative structure
total_bytes_saved = 0
for fpath in verified_to_archive:
    if not os.path.exists(fpath):
        continue
    sz = os.path.getsize(fpath)
    rel_p = os.path.relpath(fpath, PROJECT_DIR)
    dest_p = os.path.join(ARCHIVE_DIR, rel_p)
    os.makedirs(os.path.dirname(dest_p), exist_ok=True)
    shutil.move(fpath, dest_p)
    total_bytes_saved += sz

print(f"\nSuccessfully archived {len(verified_to_archive)} files!")
print(f"Total space saved: {total_bytes_saved / (1024 * 1024):.2f} MB")
print(f"Archived safely to: {ARCHIVE_DIR}")
