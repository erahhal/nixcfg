{ ... }:
{
  hostParams = {
    system = {
      hostName = "msi-linux";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      multipleSessions = true;
      ttyFontSize = 9.5;
      autoLogin = true;
      wallpaper = ../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
