PKG=com.oplus.themestore
SYS="persist.sys.trial.theme persist.sys.oppo.theme_uuid persist.sys.oplus.theme_uuid"
SEC="persist.sys.trial.theme persist.sys.oppo.theme_uuid persist.sys.oplus.theme_uuid launcher_theme_flag"

snapshot() {
  for ns in system secure; do
    keys=$SYS; [ "$ns" = secure ] && keys=$SEC
    for k in $keys; do
      printf '%-7s %-32s = %s\n' "$ns" "$k" "$(adb shell settings get $ns "$k" | tr -d '\r')"
    done
  done
}

case "$1" in
snapshot) snapshot ;;
apply)
  snapshot > snapshot_before.txt
  adb shell am force-stop $PKG
  adb shell settings put system persist.sys.trial.theme 0
  adb shell settings put secure persist.sys.trial.theme 0
  snapshot > snapshot_after.txt
  echo "Now: open Theme Store, then re-run snapshot; reboot and repeat."
  echo "Also capture: adb logcat -d > logcat_after_apply.txt" ;;
restore)
  adb shell am force-stop $PKG
  adb shell settings delete system persist.sys.trial.theme
  adb shell settings delete secure persist.sys.trial.theme
  snapshot ;;
*) echo "usage: $0 snapshot|apply|restore" ;;
esac
