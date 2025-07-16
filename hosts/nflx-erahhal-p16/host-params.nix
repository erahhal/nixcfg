{ ... }:
{
  hostParams = {
    system = {
      hostName = "nflx-erahhal-p16";
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
    };
  };
}
