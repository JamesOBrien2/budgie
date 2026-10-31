# Serves the built web app on 127.0.0.1. Every response says "no-cache" so the
# browser revalidates each file after a rebuild instead of mixing old and new
# files (e.g. a cached CanvasKit .wasm with a newer .js, which hangs on load).
import functools
import http.server
import sys

port, directory = int(sys.argv[1]), sys.argv[2]


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


http.server.ThreadingHTTPServer(
    ("127.0.0.1", port), functools.partial(Handler, directory=directory)
).serve_forever()
