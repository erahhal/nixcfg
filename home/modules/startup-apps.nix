{ pkgs, config, osConfig, lib, ... }:

let
  startupApps = osConfig.hostParams.programs.startupApps;
  wait-for-tray = (import ./wait-for-tray.nix) pkgs;

  # Script that waits for DMS tray and then launches all startup apps
  startup-apps-script = pkgs.writeShellScript "startup-apps" ''
    # Detect if this is a new session by checking the Wayland socket inode
    # The inode changes each time the compositor restarts
    WAYLAND_SOCKET="/run/user/$(id -u)/$WAYLAND_DISPLAY"
    if [ -S "$WAYLAND_SOCKET" ]; then
      SESSION_ID=$(${pkgs.coreutils}/bin/stat --format="%i" "$WAYLAND_SOCKET")
    else
      # Fallback: use current timestamp (always run)
      SESSION_ID=$(${pkgs.coreutils}/bin/date +%s)
    fi

    MARKER_FILE="/run/user/$(id -u)/startup-apps-$SESSION_ID"

    if [ -f "$MARKER_FILE" ]; then
      echo "Already ran for session $SESSION_ID (socket inode), skipping"
      exit 0
    fi

    # Create marker for this session
    touch "$MARKER_FILE"

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
        After = [ "graphical-session.target" "dms.service" "xdg-desktop-portal-gnome.service" ];
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
          "XDG_CURRENT_DESKTOP"
          # NOTE: XDG_SESSION_TYPE intentionally excluded - breaks portal screen sharing
          # D-Bus session for portal communication (screen sharing, file dialogs, etc.)
          "DBUS_SESSION_BUS_ADDRESS"
          # Electron/Chromium Wayland native support (critical for dynamic scaling)
          "ELECTRON_OZONE_PLATFORM_HINT" "NIXOS_OZONE_WL"
          # Qt Wayland support
          "QT_QPA_PLATFORM" "QT_QPA_PLATFORMTHEME" "QT_PLUGIN_PATH"
          "QT_IM_MODULE" "QT_STYLE_OVERRIDE" "QML2_IMPORT_PATH"
          # GTK support
          "GTK_IM_MODULE" "GTK_PATH" "GDK_PIXBUF_MODULE_FILE"
          # Compositor socket for scale change notifications
          "NIRI_SOCKET"
          # Portal discovery (critical for screen sharing)
          "NIX_XDG_DESKTOP_PORTAL_DIR"
          "XDG_DATA_DIRS"
          "XDG_CONFIG_DIRS"
        ];
        Environment = [
          "HOME=%h"
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          # Intel GPU settings for screen sharing compatibility with Niri
          "DRI_PRIME=0"
          "GBM_BACKEND=mesa"
          "LIBVA_DRIVER_NAME=iHD"
          "__GLX_VENDOR_LIBRARY_NAME=mesa"
          # EGL vendor discovery path for GPU operations in screen sharing
          "__EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d"
        ];
        # Unset NVIDIA GPU variables that would override Intel settings
        UnsetEnvironment = [
          "__NV_PRIME_RENDER_OFFLOAD"
          "__VK_LAYER_NV_optimus"
        ];
      };
    };
  };
}
