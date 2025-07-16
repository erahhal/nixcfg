{ ... }:
{
  hostParams = {
    system = {
      hostName = "sicmundus";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      defaultSession = "none";
    };

    # mainInterface = "enp4s0f0";
  };
}
