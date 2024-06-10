{ pkgs, ...}:

{
  home.packages = with pkgs; [
    flameshot
  ];

  systemd.user.services."flameshot" = {
    Unit = {
      Description = "Flameshot screen capture";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.flameshot}/bin/flameshot";
      Environment = [
        "QT_SCALE_FACTOR=2"
        "XDG_CURRENT_DESKTOP=sway"
      ];
    };
  };
}
