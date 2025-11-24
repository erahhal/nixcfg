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
      dpi = 192;
      autoLogin = true;
      wallpaper = ../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
    };

    programs = {
      steam = {
        enableGamescope = true;
      };
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
      intel.disableModules = false;
    };
  };
}
