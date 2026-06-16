# Raspberry Pi 3 Kiosk Deployment

Runs `index.html` fullscreen on the Pi's screen at boot, and auto-pulls
updates from GitHub every 5 minutes (restarting the display when the code
changes). You develop on your MacBook and just `git push`.

## How it works

- **`galle-kiosk.service`** — launches Chromium fullscreen via `cage` (a tiny
  Wayland kiosk compositor). No desktop environment needed; works on Pi OS Lite.
- **`galle-update.sh` + `galle-update.timer`** — every 5 min the Pi does a
  hard `git reset` to `origin/main`; if `index.html` changed, it restarts the
  kiosk so the new version shows.

## One-time Pi setup

1. Flash **Raspberry Pi OS (64-bit) Lite** (or Desktop) and boot the Pi.
   Default user is assumed to be `pi`. If yours differs, edit `USER_NAME` /
   `User=` / paths in the deploy files (and `XDG_RUNTIME_DIR` UID, `id -u pi`).

2. SSH in from your Mac and clone the repo to the home folder:

   ```bash
   ssh pi@<pi-ip-address>
   git clone https://github.com/mooniak/galle-font-terminal.git ~/galle-font-terminal
   ```

3. Run the installer:

   ```bash
   sudo bash ~/galle-font-terminal/deploy/install.sh
   ```

That's it. The kiosk launches now and on every boot.

## Pushing updates from your MacBook

Just commit and push as usual:

```bash
git add index.html
git commit -m "tweak"
git push origin main
```

Within ~5 minutes the Pi pulls it and reloads automatically. To apply
immediately, SSH in and run:

```bash
sudo systemctl start galle-update.service
```

> Note: the Pi uses a public `https` clone and `git reset --hard`, so it only
> ever **pulls**. Never commit on the Pi itself — local changes get discarded.

## Useful commands (on the Pi)

```bash
journalctl -u galle-kiosk -f         # watch kiosk logs
journalctl -u galle-update -f        # watch update logs
systemctl status galle-update.timer  # see next scheduled check
systemctl restart galle-kiosk        # force a reload
```

## Tuning

- **Update frequency:** edit `OnUnitActiveSec=5min` in `galle-update.timer`.
- **Hide mouse cursor / screen blanking:** add to the `cage` ExecStart flags or
  disable blanking with `xset`/`wlr-randr` as needed.
- **Different branch:** change `BRANCH` in `galle-update.sh`.

After editing any unit file, re-copy it and run `sudo systemctl daemon-reload`.
