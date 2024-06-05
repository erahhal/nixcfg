{ inputs, lib, pkgs, ... }:
{
  services.hypridle = let
    # hyprland = pkgs.hyprland;
    hyprland = pkgs.hyprland-patched;
    # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
    hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
    # @TODO: Should use from inputs, not pkgs
    hyprctl = "${hyprland}/bin/hyprctl";
    loginctl = "${pkgs.systemd}/bin/loginctl";
    restartWlsunset = "systemd --user restart wlsunset.service";
  in {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${hyprlock}";
        # unlock_cmd = "echo 'unlock!'";
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
          on-resume = "${hyprctl} dispatch dpms on && systemd --user restart wlsunset.service";
        }
      ];
    };
  };

  ## Don't start automatically.
  ## This allows us to have both sway and hyprland installed simultaneously, and they
  ## are responsible for starting sway-idle if needed
  systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [ ];

  home.packages = with pkgs; [
    hypridle
  ];
}
