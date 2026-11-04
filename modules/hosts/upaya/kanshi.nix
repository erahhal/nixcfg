{ config, pkgs, lib, ... }:
let
  userParams = config.hostParams.user;
  portable-monitor = "LG Electronics 16MQ70 204NZKZ005285";
  portable-monitor-scale = 1.6;
  asus-monitor = "ASUSTek COMPUTER INC ASUS VG289 RALMTF124240";
  # 3840x2160 panel; 2.0 keeps the logical size integral (1920x1080).
  eDP-1-mode = "3840x2160";
  eDP-1-scale = 2.0;
in
{
  # Profiles follow nflx-erahhal-p16's kanshi.nix (same desks, same dock),
  # adapted to this panel. No hyprctl/swaymsg execs: upaya only runs niri.
  home-manager.users.${userParams.username} = {
    # Override home-manager's Restart=always to prevent blocking graphical-session.target stop
    systemd.user.services.kanshi.Service.Restart = lib.mkForce "on-failure";

    services.kanshi = {
      enable = true;
      systemdTarget = "graphical-session.target";
      settings = [
        {
          profile = {
            name = "undocked";
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = eDP-1-mode;
                position = "0,0";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              ''${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 282"''
            ];
          };
        }
        {
          profile = {
            name = "desk-sway";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00003EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 1.5;
              }
              {
                criteria = "LG Electronics LG HDR 4K 0x00000F5B";
                status = "enable";
                mode = "3840x2160";
                position = "2560,0";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "disable";
              }
            ];
          };
        }
        {
          # ThinkPad TB4 dock with the ThinkVision daisy-chained.
          profile = {
            name = "desk-hyprland-thinkvision";
            outputs = [
              {
                criteria = "Lenovo Group Limited P40w-20 V90DFGMV";
                status = "enable";
                # Not the native 5120x2160: this host's TB3 port carries DP
                # 1.2, so 5120 tops out at 50 Hz, and the HD 630's display
                # engine doesn't scan out a 5120-wide plane correctly (only
                # part of the panel updates). A custom 21:9 mode at <= 4096
                # px wide keeps the aspect ratio -- the monitor upscales it
                # to the full panel -- and 60 Hz. Scale 1.0667 gives the
                # same 3840x1620 logical layout as the p16's 5120 @ 1.333.
                mode = "--custom 4096x1728@60Hz";
                position = "0,0";
                scale = 1.066667;
              }
              {
                criteria = "eDP-1";
                status = "disable";
              }
            ];
            exec = [
              # Physical DPI of 4096 px across the 40" panel's ~930 mm.
              ''${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 112"''
            ];
          };
        }
        {
          profile = {
            name = "desk-hyprland";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00043EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 1.5;
              }
              {
                criteria = "LG Electronics LG HDR 4K 0x00020F5B";
                status = "enable";
                mode = "3840x2160";
                position = "2560,0";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "disable";
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-left";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00003EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 1.5;
              }
              {
                # Centred under the monitor's right edge, as on the p16.
                criteria = "eDP-1";
                status = "enable";
                mode = eDP-1-mode;
                position = "1600,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-right";
            outputs = [
              {
                criteria = "LG Electronics LG HDR 4K 0x00000F5B";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = eDP-1-mode;
                position = "1600,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "portable-left";
            outputs = [
              {
                criteria = portable-monitor;
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "0,40";
                # Resolution must be integer divisible by scale
                scale = portable-monitor-scale;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = eDP-1-mode;
                position = "1600,0";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-asus-hyprland";
            outputs = [
              {
                criteria = asus-monitor;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                # Resolution must be integer divisible by scale
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = eDP-1-mode;
                position = "2560,360";
                scale = eDP-1-scale;
              }
            ];
          };
        }
      ];
    };
  };
}
