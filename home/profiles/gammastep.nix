{
  services.gammastep = {
    enable = true;
    ## latitude = "34.0522";
    # provider = "manual";
    provider = "geoclue2";
     longitude = "-118.2437";
    temperature.day = 6500;
    temperature.night = 3600;
    tray = true;
  };
}
