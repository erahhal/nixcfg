{ inputs, pkgs, userParams, lib, ... }:
let
  hyprctl="${pkgs.hyprland}/bin/hyprctl";
  tv = "LG Electronics LG TV SSCR2 0x01010101";
  yamaha = "Yamaha Corporation * *";
  index = "Valve Corporation * *";
  quarto = "Nvidia * *";
in
{
  home-manager.users.${userParams.username} = {
    # Override home-manager's Restart=always to prevent blocking graphical-session.target stop
    systemd.user.services.kanshi.Service.Restart = lib.mkForce "on-failure";

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
            name = "yamaha";
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
            name = "yamaha-index";
            outputs = [
              {
                criteria = yamaha;
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
            name = "tv-quarto";
            outputs = [
              {
                criteria = tv;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = quarto;
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
            name = "yamaha-quarto";
            outputs = [
              {
                criteria = yamaha;
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                scale = 2.666667;
              }
              {
                criteria = quarto;
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
      ];
    };
  };
}
