{ inputs, pkgs, userParams, ... }:
let
  home-monitor-left-sway = "LG Electronics LG Ultra HD 0x00003EAD";
  home-monitor-right-sway = "LG Electronics LG HDR 4K 0x00000F5B";
  home-monitor-left-hyprland = "LG Electronics LG Ultra HD 0x00043EAD";
  home-monitor-right-hyprland = "LG Electronics LG HDR 4K 0x00020F5B";
  portable-monitor = "LG Electronics 16MQ70 204NZKZ005285";
  hyprctl="${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl";
in
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
              status = "disable";
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
              status = "disable";
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
