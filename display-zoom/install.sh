#!/usr/bin/env bash
# Symlink display-zoom onto PATH and enable the hotplug service.
# The symlink is deliberate: edits in the repo take effect immediately, and
# `git status` stays honest about what is actually running.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
UNIT="$HOME/.config/systemd/user"

mkdir -p "$BIN" "$UNIT"
ln -sfn "$SRC/display-zoom" "$BIN/display-zoom"
ln -sfn "$SRC/display-zoom.service" "$UNIT/display-zoom.service"

systemctl --user daemon-reload
systemctl --user enable --now display-zoom.service

echo "installed. current state:"
"$BIN/display-zoom" status
