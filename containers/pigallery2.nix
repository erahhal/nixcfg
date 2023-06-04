{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.xx";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    pigallery2 = {
      image = "bpatrik/pigallery2:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/pigallery2/config:/app/data/config"
        "${containerDataPath}/pigallery2/db:/app/data/db"
        "/mnt/ellis/Photos - to sort:/app/data/images"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
