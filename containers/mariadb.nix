# To create a DB
#
#   nix-shell -p mariadb
#   mariadb -h mariadb -u root -p
#
# or:
#
#   mariadb -h mariadb -u root -c 'create database test;'
#
# CREATE DATABASE ${newDb}; CREATE USER '${newUser}'@'localhost' IDENTIFIED BY '${newDbPassword}'; GRANT USAGE ON *.* TO '${newUser}'@'localhost'; GRANT ALL ON ${newDb}.* TO '${newUser}'@'localhost'; FLUSH PRIVILEGES;"

{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.65";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  # Cross-container communication doesn't work without this
  networking.firewall.allowedTCPPorts = [
    3306
  ];

  virtualisation.oci-containers.containers = {
    mariadb = {
      image = "mariadb:10.9";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:3306:3306"
      ];
      volumes = [
        "${containerDataPath}/mariadb:/var/lib/mysql"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        MARIADB_AUTO_UPGRADE = "1";
        MARIADB_INITDB_SKIP_TZINFO = "1";
      };
    };
  };
}
