{ pkgs, userParams, ... }:
{
  services.udev.packages = [ pkgs.openrgb ];

  environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

  hardware.i2c.enable = true;

  services.hardware.openrgb = {
    enable = true;
    server.port = 6742;
    motherboard = "intel";
  };

  home-manager.users.${userParams.username} = {
    systemd.user.services."openrgb" = {
      Unit = {
        Description = "Start the openrgb applet";
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
          "DISPLAY"  # If needed for GUI applications
          "WAYLAND_DISPLAY"  # If using Wayland
        ];
        # You can also set them explicitly if needed
        Environment = [
          "HOME=%h"  # %h is a special variable that expands to the user's home directory
        ];
      };
    };
  };
}
