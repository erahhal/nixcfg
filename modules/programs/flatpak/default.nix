{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.programs.flatpak;
  hasNvidia = config.hardware.nvidia.modesetting.enable or false;

  mkGamescopeScript = import ../../../lib/mkGamescopeScript.nix { inherit pkgs lib config; };

  steam-gamescope-flatpak = mkGamescopeScript {
    name = "steam-gamescope-flatpak";
    innerCommand = "flatpak run com.valvesoftware.Steam -tenfoot -steamos3 -pipewire-dmabuf";
    # Remove stale theme symlinks in Flatpak persistent storage that conflict
    # with bwrap when home-manager nix store paths change after rebuilds
    preCommands = ''
      rm -rf "$HOME/.var/app/com.valvesoftware.Steam/.themes" 2>/dev/null
      rm -rf "$HOME/.var/app/com.valvesoftware.Steam/.icons" 2>/dev/null
    '';
  };

  flatpak-sync-nvidia-gl = pkgs.writeShellScript "flatpak-sync-nvidia-gl" ''
    # Get host NVIDIA driver version
    DRIVER_VERSION=$(cat /sys/module/nvidia/version 2>/dev/null || true)
    if [ -z "$DRIVER_VERSION" ]; then
      echo "No NVIDIA driver detected, skipping GL runtime sync"
      exit 0
    fi

    # Convert 595.58.03 -> nvidia-595-58-03
    FLATPAK_VERSION="nvidia-''${DRIVER_VERSION//./-}"
    GL_RUNTIME="org.freedesktop.Platform.GL.$FLATPAK_VERSION"
    GL32_RUNTIME="org.freedesktop.Platform.GL32.$FLATPAK_VERSION"

    echo "Host NVIDIA driver: $DRIVER_VERSION"
    echo "Required flatpak GL runtime: $FLATPAK_VERSION"

    # Install matching runtimes if not present
    for RUNTIME in "$GL_RUNTIME" "$GL32_RUNTIME"; do
      if ! ${pkgs.flatpak}/bin/flatpak info "$RUNTIME" &>/dev/null; then
        echo "Installing $RUNTIME..."
        ${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub "$RUNTIME" || \
          echo "Warning: failed to install $RUNTIME (may not be available yet)"
      else
        echo "$RUNTIME already installed"
      fi
    done

    # Remove old NVIDIA GL runtimes that don't match
    ${pkgs.flatpak}/bin/flatpak list --runtime --columns=application | grep 'org.freedesktop.Platform.GL' | grep nvidia | while read -r OLD; do
      if [ "$OLD" != "$GL_RUNTIME" ] && [ "$OLD" != "$GL32_RUNTIME" ]; then
        echo "Removing old runtime: $OLD"
        ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive "$OLD" 2>/dev/null || true
      fi
    done
  '';
in {
  options.nixcfg.programs.flatpak = {
    enable = lib.mkEnableOption "Flatpak with Steam and SteamVR support";
  };
  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      packages = [
        "com.valvesoftware.Steam"
        "com.github.Matoking.protontricks"
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
              "~/.themes:ro"
              "~/.icons:ro"
              "~/.local/bin:ro"
              "/nix/store:ro"
            ];
          };
          Environment = {
            FLATPAK_STEAM_XDG_DIRS_PREFIX = "~";
            FLATPAK_STEAM_UPDATE_SYMLINKS = "1";
            QT_QPA_PLATFORM = "xcb";
            STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
            STEAM_DISABLE_BROWSER_SANDBOX_FOR_CEF_SUBPROCESSES = "1";
            STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
            PATH = "/app/bin:/app/utils/bin:/usr/bin:/home/${userParams.username}/.local/bin";
          } // lib.optionalAttrs hasNvidia {
            __NV_PRIME_RENDER_OFFLOAD = "1";
            __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
            # Was previously cleared to work around CEF GPU crash (flathub #1198),
            # but empty causes Steam to fall back to mesa/zink which fails entirely.
            # -cef-force-gpu flag handles CEF GPU rendering separately.
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            __VK_LAYER_NV_optimus = "";
          };
        };
      };
    };

    hardware.steam-hardware.enable = true;

    environment.systemPackages = with pkgs; [
      gamescope
      steam-gamescope-flatpak
    ];

    home-manager.users.${userParams.username} = { lib, ... }: {
      xdg.desktopEntries.steam-gamescope-flatpak = {
        name = "Steam (Gamescope)";
        exec = "steam-gamescope-flatpak";
        terminal = false;
        type = "Application";
        icon = "steam";
      };

      # Place steamos-session-select inside ~/.local/bin so the Flatpak sandbox
      # can find it when Steam's "Switch to Desktop" falls back to the legacy
      # path: PATH="${SYSTEM_PATH-${PATH}}" steamos-session-select <session>
      # Kills Steam from within the sandbox; gamescope exits when its child dies.
      # Written as a real file (not symlink) because home-manager symlinks
      # point to the nix store which isn't accessible inside the Flatpak sandbox.
      home.activation.steamos-session-select = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/steamos-session-select" << 'SCRIPT'
#!/bin/sh
kill $(pidof steam) 2>/dev/null
touch "$HOME/.local/share/Steam/.gamescope-exit"
SCRIPT
        chmod +x "$HOME/.local/bin/steamos-session-select"
      '';
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };

    # Sync flatpak NVIDIA GL runtime with host driver version
    systemd.services.flatpak-sync-nvidia-gl = lib.mkIf hasNvidia {
      description = "Sync flatpak NVIDIA GL runtime with host driver";
      after = [ "flatpak-managed-install.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = "${flatpak-sync-nvidia-gl}";
    };

    # Native Steam creates some files as read-only; the Flatpak wrapper
    # uses set -e and dies on the first failed cp/write.
    systemd.services.steam-fix-flatpak-perms = {
      description = "Make Steam data directory writable for Flatpak";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for user_home in /home/*; do
          STEAM_DIR="$user_home/.local/share/Steam"
          if [ -d "$STEAM_DIR" ]; then
            ${pkgs.findutils}/bin/find "$STEAM_DIR" -maxdepth 1 ! -perm -u+w -exec chmod u+w {} +
            echo "Fixed permissions in $STEAM_DIR"
          fi
        done
      '';
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
