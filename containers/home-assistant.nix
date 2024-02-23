{ config, hostParams, userParams, recursiveMerge, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  # network = "homeassistant_network";
  network = "host";
  pod = "homeassistant_pod";
  pod_ports = [
    "8123:8123/tcp"
    "3000:3000/tcp"
    "3000:3000/udp"
    "8091:8091/tcp"
    "8091:8091/udp"
    "1883:1883/tcp"
    "1883:1883/udp"
    "9001:9001/tcp"
    "9001:9001/udp"
  ];
in
{
  networking.firewall.allowedTCPPorts = [
    # Home Assistant
    8123

    # zwavejs2mqtt
    3000
    8091

    # eclipse-mosquitto
    1883
    9001
  ];

  systemd.services = if hostParams.containerBackend == "docker" then {
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
  } else {
    "podman-init-pod-${pod}" = {
      description = "Create podman pod: ${pod}";
      after = [ "network.target" "podman.service" ];
      requires = [ "systemd-networkd-wait-online.service" ];
      wantedBy = [ "multi-user.target" ];

      # @TODO: This script is not idempotent.  If ports change, then the containers
      #        need to be stopped, then the pod removed before running this again
      # @TODO: Maybe it *is* idempotent. During build all containers are stopped
      #        and then started again, so this might work.
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
    home-assistant = (
    let
      baseConfig = {
        image = "homeassistant/home-assistant:latest";
        dependsOn = [
          "zwavejs2mqtt"
          "eclipse-mosquitto"
        ];
        extraOptions = [
          "--pull=always"
          "--dns-opt='options single-request'"
        ];
        # user = "1026:100";
        volumes = [
          "${containerDataPath}/home-assistant/config:/config"
          "${containerDataPath}/home-assistant/config/docker/run:/etc/services.d/home-assistant/run"
          "/run:/run-external"
          "/run/agenix.d:/run/agenix.d"
        ];
        environment = {
          TZ = "America/Los_Angeles";
          PUID = toString userParams.uid;
          GUID = toString userParams.gid;
          PGID = toString userParams.gid;
          PACKAGES = "iputils";
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
          "8123:8123"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    zwavejs2mqtt = (
    let
      baseConfig = {
        image = "zwavejs/zwavejs2mqtt:latest";
        dependsOn = [
          "eclipse-mosquitto"
        ];
        extraOptions = [
          "--pull=always"
          "--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
        volumes = [
          "${containerDataPath}/home-assistant/config-zwavejs2mqtt:/usr/src/app/store"
        ];
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
          "3000:3000"
          "8091:8091"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    eclipse-mosquitto = (
    let
      baseConfig = {
        image = "eclipse-mosquitto:latest";
        extraOptions = [
          "--pull=always"
        ];
        volumes = [
          "${containerDataPath}/home-assistant/mqtt/config:/mosquitto/config"
          "${containerDataPath}/home-assistant/mqtt/data:/mosquitto/data"
          "${containerDataPath}/home-assistant/mqtt/logs:/mosquitto/logs"
        ];
        environment = {
          TZ = "America/Los_Angeles";
          PUID = toString userParams.uid;
          PGID = toString userParams.gid;
          UMASK_SET = "000";
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
          "1883:1883"
          "9001:9001"
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
