{ config, lib, ... }:
let
  cfg = config.nixcfg.networking.kdeconnect;
in {
  options.nixcfg.networking.kdeconnect = {
    enable = lib.mkEnableOption "KDE Connect firewall rules";
  };
  config = lib.mkIf cfg.enable {
    # KDE Connect requires these ports for device discovery and communication
    networking.firewall = rec {
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };
  };
}
