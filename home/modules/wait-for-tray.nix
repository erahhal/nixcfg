# Shared script that waits for the StatusNotifierWatcher (system tray) to be ready.
# Usage: import this file and call the function with pkgs.
# Example: wait-for-tray = (import ./wait-for-tray.nix) pkgs;
pkgs:

pkgs.writeShellScript "wait-for-tray" ''
  check_tray() {
    ${pkgs.dbus}/bin/dbus-send --session \
      --dest=org.kde.StatusNotifierWatcher \
      --type=method_call --print-reply \
      /StatusNotifierWatcher \
      org.freedesktop.DBus.Properties.Get \
      string:org.kde.StatusNotifierWatcher \
      string:IsStatusNotifierHostRegistered 2>/dev/null | \
      grep -q "boolean true"
  }

  # Wait up to 60 seconds for StatusNotifierWatcher to be ready
  echo "Waiting for StatusNotifierWatcher..."
  for i in $(seq 1 60); do
    if check_tray; then
      echo "StatusNotifierWatcher found, waiting for stability..."
      sleep 3
      if check_tray; then
        echo "StatusNotifierWatcher is ready and stable"
        exit 0
      fi
      echo "StatusNotifierWatcher became unavailable, continuing to wait..."
    fi
    sleep 1
    if [ "$i" -eq 60 ]; then
      echo "Timeout waiting for StatusNotifierWatcher" >&2
      exit 1
    fi
  done
''
