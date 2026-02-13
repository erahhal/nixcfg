{ ... }:
{
  hostParams = {
    system = {
      hostName = "msi-linux";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      displayManager = "sddm";
      # displayManager = "jovian";
      # defaultSession = "gamescope-wayland";
      defaultSession = "niri";
      multipleSessions = true;
      ttyFontSize = 9.5;
      dpi = 192;
      autoLogin = true;
      wallpaper = ../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
    };

    programs = {
      # steam = {
      #   ## Currently broken
      #   bootToSteam = false;
      #   gamescope = {
      #     enable = true;
      #     width = 3840;
      #     height = 2160;
      #   };
      # };
      # foot is launched directly from niri spawn-at-startup (see niri.nix)
      # because systemd user services cannot use setuid binaries like sudo
      startupApps = [
        "spotify"
        "brave"
        "firefox"
        "flatpak run com.valvesoftware.Steam"
      ];
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
      intel.disableModules = false;
    };
  };
}
