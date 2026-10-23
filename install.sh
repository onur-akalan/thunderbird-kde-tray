#!/usr/bin/env bash
# Installs thunderbird-kde-tray. Run as your user (no sudo needed). Thunderbird must be closed.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BINDIR="$HOME/.local/bin"
APPDIR="$HOME/.local/share/applications"
TBDIR="$HOME/.thunderbird"
ADDON_ID="thunderbird-tray@onur.local"
. "$HERE/lang.sh"

command -v thunderbird >/dev/null || { msg "Thunderbird not found." "Thunderbird bulunamadı." >&2; exit 1; }
if pgrep -x thunderbird >/dev/null; then
    msg "Thunderbird is running. Quit it first (Ctrl+Q), then run this again." \
        "Thunderbird açık. Önce kapat (Ctrl+Q), sonra tekrar çalıştır." >&2
    exit 1
fi

# Profile in use: Default= in installs.ini, otherwise the Default=1 entry in profiles.ini
profile=""
if [ -f "$TBDIR/installs.ini" ]; then
    profile="$(grep -m1 '^Default=' "$TBDIR/installs.ini" | cut -d= -f2-)"
fi
if [ -z "$profile" ] && [ -f "$TBDIR/profiles.ini" ]; then
    profile="$(awk -F= '/^\[/{p=""} /^Path=/{p=$2} /^Default=1/{print p; exit}' "$TBDIR/profiles.ini")"
fi
if [ -z "$profile" ] || [ ! -d "$TBDIR/$profile" ]; then
    msg "Thunderbird profile not found ($TBDIR)." "Thunderbird profili bulunamadı ($TBDIR)." >&2
    exit 1
fi
PROFILE="$TBDIR/$profile"

msg "==> Tray script: $BINDIR/thunderbird-tray" "==> Tepsi betiği: $BINDIR/thunderbird-tray"
install -Dm755 "$HERE/thunderbird-tray" "$BINDIR/thunderbird-tray"

msg "==> Add-on: $PROFILE/extensions/$ADDON_ID.xpi" "==> Eklenti: $PROFILE/extensions/$ADDON_ID.xpi"
mkdir -p "$PROFILE/extensions"
python3 -I - "$HERE/addon" "$PROFILE/extensions/$ADDON_ID.xpi" <<'PY'
import os, sys, zipfile
src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        dirs.sort()
        for f in sorted(files):
            path = os.path.join(root, f)
            z.write(path, os.path.relpath(path, src))
PY
# Add-ons placed in the profile folder are disabled by default (autoDisableScopes=15)
grep -q '"extensions.autoDisableScopes"' "$PROFILE/prefs.js" 2>/dev/null \
    || echo 'user_pref("extensions.autoDisableScopes", 14);' >> "$PROFILE/prefs.js"

msg "==> KWin script: hide minimized Thunderbird from the taskbar" \
    "==> KWin betiği: küçülen Thunderbird görev çubuğunda görünmesin"
mkdir -p "$HOME/.local/share/kwin/scripts"
rm -rf "$HOME/.local/share/kwin/scripts/thunderbird-tray"
cp -r "$HERE/kwin/thunderbird-tray" "$HOME/.local/share/kwin/scripts/"
kwriteconfig6 --file kwinrc --group Plugins --key thunderbird-trayEnabled true
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript thunderbird-tray >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

msg "==> Application menu launcher (shadows the system Thunderbird launcher)" \
    "==> Uygulama menüsü kısayolu (sistemdeki Thunderbird kısayolunu gölgeler)"
mkdir -p "$APPDIR"
sed -E "s#^Exec=thunderbird( |$)#Exec=$BINDIR/thunderbird-tray --show\1#" \
    /usr/share/applications/org.mozilla.Thunderbird.desktop > "$APPDIR/org.mozilla.Thunderbird.desktop"
kbuildsycoca6 >/dev/null 2>&1 || true

msg "==> Start hidden at login" "==> Oturum açılışında gizli başlat"
mkdir -p "$HOME/.config/autostart"
sed "s#@BINDIR@#$BINDIR#g" "$HERE/applications/thunderbird-tray-autostart.desktop.in" \
    > "$HOME/.config/autostart/thunderbird-tray.desktop"

echo
msg "Installed. To start: thunderbird-tray --hidden (or Thunderbird from the application menu)" \
    "Kuruldu. Başlatmak için: thunderbird-tray --hidden (ya da uygulama menüsünden Thunderbird)"
