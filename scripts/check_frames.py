import re

with open('scenes/player/mushika_sprite_frames.tres', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern matching animation blocks
pattern = re.compile(r'\"frames\":\s*\[(.*?)\]\s*,\s*\"loop\":\s*(true|false)\s*,\s*\"name\":\s*&\"([^\"]+)\"\s*,\s*\"speed\":\s*([0-9.]+)', re.DOTALL)
matches = pattern.findall(content)
print(f"Total animations found: {len(matches)}")
for frames_str, loop, name, speed in matches:
    frame_count = len(re.findall(r'\"texture\"', frames_str))
    print(f"{name:20} frames={frame_count:2} speed={speed:4} loop={loop}")

