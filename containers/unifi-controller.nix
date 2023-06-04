{ config, pkgs, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
in
{
  virtualisation.oci-containers.containers = {
    unifi-controller = {
      image = "linuxserver/unifi-controller:latest";
      # image = "linuxserver/unifi-controller:6.5.55";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "3478:3478/udp"
        "10001:10001/udp"
        "8080:8080"
        ## Used by smokeping
        # "8081:8081"
        "8443:8443"
        "8843:8843"
        "8880:8880"
        "6789:6789"
      ];
      volumes = [
        "${containerDataPath}/unifi/config:/config"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString userParams.uid;
        PGID = toString userParams.gid;
      };
    };
  };
}
