{ config, pkgs, hostParams, userParams, ... }:
## Reference:
#
#   https://github.com/ONLYOFFICE/Docker-CommunityServer/blob/master/docker-compose.workspace.yml
#
## Why NOT to use OnlyOffice:
#
#   https://github.com/ONLYOFFICE/DocumentServer/issues/805

let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.70";
  network = "onlyoffice_network";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    80
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
    onlyoffice-mysql-server = {
      image = "mysql:8.0.29";
      dependsOn = [
        "init-network-${network}"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
        "--tmpfs=/var/log/mysql"
      ];
      volumes = [
        "${containerDataPath}/onlyoffice/mysql/conf.d:/etc/mysql/conf.d"
        "${containerDataPath}/onlyoffice/mysql/initdb:/docker-entrypoint-initdb.d"
        "${containerDataPath}/onlyoffice/mysql/data:/var/lib/mysql"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        MYSQL_DATABASE = "onlyoffice";
      };
    };

    onlyoffice-elasticsearch = {
      image = "onlyoffice/elasticsearch:latest";
      dependsOn = [
        "init-network-${network}"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
        "--ulimit=memlock=-1:-1"
        "--ulimit=nofile=65535:65535"
      ];
      volumes = [
        "${containerDataPath}/onlyoffice/elasticsearch:/usr/share/elasticsearch/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        "discovery.type" = "single-node";
        "bootstrap.memory_lock" = "true";
        "ES_JAVA_OPTS" = "-Xms1g -Xmx1g -Dlog4j2.formatMsgNoLookups=true";
        "indices.fielddata.cache.size" = "30%";
        "indices.memory.index_buffer_size" = "30%";
      };
    };

    onlyoffice-document-server = {
      image = "onlyoffice/documentserver:latest";
      dependsOn = [
        "init-network-${network}"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      volumes = [
        "${containerDataPath}/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data"
        "${containerDataPath}/onlyoffice/DocumentServer/logs:/var/log/onlyoffice"
        "${containerDataPath}/onlyoffice/DocumentServer/fonts:/usr/share/fonts/truetype/custom"
        "${containerDataPath}/onlyoffice/DocumentServer/forgotten:/var/lib/onlyoffice/documentserver/App_Data/cache/files/forgotten"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        JWT_ENABLED = "true";
        JWT_HEADER = "AuthorizationJwt";
        # DB_TYPE = "postgres";
        # DB_HOST = "postgres.lan";
        # DB_PORT = "5432";
        # DB_NAME = "onlyoffice";
        # DB_USER = "nextcloud";
        # REDIS_SERVER_HOST = "redis.lan";
        # REDIS_SERVER_PORT = "6379";
      };
    };

    onlyoffice-community-server = {
      image = "onlyoffice/communityserver:latest";
      dependsOn = [
        "init-network-${network}"
        "onlyoffice-mysql-server"
        "onlyoffice-document-server"
        "onlyoffice-elasticsearch"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
        "--cgroupns=host"
        "--privileged"
      ];
      ports = [
        "${service_ip}:80:80"
        "${service_ip}:443:443"
        "${service_ip}:5222:5222"
      ];
      volumes = [
        "${containerDataPath}/onlyoffice/CommunityServer/data:/var/www/onlyoffice/Data"
        "${containerDataPath}/onlyoffice/CommunityServer/logs:/var/log/onlyoffice"
        "${containerDataPath}/onlyoffice/DocumentServer/data:/var/www/onlyoffice/DocumentServerData"
        "${containerDataPath}/onlyoffice/certs:/var/www/onlyoffice/Data/certs"
        "/sys/fs/cgroup:/sys/fs/cgroup:rw"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        CONTROL_PANEL_PORT_80_TCP = "80";
        CONTROL_PANEL_PORT_80_TCP_ADDR = "onlyoffice-control-panel";
        DOCUMENT_SERVER_PORT_80_TCP_ADDR = "onlyoffice-document-server";
        DOCUMENT_SERVER_JWT_ENABLED = "true";
        DOCUMENT_SERVER_JWT_HEADER = "AuthorizationJwt";
        MYSQL_SERVER_DB_NAME = "onlyoffice";
        MYSQL_SERVER_HOST = "onlyoffice-mysql-server";
        MYSQL_SERVER_USER = "root";
        ELASTICSEARCH_SERVER_HOST = "onlyoffice-elasticsearch";
        ELASTICSEARCH_SERVER_HTTPPORT = "9200";
      };
    };

    onlyoffice-control-panel = {
      image = "onlyoffice/controlpanel:latest";
      dependsOn = [
        "init-network-${network}"
        "onlyoffice-document-server"
        "onlyoffice-community-server"
      ];
      extraOptions = [
        "--network=${network}"
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      volumes = [
        "${containerDataPath}/onlyoffice/ControlPanel/data:/var/www/onlyoffice/Data"
        "${containerDataPath}/onlyoffice/ControlPanel/logs:/var/log/onlyoffice"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
