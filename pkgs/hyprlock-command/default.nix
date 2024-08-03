{ pkgs, ... }:
pkgs.writeShellScript "hyprlock.sh" ''
  ${pkgs.hyprlock}/bin/hyprlock
''
