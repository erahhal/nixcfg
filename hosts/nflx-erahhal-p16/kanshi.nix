{ inputs, pkgs, userParams, ... }:
let
  home-monitor-left-sway = "LG Electronics LG Ultra HD 0x00003EAD";
  home-monitor-right-sway = "LG Electronics LG HDR 4K 0x00000F5B";
  home-monitor-left-hyprland = "LG Electronics LG Ultra HD 0x00043EAD";
  home-monitor-right-hyprland = "LG Electronics LG HDR 4K 0x00020F5B";
  portable-monitor = "LG Electronics 16MQ70 204NZKZ005285";
  portable-monitor-scale = 1.6;
  asus-monitor = "ASUSTek COMPUTER INC ASUS VG289 RALMTF124240";
  hyprctl="${pkgs.hyprland}/bin/hyprctl";
  eDP-1-scale = 2.1333333;
in
{
  home-manager.users.${userParams.username} = {
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
                mode = "3840x2400@60";
                position = "0,0";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              ''${pkgs.xorg.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 283"''
              "${hyprctl} dispatch dpms on"
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
                # transform = "90";
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
                # status = "enable";
                mode = "3840x2400@60";
                position = "4521,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          # echo "off" | sudo tee /sys/class/drm/card0/dpms
          profile = {
            name = "desk-hyprland-thinkvision";
            outputs = [
              {
                criteria = "Lenovo Group Limited P40w-20 V90DFGMV";
                status = "enable";
                mode = "5120x2160";
                position = "0,0";
                # scale = 1.250000;
                scale = 1.333333;
              }
              {
                criteria = "eDP-1";
                status = "disable";
                # status = "enable";
                mode = "3840x2400@60";
                position = "3844,1300";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              ''${pkgs.xorg.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 140"''
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 3 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 7 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 8 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 9 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch dpms on"
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
                # transform = "90";
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
                # status = "enable";
                mode = "3840x2400@60";
                position = "4520,1440";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 3 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 7 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 8 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 9 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch dpms on"
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
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1678,1440";
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
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1678,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        # {
        #   profile = {
        #     name = "portable-right";
        #     outputs = [
        #       {
        #         criteria = "eDP-1";
        #         status = "enable";
        #         mode = "2880x1800@90.000999";
        #         position = "0,67";
        #         scale = 1.8;
        #       }
        #       {
        #         criteria = portable-monitor;
        #         status = "enable";
        #         mode = "2560x1600@59.972000Hz";
        #         position = "1920,440";
        #         scale = portable-monitor-scale;
        #       }
        #     ];
        #     exec = [
        #       "swaymsg workspace 1, move workspace to output right"
        #       "swaymsg workspace 2, move workspace to eDP-1"
        #       "swaymsg workspace 3, move workspace to eDP-1"
        #       "swaymsg workspace 4, move workspace to output right"
        #       "swaymsg workspace 5, move workspace to output right"
        #       "swaymsg workspace 6, move workspace to output right"
        #       "swaymsg workspace 7, move workspace to output right"
        #       "swaymsg workspace 8, move workspace to output right"
        #       "swaymsg workspace 9, move workspace to output right"
        #     ];
        #   };
        # }
        {
          profile = {
            name = "portable-right";
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "0,0";
                # Resolution must be integer divisible by scale
                scale = eDP-1-scale;
              }
              {
                criteria = portable-monitor;
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "1801,200";
                # Resolution must be integer divisible by scale
                scale = portable-monitor-scale;
              }
            ];
            exec = [
            #   ## Only chrome on external monitor
            #   "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${portable-monitor}"
            #   "${hyprctl} dispatch moveworkspacetomonitor 2 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 3 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 4 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 5 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 6 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 7 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 8 eDP-1"
            #   "${hyprctl} dispatch moveworkspacetomonitor 9 eDP-1"
            ];
          };
        }
        # {
        #   profile = {
        #     name = "portable-left-hyprland";
        #     outputs = [
        #       {
        #         criteria = portable-monitor;
        #         status = "enable";
        #         mode = "2560x1600@59.972000Hz";
        #         position = "0,0";
        #         # Resolution must be integer divisible by scale
        #         scale = portable-monitor-scale;
        #       }
        #       {
        #         criteria = "eDP-1";
        #         status = "enable";
        #         mode = "2880x1800@90.000999";
        #         position = "1920,440";
        #         # Resolution must be integer divisible by scale
        #         scale = 1.8;
        #       }
        #     ];
        #     exec = [
        #       "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 2 eDP-1"
        #       "${hyprctl} dispatch moveworkspacetomonitor 3 eDP-1"
        #       "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 6 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 7 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 8 desc:${portable-monitor}"
        #       "${hyprctl} dispatch moveworkspacetomonitor 9 desc:${portable-monitor}"
        #     ];
        #   };
        # }
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
                mode = "3840x2400@60";
                position = "2560,900";
                # Resolution must be integer divisible by scale
                scale = eDP-1-scale;
              }
            ];
            exec = [
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 3 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 7 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 8 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 9 eDP-1"
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
                mode = "3840x2400@60";
                position = "2560,900";
                # Resolution must be integer divisible by scale
                scale = eDP-1-scale;
              }
            ];
            exec = [
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 3 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${asus-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 7 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 8 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 9 eDP-1"
            ];
          };
        }
        # {
        #   profile = {
        #     name = "portable-left";
        #     outputs = [
        #       {
        #         criteria = "LG Electronics 16MQ70 204NZKZ005285";
        #         status = "enable";
        #         mode = "2560x1600@59.972000Hz";
        #         position = "0,440";
        #         scale = 1.5;
        #       }
        #       {
        #         criteria = "eDP-1";
        #         status = "enable";
        #         mode = "2880x1800@90.000999";
        #         position = "1920,0";
        #         scale = 1.8;
        #       }
        #     ];
        #     exec = [
        #       "swaymsg workspace 1, move workspace to output left"
        #       "swaymsg workspace 2, move workspace to eDP-1"
        #       "swaymsg workspace 3, move workspace to eDP-1"
        #       "swaymsg workspace 4, move workspace to output left"
        #       "swaymsg workspace 5, move workspace to output left"
        #       "swaymsg workspace 6, move workspace to output left"
        #       "swaymsg workspace 7, move workspace to output left"
        #       "swaymsg workspace 8, move workspace to output left"
        #       "swaymsg workspace 9, move workspace to output left"
        #     ];
        #   };
        # }
        {
          profile = {
            name = "desk-netflix-viewsonic-dual";
            outputs = [
              {
                # criteria = "ViewSonic Corporation VP3481a";
                criteria = "ViewSonic Corporation VP3481a WAG204600294";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1287,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-dell-dual";
            outputs = [
              {
                criteria = "Dell Inc. DELL C3422WE F3BJT83";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "831,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-viewsonic-triple";
            outputs = [
              {

                criteria = "ViewSonic Corporation VP3481a";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "Goldstar Company Ltd 16MQ70";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "3847,2149";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1287,2149";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-samsung-dual";
            outputs = [
              {

                # criteria = "Samsung Electric Company C34H89x HCPR500197";
                criteria = "Samsung Electric Company C34H89x HCPR501154";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "900,1440";
                scale = eDP-1-scale;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-samsung-triple";
            outputs = [
              {
                criteria = "Samsung Electric Company C34H89x";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "Goldstar Company Ltd 16MQ70";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "3847,2149";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1287,2149";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to output right"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to eDP-1"
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-lg-dual";
            outputs = [
              {
                criteria = "LG Electronics LG ULTRAWIDE 0x0001ADA5";
                status = "enable";
                mode = "3440x1440@49.987000Hz";
                position = "420,709";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1287,2149";
                scale = eDP-1-scale;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to eDP-1"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to eDP-1"
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-lg-triple";
            outputs = [
              {
                criteria = "LG Electronics LG ULTRAWIDE 0x0000FAF6";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "420,709";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "3840x2400@60";
                position = "1287,2149";
                scale = eDP-1-scale;
              }
              {
                criteria = "LG Electronics 16MQ70 204NZKZ005285";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "2993,2149";
                scale = 1.5;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to output right"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to output right"
              "swaymsg workspace 7, move workspace to output right"
            ];
          };
        }
      ];
    };
  };
}
