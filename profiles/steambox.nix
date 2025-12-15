{ config, lib, pkgs, userParams, ... }:
let
  width = config.hostParams.programs.steam.gamescope.width;
  height = config.hostParams.programs.steam.gamescope.height;
in
{
  config = lib.mkIf config.hostParams.programs.steam.bootToSteam {
    # Clean Quiet Boot
    boot.kernelParams = [ "quiet" "splash" "console=/dev/null" ];
    boot.plymouth.enable = true;

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
    programs.steam.gamescopeSession.enable = true; # Integrates with programs.steam

    # Gamescope Auto Boot from TTY (example)
    services.xserver.enable = false; # Assuming no other Xserver needed
    services.getty.autologinUser = userParams.username;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.gamescope}/bin/gamescope -W ${toString width} -H ${toString height} -f -e --xwayland-count 2 --hdr-enabled --hdr-itm-enabled -- steam -pipewire-dmabuf -gamepadui -steamdeck -steamos3 > /dev/null 2>&1";
          user = userParams.username;
        };
      };
    };
  };
}
