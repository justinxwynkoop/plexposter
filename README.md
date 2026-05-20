# Now Playing Screen

A dedicated display for Raspberry Pi that shows the current Plex movie poster when something is playing, and cycles through Immich photos with a clock overlay when idle.

## What it does

- **Playing:** shows movie/episode poster, title, year, director, runtime, resolution, genre pills, star rating, and a live progress bar
- **Idle:** cycles through your Immich photo library (or a local folder) with a blurred backdrop and centered clock

## Hardware

- Raspberry Pi 4 (3B+ works with minor performance tradeoffs)
- Monitor connected via HDMI

## Setup

### 1. Clone onto the Pi

```bash
git clone https://github.com/YOUR_USERNAME/now-playing.git ~/now-playing-repo
```

### 2. Run the setup script

```bash
cd ~/now-playing-repo
chmod +x setup-pi.sh
./setup-pi.sh
```

This will:
- Update the system
- Install Chromium and display utilities
- Disable screen blanking
- Copy `index.html` to `~/now-playing/`
- Create a kiosk launcher script
- Set up autostart via LXDE and a systemd user service

### 3. Reboot

```bash
sudo reboot
```

Chromium will launch fullscreen automatically on boot.

### 4. Configure

Press **C** to open the config panel and enter:

| Setting | Where to find it |
|---|---|
| Plex Server URL | Your Plex server's LAN IP and port, e.g. `http://192.168.1.x:32400` |
| Plex Token | Plex Web → any media → ⋮ → Get Info → View XML → token in URL |
| Immich URL | Your Immich server's LAN IP and port, e.g. `http://192.168.1.x:2283` |
| Immich API Key | Immich → Account Settings → API Keys → New API Key |
| Album ID | Immich → Albums → open album → UUID from the URL (optional) |

All settings are saved to the browser's `localStorage`.

## Files

| File | Purpose |
|---|---|
| `index.html` | The entire app — runs directly in Chromium kiosk mode, no build step |
| `setup-pi.sh` | One-time Pi setup script |

## Technical notes

- Single HTML file, no framework, no build step
- Plex API polled every 5 seconds via `fetch` with `X-Plex-Token`
- Immich photos fetched via `/api/assets` or `/api/albums/{id}/assets`
- `--disable-web-security` in Chromium handles CORS on a local network
- Three idle modes: Immich photos, local folder via HTTP server, or clock only
