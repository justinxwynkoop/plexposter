#!/bin/bash
# ============================================================
# Now Playing Screen — Raspberry Pi 4 Setup Script
# Run as your regular user (not root), it will sudo as needed
# ============================================================

set -e
echo ""
echo "  ▶ Now Playing Screen — Pi Setup"
echo "  ================================"
echo ""

# ── 1. Update system ──────────────────────────────────────────
echo "[1/6] Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

# ── 2. Install Chromium and display tools ─────────────────────
echo "[2/6] Installing Chromium, X server utilities, and unclutter..."
sudo apt-get install -y -qq \
  chromium \
  xdotool \
  unclutter \
  x11-xserver-utils \
  xscreensaver

# ── 3. Disable screen blanking ────────────────────────────────
echo "[3/6] Disabling screen blanking..."

# For X11-based setups
XINITRC="$HOME/.xinitrc"
if ! grep -q "xset s off" "$XINITRC" 2>/dev/null; then
  cat >> "$XINITRC" << 'EOF'
xset s off
xset s noblank
xset -dpms
EOF
fi

# For lightdm / desktop environments — also set in autostart
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/disable-screensaver.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Disable Screensaver
Exec=bash -c "xset s off && xset s noblank && xset -dpms"
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# ── 4. Copy the Now Playing HTML file ─────────────────────────
echo "[4/6] Installing Now Playing app..."
mkdir -p "$HOME/now-playing"
# Copy index.html to ~/now-playing/index.html
# (If running this script manually, place index.html next to this script first)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/index.html" ]; then
  cp "$SCRIPT_DIR/index.html" "$HOME/now-playing/index.html"
  echo "  ✓ Copied index.html to ~/now-playing/"
else
  echo "  ! index.html not found next to this script."
  echo "    Copy it manually to: $HOME/now-playing/index.html"
fi

# ── 5. Create the kiosk launcher script ───────────────────────
echo "[5/6] Creating kiosk launcher..."
cat > "$HOME/now-playing/launch-kiosk.sh" << 'KIOSK'
#!/bin/bash
# Hide cursor after 0.5s of inactivity
unclutter -idle 0.5 -root &

# Disable screen blanking (belt-and-suspenders)
sleep 2
xset s off
xset s noblank
xset -dpms

# Rotate display to portrait
xrandr --output HDMI-A-2 --rotate right

# Launch Chromium in kiosk mode
chromium \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --no-first-run \
  --disable-features=TranslateUI \
  --disable-pinch \
  --overscroll-history-navigation=0 \
  --disable-web-security \
  --user-data-dir=/tmp/chromium-kiosk \
  "file://$HOME/now-playing/index.html"
KIOSK
chmod +x "$HOME/now-playing/launch-kiosk.sh"

# ── 6. Autostart on login ─────────────────────────────────────
echo "[6/6] Setting up autostart..."

# Method A: LXDE autostart (works on Pi OS with desktop)
mkdir -p "$HOME/.config/lxsession/LXDE-pi"
AUTOSTART="$HOME/.config/lxsession/LXDE-pi/autostart"
if ! grep -q "launch-kiosk" "$AUTOSTART" 2>/dev/null; then
  echo "@$HOME/now-playing/launch-kiosk.sh" >> "$AUTOSTART"
  echo "  ✓ Added to LXDE autostart"
fi

# Method B: systemd user service (works on Pi OS Lite with startx)
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/now-playing.service" << 'SERVICE'
[Unit]
Description=Now Playing Kiosk
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=%h/now-playing/launch-kiosk.sh
Restart=on-failure
RestartSec=5s
Environment=DISPLAY=:0

[Install]
WantedBy=graphical-session.target
SERVICE

echo ""
echo "  ✅ Setup complete!"
echo ""
echo "  Next steps:"
echo "  ─────────────────────────────────────────────"
echo "  1. Reboot the Pi: sudo reboot"
echo "  2. After reboot, Chromium opens the app fullscreen"
echo "  3. Press 'C' to open the config panel"
echo "  4. Enter your Plex URL, Token, and Immich details"
echo ""
echo "  If kiosk doesn't auto-launch, run manually:"
echo "    ~/now-playing/launch-kiosk.sh"
echo ""
echo "  To enable systemd service instead:"
echo "    systemctl --user enable now-playing"
echo "    systemctl --user start now-playing"
echo ""
