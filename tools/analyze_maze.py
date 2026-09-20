import sys
import os

# Add scripts/tools to sys.path
sys.path.insert(0, os.path.abspath('scripts/tools'))

from run_all_maze_updates import main

if __name__ == '__main__':
    main()
