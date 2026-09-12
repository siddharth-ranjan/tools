# CLAUDE.md — display-zoom

Scales the desktop UI up while an external monitor is attached, back to stock on
the laptop panel alone. See `README.md` for usage; this file is for changing it.

## Editing this changes the running desktop

`~/.local/bin/display-zoom` and `~/.config/systemd/user/display-zoom.service`
are symlinks *into this directory*. An edit here is live immediately — a syntax
error leaves the desktop stuck at the wrong scale or the service crash-looping.
After any change:

```sh
bash -n display-zoom                              # syntax
display-zoom status                               # sane output?
display-zoom desktop && display-zoom desktop      # idempotent? no dupe lines
systemctl --user daemon-reload                    # only if the unit changed
systemctl --user restart display-zoom.service
systemctl --user is-active display-zoom.service
```

## Decisions that are deliberate — do not "fix" them

**Fractional text scaling, not the HiDPI knob.** `text-scaling-factor`, never
`org.cinnamon.desktop.interface scaling-factor`. This is a viewing-distance
problem, not a density one: the external monitor is ~109 DPI, *lower* than the
laptop's ~142. `scaling-factor` is also integer-only, and 2x is absurd here.

**Scaling is global, not per-monitor.** X11 cannot scale two outputs
independently, so the laptop panel enlarges too while docked. That needs
Wayland; it is an accepted tradeoff, not a bug.

**Ports are matched by type, not name.** `external_attached()` skips
`eDP|LVDS|DSI` and treats everything else as external, rather than matching
`HDMI-1`. Card numbers and port indices shift across kernels and docks, so a
hardcoded name fails silently after an update.

**`BASE_*` are measured, not chosen.** They are this machine's stock Cinnamon
values, captured before the tool existed, which is what makes `scale=1.00`
restore the original desktop exactly. Re-read them with `gsettings get` before
touching them.

**The hotplug `sleep 2`.** The kernel marks a port connected slightly before the
mode is set; reading `/sys` immediately catches the stale value. One physical
plug also emits several udev events — harmless, because `auto` exits early when
the profile already matches.

## Writing other programs' config

GTK text scaling does not reach Java/Swing or Chromium, so `apply_apps()`
configures them separately. Three traps, each already worked around:

- **Firefox rewrites `prefs.js` on exit** from memory, discarding external
  edits. Use `user.js`, which it re-reads at every start.
- **Brave rewrites its `Preferences` JSON on exit** for the same reason. Its
  scale is a command-line flag, so it goes on a generated `.desktop` override in
  `~/.local/share/applications` — regenerated from the packaged file each run so
  a Brave update's new flags are not frozen at setup-day values.
- **JetBrains Toolbox writes `.vmoptions` without a trailing newline.**
  Appending blind glues the new line onto the last option. `set_vmoption()`
  normalises first, then strips the old value before appending.

These apply at app **startup only**. A running IDE or browser keeps its old size
until restarted; the Cinnamon side updates live. That asymmetry is the apps'
design and cannot be fixed here.

## Invariants

- **Idempotent.** Every run rewrites config owned by other programs. Running
  twice must not duplicate a line or double-apply a value. Always strip the old
  value before appending.
- **State lives in `~/.config/display-zoom.conf`** (`profile=`, `scale=`), never
  in the repo — the user's chosen scale must survive a `git pull`.
- **`DEFAULT_SCALE` is only the fallback** for a missing conf file. Keep it in
  sync with the value actually in use, or a cleared config silently changes the
  desktop.
- New IDE versions create new config dirs, so the JetBrains globs are re-walked
  on every run rather than cached.

## Environment

Linux Mint / Cinnamon on **X11**. The `org.cinnamon.*` gsettings keys do not
exist on GNOME. Several constraints above exist precisely because of X11.
