{ config, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.61";
  network = "wekan_network";
  db_user = "root";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    80
  ];

  systemd.services."docker-init-network-${network}" = {
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

  virtualisation.oci-containers.containers = {
    wekandb = {
      image = "mongo:6";
      extraOptions = [
        "--pull=always"
        "--network=${network}"

        ## Don't pass in secrets, as mongo would then expect a root username,
        ## since there is a mongo root password in the secrets file
        ## Wekan communicates with mongodb using the fact that mongodb accepts
        ## connections from localhost without need for authentication.
        ## If a username and password is desired, use a different .age secrets file.

        # "--env-file=${config.age.secrets.docker.path}"
      ];
      cmd = [
        "mongod"
        "--logpath"
        "/dev/null"
        "--oplogSize"
        "128"
        "--quiet"
      ];
      ports = [
        "${service_ip}:27017:27017"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/wekan/mongodb:/data/db"
        "${containerDataPath}/wekan/mongodb-dump/data/db"
      ];
      environment = {
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
      dependsOn = [
        "init-network-${network}"
      ];
    };

    wekan-app = {
      image = "ghcr.io/wekan/wekan:latest";
      extraOptions = [
        "--pull=always"
        # "--env-file=${config.age.secrets.docker.path}"
        "--network=${network}"
      ];
      ports = [
        "${service_ip}:80:8080"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/wekan/files:/data:rw"
      ];
      environment = {
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;

        # See: https://github.com/wekan/wekan/blob/main/docker-compose.yml
        WRITABLE_PATH = "/data";
        MONGO_URL = "mongodb://wekandb:27017/wekan";
        ROOT_URL = "http://${service_ip}";
        WITH_API = "true";
        RICHER_CARD_COMMENT_EDITOR = "false";
        CARD_OPENED_WEBHOOK_ENABLED = "false";
        BIGEVENTS_PATTERN = "NONE";
        BROWSER_POLICY_ENABLED = "true";
      };
      dependsOn = [
        "init-network-${network}"
        "wekandb"
      ];
    };
  };
}
