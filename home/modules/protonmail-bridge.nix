{ config, lib, pkgs, userParams, ... }:

with lib;
let
  cfg = config.services.protonmail-bridge;
in
{
  options = {
    services.protonmail-bridge = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Bridge.";
      };

      nonInteractive = mkOption {
        type = types.bool;
        default = false;
        description = "Start Bridge entirely noninteractively";
      };

      logLevel = mkOption {
        type = types.enum [ "panic" "fatal" "error" "warn" "info" "debug" "debug-client" "debug-server" ];
        default = "info";
        description = "The log level";
      };

    };
  };

  config = mkIf cfg.enable {

    home.packages = [ pkgs.unstable.protonmail-bridge ];

    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "Protonmail Bridge";
        After = [ "network.target" ];
      };

      Service = {
        Restart = "always";
        ExecStart = "${pkgs.unstable.protonmail-bridge}/bin/protonmail-bridge --no-window --log-level ${cfg.logLevel}" + optionalString (cfg.nonInteractive) " --noninteractive";
        Environment = [
          "HOME=/home/${userParams.username}"
          # @TODO: This is hacky - better to get PATH programmatically
          "PATH=/etc/profiles/per-user/${userParams.username}/bin:/run/current-system/sw/bin"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
