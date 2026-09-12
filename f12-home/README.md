# f12-home

Makes **F12** act as **Home** on keyboards that have no physical Home key.

Built for a Portronics Bubble (78-key compact wireless), where the Fn layer
carries media keys and pairing but no navigation cluster — Home simply does not
exist on the board, in any layer. Without it, jumping to the start of a line
while coding means reaching for the mouse.

## Install

```sh
git clone https://github.com/siddharth-ranjan/tools.git
./tools/f12-home/install.sh
```

Symlinks `f12-home` into `~/.local/bin`, points `~/.Xmodmap` at the repo copy,
and adds an autostart entry that reapplies it at login. An existing unrelated
`~/.Xmodmap` is backed up first.

Takes effect immediately — no logout needed.

## Use

Press F12. The modifiers work as they do on a real Home key:

| Keys | Does |
|------|------|
| `F12` | Start of line |
| `Shift+F12` | Select to start of line |
| `Ctrl+F12` | Start of document |
| `Ctrl+Shift+F12` | Select to start of document |

## Verify or toggle

```sh
f12-home status    # what is bound, where the map lives, is autostart present
f12-home apply     # reapply the map now (idempotent)
f12-home off       # restore a real F12 for this session only
```

`off` lasts until logout — useful when you need browser dev tools for a minute.

## The tradeoff

**F12 stops being F12.** The application never sees the original key, so
anything bound to F12 no longer responds — browser developer tools and VS
Code's *Go to Definition* being the two that bite in practice.

To use a different key, find its keycode and edit `f12-home.Xmodmap`:

```sh
xev -event keyboard | grep -oP 'keycode \K[0-9]+'   # press the key
```

Good donors are keys a compact board has but rarely needs: Right Alt (108),
Menu (135), Scroll Lock (78), Insert (118).

## Why Xmodmap and not the alternatives

- **Keyboard firmware** is the only fix that travels with the board, but this
  one is a fixed-function HS6209 receiver. Not reprogrammable. Ruled out.
- **`xdotool` + a key watcher** (grab the key, inject Home) is the usual advice
  and was tried first. It failed twice over: injected keystrokes were never
  delivered to applications on this system, and the application still received
  the original F12 — which made an empty popup flash in the text editor on
  every press. It also means a process reading every keystroke, forever.
- **`keyd`** works below the display server and would also cover TTYs and
  Wayland, but it needs root, a system service, and a config outside `$HOME`.
  Overkill to relabel one key.

Xmodmap changes the keyboard table X already consults, so there is nothing
running, nothing to read keystrokes, and no application sees the original key
at all.

## Requirements and limits

- **Linux, X11.** Xmodmap does not apply under Wayland; use `keyd` there.
- **Per machine, not per keyboard.** The remap lives on the computer. Plug the
  keyboard into another machine and it has no Home key again — install there
  too, or use `Ctrl+A` / `Ctrl+E`, which work natively in terminals on Linux
  and macOS with no setup at all.
- **Applies to every attached keyboard**, including a laptop's built-in one.
  Xmodmap edits the shared keymap; it cannot target one device. If the built-in
  keyboard has a real F12 you want to keep, use `keyd` and match on device id.
- **The autostart entry sleeps 3 seconds** before applying. Desktop
  environments load their own keymap during login and would overwrite an
  earlier change.

## Uninstall

```sh
rm ~/.Xmodmap ~/.config/autostart/f12-home.desktop
setxkbmap    # restore the stock keymap now, or just log out
```
