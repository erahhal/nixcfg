{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  network = "nextcloud_network";
  service_ip = "10.0.0.89";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  systemd.services."init-docker-network-${network}" = {
    description = "Create docker network bridge: ${network}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    script = let dockercli = "${config.virtualisation.docker.package}/bin/docker";
             in ''
               # Put a true at the end to prevent getting non-zero return code, which will
               # crash the whole service.
               check=$(${dockercli} network ls | grep "${network}" || true)
               if [ -z "$check" ]; then
                 ${dockercli} network create ${network}
               else
                 echo "${network} already exists in docker"
               fi
             '';
  };

  virtualisation.oci-containers.containers = {
    proxy = {
      # image = "nginx-proxy/nginx-proxy:alpine";
      image = "jwilder/nginx-proxy:alpine";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      ports = [
        "${service_ip}:80:80"
        "${service_ip}:443:443"
      ];
      volumes = [
        "${containerDataPath}/nextcloud/proxy/conf.d:/etc/nginx/conf.d:rw"
        "${containerDataPath}/nextcloud/proxy/vhost.d:/etc/nginx/vhost.d:rw"
        "${containerDataPath}/nextcloud/proxy/html:/usr/share/nginx/html:rw"
        "${containerDataPath}/nextcloud/proxy/certs:/etc/nginx/certs:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/var/run/docker.sock:/tmp/docker.sock:ro"
      ];
    };

    letsencrypt = {
      # image = "nginx-proxy/acme-companion:latest";
      image = "jrcs/letsencrypt-nginx-proxy-companion:latest";
      dependsOn = [
        "proxy"
      ];
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      volumes = [
        "${containerDataPath}/nextcloud/proxy/certs:/etc/nginx/certs:rw"
        "${containerDataPath}/nextcloud/proxy/vhost.d:/etc/nginx/vhost.d:rw"
        "${containerDataPath}/nextcloud/proxy/html:/usr/share/nginx/html:rw"
        "/etc/localtime:/etc/localtime:ro"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environment = {
        NGINX_PROXY_CONTAINER = "proxy";
      };
    };

    postgres = {
      image = "postgres:13.4";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      volumes = [
        "${containerDataPath}/nextcloud/db:/var/lib/postgresql/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        POSTGRES_USER = "nextcloud";
        POSTGRES_DB = "nextcloud";
      };
    };

    nextcloud = {
      image = "nextcloud:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      dependsOn = [
        "letsencrypt"
        "proxy"
        "postgres"
      ];
      volumes = [
        "${containerDataPath}/nextcloud/nextcloud:/var/www/html"
        "${containerDataPath}/nextcloud/app/config:/var/www/html/config"
        "${containerDataPath}/nextcloud/app/custom_apps:/var/www/html/custom_apps"
        "${containerDataPath}/nextcloud/app/data:/var/www/html/data"
        "${containerDataPath}/nextcloud/app/themes:/var/www/html/themes"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        VIRTUAL_HOST = "nextcloud.rahh.al";
        LETSENCRYPT_HOST = "nextcloud.rahh.al";
        LETSENCRYPT_EMAIL = "ellis@rahh.al";
      };
    };

    syncthing = {
      image = "lscr.io/linuxserver/syncthing:latest";
      extraOptions = [
        "--pull=always"
        "--network=${network}"
      ];
      ports = [
        "${service_ip}:8384:8384"
        "${service_ip}:22000:22000/tcp"
        "${service_ip}:22000:22000/udp"
        "${service_ip}:21027:21027/udp"
      ];
      volumes = [
        "${containerDataPath}/nextcloud/syncthing:/config"
        "${containerDataPath}/nextcloud/app/data:/nextcloud-data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        # @TODO: Get these through vars or programmatically?
        PUID = "33";  # "www-data" user
        PGID = "994"; # "users" group
      };
    };
  };
}
