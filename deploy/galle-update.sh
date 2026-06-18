#!/usr/bin/env bash
# Pull the latest code; reload the kiosk ONLY when index.html actually changed.
# This is the only place that touches git. Safe to run on a timer.
set -euo pipefail

REPO_DIR="/home/mooniak/Desktop/galle-font-terminal"
BRANCH="main"

cd "$REPO_DIR"

# Hash the displayed file before and after updating.
hash_file() { sha1sum index.html 2>/dev/null | awk '{print $1}'; }

before="$(hash_file)"
git fetch --quiet origin "$BRANCH"
git reset --hard --quiet "origin/$BRANCH"
after="$(hash_file)"

if [ "$before" != "$after" ]; then
  echo "index.html changed ($before -> $after), reloading kiosk."
  pkill -f chromium || true
else
  echo "No change to index.html; not reloading."
fi
