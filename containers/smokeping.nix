{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.88";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    smokeping = {
      image = "dperson/smokeping:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/smokeping/config.d:/etc/smokeping/config.d"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        EMAIL = "ellis@rahh.al";
        OWNER = "Ellis Rahhal";
      };
    };
  };
}
