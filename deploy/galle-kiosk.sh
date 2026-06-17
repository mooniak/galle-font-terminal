#!/usr/bin/env bash
# Kiosk launcher for Raspberry Pi OS Desktop.
# Started by XDG autostart when the desktop session loads. Runs Chromium
# fullscreen in a loop so it relaunches if it crashes or is killed for an
# update. Pulls the latest code before each (re)launch.
REPO_DIR="$HOME/Desktop/galle-font-terminal"
URL="file://${REPO_DIR}/index.html"

# Disable screen blanking / power saving (best-effort, X11 only).
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Find the Chromium binary (Bookworm uses "chromium", older uses
# "chromium-browser").
if command -v chromium >/dev/null 2>&1; then
  CHROME=chromium
elif command -v chromium-browser >/dev/null 2>&1; then
  CHROME=chromium-browser
else
  echo "ERROR: chromium not installed" >&2
  exit 1
fi

# Clean Chromium exit flags so it never shows the "restore pages" bar.
PROFILE="$HOME/.config/chromium"

while true; do
  cd "$REPO_DIR" 2>/dev/null && git pull --quiet 2>/dev/null || true

  # Clear crash/exit flags so no restore bubble appears.
  if [ -f "$PROFILE/Default/Preferences" ]; then
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "$PROFILE/Default/Preferences" 2>/dev/null || true
  fi

  "$CHROME" \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --check-for-update-interval=31536000 \
    --autoplay-policy=no-user-gesture-required \
    --ozone-platform-hint=auto \
    "$URL"

  # If Chromium exits (crash or killed for update), wait then relaunch.
  sleep 2
done
