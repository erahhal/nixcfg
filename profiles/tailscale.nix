{ ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale/key";
    authKeyParameters = {
      preauthorized = true;
      baseURL = "https://vpn.homefree.host";
    };
    extraUpFlags = [
      "--accept-routes"
      "--netfilter-mode=nodivert"
      "--login-server=https://vpn.homefree.host"
    ];
  };
}
