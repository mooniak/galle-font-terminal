#!/usr/bin/env bash
# Installer for the Galle Font Terminal kiosk on Raspberry Pi OS *Desktop*.
# Run on the Pi:  bash ~/Desktop/galle-font-terminal/deploy/install.sh
set -euo pipefail

USER_NAME="mooniak"
HOME_DIR="/home/${USER_NAME}"
REPO_DIR="${HOME_DIR}/Desktop/galle-font-terminal"

echo ">> Installing packages (chromium + git)..."
sudo apt-get update
sudo apt-get install -y git x11-xserver-utils unclutter xdotool
# Package is "chromium" on Bookworm, "chromium-browser" on older releases.
sudo apt-get install -y chromium || sudo apt-get install -y chromium-browser

echo ">> Removing the old cage service if present..."
sudo systemctl disable --now galle-kiosk.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/galle-kiosk.service

echo ">> Marking repo as a safe git directory..."
git config --global --add safe.directory "$REPO_DIR" || true
sudo git config --global --add safe.directory "$REPO_DIR" || true

echo ">> Installing kiosk autostart entry..."
chmod +x "${REPO_DIR}/deploy/galle-kiosk.sh" "${REPO_DIR}/deploy/galle-update.sh"
LAUNCHER="${REPO_DIR}/deploy/galle-kiosk.sh"

# Pi OS Bookworm Desktop uses the labwc Wayland compositor, which reads its
# own autostart file (NOT ~/.config/autostart). Start from the system default
# (so the panel still loads) then append our launcher.
mkdir -p "${HOME_DIR}/.config/labwc"
LABWC_AUTOSTART="${HOME_DIR}/.config/labwc/autostart"
if [ ! -f "$LABWC_AUTOSTART" ] && [ -f /etc/xdg/labwc/autostart ]; then
  cp /etc/xdg/labwc/autostart "$LABWC_AUTOSTART"
fi
touch "$LABWC_AUTOSTART"
grep -qF "galle-kiosk.sh" "$LABWC_AUTOSTART" || echo "${LAUNCHER} &" >> "$LABWC_AUTOSTART"

# Remove any old XDG autostart entry: labwc can honor it too, which would
# start a SECOND kiosk loop and make the screen flicker/reload.
rm -f "${HOME_DIR}/.config/autostart/galle-kiosk.desktop"

echo ">> Installing auto-update timer..."
sudo cp "${REPO_DIR}/deploy/galle-update.service" /etc/systemd/system/
sudo cp "${REPO_DIR}/deploy/galle-update.timer"   /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now galle-update.timer

echo
echo ">> Done. Reboot to start the kiosk:  sudo reboot"
echo "   The page will also appear if you log out and back in."
echo "   Test launcher now:  ~/Desktop/galle-font-terminal/deploy/galle-kiosk.sh"
