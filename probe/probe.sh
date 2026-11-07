
#!/usr/bin/env bash

for ns in system secure; do
  for key in \
    persist.sys.trial.theme \
    persist.sys.oppo.theme_uuid \
    persist.sys.oplus.theme_uuid \
    com.oplus.themestore.su \
    key_user_apply_default_theme \
    launcher_theme_flag \
    theme_customization_overlay_packages \
    Setting_Inspiration_Theme_Type \
    keyguard_clock_theme_type
  do
    echo "$ns:$key=$(adb shell settings get "$ns" "$key" | tr -d '\r')"
  done
done > "theme-state-$(date +%s).txt"

