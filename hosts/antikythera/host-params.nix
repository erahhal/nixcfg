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
      defaultSession = "niri";
      dpi = 192;
      wallpaper = ../../wallpapers/yellowstone.jpg;
      disableXwaylandScaling = true;
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
