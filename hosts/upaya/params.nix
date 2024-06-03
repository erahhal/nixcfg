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
  # defaultSession = "hyprland";
  defaultSession = "hyprland";
  multipleSessions = true;
  defaultLockProgram = "swaylock";

  ## @TODO: make xorg-specific
  ## Xorg settings
  # ttyFontSize = 7;
  # trolltechFontSize = 10;

  ttyFontSize = 9;
  trolltechFontSize = 10;
  dpi = 270;
  dpiSddm = 210;
  dpiLaptop = 270;
  touchpad_click_method = "button_areas";
  wallpaper = ../../wallpapers/teundenouden-polar-gilds-darkened-CC-BY-NC-ND-3.0.png;

  # 27" 4k: 161 dpi
  # 15.6" 4k: 280 dpi

  ## No laptop scaling
  # ttyFontSize = 24;
  # dpi = 163;

  defaultBrowser = "firefox";

  wireguardIp = "192.168.1.3";

  virtualboxEnabled = false;
  vmwareEnabled = false;
  waydroidEnabled = false;

  waydroid = {
    width = 3820;
    height = 2100;
  };
}

