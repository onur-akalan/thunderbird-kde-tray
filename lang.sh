# Shared by install.sh / uninstall.sh: msg "English" "Türkçe" prints the text in the user's language.
# Turkish if the UI language or any regional format (LC_TIME etc.) is Turkish
# (override: THUNDERBIRD_TRAY_LANG=tr|en), English otherwise.
tray_lang() {
    local forced="${THUNDERBIRD_TRAY_LANG:-}" var value lang region
    if [ -n "$forced" ]; then
        [[ "${forced,,}" == tr* ]] && echo tr || echo en
        return
    fi
    for var in LANGUAGE LC_ALL LC_MESSAGES LANG LC_TIME LC_NUMERIC LC_MONETARY LC_PAPER \
               LC_MEASUREMENT LC_ADDRESS LC_TELEPHONE; do
        IFS=: read -ra values <<<"${!var:-}"
        for value in "${values[@]}"; do
            value="${value%%.*}"
            lang="${value%%_*}"
            region=""
            [[ "$value" == *_* ]] && region="${value#*_}"
            if [[ "${lang,,}" == tr || "${region^^}" == TR ]]; then
                echo tr
                return
            fi
        done
    done
    echo en
}
TRAY_LANG="$(tray_lang)"
msg() { [ "$TRAY_LANG" = tr ] && echo "$2" || echo "$1"; }
