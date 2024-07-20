{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  hostName = "nflx-erahhal-x1c";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "nflx";
  defaultSession = "hyprland";
  multipleSessions = true;
  defaultLockProgram = "hyprlock";

  ttyFontSize = 9;
  ## Only 10 seems to get rid of the gaps in Foot terminal
  ttyLineHeight = 10;
  trolltechFontSize = 10;
  dpi = 190;
  # dpiSddm = 210;
  # dpiLaptop = 210;
  wallpaper = ../../wallpapers/yellowstone.jpg;

  defaultBrowser = "chromium-browser";

  wireguardIp = "192.168.2.4";

  virtualboxEnabled = false;
  vmwareEnabled = true;
  waydroidEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };
}

