{ inputs, pkgs, ... }:
{
  services.hypridle = let
    hyprlock = "${inputs.hyprlock.packages.${pkgs.system}.hyprlock}/bin/hyprlock";
    # @TODO: Should use from inputs, not pkgs
    hyprctl = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl";
    loginctl = "${pkgs.systemd}/bin/loginctl";
    restartWlsunset = "systemd --user restart wlsunset.service";
  in {
    enable = true;
    lockCmd = "pidof hyprlock || ${hyprlock}";
    beforeSleepCmd = "${hyprctl} dispatch dpms off";
    afterSleepCmd = "${hyprctl} dispatch dpms on && ${loginctl} lock-session && ${restartWlsunset}";
    listeners = [
      {
        timeout = 300;
        onTimeout = "${loginctl} lock-session";
      }
      {
        timeout = 360;
        onTimeout = "${hyprctl} dispatch dpms off";
        onResume = "${hyprctl} dispatch dpms on && ${restartWlsunset}";
      }
    ];
  };
}
