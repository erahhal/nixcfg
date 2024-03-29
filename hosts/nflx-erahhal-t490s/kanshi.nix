{ userParams, ... }:
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
              mode = "2560x1440";
              position = "5120,810";
              scale = 1.5;
            }
          ];
        };
        desk-left = {
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
              mode = "2560x1440";
              position = "2560,810";
              scale = 1.5;
            }
          ];
        };
        desk-right = {
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
              mode = "2560x1440";
              position = "2560,810";
              scale = 1.5;
            }
          ];
        };
        ## Only left or right can be enabled at the same time, not both
        desk-portable-right = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "2560x1440";
              position = "0,100";
              scale = 1.6;
            }
            {
              criteria = "LG Electronics 16MQ70 204NZKZ005285";
              status = "enable";
              mode = "2560x1600@59.972000Hz";
              position = "1598,0";
              scale = 1.6;
            }
          ];
          exec = [
            "swaymsg workspace 1, move workspace to output right"
            "swaymsg workspace 2, move workspace to eDP-1"
            "swaymsg workspace 3, move workspace to output right"
            "swaymsg workspace 4, move workspace to output right"
            "swaymsg workspace 5, move workspace to output right"
            "swaymsg workspace 6, move workspace to output right"
          ];
        };
        # desk-portable-left = {
        #   outputs = [
        #     {
        #       criteria = "LG Electronics 16MQ70 204NZKZ005285";
        #       status = "enable";
        #       mode = "2560x1600@59.972000Hz";
        #       position = "0,0";
        #       scale = 1.5;
        #     }
        #     {
        #       criteria = "eDP-1";
        #       status = "enable";
        #       mode = "2560x1440";
        #       position = "1706,100";
        #       scale = 1.5;
        #     }
        #   ];
        #   exec = [
        #     "swaymsg workspace 1, move workspace to output left"
        #     "swaymsg workspace 2, move workspace to eDP-1"
        #     "swaymsg workspace 3, move workspace to output left"
        #     "swaymsg workspace 4, move workspace to output left"
        #     "swaymsg workspace 5, move workspace to output left"
        #     "swaymsg workspace 6, move workspace to output left"
        #   ];
        # };
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
              mode = "2560x1440";
              position = "900,1440";
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
              # criteria = "LG Electronics LG ULTRAWIDE 0x0000FAF6";
              criteria = "LG Electronics LG ULTRAWIDE 0x0000DD5F";
              status = "enable";
              mode = "3440x1440@49.987000Hz";
              position = "420,709";
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
          exec = [
            "swaymsg workspace 1, move workspace to output up"
            "swaymsg workspace 2, move workspace to eDP-1"
            "swaymsg workspace 3, move workspace to eDP-1"
            "swaymsg workspace 4, move workspace to eDP-1"
            "swaymsg workspace 5, move workspace to eDP-1"
            "swaymsg workspace 6, move workspace to eDP-1"
          ];
        };
        desk-netflix-lg-triple = {
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
              mode = "2560x1440";
              position = "1287,2149";
              scale = 1.5;
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
      };
    };
  };
}
