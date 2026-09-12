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
# accumulate duplicate entries. The sleep is required: Cinnamon loads its own
# keymap during login and would otherwise overwrite the remap.
cat > "$AUTOSTART/f12-home.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=F12 as Home key
Comment=Applies ~/.Xmodmap so F12 acts as Home
Exec=/bin/sh -c "sleep 3; exec xmodmap $MAP"
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

xmodmap "$MAP" || exit 1

echo "installed. current state:"
"$BIN/f12-home" status
