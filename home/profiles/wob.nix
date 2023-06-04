{ pkgs, ...}:

{
  home.packages = with pkgs; [
    wob
  ];

  systemd.user.services."wob" = {
    Unit = {
      Description = "Start the wayland volume/brightness overlay bar";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.wob}/bin/wob";
    };
  };
}
