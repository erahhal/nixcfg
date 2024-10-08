{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  hostName = "nflx-erahhal-t490s";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "nflx";
  defaultSession = "sway";
  multipleSessions = true;

  ttyFontSize = 9;
  trolltechFontSize = 10;
  dpi = 210;
  dpiSddm = 210;
  dpiLaptop = 210;
  wallpaper = ../../wallpapers/yellowstone.jpg;

  defaultBrowser = "chromium-browser";

  wireguardIp = "192.168.2.4";

  virtualboxEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1700;
    height = 930;
  };
}

