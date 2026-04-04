{ ... }:
{
  system.stateVersion = "24.11";

  nixcfg = {
    networking.tailscale.enable = true;
  };
}
