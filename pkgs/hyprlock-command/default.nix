{ pkgs, ... }:
pkgs.writeShellScript "hyprlock.sh" ''
  ${pkgs.unstable.hyprlock}/bin/hyprlock
''
