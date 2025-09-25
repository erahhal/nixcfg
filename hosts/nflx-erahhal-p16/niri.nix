{ lib, ... }:
{
  xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
    debug {
        honor-xdg-activation-with-invalid-serial
        // Only use intel
        render-drm-device "/dev/dri/by-path/pci-0000:00:02.0-card"
        // Only use nvidia
        // render-drm-device "/dev/dri/by-path/pci-0000:01:00-0.card"
    }

    output "eDP-1" {
      mode "3840x2400@60"
      scale 2.1333333
      focus-at-startup
    }
    // ThinkVision
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2150@60.000"
      scale 1.332031
    }
    // Portable
    output "LG Electronics 16MQ70 20NKZ005285" {
      mode "2560x1600@60"
      scale 1.6
      position x=1801 y=200
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

    output "Dell Inc. DELL C3422WE F3BJT83" {
      mode "3440x1440@59.973000"
      scale 1.0
    }

    environment {
        STEAM_FORCE_DESKTOPUI_SCALING "2.0"
        // @TODO Determine how much more energy this uses. Maybe better to just leave it out
        // __NV_PRIME_RENDER_OFFLOAD "1"
        // __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0"
        // __VK_LAYER_NV_optimus = "NVIDIA_only"
    }

    spawn-at-startup "chromium"
    spawn-at-startup "foot" "tmux" "a" "-dt" "code"
    spawn-at-startup "slack"
    spawn-at-startup "spotify"
    spawn-at-startup "brave"
    spawn-at-startup "firefox"
    spawn-at-startup "signal-desktop"
    spawn-at-startup "Telegram"
    // spawn-at-startup "whatsapp-for-linux"
    spawn-at-startup "vesktop"
    spawn-at-startup "element-desktop"
    spawn-at-startup "joplin-desktop"
    spawn-at-startup "niri" "msg" "action" "focus-workspace" "1"
  '';
}
