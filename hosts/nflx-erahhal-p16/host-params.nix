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
      useHyprlandFlake = true;
      defaultLockProgram = "hyprlock";
      autoLogin = false;

      ttyFontSize = 9.0;
      ttyLineHeight = 10;
      dpi = 210;

      wallpaper = ../../wallpapers/tokyo-park.jpeg;
    };

    programs = {
      defaultBrowser = "chromium-browser";
    };

    gpu = {
      nvidia.enable = true;
      ## If the intel GPU is disabled, you must also set the GPU to "discrete" in the BIOS
      intel.enable = false;
    };
  };
}
