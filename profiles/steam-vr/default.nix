{ pkgs, userParams, ... }:

let
  username = userParams.username;  # Change this
  steamDir = "/home/${username}/.local/share/Steam";
  bwrapTarget = "${steamDir}/ubuntu12_32/steam-runtime/usr/libexec/steam-runtime-tools-0/srt-bwrap";
  vrcompositorPath = "${steamDir}/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher";
in
{
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        # Qt Wayland support
        kdePackages.qtwayland
        qt5.qtwayland

        # Other commonly needed libs for VR
        libxkbcommon
        wayland
      ];
    };
  };

  hardware.steam-hardware.enable = true;

  # Setuid bwrap wrapper
  security.wrappers.bwrap = {
    owner = "root";
    group = "root";
    source = "${pkgs.bubblewrap}/bin/bwrap";
    setuid = true;
  };

  # Service to symlink bwrap
  systemd.services.steam-bwrap-link = {
    description = "Symlink setuid bwrap for Steam";
    script = ''
      if [ -e "${bwrapTarget}" ] || [ -L "${bwrapTarget}" ]; then
        rm -f "${bwrapTarget}"
      fi
      mkdir -p "$(dirname "${bwrapTarget}")"
      ln -sf /run/wrappers/bin/bwrap "${bwrapTarget}"
    '';
    serviceConfig.Type = "oneshot";
  };

  # Watch for Steam overwriting the bwrap binary
  systemd.paths.steam-bwrap-watch = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = bwrapTarget;
      Unit = "steam-bwrap-link.service";
    };
  };

  # Service to setcap vrcompositor-launcher
  systemd.services.steamvr-setcap = {
    description = "Set CAP_SYS_NICE on SteamVR vrcompositor-launcher";
    script = ''
      if [ -f "${vrcompositorPath}" ]; then
        ${pkgs.libcap}/bin/setcap CAP_SYS_NICE=eip "${vrcompositorPath}"
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  # Watch for SteamVR updates
  systemd.paths.steamvr-cap-watch = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = vrcompositorPath;
      Unit = "steamvr-setcap.service";
    };
  };

  # Run both on system activation (rebuild)
  system.activationScripts.steam-vr-setup = ''
    # bwrap symlink
    if [ -d "${steamDir}" ]; then
      rm -f "${bwrapTarget}" 2>/dev/null || true
      mkdir -p "$(dirname "${bwrapTarget}")"
      ln -sf /run/wrappers/bin/bwrap "${bwrapTarget}"
    fi

    # vrcompositor setcap
    if [ -f "${vrcompositorPath}" ]; then
      ${pkgs.libcap}/bin/setcap CAP_SYS_NICE=eip "${vrcompositorPath}" || true
    fi
  '';
}
