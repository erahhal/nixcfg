{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  uid = 1000;
  gid = 100;

  hostName = "msi-linux";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "sddm-astronaut-theme";
  sddmThemeQt6 = true;
  defaultSession = "hyprland";
  # defaultSession = "steam";
  dpi = 192;
  multipleSessions = true;
  useHyprlandFlake = false;
  defaultLockProgram = "hyprlock";
  ttyFontSize = 9;
  trolltechFontSize = 10;
  defaultBrowser = "firefox";
  autoLogin = true;
  wallpaper = ../../wallpapers/hawaii-dylan-theo.jpg;
  waybarSimple = true;
  enableSteamGamescope = false;
}

