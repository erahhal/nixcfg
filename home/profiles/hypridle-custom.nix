{ pkgs, ... }:
let
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  # @TODO: Should use from inputs, not pkgs
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  loginctl = "${pkgs.systemd}/bin/loginctl";
  # @TODO: Is this even needed?
  restartWlsunset = "systemctl --user restart wlsunset.service";
  config = ''
    general {
      after_sleep_cmd=${hyprctl} dispatch dpms on && ${pkgs.systemd}/bin/loginctl lock-session && ${restartWlsunset}
      before_sleep_cmd=${loginctl} lock-session && ${hyprctl} dispatch dpms off
      ignore_dbus_inhibit=false
      lock_cmd=pidof hyprlock || ${hyprlock}
    }

    listener {
      on-timeout=${loginctl} lock-session
      timeout=300
    }

    listener {
      on-resume=${hyprctl} dispatch dpms on && ${restartWlsunset}
      on-timeout=${hyprctl} dispatch dpms off
      timeout=360
    }
  '';
in
{

  xdg.configFile = {
    "hypr/hypridle.conf".source = config;
  };

  systemd.user.services.hypridle-custom = {
    after = [
      "graphical-session-pre.target"
    ];
    partOf = [
      "graphical-session.target"
    ];
    description = "hypridle";
    restartTriggers = [ ];
    conditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle -v";
      Restart = "always";
      RestartSec = "10";
    };
  };

  home.packages = with pkgs; [
    hypridle
  ];
}
