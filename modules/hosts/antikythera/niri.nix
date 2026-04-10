{ config, lib, ... }:
let userParams = config.hostParams.user; in
{
  services.displayManager.dms-greeter = {
    compositor.customConfig = lib.mkAfter ''
      // Internal laptop display on the left
      // ThinkVision logical: 3843x1621, Laptop logical: 1600x1000
      // Bottom-align: y = 1621 - 1125 = 496
      output "eDP-1" {
        mode "2880x1800@120"
        scale 1.8
        position x=0 y=800
        variable-refresh-rate
      }

      // ThinkVision on the right
      output "Lenovo Group Limited P40w-20 V90DFGMV" {
        mode "5120x2160@60.000"
        scale 1.333333
        position x=1600 y=0
        focus-at-startup
        variable-refresh-rate
      }
    '';
  };

  home-manager.users.${userParams.username} = {
    programs.niri.settings = {
      debug = {
        render-drm-device = "/dev/dri/by-path/pci-0000:c4:00.0-render";
      };

      outputs = {
        "eDP-1" = {
          mode = { width = 2880; height = 1800; refresh = 120.0; };
          scale = 1.8;
          variable-refresh-rate = true;
        };
        "Lenovo Group Limited P40w-20 V90DFGMV" = {
          mode = { width = 5120; height = 2160; refresh = 60.0; };
          scale = 1.333333;
          variable-refresh-rate = true;
        };
        "LG Electronics 16MQ70 20NKZ005285" = {
          mode = { width = 2560; height = 1600; refresh = 60.0; };
          scale = 1.6;
          variable-refresh-rate = true;
        };
        "LG Electronics LG Ultra HD 0x00043EAD" = {
          mode = { width = 3840; height = 2160; refresh = 60.0; };
          scale = 1.5;
          variable-refresh-rate = true;
        };
        "LG Electronics L33HD334K 0x00020F5B" = {
          mode = { width = 3840; height = 2160; refresh = 60.0; };
          scale = 1.5;
          variable-refresh-rate = true;
        };
      };

      environment = {
        STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
      };

      spawn-at-startup = [
        { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
        { argv = [ "niri" "msg" "action" "focus-workspace" "five" ]; }
      ];
    };
  };
}
