{ inputs, pkgs, userParams, ... }:
let
  wlr-randr = "${pkgs.wlr-randr}/bin/wlr-randr";
  grep = "${pkgs.gnugrep}/bin/grep";
  awk = "${pkgs.gawk}/bin/awk";
  # home-monitor-left-sway = ''"LG Electronics LG Ultra HD 0x00003EAD"'';
  # home-monitor-right-sway = ''"LG Electronics LG HDR 4K 0x00000F5B"'';
  home-monitor-left-sway = ''$(${wlr-randr} | ${grep} "LG Electronics LG Ultra HD 0x00003EAD" | ${awk} '{print $1}')'';
  home-monitor-right-sway = ''$(${wlr-randr} | ${grep} "LG Electronics LG HDR 4K 0x00000F5B" | ${awk} '{print $1}')'';
  # home-monitor-left-sway = "left";
  # home-monitor-right-sway = "right";
  home-monitor-left-hyprland = "LG Electronics LG Ultra HD 0x00043EAD";
  home-monitor-right-hyprland = "LG Electronics LG HDR 4K 0x00020F5B";
  portable-monitor = "LG Electronics 16MQ70 204NZKZ005285";
  # hyprland = pkgs.hyprland;
  # hyprland = pkgs.trunk.hyprland;
  # hyprland = pkgs.unstable.hyprland-patched;
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  hyprctl="${hyprland}/bin/hyprctl";
  swaymsg="${pkgs.sway}/bin/swaymsg";
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
                mode = "3840x2160";
                position = "0,0";
                scale = 2.0;
              }
            ];
            exec = [
              "boltctl forget --all"
            ];
          };
        }
        {
          profile = {
            name = "desk-sway";
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
            exec = [
              "${swaymsg} workspace 1, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 2, move workspace to output ${home-monitor-right-sway}"
              "${swaymsg} workspace 3, move workspace to output ${home-monitor-right-sway}"
              "${swaymsg} workspace 4, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 5, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 6, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 7, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 8, move workspace to output ${home-monitor-left-sway}"
              "${swaymsg} workspace 9, move workspace to output ${home-monitor-left-sway}"
            ];
          };
        }
        {
          profile = {
            name = "desk-hyprland";
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
        }
        {
          profile = {
            name = "desk-left";
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
        }
        {
          profile = {
            name = "desk-right";
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
        }
      ];
    };
  };
}
