{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.73";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  # Cross-container communication doesn't work without this
  networking.firewall.allowedTCPPorts = [
    6379
  ];

  virtualisation.oci-containers.containers = {
    redis = {
      image = "docker.io/library/redis:alpine";
      # cmd = [ "--save 60 1 --loglevel warning" ];
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:6379:6379"
      ];
      volumes = [
        "${containerDataPath}/redis:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
