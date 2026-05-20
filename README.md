# Plex Poster — Now Playing Screen for Raspberry Pi

A dedicated display that shows the current Plex movie or TV show poster when something is playing, and a fullscreen clock when idle. No keyboard or mouse needed once it's set up.

![idle: fullscreen clock — playing: large movie poster with NOW PLAYING header]

---

## What you need

- Raspberry Pi 4 (3B+ works with minor performance tradeoffs)
- A spare monitor connected via HDMI
- MicroSD card (8 GB minimum)
- Raspberry Pi OS **64-bit Desktop** (not Lite)
- A running Plex Media Server on your local network

---

## 1. Flash the SD card

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to flash **Raspberry Pi OS (64-bit) Desktop**.

In the imager's advanced settings (gear icon), configure:
- Username and password
- Wi-Fi SSID and password
- Enable SSH
- Set your timezone

---

## 2. Boot and SSH in

Insert the SD card, power on the Pi, and SSH in:

```bash
ssh youruser@raspberrypi.local
```

Or use the IP address if hostname doesn't resolve.

---

## 3. Clone the repo

```bash
git clone https://github.com/justinxwynkoop/plexposter.git ~/plexposter
cd ~/plexposter
```

---

## 4. Run the setup script

```bash
chmod +x setup-pi.sh
./setup-pi.sh
```

This will:
- Update the system
- Install Chromium and display utilities
- Disable screen blanking
- Copy the app to `~/now-playing/`
- Create a kiosk launcher script
- Set up autostart so the kiosk launches on every boot

---

## 5. Reboot

```bash
sudo reboot
```

Chromium will launch fullscreen automatically after boot. The first launch may take 15–20 seconds.

---

## 6. Configure

Press **C** on a keyboard connected to the Pi (or plugged in just for setup) to open the config panel.

### Finding your Plex token

1. Open Plex Web in a browser
2. Click any movie or show → **⋮** → **Get Info** → **View XML**
3. Look at the URL in the address bar — copy the value after `X-Plex-Token=`

### Config fields

| Field | What to enter |
|---|---|
| Plex Server URL | `http://YOUR-PLEX-IP:32400` — use the LAN IP, not app.plex.tv |
| Plex Token | The token you copied from the XML URL above |
| Player / Client | Optional — leave blank to show any active session |
| Idle Mode | Clock Only until you have Immich set up |
| Immich URL | `http://YOUR-IMMICH-IP:2283` (if you use Immich) |
| Immich API Key | Immich → Account Settings → API Keys |
| Album ID | Optional — leave blank to use all your photos |

Click **Save & Apply**. Settings are stored in the browser's `localStorage` and survive reboots.

---

## Portrait mode (optional)

If you want to mount the monitor vertically, add this to `/boot/firmware/config.txt`:

```
display_rotate=1
```

Then reboot. This rotates the display at the hardware level.

Alternatively, you can use `xrandr` — first run `xrandr` to find your output name, then uncomment and edit the rotation line in `~/now-playing/launch-kiosk.sh`.

---

## Troubleshooting

**Kiosk doesn't launch on boot**
Run it manually to check for errors:
```bash
~/now-playing/launch-kiosk.sh
```

**Still shows clock when a movie is playing**
- Confirm your Plex URL and token are correct
- Test the API directly: `curl "http://YOUR-PLEX-IP:32400/status/sessions?X-Plex-Token=YOUR-TOKEN"`
- It should return XML with `size="1"` when something is playing

**Keyring password popup on launch**
Already handled by `--password-store=basic` in the launch script. If it appears, dismiss it and it won't ask again for that profile.

**Wrong display output for xrandr rotation**
Run `xrandr` with no arguments to list connected outputs and their names.

---

## Files

| File | Purpose |
|---|---|
| `index.html` | The entire app — single file, no framework, no build step |
| `setup-pi.sh` | One-time Pi setup script |
| `proxy.py` | Local proxy for future Immich integration |

---

## Technical notes

- Single HTML file, no framework, no build step — runs directly from the filesystem
- Plex API polled every 5 seconds via `fetch` with `X-Plex-Token`
- For TV episodes, uses `grandparentThumb` (show poster) not `thumb` (episode screenshot)
- `--disable-web-security` in Chromium handles CORS for local network requests
- Three idle modes: Immich photos, local folder via HTTP server, or clock only
- Config stored in `localStorage` at `~/.config/chromium-kiosk`
