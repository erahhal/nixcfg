{ pkgs, ...}:

{
  home.packages = with pkgs; [
    blueman
    hicolor-icon-theme
    gnome-icon-theme
    adwaita-icon-theme
  ];

  systemd.user.services."blueman-applet" = {
    Unit = {
      Description = "Start the blueman manager applet";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
      # wantedBy = [ "default.target" ];
    };
    Service = {
      # Type = "forking";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.blueman}/bin/blueman-applet";
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
}
