{ config, lib, pkgs, ... }:

# certificates are generated with:
#  certificate-gen identity.p12 certificate.pem key.pem --dns-names <hostname1> <hostname2> ...

# @TODO
# * Add specific parameters to build config directly
# * Add firewall rule for specified server port
# * Rename binaries (e.g. client -> rkvm-client) to avoid conflicts

with lib;
let
  rkvm = pkgs.callPackage ../pkgs/rkvm {};
  cfgC = config.services.rkvm.client;
  cfgS = config.services.rkvm.server;
in
{
  ###### interface
  options = {
    services.rkvm = {
      client = {
        enable = mkEnableOption "Enable rkvm client";
        configFile = mkOption {
          type = types.path;
          default = "/etc/rkvm/client.toml";
          description = "The rkvm client configuration file.";
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = "Whether the rkvm client should be started automatically.";
        };
      };
      server = {
        enable = mkEnableOption "Enable rkvm server";
        configFile = mkOption {
          type = types.path;
          default = "/etc/rkvm/server.toml";
          description = "The rkvm server configuration file.";
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = "Whether the rkvm server should be started automatically.";
        };
      };
    };
  };
  ###### implementation
  config = mkMerge [
    {
      environment.systemPackages = [ rkvm ];
      networking.firewall = {
        allowedUDPPorts = [
          # rkvm
          5258
        ];
        allowedTCPPorts = [
          # rkvm
          5258
        ];
      };
    }
    (mkIf cfgC.enable {
      systemd.services.rkvm-client = {
        after = [ "network.target" "graphical-session.target" ];
        description = "rkvm client";
        wantedBy = optional cfgC.autoStart "graphical-session.target";
        path = [ rkvm ];
        serviceConfig.ExecStart = ''${rkvm}/bin/client ${cfgC.configFile}'';
        serviceConfig.Restart = "on-failure";
      };
    })
    (mkIf cfgS.enable {
      systemd.services.rkvm-server = {
        after = [ "network.target" "graphical-session.target" ];
        description = "rkvm server";
        wantedBy = optional cfgS.autoStart "graphical-session.target";
        path = [ rkvm ];
        serviceConfig.ExecStart = ''${rkvm}/bin/server ${cfgS.configFile}'';
        serviceConfig.Restart = "on-failure";
      };
    })
  ];
}
