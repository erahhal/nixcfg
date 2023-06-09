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

  kittyFontSize = 9;
  trolltechFontSize = 10;
  dpi = 210;
  dpiSddm = 210;
  dpiLaptop = 210;
  wallpaper = "~/Wallpapers/yellowstone.jpg";

  defaultBrowser = "chromium-browser";

  wireguardIp = "192.168.2.4";

  virtualboxEnabled = false;
}

