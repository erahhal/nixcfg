{ pkgs, userParams, ... }:
{
  home-manager.users.${userParams.username} = {
    services.kanshi = {
      enable = true;
      systemdTarget = "graphical-session.target";
      profiles = {
        undocked = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "0,0";
              scale = 1.5;
            }
          ];
        };
        desk = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG Ultra HD 0x00003EAD";
              status = "enable";
              mode = "3840x2160";
              position = "0,0";
              # transform = "90";
              scale = 1.5;
            }
            {
              criteria = "Goldstar Company Ltd LG HDR 4K 0x00000F5B";
              status = "enable";
              mode = "3840x2160";
              position = "2560,0";
              scale = 1.5;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "5120,810";
              scale = 1.5;
            }
          ];
        };
        desk-left = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG Ultra HD 0x00003EAD";
              status = "enable";
              mode = "3840x2160";
              position = "0,0";
              # transform = "90";
              scale = 1.5;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "2560,810";
              scale = 1.5;
            }
          ];
        };
        desk-right = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG HDR 4K 0x00000F5B";
              status = "enable";
              mode = "3840x2160";
              position = "0,0";
              # transform = "90";
              scale = 1.5;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "2560,810";
              scale = 1.5;
            }
          ];
        };
        ## Only left or right can be enabled at the same time, not both
        #
        # desk-portable-right = {
        #   outputs = [
        #     {
        #       criteria = "eDP-1";
        #       status = "enable";
        #       mode = "2560x1440";
        #       position = "0,150";
        #       scale = 1.0;
        #     }
        #     {
        #       criteria = "Goldstar Company Ltd 16MQ70";
        #       status = "enable";
        #       mode = "2560x1600@59.972000Hz";
        #       position = "2560,0";
        #       scale = 1.0;
        #     }
        #   ];
        #   exec = [
        #     "swaymsg workspace 1, move workspace to DP-1"
        #     "swaymsg workspace 2, move workspace to eDP-1"
        #     "swaymsg workspace 3, move workspace to DP-1"
        #     "swaymsg workspace 4, move workspace to DP-1"
        #     "swaymsg workspace 5, move workspace to DP-1"
        #     "swaymsg workspace 6, move workspace to DP-1"
        #   ];
        # };
        desk-portable-left = {
          outputs = [
            {
              # criteria = "Goldstar Company Ltd 16MQ70";
              criteria = "DP-1";
              status = "enable";
              mode = "2560x1600@59.972000Hz";
              position = "0,0";
              scale = 1.5;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "1706,100";
              scale = 1.5;
            }
          ];
          exec = [
            "swaymsg workspace 1, move workspace to DP-1"
            "swaymsg workspace 2, move workspace to eDP-1"
            "swaymsg workspace 3, move workspace to DP-1"
            "swaymsg workspace 4, move workspace to DP-1"
            "swaymsg workspace 5, move workspace to DP-1"
            "swaymsg workspace 6, move workspace to DP-1"
          ];
        };
        desk-portable-left-dp-2 = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd 16MQ70";
              # criteria = "DP-2";
              status = "enable";
              mode = "2560x1600@59.972000Hz";
              position = "0,0";
              scale = 1.5;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "1706,100";
              scale = 1.5;
            }
          ];
          exec = [
            "swaymsg workspace 1, move workspace to DP-2"
            "swaymsg workspace 2, move workspace to eDP-1"
            "swaymsg workspace 3, move workspace to DP-2"
            "swaymsg workspace 4, move workspace to DP-2"
            "swaymsg workspace 5, move workspace to DP-2"
            "swaymsg workspace 6, move workspace to DP-2"
          ];
        };
        desk-netflix-viewsonic-dual = {
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
              mode = "2560x1440";
              position = "1287,1440";
              scale = 1.5;
            }
          ];
        };
        desk-netflix-viewsonic-triple = {
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
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
            }
          ];
        };
        desk-netflix-samsung-dual = {
          outputs = [
            {

              # criteria = "Samsung Electric Company C34H89x";
              criteria = "Samsung Electric Company C34H89x HCPR500197";
              status = "enable";
              mode = "3440x1440@59.973000Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
            }
          ];
        };
        desk-netflix-samsung-triple = {
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
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
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
        desk-netflix-lg-dual = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG ULTRAWIDE 0x00008194";
              # criteria = "Goldstar Company Ltd LG ULTRAWIDE 0x00008194 (DP-2 via HDMI)";
              status = "enable";
              mode = "3440x1440@49.987000Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
            }
          ];
        };
        desk-netflix-lg-triple = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG ULTRAWIDE";
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
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
            }
          ];
        };
      };
    };
  };
}
