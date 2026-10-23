# thunderbird-kde-tray

System tray icon for Thunderbird on KDE Plasma (Wayland). Thunderbird on Linux cannot minimize to
the tray: closing the window quits the application, and new mail notifications stop. This repo makes
the X button hide Thunderbird to the tray and shows the number of unseen new mails as a badge on the
icon. Unlike Birdtray, it does not need XWayland.

## What it fixes

| Problem | Cause | Fix |
|---|---|---|
| Pressing X quits Thunderbird, no more notifications | No "minimize to tray" on Linux | An add-on catches the window close and minimizes instead (File > Quit / Ctrl+Q still quits) |
| The minimized window stays in the taskbar | — | A KWin script hides the minimized main window from the taskbar; compose windows are left alone |
| No tray icon | — | `thunderbird-tray`: StatusNotifierItem icon, left click shows / hides |
| No way to see new mail at a glance | — | Red badge on the icon: 1–5, more: 5+ (inboxes of all accounts) |
| Birdtray cannot hide the window on Wayland | Wayland does not let other apps manage windows | Window handling goes through KWin scripts; Thunderbird stays native Wayland |
| Thunderbird opens as a window at login | — | Starts hidden at login, visible only in the tray |

## Usage

- **Left click on the tray icon**: shows the Thunderbird window; hides it if it is visible and focused.
  Starts Thunderbird if it is not running.
- **Right click**: Show Thunderbird, Write new message, Quit Thunderbird.
- **Window X button**: the window is hidden, Thunderbird keeps running and showing notifications.
- **Badge**: new mails since you last looked (Thunderbird's "new" count, not the unread count).
  Reset when you view that inbox. Hover the icon to see the number.

Command line: `thunderbird-tray --hidden`, `thunderbird-tray --show [mailto:…|-compose]`,
`thunderbird-tray --quit`.

## Language

Tray menu, tooltip and installer messages are in Turkish if the system language **or** any regional
format (`LC_TIME`, `LC_NUMERIC`, …) is Turkish, and in English otherwise. Force one with
`THUNDERBIRD_TRAY_LANG=tr` or `THUNDERBIRD_TRAY_LANG=en`. The add-on's name and description follow
Thunderbird's own UI language.

## Installation

Requirements: Thunderbird 128+, KDE Plasma 6, Python 3 + PyGObject + pycairo,
`libdbusmenu-glib` (GI typelib `Dbusmenu-0.4`), `qdbus6`, `kwriteconfig6`.

```bash
# with Thunderbird closed (Ctrl+Q)
./install.sh     # no sudo needed
./uninstall.sh   # reverts everything; does not touch Thunderbird's accounts or settings
```

`install.sh` installs:

| File | Purpose |
|---|---|
| `~/.local/bin/thunderbird-tray` | Tray icon (StatusNotifierItem + dbusmenu), badge drawing |
| `<profile>/extensions/thunderbird-tray@onur.local.xpi` | Add-on: minimize on X + report the new mail count |
| `<profile>/prefs.js` → `extensions.autoDisableScopes = 14` | So the add-on placed in the profile folder is not disabled |
| `~/.local/share/kwin/scripts/thunderbird-tray` | Hides the minimized main window from the taskbar, hidden start |
| `~/.local/share/applications/org.mozilla.Thunderbird.desktop` | Menu launcher opens through `thunderbird-tray --show`; the system launcher is untouched |
| `~/.config/autostart/thunderbird-tray.desktop` | `thunderbird-tray --hidden` at login |

## How it works

- **Add-on** (`addon/`): the close-blocking part comes from rsjtdrjgfuzkfg's
  [Minimize on Close](https://addons.thunderbird.net/thunderbird/addon/minimize-on-close/) (MPL 2.0),
  which can only be installed up to Thunderbird 153. Its experiment API catches the window's `close`
  event and `window.close`. The new mail count comes from `folders.getFolderInfo().newMessageCount`
  and is written to `$XDG_RUNTIME_DIR/thunderbird-tray/unread`.
- **Tray** (`thunderbird-tray`): reads that file every 2 s; when there is a count it draws a badge on
  the Thunderbird icon and serves it as `IconPixmap`. Showing / hiding the window loads temporary KWin
  scripts (the way to raise another application's window on Wayland).
- **KWin script** (`kwin/`): sets `skipTaskbar` while the main window (title `… - Mozilla Thunderbird`)
  is minimized. When the window opens it calls the tray's `org.onur.ThunderbirdTray.TakeStartHidden`
  D-Bus method; on a `--hidden` start it minimizes the window right away.

## Notes

- The add-on is unsigned and uses an experiment API; Thunderbird allows both
  (`extensions.experiments.suppressed = false`). If a future Thunderbird update disables experiments,
  X will quit the application again and the badge will not appear.
- Mails moved to other folders by filters are not counted; inboxes only.
- Tested on Thunderbird 158, KDE Plasma 6 Wayland (Arch Linux).

## License

MPL 2.0 (the add-on code is derived from Minimize on Close, so the repo uses the same license).
