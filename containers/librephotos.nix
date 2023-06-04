{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.67";
  network = "librephotos_network";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  systemd.services = {
    "docker-init-network-${network}" = {
      description = "Create docker network bridge: ${network}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      script = let cli = "${config.virtualisation.docker.package}/bin/docker";
               in ''
                 if [ "${network}" == "host" ]; then
                   exit 0
                 fi
                 # Put a true at the end to prevent getting non-zero return code, which will
                 # crash the whole service.
                 check=$(${cli} network ls | grep "${network}" || true)
                 if [ -z "$check" ]; then
                   ${cli} network create ${network}
                 else
                   echo "container ${network} already exists"
                 fi
               '';
    };
  };

  virtualisation.oci-containers.containers = {
    librephotos-proxy = {
      image = "reallibrephotos/librephotos-proxy:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      dependsOn = [
        "init-network-${network}"
        "librephotos-backend"
        "librephotos-frontend"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "/mnt/ellis/Photos - to sort:/data"
        "${containerDataPath}/librephotos/protected_media:/protected_media"
      ];
    };

    # @TODO: How to avoid using such a generic name
    frontend = {
      image = "reallibrephotos/librephotos-frontend:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      dependsOn = [
        "init-network-${network}"
        "librephotos-backend"
      ];
    };

    # @TODO: How to avoid using such a generic name
    backend = {
      image = "reallibrephotos/librephotos:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      dependsOn = [
        "init-network-${network}"
        "postgres"
      ];
      volumes = [
        "/mnt/ellis/Photos - to sort:/data"
        "${containerDataPath}/librephotos/protected_media:/protected_media"
        "${containerDataPath}/librephotos/logs:/logs"
        "${containerDataPath}/librephotos/cache:/root/.cache"

        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        BACKEND_HOST = "backend";
        DB_BACKEND = "postgresql";
        DB_NAME = "librephotos";
        DB_USER = "nextcloud";
        DB_HOST = "postgres.localdomain";
        DB_PORT = "5432";
        REDIS_HOST = "redis.localdomain";
        REDIS_PORT = "6379";
        # MAPBOX_API_KEY = "${mapApiKey}";
        WEB_CONCURRENCY = "2";
        SKIP_PATTERNS = "@eaDir,#recycle";
        ALLOW_UPLOAD = "true";
        DEBUG = "0";
        HEAVYWEIGHT_PROCESS = "2";

        TZ = "America/Los_Angeles";
      };
    };
  };
}
