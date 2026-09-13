#!/usr/bin/env bash
# Symlink f12-home onto PATH, point ~/.Xmodmap at the repo, and apply at login.
# The symlinks are deliberate: edits in the repo take effect on next login, and
# `git status` stays honest about what is actually running.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
MAP="$HOME/.Xmodmap"
AUTOSTART="$HOME/.config/autostart"

command -v xmodmap >/dev/null || { echo "xmodmap not found (install x11-xserver-utils)" >&2; exit 1; }
command -v udevadm >/dev/null || { echo "udevadm not found (install udev)" >&2; exit 1; }

# Never clobber an unrelated ~/.Xmodmap: a real file not carrying our marker is
# someone else's config, so back it up before replacing it with our symlink.
if [ -e "$MAP" ] && [ ! -L "$MAP" ] && ! grep -q "f12-home" "$MAP"; then
    cp -a "$MAP" "$MAP.bak.$(date +%s)"
    echo "existing ~/.Xmodmap backed up to $MAP.bak.*"
fi

mkdir -p "$BIN" "$AUTOSTART"
ln -sfn "$SRC/f12-home" "$BIN/f12-home"
ln -sfn "$SRC/f12-home.Xmodmap" "$MAP"

# Rewritten in full each run rather than appended to, so reinstalling cannot
# accumulate duplicate entries. It launches `watch`, not a one-shot xmodmap: a
# single apply at login is wiped the first time any keyboard device connects,
# including Bluetooth headphones.
cat > "$AUTOSTART/f12-home.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=F12 as Home key
Comment=Keeps F12 mapped to Home, reapplying when input devices connect
Exec=$BIN/f12-home watch
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

xmodmap "$MAP" || exit 1

# Start the watcher now so a reinstall does not wait for the next login.
# Replace any running one rather than stacking a second copy.
pkill -f "f12-home watch" 2>/dev/null
setsid "$BIN/f12-home" watch >/dev/null 2>&1 < /dev/null &
sleep 4   # let watch finish its initial apply before reporting

echo "installed. current state:"
"$BIN/f12-home" status
