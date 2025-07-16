{ ... }:
{
  hostParams = {
    system = {
      hostName = "antikythera";
      uid = 1026;
      gid = 100;
    };

    desktop = {
      multipleSessions = true;
      dpi = 192;
      wallpaper = ../../wallpapers/yellowstone.jpg;
    };

    programs = {
      steam = {
        enableGamescope = true;
      };
    };

    gpu = {
      amd.enable = true;
    };
  };
}
