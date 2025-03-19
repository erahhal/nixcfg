{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.81";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    wikijs = {
      image = "ghcr.io/requarks/wiki:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:3000"
      ];
      volumes = [
        "${containerDataPath}/wikijs:/data"
      ];
      # user = "${toString hostParams.uid}:${toString hostParams.gid}";
      environment = {
        DB_TYPE = "sqlite";
        DB_FILEPATH ="/data/wikijs.sqlite";
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
