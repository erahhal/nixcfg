{ config, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.71";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    cryptpad = {
      image = "promasu/cryptpad:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      ports = [
        "${service_ip}:3000:3000"
        "${service_ip}:3001:3001"
      ];
      volumes = [
        "${containerDataPath}/cryptpad/config.js:/cryptpad/config/config.js"
        "${containerDataPath}/cryptpad/customize:/cryptpad/customize"
        "${containerDataPath}/cryptpad/data/blob:/cryptpad/blob"
        "${containerDataPath}/cryptpad/data/block:/cryptpad/block"
        "${containerDataPath}/cryptpad/data/data:/cryptpad/data"
        "${containerDataPath}/cryptpad/data/files:/cryptpad/datastore"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };

  ## Couldn't get websockets to work behind OPNSense's HAProxy
  #
  # virtualisation.oci-containers.containers = {
  #   cryptpad = {
  #     image = "promasu/cryptpad:nginx";
  #     extraOptions = [
  #       "--pull=always"
  #       "--env-file=${config.age.secrets.docker.path}"
  #     ];
  #     ports = [
  #       "${service_ip}:80:80"
  #     ];
  #     volumes = [
  #       "${containerDataPath}/cryptpad/config.js:/cryptpad/config/config.js"
  #       "${containerDataPath}/cryptpad/customize:/cryptpad/customize"
  #       "${containerDataPath}/cryptpad/data/blob:/cryptpad/blob"
  #       "${containerDataPath}/cryptpad/data/block:/cryptpad/block"
  #       "${containerDataPath}/cryptpad/data/data:/cryptpad/data"
  #       "${containerDataPath}/cryptpad/data/files:/cryptpad/datastore"
  #     ];
  #     environment = {
  #       CPAD_MAIN_DOMAIN = "cryptpad.rahh.al";
  #       CPAD_SANDBOX_DOMAIN = "cryptpad-sandbox.rahh.al";
  #       CPAD_TRUSTED_PROXY = "10.0.0.0/8";
  #       CPAD_REALIP_HEADER = "X-Forwarded-For";
  #       CPAD_REALIP_RECURSIVE = "on";
  #     };
  #   };
  # };
}
