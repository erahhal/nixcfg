{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.64";
  vikunja_version = "0.20";
  network = "vikunja_network";
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
    vikunja = {
      image = "vikunja/frontend:${vikunja_version}";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      dependsOn = [
        "vikunja-api"
      ];
      # environment = {
      #   VIKUNJA_API_URL = "http://vikunja-api:3456/api/v1";
      # };
    };
    vikunja-api = {
      image = "vikunja/api:${vikunja_version}";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      dependsOn = [
        "mariadb"
      ];
      volumes = [
        "${containerDataPath}/vikunja/api:/app/vikunja/files"
      ];
      environment = {
        VIKUNJA_DATABASE_HOST = "mariadb";
        VIKUNJA_DATABASE_TYPE = "mysql";
        VIKUNJA_DATABASE_USER = "vikunja";
        VIKUNJA_DATABASE_DATABASE = "vikunja";
        VIKUNJA_SERVICE_FRONTENDURL = "https://vikunja.rahh.al/";
      };
    };
    vikunja-proxy = {
      image = "nginx:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      dependsOn = [
        "vikunja"
        "vikunja-api"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      ## @TODO: put this config into Nix
      # server {
      #   listen 80;

      #   location / {
      #       proxy_pass http://vikunja:80;
      #   }

      #   location ~* ^/(api|dav|\.well-known)/ {
      #       proxy_pass http://vikunja-api:3456;
      #       client_max_body_size 20M;
      #   }
      # }
      volumes = [
        "${containerDataPath}/vikunja/nginx.conf:/etc/nginx/conf.d/default.conf:ro"
      ];
    };
  };
}
