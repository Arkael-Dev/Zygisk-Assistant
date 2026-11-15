SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true
CONFIG_DIR="/data/adb/zygisk_assistant"
CONFIG_FILE="$CONFIG_DIR/config.prop"
APPS_FILE="$CONFIG_DIR/apps.list"
ORIG_FILE="$CONFIG_DIR/orig.prop"
LOG_FILE="$CONFIG_DIR/log.txt"
mkdir -p "$CONFIG_DIR" 2>/dev/null
touch "$APPS_FILE" "$LOG_FILE" 2>/dev/null

# alog <msg>: ke file log + logcat (tag ZygiskAssistant) + terminal
alog() {
    local L="[$(date '+%m-%d %H:%M:%S')] $*"
    echo "$L" >> "$LOG_FILE"
    /system/bin/log -t ZygiskAssistant "$*" 2>/dev/null
    echo "$L"
    if [ "$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)" -gt 204800 ]; then
        tail -n 300 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

cfg_get() { # cfg_get KEY DEFAULT
    local V
    V="$(grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n1 | cut -d= -f2)"
    echo "${V:-$2}"
}
load_config() {
    HIDE_ROOT="$(cfg_get HIDE_ROOT 1)"
    SPOOF_BOOTLOADER="$(cfg_get SPOOF_BOOTLOADER 1)"
    MODE="$(cfg_get MODE global)"   # global | perapp
}
load_config

# simpan nilai asli sebelum di-spoof (dipakai mode per-app untuk restore)
save_orig() {
    grep -q "^$1=" "$ORIG_FILE" 2>/dev/null || echo "$1=$2" >> "$ORIG_FILE"
}

resetprop_if_diff() {
    local NAME="$1" EXPECTED="$2" CURRENT
    CURRENT="$(resetprop "$NAME")"
    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] && return 0
    save_orig "$NAME" "$CURRENT"
    if resetprop -n "$NAME" "$EXPECTED"; then
        alog "SET  $NAME: $CURRENT -> $EXPECTED"
    else
        alog "FAIL $NAME"
    fi
}

resetprop_if_match() {
    local NAME="$1" CONTAINS="$2" VALUE="$3" CURRENT
    CURRENT="$(resetprop "$NAME")"
    case "$CURRENT" in
        *"$CONTAINS"*)
            save_orig "$NAME" "$CURRENT"
            resetprop -n "$NAME" "$VALUE" && alog "SET  $NAME: $CURRENT -> $VALUE" ;;
    esac
}

delprop_if_exist() {
    local NAME="$1" CURRENT
    CURRENT="$(resetprop "$NAME")"
    [ -n "$CURRENT" ] || return 0
    save_orig "$NAME" "$CURRENT"
    resetprop --delete "$NAME" && alog "DEL  $NAME (was $CURRENT)"
}
