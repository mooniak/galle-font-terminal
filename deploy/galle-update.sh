#!/usr/bin/env bash
# Pull the latest code; if anything changed, restart the kiosk so the
# new index.html is shown. Safe to run on a timer.
set -euo pipefail

REPO_DIR="/home/mooniak/Desktop/galle-font-terminal"
BRANCH="main"

cd "$REPO_DIR"

before="$(git rev-parse HEAD)"
git fetch --quiet origin "$BRANCH"
git reset --hard --quiet "origin/$BRANCH"
after="$(git rev-parse HEAD)"

if [ "$before" != "$after" ]; then
  echo "Updated $before -> $after, restarting kiosk."
  systemctl restart galle-kiosk.service
else
  echo "Already up to date ($after)."
fi
