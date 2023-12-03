{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.62";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    logseq = {
      image = "ghcr.io/logseq/logseq-webapp:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
