{ ... }:
{
  services.resolved = {
    ## Listen on all IP addresses
    ## @TODO: Replace with socat in eth-share.sh
    settings = {
      Resolve = {
        DNSStubListenerExtra = [
          "[::1]:53"
          "0.0.0.0:53"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    53   # DNS
  ];

  networking.firewall.allowedUDPPorts = [
    53   # DNS
    67   # DHCP
  ];
}
