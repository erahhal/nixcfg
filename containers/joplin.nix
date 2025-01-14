{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.76";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    joplin = {
      image = "joplin/server:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:22300:22300"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        DB_CLIENT = "pg";
        POSTGRES_DATABASE = "joplin";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PORT = "5432";
        POSTGRES_HOST = "postgres.lan";
        APP_BASE_URL = "https://joplin.rahh.al";
        TZ = "America/Los_Angeles";
      };
    };
  };
}
