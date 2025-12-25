{ pkgs, ...}:

{
  imports = [
    ./easyeffects-presets.nix
  ];
  systemd.user.services."easyeffects" = {
    Unit = {
      Description = "EasyEffects Audio Filter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "dms.service" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
      PassEnvironment = [
        "HOME"
        "XDG_DATA_HOME"
        "XDG_CONFIG_HOME"
        "XDG_CACHE_HOME"
        "XDG_RUNTIME_DIR"
        "DISPLAY"
        "WAYLAND_DISPLAY"
      ];
      Environment = [
        "HOME=%h"
      ];
    };
  };
}
