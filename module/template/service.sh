MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"
if [ "$MODE" = "perapp" ]; then
    sh "$MODPATH/apply.sh" reload
else
    sh "$MODPATH/apply.sh" mid
    {
        until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 1; done
        sh "$MODPATH/apply.sh" late
        sh "$MODPATH/apply.sh" appsync
        alog "boot selesai, spoof diterapkan"
    } &
fi
