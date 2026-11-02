# Serves the built web app on 127.0.0.1. Every response says "no-cache" so the
# browser revalidates each file after a rebuild instead of mixing old and new
# files (e.g. a cached CanvasKit .wasm with a newer .js, which hangs on load).
import functools
import http.server
import json
import os
import sys
import urllib.parse
import urllib.request

port, directory = int(sys.argv[1]), sys.argv[2]

# Bank sync: {"worker": "https://….workers.dev", "key": "BRIDGE_KEY"}, kept
# next to this script and readable only by you. Without it /inbox stays empty.
SYNC_CONFIG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sync.json")


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/inbox":
            return self.inbox()
        super().do_GET()

    # Hands the open Budgie tab the next batch of bank transactions (an
    # addTransaction app link) from the sync Worker, or 204 when none wait.
    # Budgie adds them itself, so no second tab writes over its database.
    def inbox(self):
        try:
            with open(SYNC_CONFIG) as f:
                config = json.load(f)
        except FileNotFoundError:
            return self.reply(204)
        url = config["worker"].rstrip("/") + "/next?" + urllib.parse.urlencode({"key": config["key"]})
        try:
            with urllib.request.urlopen(url, timeout=30) as res:
                return self.reply(res.status, res.read())
        except Exception as e:
            self.log_error("inbox: %s", e)
            return self.reply(502)

    def reply(self, status, body=b""):
        self.send_response(status)
        if body:
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    # App links such as /addTransaction?JSON=... are routes inside the app,
    # not files, so any path that isn't a file gets index.html.
    def send_head(self):
        if not os.path.exists(self.translate_path(self.path)):
            self.path = "/index.html"
        return super().send_head()

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


http.server.ThreadingHTTPServer(
    ("127.0.0.1", port), functools.partial(Handler, directory=directory)
).serve_forever()
