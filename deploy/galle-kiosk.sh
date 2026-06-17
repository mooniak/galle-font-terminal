#!/usr/bin/env bash
# Kiosk launcher for Raspberry Pi OS Desktop (labwc / Wayland).
# Started from ~/.config/labwc/autostart when the desktop session loads.
# Logs everything to ~/kiosk.log for debugging. Runs Chromium fullscreen in a
# loop so it relaunches if it crashes or is killed for an update.

# Log all output (so boot failures are visible in ~/kiosk.log).
exec >> "$HOME/kiosk.log" 2>&1
echo "=================================================="
echo "kiosk launcher started: $(date)"

REPO_DIR="$HOME/Desktop/galle-font-terminal"
URL="file://${REPO_DIR}/index.html"

# Chromium uses the X11 (XWayland) backend; ensure it has a display.
export DISPLAY="${DISPLAY:-:0}"

# Route input through IBus so Sinhala (Wijesekara) works inside Chromium.
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

# Find the Chromium binary (Bookworm = "chromium", older = "chromium-browser").
if command -v chromium >/dev/null 2>&1; then
  CHROME=chromium
elif command -v chromium-browser >/dev/null 2>&1; then
  CHROME=chromium-browser
else
  echo "ERROR: chromium not installed"
  exit 1
fi
echo "using browser: $CHROME, DISPLAY=$DISPLAY"

# Wait for the X (XWayland) display to be ready. On boot, autostart can run
# before XWayland is up; launching Chromium too early makes it exit silently.
for i in $(seq 1 30); do
  if xset q >/dev/null 2>&1; then
    echo "display ready after ${i}s"
    break
  fi
  echo "waiting for display (${i})..."
  sleep 1
done

# Start IBus for Sinhala input.
pgrep -x ibus-daemon >/dev/null || ibus-daemon -drx &

# Disable screen blanking / power saving (best-effort).
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

PROFILE="$HOME/.config/chromium"

while true; do
  # Pull latest, but never hang the kiosk if the network is slow/down.
  cd "$REPO_DIR" 2>/dev/null && timeout 20 git pull --quiet 2>/dev/null || true

  # Clear crash/exit flags so no "restore pages" bubble appears.
  if [ -f "$PROFILE/Default/Preferences" ]; then
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "$PROFILE/Default/Preferences" 2>/dev/null || true
  fi

  echo "launching chromium: $(date)"
  "$CHROME" \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --check-for-update-interval=31536000 \
    --autoplay-policy=no-user-gesture-required \
    --ozone-platform=x11 \
    "$URL"
  echo "chromium exited ($?): $(date)"

  sleep 2
done
