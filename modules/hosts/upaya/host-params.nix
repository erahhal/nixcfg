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

      # Mod+G cycles the ThinkVision between this machine (on the TB4 dock,
      # DisplayPort-1) and whatever is on its other input. Same dock spot and
      # codes as nflx-erahhal-p16.
      ddcInputToggle = {
        enable = true;
        title = "Switch ThinkVision Monitor Input";
        monitor = "P40w-20";
        inputs = [
          { code = "0x0f"; label = "DisplayPort-1"; }
          { code = "0x31"; label = "HDMI-2"; }
        ];
      };
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
