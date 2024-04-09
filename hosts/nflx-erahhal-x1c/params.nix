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
  defaultSession = "sway";
  multipleSessions = true;

  ttyFontSize = 9;
  trolltechFontSize = 10;
  dpi = 210;
  dpiSddm = 210;
  dpiLaptop = 210;
  # wallpaper = "~/Wallpapers/yellowstone.jpg";
  wallpaper = "~/Wallpapers/teundenouden - polar gilds darkened - CC BY-NC-ND 3.0.png";

  defaultBrowser = "chromium-browser";

  wireguardIp = "192.168.2.4";

  virtualboxEnabled = false;
  vmwareEnabled = true;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };
}

