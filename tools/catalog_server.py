#!/usr/bin/env python3
"""NebulaBeat Chart Catalog Server.

A minimal HTTP catalog server for sharing .nbeat charts between players.
Endpoints:
  GET  /api/charts              - list all available charts
  GET  /api/charts/<id>         - download a chart (.nbeat JSON)
  POST /api/charts              - upload a chart (multipart/form-data)
  GET  /api/charts/<id>/audio   - download associated audio (MP3)
  GET  /api/catalog             - catalog metadata
"""

import json
import os
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

CATALOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "catalog")
CHARTS_DIR = os.path.join(CATALOG_DIR, "charts")
AUDIO_DIR = os.path.join(CATALOG_DIR, "audio")
INDEX_FILE = os.path.join(CATALOG_DIR, "index.json")

PORT = 8765


def _ensure_dirs():
    os.makedirs(CHARTS_DIR, exist_ok=True)
    os.makedirs(AUDIO_DIR, exist_ok=True)


def _load_index():
    if not os.path.exists(INDEX_FILE):
        return []
    with open(INDEX_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def _save_index(index):
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(index, f, indent=2)


class CatalogHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Silence default logging for cleaner output
        pass

    def _send_json(self, code, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _send_file(self, code, path, content_type):
        if not os.path.exists(path):
            self._send_json(404, {"error": "not found"})
            return
        with open(path, "rb") as f:
            body = f.read()
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/charts":
            self._send_json(200, _load_index())
        elif path == "/api/catalog":
            index = _load_index()
            self._send_json(200, {
                "name": "NebulaBeat Chart Catalog",
                "version": 1,
                "chart_count": len(index),
            })
        elif path.startswith("/api/charts/"):
            parts = path.strip("/").split("/")
            if len(parts) == 3 and parts[2] == "audio":
                chart_id = parts[1]
                index = _load_index()
                entry = next((e for e in index if e.get("id") == chart_id), None)
                if not entry:
                    self._send_json(404, {"error": "chart not found"})
                    return
                audio_filename = entry.get("audio_filename", "")
                if not audio_filename:
                    self._send_json(404, {"error": "no audio"})
                    return
                audio_path = os.path.join(AUDIO_DIR, chart_id + "_" + audio_filename)
                self._send_file(200, audio_path, "audio/mpeg")
            else:
                chart_id = parts[2]
                chart_path = os.path.join(CHARTS_DIR, chart_id + ".nbeat")
                self._send_file(200, chart_path, "application/json")
        else:
            self._send_json(404, {"error": "not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/charts":
            content_length = int(self.headers.get("Content-Length", 0))
            content_type = self.headers.get("Content-Type", "")

            if not content_type.startswith("multipart/form-data"):
                self._send_json(400, {"error": "expected multipart/form-data"})
                return

            body = self.rfile.read(content_length)
            boundary = content_type.split("boundary=")[1].encode()
            parts = body.split(b"--" + boundary)

            chart_data = None
            audio_data = None
            chart_filename = None
            audio_filename = None

            for part in parts:
                if b"Content-Disposition" not in part:
                    continue
                header_end = part.find(b"\r\n\r\n")
                if header_end < 0:
                    continue
                headers = part[:header_end].decode("utf-8", errors="replace")
                payload = part[header_end + 4:].strip(b"\r\n--")

                if 'name="chart"' in headers:
                    chart_data = payload
                elif 'name="audio"' in headers:
                    audio_data = payload
                    # Extract filename
                    for line in headers.split("\r\n"):
                        if 'filename="' in line:
                            audio_filename = line.split('filename="')[1].split('"')[0]

            if not chart_data:
                self._send_json(400, {"error": "no chart data"})
                return

            try:
                chart = json.loads(chart_data.decode("utf-8"))
            except json.JSONDecodeError:
                self._send_json(400, {"error": "invalid chart JSON"})
                return

            chart_id = str(uuid.uuid4())
            chart_path = os.path.join(CHARTS_DIR, chart_id + ".nbeat")
            with open(chart_path, "w", encoding="utf-8") as f:
                json.dump(chart, f, indent=2)

            if audio_data and audio_filename:
                audio_path = os.path.join(AUDIO_DIR, chart_id + "_" + audio_filename)
                with open(audio_path, "wb") as f:
                    f.write(audio_data)
                chart["audio_filename"] = audio_filename
            else:
                chart["audio_filename"] = ""

            chart["id"] = chart_id
            chart["uploaded_at"] = __import__("datetime").datetime.utcnow().isoformat() + "Z"

            index = _load_index()
            index.append(chart)
            _save_index(index)

            self._send_json(200, {"id": chart_id, "status": "uploaded"})
        else:
            self._send_json(404, {"error": "not found"})


def main():
    _ensure_dirs()
    server = HTTPServer(("0.0.0.0", PORT), CatalogHandler)
    print(f"NebulaBeat catalog server listening on http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down catalog server.")
        server.server_close()


if __name__ == "__main__":
    main()
