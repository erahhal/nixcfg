{ ... }:
{
  hostParams = {
    system = {
      hostName = "nflx-erahhal-p16";
      uid = 1026;
      gid = 100;
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      displayManager = "sddm";
      sddmTheme = "nflx";
      sddmThemeQt6 = false;

      defaultSession = "hyprland";
      multipleSessions = false;
      useHyprlandFlake = false;
      defaultLockProgram = "hyprlock";
      autoLogin = false;

      ttyFontSize = 9;
      ttyLineHeight = 10;
      dpi = 210;

      wallpaper = ../../wallpapers/tokyo-park.jpeg;
    };

    programs = {
      defaultBrowser = "chromium-browser";
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
