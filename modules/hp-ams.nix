{ config, lib, pkgs, ... }:

with lib;
let
  hp-ams = pkgs.callPackage ../pkgs/hp-ams {};
  cfg = config.services.hp-ams;
in {
  options = {
    services.hp-ams = {
      enable = mkEnableOption "Enable HP Agentless Management Service";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ hp-ams ];

    systemd.services.hp-ams = {
      wantedBy = [ "multi-user.target" ];
      description = "HP Agentless Management Service";
      after = [ "syslog.target" "network.target" ]; # starts after network is up

      serviceConfig = {
        ExecStart = "${hp-ams}/bin/amsHelper -f -L";
        Type = "simple";
        LimitCORE = "infinity";
        StandarError = "null";
        Restart = "on-abort";
      };
    };
  };

  meta.maintainers = with maintainers; [ ];
}
