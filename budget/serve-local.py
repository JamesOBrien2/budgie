# Serves the built web app on 127.0.0.1. Every response says "no-cache" so the
# browser revalidates each file after a rebuild instead of mixing old and new
# files (e.g. a cached CanvasKit .wasm with a newer .js, which hangs on load).
import functools
import http.server
import os
import sys

port, directory = int(sys.argv[1]), sys.argv[2]


class Handler(http.server.SimpleHTTPRequestHandler):
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
