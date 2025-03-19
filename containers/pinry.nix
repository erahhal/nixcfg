{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.90";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    pinry = {
      image = "getpinry/pinry:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/pinry:/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
