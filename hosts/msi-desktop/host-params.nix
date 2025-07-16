{ ... }:
{
  hostParams = {
    system = {
      hostName = "msi-desktop";
    };

    gpu = {
      # WSL doesn't need graphics drivers
      nvidia.enable = false;
      intel.enable = false;
    };
  };
}
