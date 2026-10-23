#!/usr/bin/env bash
# Removes thunderbird-kde-tray; does not touch Thunderbird's own files or accounts.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ADDON_ID="thunderbird-tray@onur.local"
. "$HERE/lang.sh"

pkill -f '^\S*python3? \S*/thunderbird-tray( |$)' || true
rm -f "$HOME/.local/bin/thunderbird-tray" \
      "$HOME/.local/share/applications/org.mozilla.Thunderbird.desktop" \
      "$HOME/.config/autostart/thunderbird-tray.desktop"
kbuildsycoca6 >/dev/null 2>&1 || true

qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript thunderbird-tray >/dev/null 2>&1 || true
kwriteconfig6 --file kwinrc --group Plugins --key thunderbird-trayEnabled --delete
rm -rf "$HOME/.local/share/kwin/scripts/thunderbird-tray"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# The add-on file must be deleted while Thunderbird is closed; otherwise remove it from the Add-ons page
if pgrep -x thunderbird >/dev/null; then
    msg "Thunderbird is running: remove the add-on from Add-ons and Themes ('Thunderbird tray helper')." \
        "Thunderbird açık: eklentiyi Eklentiler ve Temalar'dan kaldır ('Thunderbird tepsi yardımcısı')."
else
    rm -f "$HOME"/.thunderbird/*/extensions/"$ADDON_ID.xpi"
fi

msg "Removed. Thunderbird now quits when X is pressed." "Kaldırıldı. Thunderbird artık X'e basınca kapanır."
