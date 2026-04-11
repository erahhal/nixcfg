{ ... }:
{
  hostParams = {
    networking = {
      networkMonitor = {
        vpnEndpoints = {
          tailscale0 = {
            endpoint = "10.0.0.1";
            method = "ping";
          };
          wg0 = {
            endpoint = "github.com";
            method = "ping";
          };
        };
      };
    };

    system = {
      hostName = "msi-linux";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      displayManager = "dms";
      # displayManager = "jovian";
      # defaultSession = "gamescope-wayland";
      defaultSession = "niri";
      multipleSessions = true;
      ttyFontSize = 9.5;
      dpi = 192;
      autoLogin = true;
      wallpaper = ../../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
      dmsLockProgram = "hyprlock";
    };

    programs = {
      # foot is launched directly from niri spawn-at-startup (see niri.nix)
      # because systemd user services cannot use setuid binaries like sudo
      startupApps = [
        "spotify"
        "brave"
        "firefox"
        # "flatpak run com.valvesoftware.Steam -cef-force-gpu -no-cef-sandbox steam://open/bigpicture"
      ];
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
      intel.disableModules = false;
    };
  };
}
