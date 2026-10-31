#!/bin/bash
# Build Budgie for the web and serve it on this Mac at http://127.0.0.1:8484,
# starting automatically at login. Rerun after any code change.
set -euo pipefail
cd "$(dirname "$0")"

PORT=8484
SITE="$HOME/.budgie/web"
AGENT="$HOME/Library/LaunchAgents/com.budgie.server.plist"

# --no-web-resources-cdn bundles CanvasKit so the app works offline;
# no service worker, so a rebuild shows up on the next reload.
flutter build web --release --no-web-resources-cdn --pwa-strategy=none

mkdir -p "$SITE"
rsync -a --delete build/web/ "$SITE/"
cp serve-local.py "$HOME/.budgie/serve-local.py"

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.budgie.server</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string><string>$HOME/.budgie/serve-local.py</string>
    <string>$PORT</string><string>$SITE</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/com.budgie.server" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"

for _ in 1 2 3 4 5; do curl -fs -o /dev/null "http://127.0.0.1:$PORT/" && break; sleep 1; done
echo "Budgie is running at http://127.0.0.1:$PORT"
