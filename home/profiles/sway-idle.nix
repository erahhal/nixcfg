{ pkgs, swayLockCmd, ...}:

let
  idlecmd = pkgs.writeShellScript "swayidle.sh" ''
    pkill swayidle
    ${pkgs.swayidle}/bin/swayidle \
    before-sleep '${swayLockCmd}' \
    lock '${swayLockCmd}' \
    timeout 600 '${swayLockCmd}' \
    timeout 600 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"; sleep 2; systemctl --user restart kanshi'
  '';
in
{

  systemd.user.services."sway-idle" = {
    Unit = {
      Description = "Idle lock";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${idlecmd}";
    };
  };
}
