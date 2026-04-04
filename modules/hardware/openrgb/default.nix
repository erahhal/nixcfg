{ config, lib, pkgs, userParams, ... }:
let
  cfg = config.nixcfg.hardware.openrgb;
  profilePath = ./Aquamarine.orp;
in {
  options.nixcfg.hardware.openrgb = {
    enable = lib.mkEnableOption "OpenRGB LED controller";
  };
  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.openrgb ];

    environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

    hardware.i2c.enable = true;

    services.hardware.openrgb = {
      enable = true;
      server.port = 6742;
      motherboard = "intel";
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/OpenRGB/Aquamarine.orp - - - - ${profilePath}"
    ];

    systemd.services.openrgb.serviceConfig.ExecStart = let
      cfg' = {
        package = pkgs.openrgb;
        server.port = 6742;
      };
    in pkgs.lib.mkForce "${cfg'.package}/bin/openrgb --server --server-port ${toString cfg'.server.port} --profile Aquamarine";

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
          ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --startminimized";
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
