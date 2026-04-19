{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  usingIntel = config.hostParams.gpu.intel.enable;
  defaultIntel = config.hostParams.gpu.intel.defaultWindowManagerGpu;
  renderDevice =
    if usingIntel && defaultIntel then "/dev/dri/by-path/pci-0000:00:02.0-render"
    else if usingIntel then "/dev/dri/by-path/pci-0000:01:00.0-render"
    else null;

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
  # DMS greeter still uses KDL string for debug block
  debug-block = ''
      debug {
          honor-xdg-activation-with-invalid-serial
    ''
    + (if usingIntel && defaultIntel then ''
          render-drm-device "/dev/dri/by-path/pci-0000:00:02.0-render"
    '' else if usingIntel then ''
          render-drm-device "/dev/dri/by-path/pci-0000:01:00.0-render"
    '' else "")
    + ''
      }
  '';

  greeter-compositor-config = lib.mkAfter ''
    ${debug-block}

    // ThinkVision on the left
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2160@60.000"
      scale 1.333333
      position x=0 y=0
      variable-refresh-rate
      focus-at-startup
    }

    // Internal laptop display on the right
    output "eDP-1" {
      mode "3840x2400@60"
      scale 2.1333333
      position x=3843 y=1300
      variable-refresh-rate
    }
  '';
in
{
  # Set both option paths so the config applies whether the greeter is
  # sourced from the DMS flake (programs.dank-material-shell.greeter) or
  # from the nixpkgs-native module (services.displayManager.dms-greeter).
  # Only one is active at a time; the unused one is a no-op.
  programs.dank-material-shell.greeter.compositor.customConfig = greeter-compositor-config;
  services.displayManager.dms-greeter.compositor.customConfig = greeter-compositor-config;

  home-manager.users.${userParams.username} = {
    programs.niri.settings = {
      debug = lib.mkIf (renderDevice != null) {
        render-drm-device = renderDevice;
      };

      outputs = {
        "eDP-1" = {
          mode = { width = 3840; height = 2400; refresh = 60.0; };
          scale = 2.1333333;
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
          position = { x = 1801; y = 200; };
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
        "Dell Inc. DELL C3422WE F3BJT83" = {
          mode = { width = 3440; height = 1440; refresh = 59.973; };
          scale = 1.0;
          variable-refresh-rate = true;
        };
      };

      environment = {
        STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
      };

      spawn-at-startup = [
        { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
        { argv = [ "niri" "msg" "action" "focus-workspace" "one" ]; }
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
