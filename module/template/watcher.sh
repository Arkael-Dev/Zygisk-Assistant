#!/system/bin/sh
# Mode per-app: spoof hanya aktif selama proses app terpilih berjalan.
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
alog "watcher per-app start"
ACTIVE=0
while :; do
    load_config
    if [ "$MODE" != "perapp" ]; then
        [ $ACTIVE = 1 ] && sh "$MODPATH/apply.sh" restore
        alog "watcher stop (mode=$MODE)"; break
    fi
    HIT=""
    while read -r P; do
        [ -n "$P" ] && pidof "$P" >/dev/null 2>&1 && { HIT="$P"; break; }
    done < "$APPS_FILE"
    if [ -n "$HIT" ] && [ $ACTIVE = 0 ]; then
        alog "target $HIT jalan -> spoof ON"; sh "$MODPATH/apply.sh" all; ACTIVE=1
    elif [ -z "$HIT" ] && [ $ACTIVE = 1 ]; then
        alog "tidak ada target -> spoof OFF"; sh "$MODPATH/apply.sh" restore; ACTIVE=0
    fi
    sleep 1
done
