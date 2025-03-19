{ hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.83";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    drawio = {
      image = "fjudith/draw.io:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:8080"
        "${service_ip}:443:8443"
      ];
      volumes = [
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
