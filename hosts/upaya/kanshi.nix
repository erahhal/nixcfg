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
              mode = "3840x2160";
              position = "0,0";
              scale = 2.0;
            }
          ];
          exec = [
            "boltctl forget --all"
          ];
        };
        desk = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "3840x2160";
              position = "0,910";
              scale = 2.0;
            }
            {
              criteria = "LG Electronics LG Ultra HD 0x00003EAD";
              status = "enable";
              mode = "3840x2160";
              position = "1920,0";
              # transform = "90";
              scale = 1.5;
            }
            {
              criteria = "LG Electronics LG HDR 4K 0x00000F5B";
              status = "enable";
              mode = "3840x2160";
              position = "4480,0";
              scale = 1.5;
            }
          ];
        };
        desk-hyprland = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "3840x2160";
              position = "0,910";
              scale = 2.0;
            }
            {
              criteria = "LG Electronics LG Ultra HD 0x00043EAD";
              status = "enable";
              mode = "3840x2160";
              position = "1920,0";
              # transform = "90";
              scale = 1.5;
            }
            {
              criteria = "LG Electronics LG HDR 4K 0x00020F5B";
              status = "enable";
              mode = "3840x2160";
              position = "4480,0";
              scale = 1.5;
            }
          ];
        };
        desk-left = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "3840x2160";
              position = "0,1500";
              scale = 2.0;
            }
            {
              criteria = "Goldstar Company Ltd LG Ultra HD 0x00003EAD";
              status = "enable";
              mode = "3840x2160";
              position = "2560,0";
              # transform = "90";
              scale = 1.5;
            }
          ];
        };
        desk-right = {
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "3840x2160";
              position = "0,1500";
              scale = 2.0;
            }
            {
              criteria = "Goldstar Company Ltd LG HDR 4K 0x00000F5B";
              status = "enable";
              mode = "3840x2160";
              position = "2560,0";
              # transform = "90";
              scale = 1.5;
            }
          ];
        };
      };
    };
  };
}
