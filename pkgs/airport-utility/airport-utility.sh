#!/usr/bin/env bash
# Apple AirPort Utility 5.6.1, run under Wine.
#
# Configures the "classic" AirPort base stations (AirPort Express/Extreme and
# Time Capsule) that the modern macOS/iOS AirPort Utility can no longer manage.
#
# The Wine prefix is created lazily on first launch and persisted per-user so
# saved base-station passwords and Wine config survive across runs. Tools
# (wine, wineserver, winetricks, ...) come from PATH, set up by the Nix wrapper.
# MSIDIR points at the extracted installer payloads in the Nix store.
set -euo pipefail

# Persistent per-user prefix; override with AIRPORT_UTILITY_WINEPREFIX.
WINEPREFIX="${AIRPORT_UTILITY_WINEPREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/airport-utility/prefix}"
export WINEPREFIX
# APUtil is happiest as Windows 7; disable the Mono/Gecko install prompts since
# the utility needs neither.
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree=d;mshtml=d;winemenubuilder.exe=d}"
export WINEDEBUG="${WINEDEBUG:--all}"

aputil="$WINEPREFIX/drive_c/Program Files/AirPort/APUtil.exe"

if [ ! -f "$aputil" ]; then
  echo "airport-utility: first run, creating Wine prefix at $WINEPREFIX ..." >&2
  mkdir -p "$WINEPREFIX"

  wineboot --init
  wineserver -w
  winetricks -q win7

  # Install the payloads extracted from Apple's AirPortSetup.exe. AirPort.msi
  # is the utility itself; Bonjour provides the mDNS stack used to discover
  # base stations on the LAN.
  wine msiexec /i "$MSIDIR/AirPort.msi" /qn
  wineserver -w
  wine msiexec /i "$MSIDIR/Bonjour.msi" /qn
  wineserver -w

  if [ ! -f "$aputil" ]; then
    echo "airport-utility: install failed, $aputil is missing." >&2
    echo "Remove $WINEPREFIX and try again, or run with WINEDEBUG=+all for details." >&2
    exit 1
  fi
fi

# Graphics backend. APUtil ignores Wine's logical DPI, so under XWayland it is
# stuck tiny on HiDPI outputs. Wine's native Wayland driver instead hands the
# window to the compositor, which applies the output scale -- the only thing
# that actually enlarges this app. Set AIRPORT_UTILITY_BACKEND=x11 to fall back.
backend="${AIRPORT_UTILITY_BACKEND:-wayland}"
case "$backend" in
  wayland) graphics="wayland,x11" ;;
  x11)     graphics="x11" ;;
  *)       graphics="$backend" ;;
esac
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "$graphics" /f >/dev/null 2>&1 || true

# Wine logical DPI. Only bites under the x11 backend (and only for the app's few
# DPI-aware bits); the Wayland backend scales via the compositor instead.
dpi="${AIRPORT_UTILITY_DPI:-96}"
wine reg add "HKCU\\Control Panel\\Desktop" /v LogPixels /t REG_DWORD /d "$dpi" /f >/dev/null 2>&1 || true

# Drop the broken launcher entry Wine's menu builder created during the original
# install (it targets the default ~/.wine prefix and does nothing). The builder
# is disabled via WINEDLLOVERRIDES above, so it will not reappear.
rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/wine/Programs/AirPort Utility.desktop"

exec wine "$aputil" "$@"
