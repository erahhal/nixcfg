{ config, pkgs, hostParams, userParams, ... }:

let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.68";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    libreoffice = {
      image = "linuxserver/libreoffice:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:80:3000"
      ];
      volumes = [
        "${containerDataPath}/libreoffice:/config"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
