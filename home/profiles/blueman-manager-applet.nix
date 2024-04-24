{ pkgs, userParams, ...}:

{
  home.packages = with pkgs; [
    blueman
    hicolor-icon-theme
    gnome2.gnome_icon_theme
    gnome3.adwaita-icon-theme
  ];

  systemd.user.services."blueman-manager-applet" = {
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
    };
    Environment = {
       XDG_DATA_DIRS = "${pkgs.blueman}/share";
    };
  };
}
