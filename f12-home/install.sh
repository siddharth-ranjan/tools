#!/usr/bin/env bash
# Symlink the Xmodmap fragment into place and apply it at every login.
# The symlink is deliberate: edits in the repo take effect on next login, and
# `git status` stays honest about what is actually running.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP="$HOME/.Xmodmap"
AUTOSTART="$HOME/.config/autostart"

command -v xmodmap >/dev/null || { echo "xmodmap not found (install x11-xserver-utils)"; exit 1; }

# Never clobber an existing ~/.Xmodmap that is not ours.
if [ -e "$MAP" ] && [ ! -L "$MAP" ]; then
    if ! grep -q "f12-home" "$MAP"; then
        cp -a "$MAP" "$MAP.bak.$(date +%s)"
        echo "existing ~/.Xmodmap backed up to $MAP.bak.*"
    fi
fi

ln -sfn "$SRC/f12-home.Xmodmap" "$MAP"

mkdir -p "$AUTOSTART"
cat > "$AUTOSTART/f12-home.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=F12 as Home key
Comment=Applies ~/.Xmodmap so F12 acts as Home
Exec=/bin/sh -c "sleep 3; exec xmodmap $MAP"
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

xmodmap "$MAP"

echo "installed. F12 now reports:"
xmodmap -pke | grep -E '^keycode +96 '
