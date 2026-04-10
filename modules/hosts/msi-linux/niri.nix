{ lib, ... }:
{
  programs.niri.settings = {
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
      "LG Electronics LG TV SSCR2 0x01010101" = {
        mode = { width = 3840; height = 2160; };
        scale = 2.666667;
        variable-refresh-rate = true;
      };
      "Yamaha Corporation - RX-A2A" = {
        mode = { width = 3840; height = 2160; };
        scale = 2.666667;
        variable-refresh-rate = true;
      };
    };

    environment = {
      STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };

    spawn-at-startup = [
      { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
      { argv = [ "niri" "msg" "action" "focus-workspace" "ten" ]; }
    ];
  };
}
