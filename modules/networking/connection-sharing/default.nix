{ config, lib, ... }:
let
  cfg = config.nixcfg.networking.connection-sharing;
in
{
  key = "nixcfg/networking/connection-sharing";

  options.nixcfg.networking.connection-sharing.enable = lib.mkEnableOption "DNS/DHCP sharing for nixos-anywhere installs";

  config = lib.mkIf cfg.enable {
    services.resolved.settings = {
      Resolve = {
        DNSStubListenerExtra = [
          "[::1]:53"
          "0.0.0.0:53"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      53   # DNS
    ];

    networking.firewall.allowedUDPPorts = [
      53   # DNS
      67   # DHCP
    ];
  };
}
