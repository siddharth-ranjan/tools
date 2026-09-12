# CLAUDE.md

Context for Claude Code when working in this repo.

## What this is

A mega-repo of small personal utilities, one directory per tool. Tools are
standalone — nothing here is a shared library, and tools do not import from each
other. Each directory owns its own README and installer.

## Edits here change a live system

**This is the most important thing to know.** Installed tools are *symlinked*
from this repo into the user's system, not copied:

```
~/.local/bin/<tool>                    -> ~/tools/<tool>/<tool>
~/.config/systemd/user/<tool>.service  -> ~/tools/<tool>/<tool>.service
```

So editing a file here takes effect on the user's machine immediately — a broken
edit to `display-zoom` can leave the desktop at the wrong scale, or a systemd
service crash-looping. Before finishing any edit:

- `bash -n <script>` — syntax check
- run the tool's own status/dry command and confirm sane output
- `systemctl --user is-active <tool>.service` if it has a service
- if the service file changed: `systemctl --user daemon-reload && restart`

Do not "clean up" a tool without running it afterwards.

## Conventions

**Layout.** A new tool is `<name>/` containing the executable `<name>` (no
extension), `README.md`, `install.sh`, and any unit file. Add a row to the table
in the root `README.md`.

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
