{ config, ... }:
{
  nixcfg-niri.desktop.weather = {
    location = config.hostParams.desktop.location;
    coordinates = config.hostParams.desktop.coordinates;
    useFahrenheit = config.hostParams.desktop.useFahrenheit;
  };

  nixcfg-niri.desktop.killOnExit = config.hostParams.desktop.killOnExit;

  nixcfg-niri.desktop.cycleColumnsOnRepeatedWorkspaceFocus =
    config.hostParams.desktop.cycleColumnsOnRepeatedWorkspaceFocus;

  # Hybrid Intel+NVIDIA laptops: force startup-apps onto the Intel iGPU so screen
  # sharing works. AMD-only or single-GPU hosts skip this (sets wrong driver).
  nixcfg-niri.desktop.startupAppsForceIntelGpu =
    config.hostParams.gpu.intel.enable && config.hostParams.gpu.nvidia.enable;

  nixcfg-niri.desktop.terminal = config.hostParams.user.tty;
  nixcfg-niri.desktop.themeToggleCommand = "toggle-theme";

  nixcfg-niri.desktop.easyeffects = {
    enable = config.hostParams.desktop.easyeffects.enable;
    generic = true;
    headphoneProfiles = true;
    laptopSpeakers = true;
    dolbyAtmos = true;
    thinkpadDolby = true;
  };

  nixcfg-niri.desktop.persona.enable = config.hostParams.desktop.persona.enable;

  nixcfg-niri.desktop.hyprComp.enable = config.hostParams.desktop.hyprComp.enable;

  nixcfg-niri.desktop.greyline.enable = config.hostParams.desktop.greyline.enable;

  nixcfg-niri.desktop.greyline.settings = {
    # Hide the bottom-left corner logo (bundled default is Tux).
    logo = false;

    # greyline matches the "home" city by timezone, not name. Pin it to LA's tz
    # so the Los Angeles entry below gets the home dot/label/column highlight.
    home.tz = "America/Los_Angeles";

    # A user city list REPLACES greyline's bundled list wholesale, so restate the
    # full set. This mirrors the upstream default with Los Angeles swapped in for
    # San Francisco — both share America/Los_Angeles, so SF can't stay without
    # also grabbing the home highlight.
    city = [
      { name = "Los Angeles";  lat = 34.05;  lon = -118.24; tz = "America/Los_Angeles"; }
      { name = "New York";     lat = 40.71;  lon = -74.01;  tz = "America/New_York"; }
      { name = "Buenos Aires"; lat = -34.61; lon = -58.38;  tz = "America/Argentina/Buenos_Aires"; }
      { name = "London";       lat = 51.51;  lon = -0.13;   tz = "Europe/London"; }
      { name = "Paris";        lat = 48.85;  lon = 2.35;    tz = "Europe/Paris"; }
      { name = "Moscow";       lat = 55.76;  lon = 37.62;   tz = "Europe/Moscow"; }
      { name = "Beijing";      lat = 39.90;  lon = 116.41;  tz = "Asia/Shanghai"; }
      { name = "Tokyo";        lat = 35.68;  lon = 139.69;  tz = "Asia/Tokyo"; }
      { name = "Jakarta";      lat = -6.21;  lon = 106.85;  tz = "Asia/Jakarta"; }
      { name = "Sydney";       lat = -33.87; lon = 151.21;  tz = "Australia/Sydney"; }
    ];
  };
}
