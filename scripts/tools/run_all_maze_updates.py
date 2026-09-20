import os
import subprocess
import sys

def main():
    print("==================================================")
    print("STEP 1: RUNNING MAZE WIDENING & CLUTTER CLEANUP")
    print("==================================================")
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from widen_and_clean_maze import run_cleanup
    run_cleanup()

    print("\n==================================================")
    print("STEP 2: REGENERATING MAZE SCENE (maze.tscn)")
    print("==================================================")
    ret = subprocess.run([sys.executable, 'scripts/generate_maze_scene.py'], capture_output=True, text=True)
    print("STDOUT:", ret.stdout.strip())
    if ret.stderr:
        print("STDERR:", ret.stderr.strip())
    if ret.returncode != 0:
        raise RuntimeError(f"generate_maze_scene.py failed with code {ret.returncode}")

    print("\n==================================================")
    print("STEP 3: RUNNING GODOT HEADLESS AUTOMATED TEST")
    print("==================================================")
    godot_exe = r"D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
    if os.path.exists(godot_exe):
        print(f"Launching Godot headless test runner: {godot_exe}...")
        try:
            test_ret = subprocess.run(
                [godot_exe, "--headless", "scenes/test_maze_runner.tscn"],
                capture_output=True,
                text=True,
                timeout=60
            )
            print("--- GODOT TEST OUTPUT ---")
            print(test_ret.stdout.strip())
            if test_ret.stderr:
                print("--- GODOT STDERR ---")
                print(test_ret.stderr.strip())
            print(f"Godot exit code: {test_ret.returncode}")
            if test_ret.returncode == 0:
                print(">>> ALL GODOT TESTS PASSED SUCCESSFULLY! <<<")
            else:
                print(f"WARNING: Godot test exited with non-zero code {test_ret.returncode}")
        except subprocess.TimeoutExpired:
            print("ERROR: Godot test timed out after 60 seconds!")
    else:
        print(f"Godot executable not found at {godot_exe}, skipping headless execution.")

    print("\n==================================================")
    print("ALL PIPELINE STEPS COMPLETED!")
    print("==================================================")

if __name__ == '__main__':
    main()
