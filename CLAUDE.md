# CLAUDE.md

Context for Claude Code when working in this repo.

## What this is

A mega-repo of small personal utilities, one directory per tool. Tools are
standalone — nothing here is a shared library, and tools do not import from each
other. Each directory owns its own README and installer.

## Edits here change a live system

**This is the most important thing to know.** Installed tools are *symlinked*
from this repo into wherever the target system expects them, not copied:

```
~/.local/bin/<tool>                    -> ~/tools/<tool>/<tool>
~/.config/systemd/user/<tool>.service  -> ~/tools/<tool>/<tool>.service
~/.Xmodmap                             -> ~/tools/f12-home/f12-home.Xmodmap
```

So editing a file here takes effect on the user's machine immediately — a broken
edit to `display-zoom` can leave the desktop at the wrong scale, or a systemd
service crash-looping. Before finishing any edit:

- `bash -n <script>` — syntax check
- run the tool's own status/dry command and confirm sane output
- if it has a service: `systemctl --user is-active <tool>.service`, and after a
  unit-file change `systemctl --user daemon-reload && systemctl --user restart`
- if it has no service, verify through whatever actually owns the state
  (e.g. `xmodmap -pke | grep '^keycode  96'` for f12-home)

Do not "clean up" a tool without running it afterwards.

## Conventions

**Layout.** A new tool is `<name>/` containing `README.md`, `install.sh`, and
its payload. The payload is an executable named `<name>` with no extension
(`display-zoom`) *or* a data/config file the system consumes directly
(`f12-home.Xmodmap`) — not every tool ships a program. `install.sh` is the one
constant: it symlinks the payload into place and wires up whatever runs it
(a systemd user service, an XDG autostart entry). Add a row to the table in the
root `README.md`.

**Scripts.** Bash, `set -uo pipefail`, subcommands via a `case` on `$1` with a
usage line in the `*)` branch. Prefer a `status` subcommand — it makes the tool
verifiable without changing anything.

**Idempotency is required.** These scripts rewrite config files owned by other
programs. Running one twice must not duplicate lines or double-apply a value.
Strip the old value before appending the new one, never append blindly.

**Comment the why, not the what.** The code shows what it does. Comments exist
to stop a future reader from "fixing" something deliberate — a non-obvious API
choice, a workaround for another program's behaviour, an accepted tradeoff.
Every such decision in `display-zoom` is commented; match that bar.

**Never clobber a user file.** An installer that writes to a shared location
(`~/.Xmodmap`, a dotfile, a `.desktop` the distro also ships) must check for a
pre-existing non-symlink file and back it up before replacing it. See
`f12-home/install.sh`.

**State** lives in `~/.config/<tool>.conf` as `key=value`, not in the repo.
User preferences must survive a `git pull`.

## Editing other programs' config

Several tools write into files owned by GUI apps. Two rules learned the hard way:

- Some apps rewrite their config from memory on exit (Firefox `prefs.js`, Brave
  `Preferences`). Editing those silently loses the change — use the override
  mechanism instead (`user.js`, a `.desktop` file in `~/.local/share/applications`).
- JetBrains Toolbox writes `.vmoptions` files **without a trailing newline**.
  Appending blind glues your line onto the last option. Normalise first.

## Environment this targets

Linux Mint / Cinnamon on **X11**. `gsettings` keys under `org.cinnamon.*` are
Cinnamon-specific and absent on GNOME. Do not assume Wayland — several
constraints in `display-zoom` exist precisely because the session is X11.

## Tools

- **display-zoom** — scales the desktop UI to match the attached display setup.
  See `display-zoom/README.md`; the script's header comment explains why it uses
  fractional text scaling rather than the HiDPI `scaling-factor` knob.
- **f12-home** — remaps F12 to Home via an Xmodmap fragment, reapplied at login
  through an autostart entry. No executable; the payload is the keymap itself.
