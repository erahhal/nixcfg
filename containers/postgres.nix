# To create a DB
#
#   nix-shell -p postgresql
#   createdb -h postgres -U nextcloud <dbname>
#
# or:
#
#   psql -h postgres -U nextcloud -c 'create database test;'
#
# Client:
#
#   psql -h postgres -U nextcloud [-d <database>]

{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.75";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  # Cross-container communication doesn't work without this
  networking.firewall.allowedTCPPorts = [
    5432
  ];

  virtualisation.oci-containers.containers = {
    postgres = {
      image = "postgres:13.4";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:5432:5432"
      ];
      volumes = [
        "${containerDataPath}/postgres:/var/lib/postgresql/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        POSTGRES_USER = "nextcloud";
        POSTGRES_DB = "nextcloud";
      };
    };
  };
}
