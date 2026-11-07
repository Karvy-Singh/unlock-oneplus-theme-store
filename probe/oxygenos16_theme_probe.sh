#!/usr/bin/env bash

out="oos16-theme-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

adb shell pm list packages | grep -Ei 'theme|wallpaper' > "$out/packages.txt"

keys=(
  persist.sys.trial.theme persist.sys.trial.font persist.sys.trial.live_wp
  persist.sys.oppo.theme_uuid persist.sys.oplus.theme_uuid
  persist.sys.oppo.live_wp_uuid persist.sys.oplus.live_wp_uuid
  current_wallpaper_name current_typeface_name
)

for ns in system secure global; do
  for key in "${keys[@]}"; do
    printf '%s=' "$key"
    adb shell settings get "$ns" "$key" | tr -d '\r'
  done > "$out/${ns}_legacy.txt"

  adb shell settings list "$ns" | tr -d '\r' |
    awk -F= 'tolower($1) ~ /(theme|wallpaper|typeface|live_wp|trial)/ {print $1}' |
    sort -u > "$out/${ns}_candidate_keys.txt"
done

echo "Saved in: $out"


