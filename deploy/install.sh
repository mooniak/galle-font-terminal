#!/usr/bin/env bash
# Installer for the Galle Font Terminal kiosk on Raspberry Pi OS *Desktop*.
# Run on the Pi:  bash ~/Desktop/galle-font-terminal/deploy/install.sh
set -euo pipefail

USER_NAME="mooniak"
HOME_DIR="/home/${USER_NAME}"
REPO_DIR="${HOME_DIR}/Desktop/galle-font-terminal"

echo ">> Installing packages (chromium + git)..."
sudo apt-get update
sudo apt-get install -y git x11-xserver-utils
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
# own autostart file (NOT ~/.config/autostart). Wire the kiosk in there.
mkdir -p "${HOME_DIR}/.config/labwc"
LABWC_AUTOSTART="${HOME_DIR}/.config/labwc/autostart"
touch "$LABWC_AUTOSTART"
grep -qF "$LAUNCHER" "$LABWC_AUTOSTART" || echo "${LAUNCHER} &" >> "$LABWC_AUTOSTART"

# Also drop an XDG autostart entry as a fallback for wayfire/X11 sessions.
mkdir -p "${HOME_DIR}/.config/autostart"
cp "${REPO_DIR}/deploy/galle-kiosk.desktop" "${HOME_DIR}/.config/autostart/"

echo ">> Installing auto-update timer..."
sudo cp "${REPO_DIR}/deploy/galle-update.service" /etc/systemd/system/
sudo cp "${REPO_DIR}/deploy/galle-update.timer"   /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now galle-update.timer

echo
echo ">> Done. Reboot to start the kiosk:  sudo reboot"
echo "   The page will also appear if you log out and back in."
echo "   Test launcher now:  ~/Desktop/galle-font-terminal/deploy/galle-kiosk.sh"
