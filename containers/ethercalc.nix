{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.72";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    ethercalc = {
      image = "audreyt/ethercalc:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:80:8000"
      ];
      environment = {
        REDIS_PORT_6379_TCP_ADDR = "redis.lan";
        REDIS_PORT_6379_TCP_PORT = "6379";
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
