#!/usr/bin/env bash
# One-shot installer for the Galle Font Terminal kiosk on Raspberry Pi OS.
# Run on the Pi:  sudo bash /home/pi/galle-font-terminal/deploy/install.sh
set -euo pipefail

USER_NAME="mooniak"
REPO_DIR="/home/${USER_NAME}/galle-font-terminal"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo." >&2
  exit 1
fi

echo ">> Installing packages (chromium + cage)..."
apt-get update
apt-get install -y chromium-browser cage git

echo ">> Marking repo as a safe git directory for root..."
git config --global --add safe.directory "$REPO_DIR"

echo ">> Installing systemd units..."
install -m 0755 "${REPO_DIR}/deploy/galle-update.sh" "${REPO_DIR}/deploy/galle-update.sh"
cp "${REPO_DIR}/deploy/galle-kiosk.service"  /etc/systemd/system/
cp "${REPO_DIR}/deploy/galle-update.service" /etc/systemd/system/
cp "${REPO_DIR}/deploy/galle-update.timer"   /etc/systemd/system/

# Patch XDG_RUNTIME_DIR to this user's real UID (may not be 1000).
USER_UID="$(id -u "$USER_NAME")"
sed -i "s|XDG_RUNTIME_DIR=/run/user/[0-9]*|XDG_RUNTIME_DIR=/run/user/${USER_UID}|" \
  /etc/systemd/system/galle-kiosk.service

chmod +x "${REPO_DIR}/deploy/galle-update.sh"

echo ">> Enabling services..."
systemctl daemon-reload
systemctl enable --now galle-kiosk.service
systemctl enable --now galle-update.timer

echo ">> Done. Kiosk should appear on the attached screen."
echo "   Logs:   journalctl -u galle-kiosk -f"
echo "   Update: systemctl start galle-update.service"
