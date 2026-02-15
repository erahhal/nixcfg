{ ... }:
{
  hostParams = {
    system = {
      hostName = "antikythera";
      uid = 1026;
      gid = 100;
      # timeZone = "America/Denver";
      thinkpad-battery-charge-to-full = false;
    };

    desktop = {
      displayManager = "dms";
      multipleSessions = true;
      defaultSession = "niri";
      dpi = 192;
      wallpaper = ../../wallpapers/huashan-temple.jpg;
      disableXwaylandScaling = true;
      dmsLockProgram = "hyprlock";
    };

    programs = {
      steam = {
        gamescope = {
          enable = true;
          width = 1920;
          height = 1080;
        };
      };
      # foot is launched directly from niri spawn-at-startup (see niri.nix)
      # because systemd user services cannot use setuid binaries like sudo
      startupApps = [
        "spotify"
        "brave"
        "firefox"
        "signal-desktop"
        "Telegram"
        "vesktop"
        "element-desktop"
        "joplin-desktop"
      ];
    };

    gpu = {
      amd.enable = true;
    };
  };
}
