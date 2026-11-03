{ ... }:
{
  hostParams = {
    system = {
      hostName = "upaya";
    };

    networking = {
      tailscale.enable = true;
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      displayManager = "dms";
      defaultSession = "niri";
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
