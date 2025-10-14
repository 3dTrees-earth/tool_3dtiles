#!/usr/bin/env python3
"""
Simple HTTP server for serving 3D Tiles viewer and output files.
Includes proper CORS headers for cross-origin requests.
"""

import http.server
import os
import socketserver
import sys
from pathlib import Path


class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS support."""

    def end_headers(self):
        """Add CORS headers to all responses."""
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        super().end_headers()

    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS preflight."""
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        """Custom log format."""
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")


def main():
    """Start the HTTP server."""
    # Change to project root directory
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)

    PORT = 8001

    print("=" * 60)
    print("🌍 3D Tiles Viewer Server")
    print("=" * 60)
    print(f"\nServing directory: {project_root}")
    print(f"\n📍 Viewer URL: http://localhost:{PORT}/viewer/")
    print(f"📁 Output URL: http://localhost:{PORT}/data/output/")
    print("\n✨ Available tilesets:")

    # List available tilesets in data/output
    output_dir = project_root / "data" / "output"
    if output_dir.exists():
        for tileset_dir in output_dir.iterdir():
            if tileset_dir.is_dir():
                tileset_json = tileset_dir / "tileset.json"
                if tileset_json.exists():
                    print(f"   • {tileset_dir.name}")
    else:
        print("   (No data/output directory found)")

    print(f"\n🚀 Server running on http://localhost:{PORT}")
    print("Press Ctrl+C to stop the server\n")
    print("=" * 60)

    try:
        with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped")
        sys.exit(0)
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"\n❌ Error: Port {PORT} is already in use.")
            print(f"   Try closing other applications or use a different port.")
            sys.exit(1)
        else:
            raise


if __name__ == "__main__":
    main()
