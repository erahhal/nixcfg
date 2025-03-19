## References
#
#    https://community.getgrist.com/t/grist-core-multi-user-docker-setup/666
#    https://www.reddit.com/r/selfhosted/comments/su6tv3/comment/hxghbc4/?context=3
#    https://github.com/gristlabs/grist-core/issues/135
#    https://blog.cubieserver.de/2022/complete-guide-to-nextcloud-saml-authentication-with-authentik/

{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.78";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    grist = {
      image = "gristlabs/grist:latest";
      extraOptions = [
        "--pull=always"
      ];
      ports = [
        "${service_ip}:80:80"
      ];
      volumes = [
        "${containerDataPath}/grist:/persist"
        "${containerDataPath}/authentik/certs:/sso"
      ];
      environment = {
        PORT = "80";
        APP_HOME_URL = "https://grist.rahh.al";
        GRIST_SAML_SP_HOST = "https://grist.rahh.al";
        GRIST_SAML_SP_KEY = "/sso/sp.key";
        GRIST_SAML_SP_CERT = "/sso/sp.pem";
        GRIST_SAML_IDP_LOGIN = "https://authentik.rahh.al/application/saml/grist/sso/binding/redirect/";
        GRIST_SAML_IDP_LOGOUT = "https://authentik.rahh.al/application/saml/grist/sso/binding/redirect/";
        GRIST_SAML_IDP_CERTS = "/sso/idp.pem";
        GRIST_SAML_IDP_UNENCRYPTED = "1";
        TZ = "America/Los_Angeles";
        PUID = toString hostParams.uid;
        PGID = toString hostParams.gid;
      };
    };
  };
}
