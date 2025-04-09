{ inputs, pkgs, userParams, ... }:
let
  hyprctl="${pkgs.hyprland}/bin/hyprctl";
  tv = "LG Electronics LG TV SSCR2 0x01010101";
  index = "Valve Corporation Index HMD 0x92B574CE ";
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
                scale = 3.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on"
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
                scale = 3.0;
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
              "${hyprctl} dispatch dpms on"
            ];
          };
        }
        {
          profile = {
            name = "tv-index-simple";
            outputs = [
              {
                ## TV
                criteria = "HDMI-A-4";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 3.0;
              }
              {
                ## Valve Index
                criteria = "DP-3";
                status = "disable";
                mode = "2880x1600";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on"
            ];
          };
        }
      ];
    };
  };
}
