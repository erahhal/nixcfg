{ pkgs, userParams, ... }:
let
  profilePath = ./openrgb/Aquamarine.orp;
in
{
  services.udev.packages = [ pkgs.openrgb ];

  environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

  hardware.i2c.enable = true;

  services.hardware.openrgb = {
    enable = true;
    server.port = 6742;
    motherboard = "intel";
  };

  # Deploy profile to /var/lib/OpenRGB/
  systemd.tmpfiles.rules = [
    "L+ /var/lib/OpenRGB/Aquamarine.orp - - - - ${profilePath}"
  ];

  # Override the system service to load the profile at boot
  systemd.services.openrgb.serviceConfig.ExecStart = let
    cfg = {
      package = pkgs.openrgb;
      server.port = 6742;
    };
  in pkgs.lib.mkForce "${cfg.package}/bin/openrgb --server --server-port ${toString cfg.server.port} --profile Aquamarine";

  # User service for the tray applet
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
          "HOME"
          "XDG_DATA_HOME"
          "XDG_CONFIG_HOME"
          "XDG_CACHE_HOME"
          "XDG_RUNTIME_DIR"
          "DISPLAY"
          "WAYLAND_DISPLAY"
        ];
        # You can also set them explicitly if needed
        Environment = [
          "HOME=%h"  # %h is a special variable that expands to the user's home directory
        ];
      };
    };
  };
}
