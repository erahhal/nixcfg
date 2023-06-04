{ pkgs, ...}:
let
  startSNC = pkgs.writeShellScript "startsnc.sh" ''
    ${pkgs.procps}/bin/pkill swaync
    ${pkgs.swaynotificationcenter}/bin/swaync
  '';
in
{
  home.packages = with pkgs; [
    unstable.swaynotificationcenter
  ];

  systemd.user.services.swaynotificationcenter = {
    Unit = {
      Description = "Sway Notification Center daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${startSNC}";
      RestartSec = 5;
      Restart = "always";
    };
  };
}
