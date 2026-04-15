{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;

  ddcutil = "${pkgs.ddcutil}/bin/ddcutil";
  modprobe = "/run/current-system/sw/bin/modprobe";
  notify-send = "${pkgs.libnotify}/bin/notify-send";

  toggle-thinkvision-input = pkgs.writeShellScript "toggle-input" ''
    notify() {
      ${notify-send} -t 3000 "Monitor Input" "$1"
    }

    try_detect() {
      ${ddcutil} detect --sleep-multiplier 2 2>/dev/null | grep -i "P40w-20"
    }

    get_bus() {
      ${ddcutil} detect --sleep-multiplier 2 2>/dev/null | grep -B 4 "P40w-20" | grep "I2C bus:" | sed -E 's/.*\/dev\/i2c-([0-9]+).*/\1/'
    }

    MONITOR_CONNECTED=$(try_detect)

    # If not found, try reloading i2c-dev and retry
    if [ -z "$MONITOR_CONNECTED" ]; then
      for attempt in 1 2; do
        sudo ${modprobe} -r i2c-dev 2>/dev/null
        sudo ${modprobe} i2c-dev 2>/dev/null
        sleep 1
        MONITOR_CONNECTED=$(try_detect)
        [ -n "$MONITOR_CONNECTED" ] && break
      done
    fi

    if [ -z "$MONITOR_CONNECTED" ]; then
      notify "P40w-20 not detected (DDC/CI unavailable through dock MST)"
      exit 1
    fi

    BUS_NUMBER=$(get_bus)
    if [ -z "$BUS_NUMBER" ]; then
      notify "Could not determine I2C bus for P40w-20"
      exit 1
    fi

    CURRENT_INPUT=$(${ddcutil} --bus "$BUS_NUMBER" --sleep-multiplier 2 getvcp 60 2>/dev/null | grep -o "sl=0x[0-9a-f]\+" | cut -d'x' -f2)
    CURRENT_INPUT=''${CURRENT_INPUT#0x}
    CURRENT_INPUT=$(echo "$CURRENT_INPUT" | tr '[:upper:]' '[:lower:]')

    if [ "$CURRENT_INPUT" = "0f" ] || [ "$CURRENT_INPUT" = "f" ]; then
      ${ddcutil} --bus "$BUS_NUMBER" --sleep-multiplier 2 setvcp 60 0x31 2>/dev/null
      notify "Switched to HDMI-2"
    elif [ "$CURRENT_INPUT" = "31" ]; then
      ${ddcutil} --bus "$BUS_NUMBER" --sleep-multiplier 2 setvcp 60 0x0f 2>/dev/null
      notify "Switched to DisplayPort-1"
    else
      notify "Unknown current input: 0x$CURRENT_INPUT"
    fi
  '';
in
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
  };
}
