{ lib, pkgs, ... }:
{
  services.hypridle = let
    hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
    # @TODO: Should use from inputs, not pkgs
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    loginctl = "${pkgs.systemd}/bin/loginctl";
    restartWlsunset = "systemctl --user restart wlsunset.service";
  in {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${hyprlock}";
        # unlock_cmd = "echo 'unlock!'";

        ## This sometimes kills the hyprlock that is currently locking the screen,
        ## which leaves hyprland with a red screen
        ## INSTEAD: only kill hyprlock if it's older than a certain age, say 1 minute?
        # before_sleep_cmd = "kill $(pidof hyprlock); ${loginctl} lock-session && ${hyprctl} dispatch dpms off";

        before_sleep_cmd = "${loginctl} lock-session && ${hyprctl} dispatch dpms off";
        after_sleep_cmd = "${hyprctl} dispatch dpms on && ${loginctl} lock-session && ${restartWlsunset}";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "${loginctl} lock-session";
          # on-resume = "echo 'service resumed'";
        }

        {
          timeout = 360;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on && systemctl --user restart wlsunset.service";
        }
      ];
    };
  };

  ## Don't start automatically.
  ## This allows us to have both sway and hyprland installed simultaneously, and they
  ## are responsible for starting sway-idle if needed
  systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [ ];

  ## Verbose
  # systemd.user.services.hypridle.Service.ExecStart = lib.mkForce "${pkgs.hypridle}/bin/hypridle -v";

  home.packages = with pkgs; [
    hypridle
  ];
}
