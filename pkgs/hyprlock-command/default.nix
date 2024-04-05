{ inputs, pkgs, ... }:
pkgs.writeShellScript "hyprlock.sh" ''
  ${inputs.hyprlock.packages.${pkgs.system}.hyprlock}/bin/hyprlock
''
