{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.hardware.openrgb;
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
      let
        srv = config.services.hardware.openrgb;
      in lib.mkIf (cfg.profile != null) (lib.mkForce
        "${srv.package}/bin/openrgb --server --server-port ${toString srv.server.port} --profile ${profileName}");

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
