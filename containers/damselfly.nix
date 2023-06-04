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
    damselfly = {
      image = "webreaper/damselfly:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:6363"
      ];
      volumes = [
        "${containerDataPath}/damselfly/config:/config"
        "${containerDataPath}/damselfly/thumbs:/thumbs"
        "/mnt/ellis/Photos - to sort:/pictures"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
