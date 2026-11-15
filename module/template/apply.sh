#!/system/bin/sh
# apply.sh <early|mid|late|all|restore|reload>
MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"
PHASE="${1:-all}"

fix_buildstr() {
    local NAME="$1" CUR NEW
    CUR="$(resetprop "$NAME")"
    case "$CUR" in
        *test-keys*|*dev-keys*|*userdebug*)
            NEW="$(echo "$CUR" | sed -e 's/test-keys/release-keys/;s/dev-keys/release-keys/;s/userdebug/user/')"
            resetprop_if_diff "$NAME" "$NEW" ;;
    esac
}

susfs_run() {
    local OUT RC
    OUT="$("$@" 2>&1)"; RC=$?
    if [ $RC -eq 0 ]; then alog "SuSFS OK: $*"; else alog "SuSFS GAGAL($RC): $* $OUT"; fi
    return $RC
}

do_early() {
    if [ "$HIDE_ROOT" = "1" ]; then
        for P in ro.boot.warranty_bit ro.vendor.boot.warranty_bit ro.vendor.warranty_bit ro.warranty_bit; do
            resetprop_if_diff $P 0
        done
        resetprop_if_diff ro.boot.realmebootstate green
        resetprop_if_diff ro.is_ever_orange 0
        for P in $(resetprop | grep -oE 'ro.*.build.tags'); do resetprop_if_diff $P release-keys; done
        for P in $(resetprop | grep -oE 'ro.*.build.type'); do resetprop_if_diff $P user; done
        resetprop_if_diff ro.adb.secure 1
        for P in ro.build.description ro.build.display.id ro.vendor.build.description \
                 $(resetprop | grep -oE 'ro\.[A-Za-z0-9_.]*build\.(fingerprint|flavor)'); do
            fix_buildstr "$P"
        done
        if ! $SKIPDELPROP; then
            delprop_if_exist ro.boot.verifiedbooterror
            delprop_if_exist ro.boot.verifyerrorpart
        fi
        resetprop_if_diff ro.debuggable 0
        resetprop_if_diff ro.force.debuggable 0
        resetprop_if_diff ro.secure 1
    fi
    [ "$SPOOF_BOOTLOADER" = "1" ] && resetprop_if_diff ro.boot.veritymode.managed yes
}

do_mid() {
    [ "$HIDE_ROOT" = "1" ] || return 0
    resetprop_if_match ro.boot.mode recovery unknown
    resetprop_if_match ro.bootmode recovery unknown
    resetprop_if_match vendor.boot.mode recovery unknown
    resetprop_if_diff ro.boot.selinux enforcing
    $SKIPDELPROP || delprop_if_exist ro.build.selinux
    if [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
        chmod 640 /sys/fs/selinux/enforce
        chmod 440 /sys/fs/selinux/policy
        alog "SELinux node permissions hardened"
    fi
}

do_late() {
    [ "$SPOOF_BOOTLOADER" = "1" ] || return 0
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff sys.oem_unlock_allowed 0
    # GMS membaca prop saat start; paksa baca ulang nilai yang sudah di-spoof
    pkill -f com.google.android.gms.unstable 2>/dev/null && alog "restart gms.unstable"
}

do_restore() {
    [ -f "$ORIG_FILE" ] || return 0
    while IFS= read -r LINE; do
        N="${LINE%%=*}"; V="${LINE#*=}"
        [ -n "$N" ] && resetprop -n "$N" "$V" && alog "REST $N -> $V"
    done < "$ORIG_FILE"
    : > "$ORIG_FILE"
}

denylist_sync() {
    # KernelSU Next: tidak ada CLI ksud untuk app-profile umount (profil disimpan
    # kernel & diatur lewat Manager). Jadi di sini tidak ada yang "di-add".
    # Atur: Manager > Settings > "Umount modules by default" (aktif = semua app
    # non-root otomatis di-umount), atau per-app di App Profile.
    alog "KSU Next: umount modul diatur dari Manager (Umount modules by default / App Profile)"
    if command -v ksu_susfs >/dev/null 2>&1; then
        susfs_run ksu_susfs hide_sus_mnts_for_non_su_procs 1
        susfs_run ksu_susfs add_sus_path "$MODPATH"
        for SO in "$MODPATH"/zygisk/*.so; do
            [ -f "$SO" ] || continue
            susfs_run ksu_susfs add_sus_map "$SO"
        done
    else
        alog "ksu_susfs tidak ada: tidak ada hiding mount/path/maps tambahan"
    fi
}

case "$PHASE" in
    early) do_early ;;
    mid) do_mid ;;
    late) do_late ;;
    appsync) [ "$HIDE_ROOT" = "1" ] && { alog "appsync (profile umount_modules + SuSFS)"; denylist_sync; } ;;
    all) alog "apply ALL (hide_root=$HIDE_ROOT spoof_bl=$SPOOF_BOOTLOADER mode=$MODE)"; do_early; do_mid; do_late ;;
    restore) alog "restore props asli"; do_restore ;;
    reload)
        alog "reload config (hide_root=$HIDE_ROOT spoof_bl=$SPOOF_BOOTLOADER mode=$MODE)"
        pkill -f "$MODPATH/watcher.sh" 2>/dev/null
        do_restore
        denylist_sync
        if [ "$MODE" = "perapp" ]; then
            nohup sh "$MODPATH/watcher.sh" >/dev/null 2>&1 &
            alog "watcher per-app dijalankan"
        else
            do_early; do_mid; do_late
        fi ;;
esac
