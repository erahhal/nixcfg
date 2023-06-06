{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  hostName = "upaya";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "adapta";
  # defaultSession = "none+i3";
  # defaultSession = "sway";
  defaultSession = "hyprland";

  ## @TODO: make xorg-specific
  ## Xorg settings
  # kittyFontSize = 7;
  # trolltechFontSize = 10;

  kittyFontSize = 9;
  trolltechFontSize = 10;
  dpi = 210;
  dpiSddm = 210;
  dpiLaptop = 270;
  touchpad_click_method = "button_areas";
  wallpaper = "~/Wallpapers/teundenouden - polar gilds darkened - CC BY-NC-ND 3.0.png";

  # 27" 4k: 161 dpi
  # 15.6" 4k: 280 dpi

  ## No laptop scaling
  # kittyFontSize = 24;
  # dpi = 163;

  defaultBrowser = "firefox";

  wireguardIp = "192.168.1.3";

  virtualboxEnabled = false;
}

