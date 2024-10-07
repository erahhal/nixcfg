{ config, lib, pkgs, ... }:

let
  cfg = config.services.snapclient;
in {
  options = {
    services.snapclient = {
      enable = lib.mkEnableOption "Enable Snapcast client.";

      # Required
      username = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Username to run service under. Needs access to pulseaudio.
        '';
      };

      # Required
      serverHost = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          hostname or IP of snapcast server
        '';
      };

      latency = lib.mkOption {
        type = lib.types.number;
        default = 0;
        description = lib.mdDoc ''
          latency of output in ms.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.snapcast ];

    ## Use local audio (locally connected speaker)
    ## TO DEBUG INSTABILITY:
    ##   https://github.com/badaix/snapcast/issues/774
    systemd.services.snapclient = {
      wantedBy = [
        "pulseaudio.service"
      ];
      after = [
        "pulseaudio.service"
      ];
      path = with pkgs; [
        pulseaudio
        snapcast
      ];
      script = ''
        ${pkgs.snapcast}/bin/snapclient --latency ${toString cfg.latency} -h ${cfg.serverHost}

        ## Use pulse instead of alsa
        ## Requires "pactl move-sink-input <sink-input number> 0" after running
        ## Otherwise gets in a feedback loop
        # ${pkgs.snapcast}/bin/snapclient --player pulse -h ::1 --latency 60
      '';
      serviceConfig = {
        ## Needed to get access to pulseaudio
        User = cfg.username;
      };
    };
  };

  meta.maintainers = [ ];
}

