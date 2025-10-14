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

    containers = {
      backend = "docker";
    };

    desktop = {
      # displayManager = "sddm";
      # sddmTheme = "nflx";
      # sddmThemeQt6 = false;

      defaultSession = "hyprland";
      multipleSessions = true;
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
      defaultBrowser = "chromium-intel";
    };

    gpu = {
      nvidia.enable = true;
      ## If the intel GPU is disabled, you should also set the GPU to "discrete" in the BIOS.
      ## Otherwise the laptop display is still routed through the intel GPU, and generally doesn't work, either DPMS or rendering
      intel.enable = true;
      intel.disableModules = false;
    };

    virtualisation = {
      virtualbox.enable = true;
      ## @BROKEN
      vmware.enable = false;
    };
  };
}
