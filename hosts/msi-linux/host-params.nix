{ ... }:
{
  hostParams = {
    system = {
      hostName = "msi-desktop";
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
