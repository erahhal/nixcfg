{ ... }:
{
  hostParams = {
    system = {
      hostName = "nflx-erahhal-p16";
      uid = 1026;
      gid = 100;
      # timeZone = "America/Denver";
      thinkpad-battery-charge-to-full = false;
    };

    networking = {
      networkMonitor = {
        vpnEndpoint = "https://data.netflix.net";
      };
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      # displayManager = "sddm";
      # sddmTheme = "nflx";
      # sddmThemeQt6 = false;

      displayManager = "dms";

      multipleSessions = true;
      defaultSession = "niri";
      useHyprlandFlake = false;
      disableXwaylandScaling = true;
      defaultLockProgram = "hyprlock";
      autoLogin = false;

      ttyFontSize = 9.0;
      ttyLineHeight = 10;
      dpi = 210;

      wallpaper = ../../wallpapers/tokyo-park.jpeg;
    };

    programs = {
      # defaultBrowser = "chromium-browser";
      # defaultBrowser = "chromium-intel";
      defaultBrowser = "chromium-native";
      # foot is launched directly from niri spawn-at-startup (see niri.nix)
      # because systemd user services cannot use setuid binaries like sudo
      startupApps = [
        # "chromium-intel"
        "chromium-native"
        "slack"
        "spotify"
        "brave"
        "firefox"
        "signal-desktop"
        "Telegram"
        "vesktop"
        "element-desktop"
        "joplin-desktop"
      ];

      steam = {
        gamescope = {
          enable = true;
          width = 3840;
          height = 2160;
        };
      };
    };

    gpu = {
      nvidia.enable = true;
      ## If the intel GPU is disabled, you should also set the GPU to "discrete" in the BIOS.
      ## Otherwise the laptop display is still routed through the intel GPU, and generally doesn't work, either DPMS or rendering
      intel.enable = true;
      intel.disableModules = false;
      intel.defaultWindowManagerGpu = true;
    };

    virtualisation = {
      virtualbox.enable = true;
      ## @BROKEN
      vmware.enable = false;
      libvirtd.enable = false;
    };
  };
}
