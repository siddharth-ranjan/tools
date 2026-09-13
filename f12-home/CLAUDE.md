# CLAUDE.md — f12-home

Context for Claude Code when working on this tool. Self-contained: this repo
keeps no root-level CLAUDE.md, so everything that applies here is below.

## What this tool is

Makes F12 report Home on a keyboard that has no Home key (Portronics Bubble,
78-key compact). The payload is `f12-home.Xmodmap`, a keymap fragment X applies
directly. `f12-home watch`, launched by autostart, keeps the mapping applied
by listening for udev input-device *connect* events. It never reads keystrokes —
the user explicitly had an earlier keystroke-reading watcher removed. Keep it
that way.

## Edits here change a live system

**This is the most important thing to know.** The tool is *symlinked* into place,
not copied:

```
~/.local/bin/f12-home   -> ~/tools/f12-home/f12-home
~/.Xmodmap              -> ~/tools/f12-home/f12-home.Xmodmap
```

Editing `f12-home.Xmodmap` changes what the user's keyboard does at their next
login. A bad edit can leave a key dead. Before finishing any edit:

- `bash -n f12-home` and `bash -n install.sh` — syntax check
- `f12-home status` — confirm sane output
- verify through what actually owns the state, not just the tool's own report:
  `xmodmap -pke | grep '^keycode  96'`
- no systemd service: the watcher is launched by XDG autostart. After editing
  `f12-home`, restart it by rerunning `install.sh` (it replaces, never stacks)
- to test the watcher, `f12-home off` then reconnect a Bluetooth headset;
  `status` must return to active within ~2s

Do not "clean up" this tool without running it afterwards.

## Tool-specific facts

**All shift levels must be mapped.** `keycode 96 = Home` alone leaves the
shifted levels `NoSymbol`, which silently breaks `Shift+F12` (select to line
start) and `Ctrl+Shift+F12`. Hence `Home` repeated six times. Do not "simplify"
this.

**A one-shot apply is not enough — that is why `watch` exists.** X gives every
newly added keyboard device the default layout, wiping the remap. Bluetooth
headsets register as keyboards via AVRCP (media buttons), so connecting
headphones minutes after login silently reverted F12. Found in Xorg.0.log:
`Adding extended input device "HBTS004 (AVRCP)" (type: KEYBOARD)`.

**`watch` sleeps 3 seconds before its first apply.** Cinnamon loads its own
keymap during login and overwrites anything applied earlier. Removing the sleep
makes the remap fail on boot while still working when run by hand.

**`stdbuf -oL` on `udevadm monitor` is required**, and so is the 1-second wait
plus burst drain after an `add`: one connect emits several udev events, and X
attaches the device slightly after udev reports it.

**xmodmap is global.** It rewrites the keymap shared by every attached keyboard,
including the laptop's built-in one. It cannot be scoped to a device. Scoping
needs `keyd`, which needs root and a system service — rejected as overkill for
relabelling one key.

**Rejected approaches, with reasons** — do not reintroduce these:

- *Keyboard firmware.* The only fix that travels with the board, but this is a
  fixed-function HS6209 receiver. Not reprogrammable.
- *`xdotool` + a key watcher.* Tried first and failed twice over: injected
  keystrokes were never delivered to applications on this system, and the app
  still received the original F12, flashing an empty popup in the text editor on
  every press. It also means a process reading every keystroke forever.
- *Piping `xinput` into a watcher.* If this is ever revisited, note that
  `xinput` block-buffers into a pipe, so keypresses stall until 4KB accumulates.
  It appears to work only while the mouse is moving. `stdbuf -oL` is required.

## Repo conventions

**Layout.** `<name>/` holds `README.md`, `install.sh`, `CLAUDE.md`, and the
payload — an executable named `<name>` with no extension, a data file the system
consumes directly, or both, as here. `install.sh` is the constant: it symlinks
the payload into place and wires up whatever runs it. Add a row to the table in
the root `README.md`.

**Scripts.** Bash, `set -uo pipefail`, subcommands via a `case` on `$1` with a
usage line in the `*)` branch. A `status` subcommand is expected — it makes the
tool verifiable without changing anything.

**Idempotency is required.** Running `install.sh` or `f12-home apply` twice must
not duplicate or double-apply anything. `xmodmap` replaces a binding rather than
appending, and the `.desktop` file is rewritten in full each run, never appended
to.

**Never clobber a user file.** `install.sh` writes to `~/.Xmodmap`, a shared
location. It must keep checking for a pre-existing non-symlink file that lacks
our marker and back it up before replacing it.

**Comment the why, not the what.** Comments exist to stop a future reader from
"fixing" something deliberate — the six `Home`s, the 3-second sleep.

**State** lives in `~/.config/<tool>.conf`, not in the repo. This tool currently
keeps none.

## Environment

Linux Mint / Cinnamon on **X11**. Xmodmap does not apply under Wayland. The
remap is per-machine, not per-keyboard: the same keyboard on another computer
has no Home key until `install.sh` runs there too.
