{ pkgs, ... }: {
  services.flatpak = {
    enable = true;
    packages = [
      # "com.google.Chrome"
      # "org.chromium.Chromium"
      "com.valvesoftware.Steam"
      "net.davidotek.pupgui2"
    ];
    # Optional: ensure Flathub is added automatically
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    ];
    overrides = {
      "com.valvesoftware.Steam" = {
        Environment = {
          QT_QPA_PLATFORM = "xcb";
        };
      };
    };
  };

  # Udev rules for Steam controllers, etc.
  hardware.steam-hardware.enable = true;

  # Required for Flatpak application icons and proper desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # SteamVR Flatpak fix: set capability and patch vrsetup.sh to skip the blocking check
  systemd.services.steamvr-flatpak-fix = {
    description = "Fix SteamVR for Flatpak (setcap + patch vrsetup.sh)";
    after = [ "flatpak-managed-install.service" ];
    wants = [ "flatpak-managed-install.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ libcap gnused ];
    script = ''
      for user_home in /home/*; do
        STEAMVR_DIR="$user_home/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/SteamVR"
        LAUNCHER="$STEAMVR_DIR/bin/linux64/vrcompositor-launcher"
        SETUP_SCRIPT="$STEAMVR_DIR/bin/vrsetup.sh"

        # Set capability on vrcompositor-launcher
        if [ -f "$LAUNCHER" ]; then
          setcap CAP_SYS_NICE=eip "$LAUNCHER" && \
            echo "Set CAP_SYS_NICE on $LAUNCHER"
        fi

        # Patch vrsetup.sh to skip the capability check that blocks on polkit
        if [ -f "$SETUP_SCRIPT" ]; then
          # Check if already patched
          if ! grep -q "# NIXOS_PATCHED: skip capability check" "$SETUP_SCRIPT"; then
            # Insert early return at the start of SteamVRLauncherSetup function
            sed -i '/^function SteamVRLauncherSetup()/a\    # NIXOS_PATCHED: skip capability check - capability set by systemd service\n    return 0' "$SETUP_SCRIPT"
            echo "Patched $SETUP_SCRIPT to skip capability check"
          else
            echo "$SETUP_SCRIPT already patched"
          fi
        fi
      done
    '';
  };
}
