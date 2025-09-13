{ lib, ... }:
{
  xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
    output "eDP-1" {
      mode "2880x1800@120"
      scale 1.8
    }
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2150@60.000"
      scale 1.332031
    }
    output "LG Electronics 16MQ70 20NKZ005285" {
      mode "2560x1600@60"
      scale 1.6
    }
    output "LG Electronics LG Ultra HD 0x00043EAD" {
      mode "3840x2160@60"
      scale 1.5
    }
    output "LG Electronics L33HD334K 0x00020F5B" {
      mode "3840x2160@60"
      scale 1.5
    }
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2160@74.978996"
      scale 1.333333
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

    spawn-at-startup "foot" "tmux" "a" "-dt" "code"
    spawn-at-startup "spotify"
    spawn-at-startup "brave"
    spawn-at-startup "firefox"
    spawn-at-startup "signal-desktop"
    spawn-at-startup "Telegram"
    // spawn-at-startup "whatsapp-for-linux"
    spawn-at-startup "vesktop"
    spawn-at-startup "element-desktop"
    spawn-at-startup "joplin-desktop"
    spawn-at-startup "niri" "msg" "action" "focus-workspace" "5"
  '';
}
