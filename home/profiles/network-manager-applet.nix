{ pkgs, ...}:

{
  home.packages = with pkgs; [
    networkmanagerapplet
    hicolor-icon-theme
    gnome-icon-theme
    adwaita-icon-theme
  ];

  systemd.user.services."network-manager-applet" = {
    Unit = {
      Description = "Start the network manager applet";
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
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator --sm-disable";
      Environment = [
       "XDG_DATA_DIRS=${pkgs.networkmanagerapplet}/share"
      ];
    };
  };
}
