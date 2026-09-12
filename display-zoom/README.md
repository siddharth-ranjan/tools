# display-zoom

Scales the whole desktop UI up when an external monitor is connected, and back
to normal on the laptop panel alone. Switching is automatic on hotplug.

Built for a desk setup where the monitor sits further away than laptop viewing
distance, so everything needs to be physically larger to stay readable.

## Install

```sh
git clone https://github.com/siddharth-ranjan/tools.git
./tools/display-zoom/install.sh
```

This symlinks the script into `~/.local/bin` and enables a systemd **user**
service that reacts to display hotplug events.

## Use

It runs itself. Plug the monitor in, the UI grows; unplug, it shrinks. The
manual commands are there for tuning:

```sh
display-zoom status     # what is detected and applied
display-zoom up         # one notch bigger  (saved, reused on every plug-in)
display-zoom down       # one notch smaller
display-zoom set 1.18   # any value, on or off the ladder
display-zoom toggle     # flip profiles by hand
display-zoom apps       # rewrite only the IDE/browser configs
```

Ladder: `1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.40 1.50`.
Your choice persists in `~/.config/display-zoom.conf`.

## What it actually changes

**Cinnamon** (applies live): `text-scaling-factor`, cursor size, panel height
and tray icon sizes. The pixel sizes are derived from the scale, so they stay
proportional; `scale=1.00` reproduces stock Cinnamon exactly.

**Apps** (apply at next launch): GTK text scaling does not reach Java/Swing or
Chromium, so these are configured separately.

| App | Setting | File |
|-----|---------|------|
| IntelliJ / WebStorm / Android Studio | `-Dide.ui.scale` | each `*.vmoptions` |
| Firefox | `layout.css.devPixelsPerPx` | each profile's `user.js` |
| Brave | `--force-device-scale-factor` | generated `.desktop` override |

`user.js` and the `.desktop` override are used on purpose — Firefox rewrites
`prefs.js` on exit and Brave rewrites its `Preferences` JSON, so edits to those
would be silently discarded.

## Requirements and limits

- **Linux, X11, Cinnamon.** The `gsettings` keys are Cinnamon-specific.
- **Scaling is global, not per-monitor.** X11 cannot scale two outputs
  independently, so the laptop panel is enlarged too while docked. Per-monitor
  scaling needs Wayland.
- **Running apps do not resize.** IDEs and browsers read their scale at startup;
  they pick up the new value on restart. The desktop itself updates instantly.
- **Terminal-launched Brave is unscaled** — it bypasses the `.desktop` file.

## Adapting it

Everything tunable is at the top of the script: `STEPS`, `DEFAULT_SCALE`, and
the `BASE_*` pixel sizes. Read the `BASE_*` values off your own machine
(`gsettings get org.cinnamon panels-height`) before changing them, or the
laptop profile stops matching your stock desktop.
