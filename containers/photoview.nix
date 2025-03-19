{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.xx";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    3306
  ];

  virtualisation.oci-containers.containers = {
    photoview-mariadb = {
      image = "mariadb:10.5";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:3306:3306"
      ];
      volumes = [
        "${containerDataPath}/photoview/db:/var/lib/mysql"
      ];
      environment = {
        MYSQL_DATABASE = "photoview";
        MYSQL_USER = "photoview";
        MYSQL_RANDOM_ROOT_PASSWORD = "1";
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };

    photoview = {
      image = "viktorstrate/photoview:latest";
      dependsOn = [
        "photoview-mariadb"
      ];
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/photoview/api_cache:/app/cache"
        "/mnt/ellis/Photos - to sort:/photos:ro"
      ];
      environment = {
        PHOTOVIEW_DATABASE_DRIVER = "mysql";
        PHOTOVIEW_LISTEN_IP = "photoview";
        PHOTOVIEW_LISTEN_PORT = "80";
        PHOTOVIEW_MEDIA_CACHE = "/app/cache";
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
