{ pkgs, config, osConfig, lib, ... }:

let
  startupApps = osConfig.hostParams.programs.startupApps;
  wait-for-tray = (import ./wait-for-tray.nix) pkgs;

  # Script that waits for DMS tray and then launches all startup apps
  startup-apps-script = pkgs.writeShellScript "startup-apps" ''
    # Wait for tray to be ready
    ${wait-for-tray}

    # Launch all apps (use PATH to get same versions as manual launch)
    ${lib.concatMapStringsSep "\n    " (app: "${app} &") startupApps}

    echo "All startup apps launched"
  '';
in
{
  config = lib.mkIf (startupApps != []) {
    systemd.user.services.startup-apps = {
      Unit = {
        Description = "Launch startup applications";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "dms.service" ];
        # Don't restart even if the service definition changes (store path changes on each rebuild)
        X-RestartIfChanged = "false";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        # Keep service "active" after completion so sd-switch doesn't restart it on rebuild
        RemainAfterExit = true;
        KillMode = "none";
        ExecStart = "${startup-apps-script}";
        PassEnvironment = [
          "HOME" "XDG_DATA_HOME" "XDG_CONFIG_HOME" "XDG_CACHE_HOME"
          "XDG_RUNTIME_DIR" "DISPLAY" "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE"
          # Electron/Chromium Wayland native support (critical for dynamic scaling)
          "ELECTRON_OZONE_PLATFORM_HINT" "NIXOS_OZONE_WL"
          # Qt Wayland support
          "QT_QPA_PLATFORM" "QT_QPA_PLATFORMTHEME" "QT_PLUGIN_PATH"
          "QT_IM_MODULE" "QT_STYLE_OVERRIDE" "QML2_IMPORT_PATH"
          # GTK support
          "GTK_IM_MODULE" "GTK_PATH" "GDK_PIXBUF_MODULE_FILE"
          # Compositor socket for scale change notifications
          "NIRI_SOCKET"
        ];
        Environment = [
          "HOME=%h"
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        ];
      };
    };
  };
}
