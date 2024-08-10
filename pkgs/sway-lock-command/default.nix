{ pkgs, ... }:
pkgs.writeShellScript "swaylock.sh" ''
  ${pkgs.swaylock-effects}/bin/swaylock -c '#000000' --indicator-radius 100 --indicator-thickness 20 --show-failed-attempts &
  if [ "$1" == "suspend" ]; then
    sleep 2
    ${pkgs.systemd}/bin/systemctl suspend
  fi
''
