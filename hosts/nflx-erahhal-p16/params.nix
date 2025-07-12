{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  # Match the UID of admin user on Synology NAS
  uid = 1026;
  gid = 100;

  hostName = "nflx-erahhal-p16";
  timeZone = "America/Los_Angeles";
  containerBackend = "docker";
  displayManager = "sddm";
  sddmTheme = "nflx";
  sddmThemeQt6 = false;
  # sddmTheme = "sddm-astronaut-theme";
  # sddmThemeQt6 = true;
  defaultSession = "hyprland";
  multipleSessions = false;
  # defaultLockProgram = "swaylock";
  defaultLockProgram = "hyprlock";
  autoLogin = false;

  ttyFontSize = 9;
  ## Only 10 seems to get rid of the gaps in Foot terminal
  ttyLineHeight = 10;
  trolltechFontSize = 10;
  # dpi = 190;
  dpi = 210;
  # dpiSddm = 210;
  # dpiLaptop = 210;
  wallpaper = ../../wallpapers/tokyo-park.jpeg;

  defaultBrowser = "chromium-browser";
  # defaultBrowser = "firefox";

  useHyprlandFlake = false;

  virtualboxEnabled = false;

  # This thing sucks, requires manually downloading vmware first
  ## Message
  # > Unfortunately, we cannot download file VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle automatically.
  # > Please go to https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true to download it yourself, and add it to the Nix store
  # > using either
  # >   nix-store --add-fixed sha256 VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle
  # > or
  # >   nix-prefetch-url --type sha256 file:///path/to/VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle
  vmwareEnabled = false;

  waydroidEnabled = false;

  waydroid = {
    # width = 3400;
    # height = 1860;
    width = 1600;
    height = 1000;
  };

  wireguardIp = "192.168.2.8";
}

