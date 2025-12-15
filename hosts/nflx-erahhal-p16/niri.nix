{ osConfig, lib, ... }:
let
  usingIntel = osConfig.hostParams.gpu.intel.enable;
in
{
  xdg.configFile."niri/config.kdl".text = lib.mkAfter (''
    debug {
        honor-xdg-activation-with-invalid-serial
  ''
  +
  ## @IMPORTANT NOTE: On Hybrid setup:
  ## - Internal display is driven by intel GPU
  ## - External display is driven by nvidia GPU
  ## - Rendering on intel and offloading to nvidia is slow on external monitors, especially high resolution ones.
  ## - Rendering on nvidia and offloading to intel is slow on laptop monitor, but tolerable
  ## - SO, make sure window manager is using discrete nvidia GPU to render

  ## BUUUUT it seems that Niri is faster at copying now? Using Intel and perf is not THAT bad
  (if usingIntel then ''
        // Use Nvidia GPU as primary
        // See comment above
        render-drm-device "/dev/dri/by-path/pci-0000:01:00.0-render"
  '' else "")
  +
  ''
    }

    output "eDP-1" {
      mode "3840x2400@60"
      scale 2.1333333
      focus-at-startup
      variable-refresh-rate
    }
    // ThinkVision
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2150@60.000"
      scale 1.332031
      variable-refresh-rate
    }
    // Portable
    output "LG Electronics 16MQ70 20NKZ005285" {
      mode "2560x1600@60"
      scale 1.6
      position x=1801 y=200
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
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2160@74.978996"
      scale 1.333333
      variable-refresh-rate
    }

    output "Dell Inc. DELL C3422WE F3BJT83" {
      mode "3440x1440@59.973000"
      scale 1.0
      variable-refresh-rate
    }

    environment {
        STEAM_FORCE_DESKTOPUI_SCALING "2.0"
        // @TODO Determine how much more energy this uses. Maybe better to just leave it out
        // __NV_PRIME_RENDER_OFFLOAD "1"
        // __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0"
        // __VK_LAYER_NV_optimus = "NVIDIA_only"
    }

    // Apps moved to systemd services (startup-apps.nix)
    spawn-at-startup "niri" "msg" "action" "focus-workspace" "1"
  '');
}
