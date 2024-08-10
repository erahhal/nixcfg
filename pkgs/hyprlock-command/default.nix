{ pkgs, ... }:
pkgs.writeShellScript "hyprlock.sh" ''
  ${pkgs.hyprlock}/bin/hyprlock &
  if [ "$1" == "suspend" ]; then
    sleep 1
    ${pkgs.systemd}/bin/systemctl suspend
  fi
''
