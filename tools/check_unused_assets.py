import os

PROJECT_DIR = r"d:\last-utsav-main"

searchable_exts = {".tscn", ".tres", ".gd", ".godot"}
code_files = []
for root, dirs, files in os.walk(PROJECT_DIR):
    if "\\.godot" in root or "\\builds" in root or "\\.git" in root or "\\archive" in root:
        continue
    for f in files:
        if os.path.splitext(f)[1] in searchable_exts:
            code_files.append(os.path.join(root, f))

all_content = []
for p in code_files:
    try:
        with open(p, "r", encoding="utf-8", errors="ignore") as f:
            all_content.append((p, f.read()))
    except Exception as e:
        pass

def is_file_referenced(filename_or_path):
    base = os.path.basename(filename_or_path)
    for path, content in all_content:
        if path == filename_or_path:
            continue
        if base in content:
            return True, path
    return False, None

# Scan all files in assets and scenes
candidate_files = []
for folder in ["assets", os.path.join("scenes", "levels", "l3")]:
    target_dir = os.path.join(PROJECT_DIR, folder)
    if os.path.exists(target_dir):
        for root, dirs, files in os.walk(target_dir):
            for f in files:
                if f.endswith(".import") or f.endswith(".uid") or f.endswith(".tscn") or f.endswith(".gd") or f.endswith(".tres"):
                    continue
                candidate_files.append(os.path.join(root, f))

print(f"Total candidate asset files checked: {len(candidate_files)}")

unused_files = []
total_unused_bytes = 0

for cf in candidate_files:
    ref, where = is_file_referenced(cf)
    if not ref:
        size = os.path.getsize(cf)
        unused_files.append((cf, size))
        total_unused_bytes += size

unused_files.sort(key=lambda x: x[1], reverse=True)

print(f"\nFound {len(unused_files)} completely unreferenced asset files.")
print(f"Total size of unreferenced files: {total_unused_bytes / (1024 * 1024):.2f} MB")
print("\nTop 30 largest completely unused files:")
for path, size in unused_files[:30]:
    rel = os.path.relpath(path, PROJECT_DIR)
    print(f"  {size / (1024*1024):.2f} MB : {rel}")
