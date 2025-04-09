{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  # Match the UID of admin user on Synology NAS
  uid = 1026;
  gid = 100;

  hostName = "nflx-erahhal-x1c";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "nflx";
  sddmThemeQt6 = false;
  # sddmTheme = "sddm-astronaut-theme";
  # sddmThemeQt6 = true;
  defaultSession = "hyprland";
  multipleSessions = true;
  # defaultLockProgram = "swaylock";
  defaultLockProgram = "hyprlock";
  autoLogin = false;

  ttyFontSize = 9;
  ## Only 10 seems to get rid of the gaps in Foot terminal
  ttyLineHeight = 10;
  trolltechFontSize = 10;
  dpi = 190;
  # dpiSddm = 210;
  # dpiLaptop = 210;
  wallpaper = ../../wallpapers/tokyo-park.jpeg;

  defaultBrowser = "chromium-browser";
  # defaultBrowser = "firefox";

  useHyprlandFlake = false;

  virtualboxEnabled = false;

  vmwareEnabled = true;

  waydroidEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };

  wireguardIp = "192.168.2.4";
}

