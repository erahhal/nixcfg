{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.87";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "jellyfin/jellyfin:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:8096"
        "${service_ip}:443:8920"
        "${service_ip}:1900:1900/udp"
        "${service_ip}:7359:7359/udp"
      ];
      volumes = [
        "${containerDataPath}/jellyfin/config:/config"
        "${containerDataPath}/jellyfin/cache:/cache"
        "/mnt/ellis/Media:/media"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
