{ inputs, pkgs, userParams, ... }:
let
  hyprctl="${pkgs.hyprland}/bin/hyprctl";
  tv = "LG Electronics LG TV SSCR2 0x01010101";
  yamaha = "Yamaha Corporation - RX-A2A";
  index = "Valve Corporation Index HMD 0x92B574CE";
in
{
  home-manager.users.${userParams.username} = {
    services.kanshi = {
      enable = true;
      systemdTarget = "graphical-session.target";
      settings = [
        {
          profile = {
            name = "tv";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
        {
          profile = {
            name = "tv";
            outputs = [
              {
                criteria = yamaha;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
        {
          profile = {
            name = "tv-index";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = index;
                status = "disable";
                mode = "2880x1600";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
        {
          profile = {
            name = "tv-dp-1";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = "DP-1";
                status = "disable";
                mode = "640x480";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
        {
          profile = {
            name = "tv-dp-2";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = "DP-2";
                status = "disable";
                mode = "640x480";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
        {
          profile = {
            name = "tv-dp-3";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = "DP-3";
                status = "disable";
                mode = "640x480";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on | true"
            ];
          };
        }
      ];
    };
  };
}
