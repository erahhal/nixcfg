{ pkgs, ... }:

let
  find = "${pkgs.findutils}/bin/find";
  head = "${pkgs.coreutils}/bin/head";
  id = "${pkgs.coreutils}/bin/id";
  pidof = "${pkgs.procps}/bin/pidof";
  hyprctl="${pkgs.hyprland}/bin/hyprctl";
  swayLockCmd = pkgs.callPackage ../../pkgs/sway-lock-command { };
  hyprlockCmd = pkgs.writeShellScript "hyprlock.sh" ''
    ${pidof} hyprlock || ${pkgs.hyprlock}/bin/hyprlock
  '';
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
  niri-dpms-off-cmd = pkgs.writeShellScript "niri-dpms-off-cmd.sh" ''
    echo "NIRI DPMS OFF"
    export NIRI_SOCKET=$(${find} /run/user/$(${id} -u) -name "niri.wayland-*.sock" 2>/dev/null | ${head} -1)
     ${pkgs.niri}/bin/niri msg action power-off-monitors;
  '';
  niri-dpms-on-cmd = pkgs.writeShellScript "niri-dpms-on-cmd.sh" ''
    echo "NIRI DPMS ON"
    export NIRI_SOCKET=$(${find} /run/user/$(${id} -u) -name "niri.wayland-*.sock" 2>/dev/null | ${head} -1)
     ${pkgs.niri}/bin/niri msg action power-on-monitors ;
  '';
  idlecmd = pkgs.writeShellScript "swayidle.sh" ''
    # asterisk in sway command gets interpolated without this setting
    # set -o noglob

    ${pkgs.procps}/bin/pkill swayidle

    if ${pidof} sway > /dev/null; then
      ${pkgs.swayidle}/bin/swayidle \
      before-sleepl'${swayLockCmd}' \
      lock '${swayLockCmd}' \
      timeout 300 '${swayLockCmd}' \
      timeout 300 '${sway-dpms-off-cmd}' \
      resume '${sway-dpms-on-cmd}'
    elif ${pidof} Hyprland > /dev/null; then
      ${pkgs.swayidle}/bin/swayidle \
      before-sleep '${hyprlockCmd}' \
      lock '${hyprlockCmd}' \
      timeout 300 '${hyprlockCmd}' \
      timeout 300 '${hyprland-dpms-off-cmd}' \
      resume '${hyprland-dpms-on-cmd}'
    elif ${pidof} niri > /dev/null; then
      ${pkgs.swayidle}/bin/swayidle \
      before-sleep '${hyprlockCmd}' \
      lock '${hyprlockCmd}' \
      timeout 300 '${hyprlockCmd}' \
      timeout 300 '${niri-dpms-off-cmd}' \
      after-resume '${niri-dpms-on-cmd}'
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
