{ pkgs, config, ... }:

let
  # Script that waits for DMS tray and then launches all startup apps
  startup-apps-script = pkgs.writeShellScript "startup-apps" ''
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
          break
        fi
        echo "StatusNotifierWatcher became unavailable, continuing to wait..."
      fi
      sleep 1
      if [ "$i" -eq 60 ]; then
        echo "Timeout waiting for StatusNotifierWatcher" >&2
        exit 1
      fi
    done

    # Launch all apps (use PATH to get same versions as manual launch)
    foot tmux a -dt code &
    spotify &
    brave &
    firefox &
    signal-desktop &
    Telegram &
    vesktop &
    element-desktop &
    joplin-desktop &

    echo "All startup apps launched"
  '';
in
{
  systemd.user.services.startup-apps = {
    Unit = {
      Description = "Launch startup applications";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "dms.service" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = false;
      KillMode = "none";
      ExecStart = "${startup-apps-script}";
      PassEnvironment = [
        "HOME" "XDG_DATA_HOME" "XDG_CONFIG_HOME" "XDG_CACHE_HOME"
        "XDG_RUNTIME_DIR" "DISPLAY" "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE"
      ];
      Environment = [
        "HOME=%h"
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };
  };
}
