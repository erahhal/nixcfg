{ ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale/key";
    authKeyParameters = {
      preauthorized = true;
      baseURL = "https://headscale.homefree.host";
    };
    extraUpFlags = [
      "--accept-routes"
    ];
  };
}
