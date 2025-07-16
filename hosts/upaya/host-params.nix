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
      swayTouchpadClickMethod = "button_areas";
      wallpaper = ../../wallpapers/teundenouden-polar-gilds-darkened-CC-BY-NC-ND-3.0.png;
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
