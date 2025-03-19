{ config, lib, pkgs, hostParams, userParams, recursiveMerge, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.86";
  network = "xbrowsersync_network";
  pod = "xbrowsersync_pod";
  pod_ports = [
    "${service_ip}:80:8080"
  ];
  db_user = "root";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    80
  ];

  systemd.services = if hostParams.containerBackend == "docker" then {
    "docker-init-network-${network}" = {
      description = "Create docker network bridge: ${network}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      script = let cli = "${pkgs.docker}/bin/docker";
               in ''
                 if [ "${network}" == "host" ]; then
                   exit 0
                 fi
                 # Put a true at the end to prevent getting non-zero return code, which will
                 # crash the whole service.
                 check=$(${cli} network ls | grep "${network}")
                 if [ -z "$check" ]; then
                   ${cli} network create ${network}
                 else
                   echo "container ${network} already exists"
                   exit 0
                 fi
               '';
    };
  } else {
    systemd.services."podman-init-pod-${pod}" = {
      description = "Create podman pod: ${pod}";
      after = [ "network.target" "podman.service" ];
      requires = [ "systemd-networkd-wait-online.service" ];
      wantedBy = [ "multi-user.target" ];

      # @TODO: This script is not idempotent.  If ports change, then the containers
      #        need to be stopped, then the pod removed before running this again
      serviceConfig.Type = "oneshot";
      script = let
                  cli = "${config.virtualisation.podman.package}/bin/podman";
                  concat = lib.foldr (a: b: " -p ${a}" + b) "";
               in ''
                 # Put a true at the end to prevent getting non-zero return code, which will
                 # crash the whole service.
                 check=$(${cli} pod ls | grep "${pod}" || true)
                 if [ -z "$check" ]; then
                   ${cli} pod create --name ${pod} ${concat pod_ports}
                 else
                   echo "pod ${pod} already exists"
                 fi
               '';
    };
  };

  virtualisation.oci-containers.containers = {
    xbrowsersync = (
    let
      baseConfig = {
        image = "xbrowsersync/api:latest";
        extraOptions = [
          "--pull=always"
          "--env-file=${config.age.secrets.docker.path}"
        ];
        dependsOn = [
          "xbrowsersync-mongodb"
        ];
        volumes = [
          "${containerDataPath}/xbrowsersync/settings.json:/usr/src/api/config/settings.json"
        ];
        environment = {
          TZ = "America/Los_Angeles";
          PUID = toString hostParams.uid;
          PGID = toString hostParams.gid;
          XBROWSERSYNC_DB_USER = db_user;
        };
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
        ports = [
          "${service_ip}:80:8080"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    xbrowsersync-mongodb = (
    let
      baseConfig = {
        image = "mongo:latest";
        extraOptions = [
          "--pull=always"
          "--env-file=${config.age.secrets.docker.path}"
        ];
        volumes = [
          "${containerDataPath}/xbrowsersync/mongodb:/data/db"
        ];
        environment = {
          TZ = "America/Los_Angeles";
          PUID = toString hostParams.uid;
          PGID = toString hostParams.gid;
          MONGO_INITDB_ROOT_USERNAME = db_user;
        };
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );
  };
}
