MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"
echo "== Zygisk Assistant (by @arqzey) =="
echo "Hide Root: $HIDE_ROOT | Spoof Bootloader: $SPOOF_BOOTLOADER | Mode: $MODE"
for P in ro.boot.verifiedbootstate ro.boot.vbmeta.device_state ro.boot.flash.locked ro.debuggable ro.secure; do
    echo "$P = $(getprop $P)"
done
echo "-- apps: $(wc -l < "$APPS_FILE") --"
echo "-- log terakhir --"
tail -n 15 "$LOG_FILE"
