import sys
import os

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from scripts.tools.build_25d_maze import build_25d_maze

if __name__ == '__main__':
    build_25d_maze()
