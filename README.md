# unlock-oneplus-theme-store
A paid Theme Store theme remains applied after the trial
flag `persist.sys.trial.theme` is cleared with `adb shell settings put`.


## Research log and reproduction

**Device:** OnePlus Nord 5

**OS:** OxygenOS 16 / Android 16

**Theme Store package:** `com.oplus.themestore`

**Root / bootloader unlock:** not required

---

### TL;DR

OxygenOS 16 still stores the Theme Store trial state in the legacy Android
setting `persist.sys.trial.theme`, duplicated in the `system` and `secure`
namespaces. During a paid theme trial the key is `1`. Writing `0` to it with
ADB without touching anything else keeps the premium theme applied. The
trial is gated client-side, and the client does not re-assert or invalidate the
patched value on store relaunch. 

The scripts that were used to find the values needed in the final script resides in `probe` and the results in `evidence`, if the final script does not work for your device, you may run the probe scripts to collect the required values to be used in the final script.

---

The starting reference for all of it was the original
[legendsayantan/ThemePatcher](https://github.com/legendsayantan/ThemePatcher),
which targets the older HeyTap/NearMe Theme Store packages and older
OxygenOS/ColorOS builds.

---

## focused state capture (`probe.sh`)

`probe.sh` reads nine keys in `system-*` and `secure-*` in evidence. It was run three times, once per state:

1. Default OnePlus theme.
2. Free Theme Store theme applied.
3. Paid Theme Store trial active.

### Comparison table

| Setting | Default  | Free theme  | Paid trial  |
| --- | --- | --- | --- |
| `system:persist.sys.trial.theme` | `null` | `0` | `1` |
| `secure:persist.sys.trial.theme` | `null` | `0` | `1` |
| `system:persist.sys.oppo.theme_uuid` | `-1` | `unified_apply_record_v2` | `unified_apply_record_v2` |
| `secure:persist.sys.oppo.theme_uuid` | `-1` | `unified_apply_record_v2` | `unified_apply_record_v2` |
| `system:persist.sys.oplus.theme_uuid` | `-1` | `-1` | `-1` |
| `secure:persist.sys.oplus.theme_uuid` | `-1` | `-1` | `-1` |
| `system:com.oplus.themestore.su` | `2` | `2` | `2` |
| `secure:launcher_theme_flag` | `1` | `-1` | `-1` |
| `secure:key_user_apply_default_theme` | `false` | `false` | `false` |
| `secure:Setting_Inspiration_Theme_Type` | `6` | `6` | `6` |
| `secure:keyguard_clock_theme_type` | `0` | `0` | `0` |

### What the snapshots showed

1. **`persist.sys.trial.theme` is the trial indicator.** It is `1` only during
   the active paid trial, `0` for free-theme and non-trial states, and `null`
   on the untouched default theme. It exists in both `system` and `secure` and
   the two stayed in sync in every capture.
2. **`persist.sys.oppo.theme_uuid`** here, `-1` is what the
   key holds when the default theme is active or a theme has been reverted,
   while `unified_apply_record_v2` is the marker while any Theme Store theme
   is applied. It is an application record, not a per-theme ID: free and paid
   themes both produced the same value.
3. **`secure:launcher_theme_flag` mirrors application/reversion.** It is `1`
   on the default theme and `-1` while a Theme Store theme is applied. It was
   not shown to control the launcher directly, but it is a reliable state
   indicator.

---

## the hypothesis and the final script

### Hypothesis

If the trial state is enforced only through `persist.sys.trial.theme`, then
clearing that key (`0`) during an active trial while leaving the application
marker `unified_apply_record_v2` intact should keep the premium theme
applied without any purchase.

This is the minimal change that isolates the licensing variable:

- one key,
- two namespaces (`system` and `secure`),
- no UUID writes,
- no font/live-wallpaper logic.

### `oos16_theme_test.sh`

The final script implements that hypothesis and nothing else:

| Mode | Behavior |
| --- | --- |
| `snapshot` | Prints the theme-related keys in `system` and `secure`. |
| `apply` | Saves `snapshot_before.txt`, force-stops `com.oplus.themestore`, sets `persist.sys.trial.theme=0` in `system` and `secure`, saves `snapshot_after.txt`. |
| `restore` | Force-stops the store, deletes `persist.sys.trial.theme` in both namespaces (returning them to `null`), and prints the result. |

---

## running the reproduction, start to finish

### Prerequisites

1. ADB installed on the computer; phone connected over USB.
2. Developer options enabled, **USB debugging** on, and the computer
   authorized on the phone.
3. **Disable permission monitoring** in Developer options (required for
   `settings put` to succeed on OPPO/OPlus builds).
4. The script is executable:

   ```sh
   chmod +x oos16_theme_test.sh
   adb devices    # must list the phone as "device", not "unauthorized"
   ```

### Sequence

```sh

# 1. Baseline on the default theme
sh ./oos16_theme_test.sh snapshot

# 2. In Theme Store on the phone: start the paid theme trial.
# Capture the active-trial state before touching anything
sh ./oos16_theme_test.sh snapshot

# 4. Apply the test condition
sh ./oos16_theme_test.sh apply
```

And it's done.

### Roadmap
- [ ] add live wallpaper/font support (that is, if it differs from this, not yet explored)
