#!/usr/bin/env python3
import http.server
import urllib.request
import urllib.error
import os
from urllib.parse import urlparse, parse_qs, unquote

PORT = 8080
DIR = os.path.expanduser("~/now-playing")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIR, **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if parsed.path == "/api/plex/sessions":
            self._proxy_plex_sessions(params)
        elif parsed.path == "/api/plex/thumb":
            self._proxy_plex_thumb(params)
        elif parsed.path == "/api/immich/thumb":
            self._proxy_immich_thumb(params)
        else:
            super().do_GET()

    def _proxy_plex_sessions(self, params):
        url = unquote(params.get("url", [""])[0])
        token = unquote(params.get("token", [""])[0])
        if not url or not token:
            self._respond(400, b"Missing url or token")
            return
        try:
            req = urllib.request.Request(
                f"{url}/status/sessions?X-Plex-Token={token}",
                headers={"Accept": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=8) as r:
                data = r.read()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self._respond(500, str(e).encode())

    def _proxy_plex_thumb(self, params):
        url = unquote(params.get("url", [""])[0])
        token = unquote(params.get("token", [""])[0])
        path = unquote(params.get("path", [""])[0])
        if not url or not token or not path:
            self._respond(400, b"Missing params")
            return
        try:
            with urllib.request.urlopen(f"{url}{path}?X-Plex-Token={token}", timeout=8) as r:
                data = r.read()
                ct = r.headers.get("Content-Type", "image/jpeg")
            self.send_response(200)
            self.send_header("Content-Type", ct)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self._respond(500, str(e).encode())

    def _proxy_immich_thumb(self, params):
        url = unquote(params.get("url", [""])[0])
        key = unquote(params.get("key", [""])[0])
        asset_id = unquote(params.get("id", [""])[0])
        if not url or not key or not asset_id:
            self._respond(400, b"Missing params")
            return
        try:
            req = urllib.request.Request(
                f"{url}/api/assets/{asset_id}/thumbnail?size=preview",
                headers={"x-api-key": key}
            )
            with urllib.request.urlopen(req, timeout=8) as r:
                data = r.read()
                ct = r.headers.get("Content-Type", "image/jpeg")
            self.send_response(200)
            self.send_header("Content-Type", ct)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self._respond(500, str(e).encode())

    def _respond(self, code, body):
        self.send_response(code)
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # suppress request logs

if __name__ == "__main__":
    os.chdir(DIR)
    print(f"Proxy serving on http://localhost:{PORT}")
    with http.server.HTTPServer(("127.0.0.1", PORT), Handler) as httpd:
        httpd.serve_forever()
