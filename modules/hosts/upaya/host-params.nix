{ ... }:
{
  hostParams = {
    system = {
      hostName = "upaya";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      dpi = 210;
      wallpaper = ../../../wallpapers/yellowstone.jpg;
    };

    services = {
      nfs-mounts.enable = true;
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
