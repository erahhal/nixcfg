{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  hostName = "antikythera";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "adapta";
  defaultSession = "hyprland";
  multipleSessions = true;
  # defaultLockProgram = "swaylock";
  defaultLockProgram = "hyprlock";

  ttyFontSize = 9;
  ## Only 10 seems to get rid of the gaps in Foot terminal
  ttyLineHeight = 10;
  trolltechFontSize = 10;

  ## Use with no Xwayland scaling (in Hyperland)
  dpi = 192;
  dpiSddm = 192;
  ## Use with Xwayland scaling (in Sway)
  # dpi = 96;

  defaultBrowser = "firefox";

  useHyprlandFlake = true;

  virtualboxEnabled = false;

  vmwareEnabled = false;

  wallpaper = ../../wallpapers/yellowstone.jpg;

  waydroidEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };

  wireguardIp = "192.168.2.4";
}

