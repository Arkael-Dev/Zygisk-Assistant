CFG=/data/adb/zygisk_assistant
ui_print "*********************************"
ui_print "  Zygisk Assistant v2.1.4-arqzey2"
ui_print "  KernelSU Next edition (ksunext1)"
ui_print "  Modded by @arqzey"
ui_print "*********************************"
if [ "$KSU" != "true" ]; then
    ui_print "! Bukan KernelSU/KernelSU Next terdeteksi."
    ui_print "! Script edisi ini dioptimalkan untuk KernelSU Next."
fi
if [ ! -d /data/adb/modules/zygisksu ] && [ ! -d /data/adb/modules/rezygisk ] && [ ! -d /data/adb/modules/zygisk_next ]; then
    ui_print "! Zygisk Next / ReZygisk tidak ditemukan."
    ui_print "! Modul ini butuh implementasi Zygisk aktif."
fi
mkdir -p $CFG
[ -f $CFG/config.prop ] || printf 'HIDE_ROOT=1\nSPOOF_BOOTLOADER=1\nMODE=global\n' > $CFG/config.prop
touch $CFG/apps.list $CFG/log.txt
ui_print "- Config : $CFG/config.prop"
ui_print "- Hide Root        : $(grep ^HIDE_ROOT= $CFG/config.prop | cut -d= -f2)"
ui_print "- Spoof Bootloader : $(grep ^SPOOF_BOOTLOADER= $CFG/config.prop | cut -d= -f2)"
ui_print "- Mode             : $(grep ^MODE= $CFG/config.prop | cut -d= -f2)"
ui_print "- Umount modul: atur di KSU Next Manager (Umount modules by default / App Profile)"
ui_print "- WebUI : buka dari KernelSU Next Manager"
ui_print "- Log   : $CFG/log.txt  (logcat tag: ZygiskAssistant)"
echo "[$(date '+%m-%d %H:%M:%S')] module installed/updated (ksunext1)" >> $CFG/log.txt
set_perm_recursive $MODPATH 0 0 0755 0644
for f in apply.sh watcher.sh service.sh post-fs-data.sh action.sh uninstall.sh customize.sh; do
    set_perm $MODPATH/$f 0 0 0755
done
ui_print "- Selesai. Reboot, lalu cek WebUI."
