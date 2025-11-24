{ pkgs, ...}:

{
  home.packages = with pkgs; [
    qpwgraph
  ];

  systemd.user.services."qpwgraph" = {
    Unit = {
      Description = "Start qpwgraph";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.qpwgraph}/bin/qpwgraph";
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
