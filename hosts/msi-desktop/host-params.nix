{ ... }:
{
  hostParams = {
    system = {
      hostName = "msi-desktop";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      defaultSession = "none";
      dpi = 192;
    };

    gpu = {
      # WSL doesn't need graphics drivers
      nvidia.enable = false;
      intel.enable = false;
    };
  };
}
