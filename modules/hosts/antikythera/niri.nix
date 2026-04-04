{ lib, userParams, ... }:
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
        mode "5120x2160@60.000" // Don't use 74.97899 rate as it requires negotation and sometimes hangs for 20 seconds before displaying anything
        scale 1.333333
        position x=1600 y=0
        focus-at-startup
        variable-refresh-rate
      }
    '';
  };

  home-manager.users.${userParams.username} = {
    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      debug {
          honor-xdg-activation-with-invalid-serial
          // Explicitly set render device to avoid detection delay at startup
          render-drm-device "/dev/dri/by-path/pci-0000:c4:00.0-render"
      }

      output "eDP-1" {
        mode "2880x1800@120"
        scale 1.8
        variable-refresh-rate
      }
      output "Lenovo Group Limited P40w-20 V90DFGMV" {
        mode "5120x2160@60.000" // Don't use 74.97899 rate as it requires negotation and sometimes hangs for 20 seconds before displaying anything
        scale 1.333333
        variable-refresh-rate
      }
      output "LG Electronics 16MQ70 20NKZ005285" {
        mode "2560x1600@60"
        scale 1.6
        variable-refresh-rate
      }
      output "LG Electronics LG Ultra HD 0x00043EAD" {
        mode "3840x2160@60"
        scale 1.5
        variable-refresh-rate
      }
      output "LG Electronics L33HD334K 0x00020F5B" {
        mode "3840x2160@60"
        scale 1.5
        variable-refresh-rate
      }

      environment {
        STEAM_FORCE_DESKTOPUI_SCALING "2.0"
      }

      //  workspace = [
      //    "desc:LG Electronics LG Ultra HD 0x00043EAD, 1"
      //    "desc:LG Electronics LG Ultra HD 0x00043EAD, 4"
      //    "desc:LG Electronics LG Ultra HD 0x00043EAD, 5"
      //    "desc:LG Electronics LG HDR 4K 0x00020F5B, 2"
      //    "desc:LG Electronics LG HDR 4K 0x00020F5B, 7"
      //  ];

      // Most apps launched via systemd service (startup-apps.nix)
      // foot launched here because systemd user services cannot use setuid binaries like sudo
      spawn-at-startup "foot" "tmux" "a" "-dt" "code"
      spawn-at-startup "niri" "msg" "action" "focus-workspace" "five"
    '';
  };
}
