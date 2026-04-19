{ lib, pkgs, ... }:
let
  toggle-thinkvision-input = pkgs.writeShellScript "toggle-input" ''
    CACHE="/tmp/thinkvision_bus"

    get_bus() {
      if [ -f "$CACHE" ]; then
        cached=$(cat "$CACHE")
        if ${pkgs.ddcutil}/bin/ddcutil --bus "$cached" --skip-ddc-checks getvcp 60 &>/dev/null; then
          echo "$cached"
          return
        fi
        rm -f "$CACHE"
      fi

      BUS=$(${pkgs.ddcutil}/bin/ddcutil detect 2>/dev/null | grep -B 4 "P40w-20" | grep "I2C bus:" | sed -E 's/.*\/dev\/i2c-([0-9]+).*/\1/')
      if [ -n "$BUS" ]; then
        echo "$BUS" > "$CACHE"
        echo "$BUS"
      fi
    }

    BUS_NUMBER=$(get_bus)
    if [ -z "$BUS_NUMBER" ]; then
      echo "ThinkVision P40w-20 not detected."
      exit 1
    fi

    CURRENT_INPUT=$(${pkgs.ddcutil}/bin/ddcutil --bus "$BUS_NUMBER" --skip-ddc-checks getvcp 60 2>/dev/null | grep -o "sl=0x[0-9a-f]\+" | cut -d'x' -f2)
    CURRENT_INPUT=''${CURRENT_INPUT#0x}
    CURRENT_INPUT=$(echo "$CURRENT_INPUT" | tr '[:upper:]' '[:lower:]')

    if [ "$CURRENT_INPUT" = "0f" ] || [ "$CURRENT_INPUT" = "f" ]; then
      ${pkgs.ddcutil}/bin/ddcutil --bus "$BUS_NUMBER" --skip-ddc-checks --noverify setvcp 60 0x31
    elif [ "$CURRENT_INPUT" = "31" ]; then
      ${pkgs.ddcutil}/bin/ddcutil --bus "$BUS_NUMBER" --skip-ddc-checks --noverify setvcp 60 0x0f
    fi
  '';
in
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

    binds = {
      "Mod+G" = lib.mkForce { hotkey-overlay.title = "Switch ThinkVision Monitor Input"; allow-when-locked = true; action.spawn = "${toggle-thinkvision-input}"; };
    };

    workspaces = {
      "01-one" = { open-on-output = "eDP-1"; };
      "02-two" = { open-on-output = "eDP-1"; };
      "03-three" = { open-on-output = "eDP-1"; };
      "04-four" = { open-on-output = "eDP-1"; };
      "05-five" = { open-on-output = "eDP-1"; };
      "06-six" = { open-on-output = "eDP-1"; };
      "07-seven" = { open-on-output = "eDP-1"; };
      "08-eight" = { open-on-output = "eDP-1"; };
      "09-nine" = { open-on-output = "eDP-1"; };
      "10-ten" = { open-on-output = "eDP-1"; };
    };
  };
}
