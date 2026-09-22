#!/bin/sh
# Menu launcher for Xteink Unlocker.
#
# The GUI is inert without its root helper, and upstream's own "install helper"
# button shells out to a hardcoded /usr/bin/pkexec that doesn't exist on NixOS.
# So bring the helper up here instead: starting its unit makes polkit prompt for
# the user's password (see the rule in modules/programs/xteink-unlocker), the GUI
# then finds a healthy helper over its socket, and we stop the unit again on exit.
# It must not outlive the flash -- while up it turns the Wi-Fi radio into a
# hotspot and answers DNS/NTP/HTTP(S) for the e-reader.

set -u

SYSTEMCTL=@systemctl@
SLEEP=@sleep@
GUI=@gui@
UNIT=@unit@
SOCKET=/var/run/com.sofriendly.crosspoint.unlocker.helper.sock

started=""

cleanup() {
  [ -n "$started" ] || return 0
  started=""
  "$SYSTEMCTL" stop "$UNIT" >/dev/null 2>&1 || true
}

# No unit at all means the package was installed without the NixOS module; fall
# through and let the GUI's own helper-status panel report what's missing. Same
# if the user cancels the password prompt -- that reads better than a launcher
# that silently does nothing.
if "$SYSTEMCTL" cat "$UNIT" >/dev/null 2>&1; then
  if "$SYSTEMCTL" is-active --quiet "$UNIT"; then
    # Already up (a second window, or a deliberate manual start) -- leave its
    # lifetime to whoever started it rather than stopping it out from under them.
    :
  elif "$SYSTEMCTL" start "$UNIT" >/dev/null 2>&1; then
    started=1
    trap cleanup EXIT INT TERM HUP

    # The unit is Type=simple, so start returns before the helper has bound its
    # socket. Wait up to 5s so the GUI's first probe doesn't report "not running".
    i=0
    while [ ! -S "$SOCKET" ] && [ "$i" -lt 50 ]; do
      "$SLEEP" 0.1
      i=$((i + 1))
    done
  fi
fi

"$GUI" "$@"
