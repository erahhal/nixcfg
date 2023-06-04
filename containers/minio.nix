{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.63";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    9000
    9001
  ];

  virtualisation.oci-containers.containers = {
    minio = {
      image = "quay.io/minio/minio:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      cmd = [
        "server"
        "/data"
        # "--console-address=\"0.0.0.0:9001\""
      ];
      ports = [
        "${service_ip}:9000:9000"
        "${service_ip}:9001:9001"
      ];
      volumes = [
        "/mnt/ellis/s3:/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };
  };
}
