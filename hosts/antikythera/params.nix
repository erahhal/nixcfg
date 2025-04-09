{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  # Match the UID of admin user on Synology NAS
  uid = 1026;
  gid = 100;

  hostName = "antikythera";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  # sddmTheme = "adapta";
  # sddmThemeQt6 = false;
  sddmTheme = "sddm-astronaut-theme";
  sddmThemeQt6 = true;
  defaultSession = "hyprland";
  multipleSessions = true;
  # defaultLockProgram = "swaylock";
  defaultLockProgram = "hyprlock";
  autoLogin = false;

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

  useHyprlandFlake = false;

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

  enableSteamGamescope = true;
}

