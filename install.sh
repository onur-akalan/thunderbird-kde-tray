#!/usr/bin/env bash
# thunderbird-kde-tray kurulumu. Kullanıcı olarak çalıştır (sudo gerekmez). Thunderbird kapalı olmalı.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BINDIR="$HOME/.local/bin"
APPDIR="$HOME/.local/share/applications"
TBDIR="$HOME/.thunderbird"
ADDON_ID="thunderbird-tray@onur.local"

command -v thunderbird >/dev/null || { echo "Thunderbird bulunamadı." >&2; exit 1; }
if pgrep -x thunderbird >/dev/null; then
    echo "Thunderbird açık. Önce kapat (Ctrl+Q), sonra tekrar çalıştır." >&2
    exit 1
fi

# Kullanılan profil: installs.ini'deki Default=, yoksa profiles.ini'deki Default=1 olan
profile=""
if [ -f "$TBDIR/installs.ini" ]; then
    profile="$(grep -m1 '^Default=' "$TBDIR/installs.ini" | cut -d= -f2-)"
fi
if [ -z "$profile" ] && [ -f "$TBDIR/profiles.ini" ]; then
    profile="$(awk -F= '/^\[/{p=""} /^Path=/{p=$2} /^Default=1/{print p; exit}' "$TBDIR/profiles.ini")"
fi
[ -n "$profile" ] && [ -d "$TBDIR/$profile" ] || { echo "Thunderbird profili bulunamadı ($TBDIR)." >&2; exit 1; }
PROFILE="$TBDIR/$profile"

echo "==> Tepsi script'i: $BINDIR/thunderbird-tray"
install -Dm755 "$HERE/thunderbird-tray" "$BINDIR/thunderbird-tray"

echo "==> Eklenti: $PROFILE/extensions/$ADDON_ID.xpi"
mkdir -p "$PROFILE/extensions"
python3 -I - "$HERE/addon" "$PROFILE/extensions/$ADDON_ID.xpi" <<'PY'
import os, sys, zipfile
src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(os.listdir(src)):
        z.write(os.path.join(src, f), f)
PY
# Profil klasörüne konan eklentiler varsayılan olarak devre dışı gelir (autoDisableScopes=15)
grep -q '"extensions.autoDisableScopes"' "$PROFILE/prefs.js" 2>/dev/null \
    || echo 'user_pref("extensions.autoDisableScopes", 14);' >> "$PROFILE/prefs.js"

echo "==> KWin betiği: küçülen Thunderbird görev çubuğunda görünmesin"
mkdir -p "$HOME/.local/share/kwin/scripts"
rm -rf "$HOME/.local/share/kwin/scripts/thunderbird-tray"
cp -r "$HERE/kwin/thunderbird-tray" "$HOME/.local/share/kwin/scripts/"
kwriteconfig6 --file kwinrc --group Plugins --key thunderbird-trayEnabled true
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript thunderbird-tray >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

echo "==> Uygulama menüsü kısayolu (sistemdeki Thunderbird kısayolunu gölgeler)"
mkdir -p "$APPDIR"
sed -E "s#^Exec=thunderbird( |$)#Exec=$BINDIR/thunderbird-tray --show\1#" \
    /usr/share/applications/org.mozilla.Thunderbird.desktop > "$APPDIR/org.mozilla.Thunderbird.desktop"
kbuildsycoca6 >/dev/null 2>&1 || true

echo "==> Oturum açılışında gizli başlat"
mkdir -p "$HOME/.config/autostart"
sed "s#@BINDIR@#$BINDIR#g" "$HERE/applications/thunderbird-tray-autostart.desktop.in" \
    > "$HOME/.config/autostart/thunderbird-tray.desktop"

echo
echo "Kuruldu. Başlatmak için: thunderbird-tray --hidden (ya da uygulama menüsünden Thunderbird)"
