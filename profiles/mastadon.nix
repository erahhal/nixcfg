{ pkgs, usreParams, ... }:
{
  services = {
    elasticsearch = {
      enable = true;
      package = pkgs.elasticsearch7;
      dataDir = "/persist/elasticsearch";
    };
    mastodon = {
      enable = true;
      configureNginx = true;
      localDomain = "mastodon.rahh.al";
      smtp.fromAddress = "mastodon@rahh.al";
      elasticsearch.host = "localhost";
      #extraEnvFiles = [ "/persist/mastodon/secrets.env" ];
    };
    nginx = let dir = "/persist/nginx";
    in {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedBrotliSettings = true;
      virtualHosts."mastodon.rahh.al" = {
        enableACME = false;
        sslCertificate = "${dir}/cfcert.pem";
        sslCertificateKey = "${dir}/cfkey.pem";
        kTLS = true;
        extraConfig = ''
          ssl_verify_client on;
          ssl_client_certificate ${dir}/authenticated_origin_pull_ca.pem;
        '';
      };
    };
    postgresql = {
      settings = {
        shared_preload_libraries = "pg_stat_statements";
        "pg_stat_statements.track" = "all";
        "pg_stat_statements.max" = 10000;
        track_activity_query_size = 2048;
      };
    };
    postgresqlBackup = {
      enable = true;
      compression = "zstd";
      backupAll = true;
      location = "/persist/postgresbackup";
    };
  };
}
