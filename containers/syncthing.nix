{ hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.85";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    syncthing = {
      image = "lscr.io/linuxserver/syncthing:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:8384"
        "${service_ip}:22000:22000/tcp"
        "${service_ip}:22000:22000/udp"
        "${service_ip}:21027:21027/udp"
      ];
      volumes = [
        "${containerDataPath}/syncthing:/config"
        "/mnt/ellis:/sync-data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
