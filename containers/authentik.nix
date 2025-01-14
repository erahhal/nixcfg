## See for initial setup:
#
#    https://goauthentik.io/docs/installation/docker-compose
#
## For HAProxy setup, only use 9443, otherwise CSRF errors occur,
## Hence, port 9000 is disabled below.
#


{ config, lib, pkgs, hostParams, userParams, recursiveMerge, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.74";
  network = "authentik_network";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    9000
    9443
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
    authentik-server = {
      image = "ghcr.io/goauthentik/server";
      cmd = [ "server" ];
      dependsOn = [
        "init-network-${network}"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      volumes = [
        "${containerDataPath}/authentik/media:/media"
        "${containerDataPath}/authentik/custom-templates:/templates"
        "${containerDataPath}/geoip:/geoip"
      ];
      environment = {
        AUTHENTIK_REDIS__HOST = "redis.lan";
        AUTHENTIK_POSTGRESQL__HOST = "postgres.lan";
        AUTHENTIK_POSTGRESQL__USER = "nextcloud";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
        AUTHENTIK_LOG_LEVEL = "trace";
      };
      ports = [
        "${service_ip}:9000:9000"
        "${service_ip}:9443:9443"
      ];
    };
  };

  virtualisation.oci-containers.containers = {
    authentik-worker = {
      image = "ghcr.io/goauthentik/server";
      cmd = [ "worker" ];
      dependsOn = [
        "init-network-${network}"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      user = "root";
      volumes = [
        "${containerDataPath}/authentik/media:/media"
        "${containerDataPath}/authentik/certs:/certs"
        "${containerDataPath}/authentik/custom-templates:/templates"
        "${containerDataPath}/geoip:/geoip"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      environment = {
        AUTHENTIK_REDIS__HOST = "redis.lan";
        AUTHENTIK_POSTGRESQL__HOST = "postgres.lan";
        AUTHENTIK_POSTGRESQL__USER = "nextcloud";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
      };
    };
  };

##  Outpost
##    Needs to be on a separate network
##    One per proxy?
#
#   virtualisation.oci-containers.containers = {
#     authentik-proxy = {
#       image = "ghcr.io/goauthentik/proxy";
#       dependsOn = [
#         "init-network-${network}"
#       ];
#       extraOptions = [
#         "--network=${network}"
#         "--pull=always"
#         "--env-file=${config.age.secrets.docker.path}"
#       ];
#       user = "root";
#       environment = {
#         AUTHENTIK_HOST = "https://authentik.rahh.al";
#         AUTHENTIK_INSECURE = "false";
#       };
#       ports = [
#         "${service_ip}:9000:9000"
#         "${service_ip}:9443:9443"
#       ];
#     };
#   };
}
