#!/usr/bin/env python3
"""
Custom local HTTP server for Godot 4 HTML5 Web Exports.
Enables Cross-Origin-Opener-Policy (COOP) and Cross-Origin-Embedder-Policy (COEP)
required by modern browsers for SharedArrayBuffer and WebAssembly multithreading.
Also sets correct MIME types for .wasm and .pck files.
"""

import http.server
import os
import sys

PORT = 8000
DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "builds", "web"))

class GodotHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Critical headers for Godot 4 Web builds
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        return super().guess_type(path)

if __name__ == "__main__":
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory not found: {DIRECTORY}")
        sys.exit(1)

    server_address = ("", PORT)
    httpd = http.server.HTTPServer(server_address, GodotHTTPRequestHandler)
    print("=" * 60)
    print(f"  Godot 4 Web Server running at: http://localhost:{PORT}/")
    print(f"  Serving directory: {DIRECTORY}")
    print("  COOP & COEP headers: ENABLED (SharedArrayBuffer supported)")
    print("  Press Ctrl+C to stop.")
    print("=" * 60)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
