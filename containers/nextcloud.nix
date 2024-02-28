{ config, lib, pkgs, hostParams, userParams, recursiveMerge, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.89";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    nextcloud = {
      image = "nextcloud:latest";
      extraOptions = [
        "--pull=always"
        "--dns=10.0.0.1"
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
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PORT = "5432";
        POSTGRES_HOST = "postgres.localdomain";
        VIRTUAL_HOST = "nextcloud";
        TZ = "America/Los_Angeles";
      };
      ports = [
        "${service_ip}:80:80"
      ];
    };
  };

  systemd.services.nextcloud-cron = {
    enable = true;
    description = "Run Nextcloud janitor";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.docker}/bin/docker exec -u www-data nextcloud php -f /var/www/html/cron.php
    '';
  };
  systemd.timers.nextcloud-cron = {
    wantedBy = [ "timers.target" ];
    partOf = [ "nextcloud-cron.service" ];
    timerConfig = {
      # Every 15 minutes
      OnCalendar = "*:0/15";
      Unit = "nextcloud-cron.service";
    };
  };
}
