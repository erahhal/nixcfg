{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.79";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    vaultwarden = {
      image = "vaultwarden/server:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/vaultwarden:/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
