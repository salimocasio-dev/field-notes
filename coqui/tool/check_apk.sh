#!/usr/bin/env bash
# Two checks of the debug apk that .github/workflows/coqui-android.yml builds.
#
#   bash coqui/tool/check_apk.sh key <apk>                       the apk is signed with the key in the repo
#   bash coqui/tool/check_apk.sh emulator <apk> [screenshot.png] on a running emulator: install twice,
#                                                                start once, and look at it
#
# key: the SHA-256 of the certificate the apk is signed with (apksigner, from the Android SDK) must
# equal the one in coqui/app/android/debug.keystore (keytool). This is what lets each build install
# over the last one.
#
# emulator: `adb install`, then `adb install -r` of the same file over it (both must say Success),
# then starts the app with monkey. It fails if the app is not running 15 seconds later, or if the
# log holds a fatal exception of the app. The screenshot, when asked for, is of what is on the screen.
set -euo pipefail

ID=dev.salimocasio.coqui
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
keystore="$here/../app/android/debug.keystore"

fail() { echo "check_apk: $*" >&2; exit 1; }

mode="${1:-}"
apk="${2:-}"
[ -n "$mode" ] && [ -f "$apk" ] || fail "usage: check_apk.sh key|emulator <apk> [screenshot.png]"

case "$mode" in
  key)
    sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    apksigner="$(ls -d "$sdk"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1)"
    [ -x "$apksigner" ] || fail "apksigner not found under '$sdk/build-tools'"
    in_apk="$("$apksigner" verify --print-certs "$apk" | grep -i 'certificate SHA-256 digest' | head -1 | sed 's/.*: *//' | tr -d ' :' | tr 'A-F' 'a-f')"
    in_repo="$(keytool -list -v -keystore "$keystore" -storepass android 2>/dev/null | grep -i 'SHA256:' | head -1 | sed 's/.*SHA256: *//' | tr -d ' :' | tr 'A-F' 'a-f')"
    echo "the apk is signed with   $in_apk"
    echo "debug.keystore holds     $in_repo"
    [ -n "$in_apk" ] && [ "$in_apk" = "$in_repo" ] || fail "the apk is not signed with coqui/app/android/debug.keystore"
    echo "same key"
    ;;
  emulator)
    shot="${3:-}"
    adb devices
    install() {
      local out
      out="$(adb install "$@" "$apk" 2>&1)" || true
      echo "$out"
      grep -q '^Success' <<<"$out" || fail "adb install $* did not say Success"
    }
    echo "== first install"
    install
    echo "== second install, over the first (-r)"
    install -r
    adb shell pm list packages | grep -q "package:$ID" || fail "$ID is not installed"

    echo "== start the app"
    adb logcat -c
    adb shell monkey -p "$ID" -c android.intent.category.LAUNCHER 1
    sleep 15
    pid="$(adb shell pidof "$ID" | tr -d '\r')"
    if [ -z "$pid" ]; then
      adb logcat -d | tail -80
      fail "the app is not running 15 seconds after it was started"
    fi
    echo "running, pid $pid"
    if adb logcat -d | grep -q "FATAL EXCEPTION"; then
      adb logcat -d | grep -A12 "FATAL EXCEPTION" | head -40
      fail "the log holds a fatal exception"
    fi
    adb shell dumpsys activity activities | grep -i 'ResumedActivity' | head -3
    if [ -n "$shot" ]; then
      adb exec-out screencap -p > "$shot"
      echo "screenshot: $shot ($(wc -c < "$shot") bytes)"
    fi
    echo "installed twice, started once, running"
    ;;
  *)
    fail "unknown mode '$mode'"
    ;;
esac
