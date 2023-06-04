{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
in
{
  virtualisation.oci-containers.containers = {
    geoip = {
      image = "maxmindinc/geoipupdate:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
      ];
      volumes = [
        "${containerDataPath}/geoip:/usr/share/GeoIP"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        ## This won't work without a license key
        ## See: https://goauthentik.io/docs/installation/docker-compose
        ## Place the following in the agenix secrets file:
        #
        # GEOIPUPDATE_ACCOUNT_ID=*your account ID*
        # GEOIPUPDATE_LICENSE_KEY=* your license key*
        # AUTHENTIK_AUTHENTIK__GEOIP=/geoip/GeoLite2-City.mmdb
        #
        GEOIPUPDATE_EDITION_IDS = "GeoLite2-City";
        GEOIPUPDATE_FREQUENCY = "8";
        TZ = "America/Los_Angeles";
      };
    };
  };
}
