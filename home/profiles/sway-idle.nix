{ inputs, pkgs, ... }:

let
  hyprland = pkgs.hyprland;
  # hyprland = pkgs.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  hyprctl="${hyprland}/bin/hyprctl";
  swayLockCmd = pkgs.callPackage ../../pkgs/sway-lock-command { };
  sway-dpms-off-cmd = pkgs.writeShellScript "sway-dpms-off-cmd.sh" ''
      ${pkgs.sway}/bin/swaymsg "output * dpms off"
  '';
  sway-dpms-on-cmd = pkgs.writeShellScript "sway-dpms-on-cmd.sh" ''
      ${pkgs.sway}/bin/swaymsg "output * dpms on"; sleep 2
  '';
  hyprland-dpms-off-cmd = pkgs.writeShellScript "hyprland-dpms-off-cmd.sh" ''
     ${hyprctl} dispatch dpms off;
  '';
  hyprland-dpms-on-cmd = pkgs.writeShellScript "hyprland-dpms-on-cmd.sh" ''
     ${hyprctl} dispatch dpms on;
  '';
  idlecmd = pkgs.writeShellScript "swayidle.sh" ''
    # asterisk in sway command gets interpolated without this setting
    # set -o noglob

    ${pkgs.procps}/bin/pkill swayidle

    if ${pkgs.procps}/bin/pidof sway > /dev/null; then
      ${pkgs.swayidle}/bin/swayidle \
      before-sleep '${swayLockCmd}' \
      lock '${swayLockCmd}' \
      timeout 600 '${swayLockCmd}' \
      timeout 600 '${sway-dpms-off-cmd}' \
      resume '${sway-dpms-on-cmd}'
    elif ${pkgs.procps}/bin/pidof Hyprland > /dev/null; then
      ${pkgs.swayidle}/bin/swayidle \
      before-sleep '${swayLockCmd}' \
      lock '${swayLockCmd}' \
      timeout 600 '${swayLockCmd}' \
      timeout 600 '${hyprland-dpms-off-cmd}' \
      resume '${hyprland-dpms-on-cmd}'
    fi
  '';
in
{
  systemd.user.services."sway-idle" = {
    Unit = {
      Description = "Idle lock";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      ## This is commented out as we don't want it to start automatically
      ## This allows us to have both sway and hyprland installed simultaneously, and they
      ## are responsible for starting sway-idle if needed
      # WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "no";
      RestartSec = 2;
      ExecStart = "${idlecmd}";
    };
  };
}
