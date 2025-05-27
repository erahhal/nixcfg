{ ... }:
{
  services.synergy = {
    client = {
      enable = true;
      screenName = "nflx-erahhal-t490s";
      # port 24800 is default and is optionally added here
      serverAddress = "upaya:24800";
      autoStart = true;
    };
  };
}
