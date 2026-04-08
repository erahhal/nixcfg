{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.flatpak;
in {
  options.nixcfg.programs.flatpak = {
    enable = lib.mkEnableOption "Flatpak with Steam and SteamVR support";
  };
  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      packages = [
        "com.valvesoftware.Steam"
        "net.davidotek.pupgui2"
        "com.tencent.WeChat"
      ];
      remotes = [
        { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
      ];
      overrides = {
        "com.valvesoftware.Steam" = {
          Context = {
            filesystems = [
              "~/.local/share/Steam"
            ];
          };
          Environment = {
            FLATPAK_STEAM_XDG_DIRS_PREFIX = "~";
            FLATPAK_STEAM_UPDATE_SYMLINKS = "1";
            QT_QPA_PLATFORM = "xcb";
            STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
            STEAM_DISABLE_BROWSER_SANDBOX_FOR_CEF_SUBPROCESSES = "1";
            __NV_PRIME_RENDER_OFFLOAD = "1";
            __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
            __GLX_VENDOR_LIBRARY_NAME = "";
            __VK_LAYER_NV_optimus = "";
          };
        };
      };
    };

    hardware.steam-hardware.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };

    # SteamVR Flatpak fix
    systemd.services.steamvr-flatpak-fix = {
      description = "Fix SteamVR for Flatpak (setcap + patch vrsetup.sh)";
      after = [ "flatpak-managed-install.service" ];
      wants = [ "flatpak-managed-install.service" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = with pkgs; [ libcap gnused ];
      script = ''
        for user_home in /home/*; do
          for STEAMVR_DIR in \
            "$user_home/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/SteamVR" \
            "$user_home/.local/share/Steam/steamapps/common/SteamVR"; do

            LAUNCHER="$STEAMVR_DIR/bin/linux64/vrcompositor-launcher"
            SETUP_SCRIPT="$STEAMVR_DIR/bin/vrsetup.sh"

            if [ -f "$LAUNCHER" ]; then
              setcap CAP_SYS_NICE=eip "$LAUNCHER" && \
                echo "Set CAP_SYS_NICE on $LAUNCHER"
            fi

            if [ -f "$SETUP_SCRIPT" ]; then
              sed -i '/# NIXOS_PATCHED: skip capability check/{N;d}' "$SETUP_SCRIPT"
              sed -i '/^function SteamVRLauncherSetup()/{n;a\    # NIXOS_PATCHED: skip capability check - capability set by systemd service\n    return 0
}' "$SETUP_SCRIPT"
              echo "Patched $SETUP_SCRIPT to skip capability check"
            fi
          done
        done
      '';
    };
  };
}
