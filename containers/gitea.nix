{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.82";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    gitea = {
      image = "gitea/gitea:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:3000"
        "${service_ip}:222:22"
      ];
      volumes = [
        "${containerDataPath}/gitea:/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
