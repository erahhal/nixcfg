{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
    8080
    8443
  ];

  networking.extraHosts = ''
    127.0.0.1 homefree.lan
    127.0.0.1 radicale.homefree.lan
    127.0.0.1 auth.homefree.lan
    127.0.0.1 authentik.homefree.lan
    127.0.0.1 vaultwarden.homefree.lan
    127.0.0.1 homeassistant.homefree.lan
    127.0.0.1 ha.homefree.lan
  '';
}
