#!/usr/bin/env bash
# thunderbird-kde-tray'i kaldırır; Thunderbird'ün kendi dosyalarına ve hesaplarına dokunmaz.
set -euo pipefail

ADDON_ID="thunderbird-tray@onur.local"

pkill -f 'local/bin/thunderbird-tray' || true
rm -f "$HOME/.local/bin/thunderbird-tray" \
      "$HOME/.local/share/applications/org.mozilla.Thunderbird.desktop" \
      "$HOME/.config/autostart/thunderbird-tray.desktop"
kbuildsycoca6 >/dev/null 2>&1 || true

qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript thunderbird-tray >/dev/null 2>&1 || true
kwriteconfig6 --file kwinrc --group Plugins --key thunderbird-trayEnabled --delete
rm -rf "$HOME/.local/share/kwin/scripts/thunderbird-tray"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# Eklenti dosyası Thunderbird kapalıyken silinmeli; açıksa Eklentiler sayfasından kaldır
if pgrep -x thunderbird >/dev/null; then
    echo "Thunderbird açık: eklentiyi Eklentiler ve Temalar'dan kaldır ('Thunderbird tepsi yardımcısı')."
else
    rm -f "$HOME"/.thunderbird/*/extensions/"$ADDON_ID.xpi"
fi

echo "Kaldırıldı. Thunderbird artık X'e basınca kapanır."
