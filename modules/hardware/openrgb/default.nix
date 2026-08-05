{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.hardware.openrgb;
  srv = config.services.hardware.openrgb;
  profileName = lib.removeSuffix ".orp" (baseNameOf cfg.profile);
in {
  options.nixcfg.hardware.openrgb = {
    enable = lib.mkEnableOption "OpenRGB LED controller";

    motherboard = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "amd" "intel" ]);
      default = null;
      description = "Motherboard vendor, selects the SMBus kernel driver used for RGB detection.";
    };

    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ".orp profile the server applies at startup. Its filename (minus extension) is the profile name.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.openrgb ];

    environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

    hardware.i2c.enable = true;

    services.hardware.openrgb = {
      enable = true;
      server.port = 6742;
      motherboard = cfg.motherboard;
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.profile != null) [
      "L+ /var/lib/OpenRGB/${profileName}.orp - - - - ${cfg.profile}"
    ];

    systemd.services.openrgb.serviceConfig.ExecStart =
      lib.mkIf (cfg.profile != null) (lib.mkForce
        "${srv.package}/bin/openrgb --server --server-port ${toString srv.server.port} --profile ${profileName}");

    ## The controllers lose their state across S3 and come back at their
    ## firmware default (dark), but the server keeps running, so the profile
    ## it applied at startup is never re-pushed. Send it again through the
    ## SDK port instead of restarting the server: a restart re-detects every
    ## device and drops the tray applet's connection.
    systemd.services.openrgb-resume = lib.mkIf (cfg.profile != null) {
      description = "Reapply the OpenRGB profile after resume";
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
      serviceConfig = {
        Type = "oneshot";
        ## OpenRGB resolves its config directory from $HOME and falls back to
        ## the working directory when that is unset, which is how the profile
        ## ends up read from /var/lib/OpenRGB. Match the server exactly: set
        ## no User= (systemd would then set HOME=/root) and the same WorkingDirectory,
        ## or the client looks in /root/.config/OpenRGB and finds no profile.
        WorkingDirectory = "/var/lib/OpenRGB";
        ExecStart = pkgs.writeShellScript "openrgb-reapply-profile" ''
          ## The client exits 0 whether or not the profile applied, so its
          ## output is the only success signal. Retry: the bus may need a
          ## moment after resume.
          for _ in $(seq 1 10); do
            if ${srv.package}/bin/openrgb --client 127.0.0.1:${toString srv.server.port} \
                 --profile ${profileName} 2>&1 | grep -q 'Profile loaded successfully'; then
              exit 0
            fi
            sleep 1
          done
          echo "openrgb: profile ${profileName} did not apply after resume" >&2
          exit 1
        '';
      };
    };

    home-manager.users.${userParams.username} = {
      systemd.user.services."openrgb" = {
        Unit = {
          Description = "OpenRGB tray applet";
          PartOf = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          Restart = "always";
          RestartSec = 2;
          ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --startminimized --nodetect --client 127.0.0.1:6742";
          PassEnvironment = [
            "HOME" "XDG_DATA_HOME" "XDG_CONFIG_HOME" "XDG_CACHE_HOME"
            "XDG_RUNTIME_DIR" "DISPLAY" "WAYLAND_DISPLAY"
          ];
          Environment = [ "HOME=%h" ];
        };
      };
    };
  };
}
