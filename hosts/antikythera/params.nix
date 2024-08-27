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
  ## Use with Xwayland scaling (in Sway)
  # dpi = 96;

  wallpaper = ../../wallpapers/yellowstone.jpg;

  defaultBrowser = "firefox";

  wireguardIp = "192.168.2.4";

  virtualboxEnabled = false;
  vmwareEnabled = false;
  waydroidEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };
}

