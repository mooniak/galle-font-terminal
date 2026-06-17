#!/usr/bin/env bash
# One-shot installer for the Galle Font Terminal kiosk on Raspberry Pi OS.
# Run on the Pi:  sudo bash ~/Desktop/galle-font-terminal/deploy/install.sh
set -euo pipefail

USER_NAME="mooniak"
REPO_DIR="/home/${USER_NAME}/Desktop/galle-font-terminal"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo." >&2
  exit 1
fi

echo ">> Installing packages (chromium + cage)..."
apt-get update
apt-get install -y chromium-browser cage git

echo ">> Adding ${USER_NAME} to video/render/input groups (GPU + input access)..."
usermod -aG video,render,input "$USER_NAME"

echo ">> Marking repo as a safe git directory for root..."
git config --global --add safe.directory "$REPO_DIR"

echo ">> Installing systemd units..."
chmod +x "${REPO_DIR}/deploy/galle-update.sh"
cp "${REPO_DIR}/deploy/galle-kiosk.service"  /etc/systemd/system/
cp "${REPO_DIR}/deploy/galle-update.service" /etc/systemd/system/
cp "${REPO_DIR}/deploy/galle-update.timer"   /etc/systemd/system/

echo ">> Setting graphical boot target (kiosk runs on tty1)..."
systemctl set-default graphical.target

echo ">> Enabling services..."
systemctl daemon-reload
systemctl enable galle-kiosk.service
systemctl enable --now galle-update.timer

echo
echo ">> Done. Reboot to start the kiosk:  sudo reboot"
echo "   Logs:   journalctl -u galle-kiosk -b"
echo "   Update: sudo systemctl start galle-update.service"
