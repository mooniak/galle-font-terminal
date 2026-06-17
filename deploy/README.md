# Raspberry Pi Kiosk Deployment (Pi OS Desktop)

Runs `index.html` fullscreen on the Pi's screen at login/boot, and auto-pulls
updates from GitHub every 5 minutes (reloading the display when the code
changes). You develop on your MacBook and just `git push`.

> Target: **Raspberry Pi OS Desktop** with autologin to user `mooniak`, repo
> cloned at `~/Desktop/galle-font-terminal`.

## How it works

- **`galle-kiosk.sh` + `galle-kiosk.desktop`** — an XDG autostart entry launches
  Chromium fullscreen (`--kiosk`) inside the desktop session when it loads. The
  script runs in a loop, so Chromium relaunches if it crashes or is killed for
  an update. (We do **not** use `cage`/a systemd display service here — that is
  only for Pi OS Lite, and it fights the desktop for the screen.)
- **`galle-update.sh` + `galle-update.timer`** — every 5 min the Pi does a hard
  `git reset` to `origin/main`; if anything changed it kills Chromium, and the
  launcher loop relaunches with the new `index.html`.

## One-time Pi setup

1. On the Pi (Desktop), open a terminal and clone the repo to the Desktop:

   ```bash
   git clone https://github.com/mooniak/galle-font-terminal.git ~/Desktop/galle-font-terminal
   ```

2. Run the installer:

   ```bash
   bash ~/Desktop/galle-font-terminal/deploy/install.sh
   ```

3. Reboot:

   ```bash
   sudo reboot
   ```

The kiosk launches automatically after the desktop logs in.

## Pushing updates from your MacBook

Just commit and push as usual:

```bash
git add index.html
git commit -m "tweak"
git push origin main
```

Within ~5 minutes the Pi pulls it and reloads automatically. To apply
immediately, on the Pi run:

```bash
sudo systemctl start galle-update.service
```

> Note: the Pi uses `git reset --hard`, so it only ever **pulls**. Never commit
> on the Pi itself — local changes get discarded.

## Useful commands (on the Pi)

```bash
journalctl -u galle-update -f          # watch update logs
systemctl status galle-update.timer    # see next scheduled check
pkill -f chromium                      # force a reload now
~/Desktop/galle-font-terminal/deploy/galle-kiosk.sh   # test the launcher
```

## Exiting the kiosk

Press `Ctrl`+`Alt`+`F2` for a text console, log in, and run
`pkill -f galle-kiosk.sh` then `pkill -f chromium`. Or SSH in and do the same.

## Tuning

- **Update frequency:** edit `OnUnitActiveSec=5min` in `galle-update.timer`.
- **Different branch:** change `BRANCH` in `galle-update.sh`.

After editing the timer/service, re-copy them to `/etc/systemd/system/` and run
`sudo systemctl daemon-reload`. After editing the autostart entry, copy it to
`~/.config/autostart/`.
