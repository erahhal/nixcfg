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
  service_ip = "10.0.0.69";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    9980
  ];

  virtualisation.oci-containers.containers = {
    collabora = {
      image = "collabora/code:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:9980:9980"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
