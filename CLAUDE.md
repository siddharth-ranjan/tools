# CLAUDE.md

A mega-repo of small personal utilities, one directory per tool. Tools are
standalone — nothing here is a shared library and tools do not import from each
other.

**Per-tool context lives in that tool's own `CLAUDE.md`.** Read it before
changing anything in that directory; this file only covers what is true of every
tool.

## Edits here change a live system

Installed tools are *symlinked* from this repo into wherever the system expects
them, not copied:

```
~/.local/bin/<tool>                    -> ~/tools/<tool>/<tool>
~/.config/systemd/user/<tool>.service  -> ~/tools/<tool>/<tool>.service
~/.Xmodmap                             -> ~/tools/f12-home/f12-home.Xmodmap
```

So an edit here takes effect on the user's machine immediately, and a broken one
degrades their desktop rather than failing a build. Never finish an edit without
running the tool afterwards — `bash -n`, then the tool's own `status`, then
`systemctl --user is-active <tool>.service` if it has a service. The tool's
`CLAUDE.md` gives the exact recipe.

## Conventions

**Layout.** A new tool is `<name>/` containing `README.md`, `CLAUDE.md`,
`install.sh`, and its payload — an executable named `<name>` with no extension,
a data file the system consumes directly (`f12-home.Xmodmap`), or both.
`install.sh` is the one constant: it symlinks the payload into place and wires
up whatever runs it (a systemd user service, an XDG autostart entry). Add a row
to the table in `README.md`.

**Scripts.** Bash, `set -uo pipefail`, subcommands via a `case` on `$1` with a
usage line in the `*)` branch. Provide a `status` subcommand — it makes the tool
verifiable without changing anything.

**Idempotency is required.** These scripts rewrite config owned by other
programs. Running one twice must not duplicate lines or double-apply a value.
Strip the old value before appending, never append blindly.

**Never clobber a user file.** An installer writing to a shared location
(`~/.Xmodmap`, a dotfile, a `.desktop` the distro also ships) must detect a
pre-existing non-symlink file and back it up first. See `f12-home/install.sh`.

**State** lives in `~/.config/<tool>.conf` as `key=value`, never in the repo —
user preferences must survive a `git pull`.

**Comment the why, not the what.** Comments exist to stop a future reader from
"fixing" something deliberate: a non-obvious API choice, a workaround for
another program's behaviour, an accepted tradeoff. `display-zoom` sets the bar.

## Environment

Linux Mint / Cinnamon on **X11**. `gsettings` keys under `org.cinnamon.*` are
Cinnamon-specific and absent on GNOME. Do not assume Wayland — several
constraints in these tools exist precisely because the session is X11.

## Tools

- **[display-zoom](display-zoom/CLAUDE.md)** — scales the desktop UI to match
  the attached display setup.
- **f12-home** — remaps F12 to Home via an Xmodmap fragment, reapplied at login
  through an autostart entry.
