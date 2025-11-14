{
  services.gammastep = {
    enable = true;
    provider = "manual";
    # provider = "geoclue2";
    latitude = "34.0522";
    longitude = "-118.2437";
    temperature.day = 6500;
    temperature.night = 4500;
    tray = true;
  };
}
