{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.desktop.pipewire;
in {
  options.nixcfg.desktop.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio";
  };
  config = lib.mkIf cfg.enable {
    users.users."${userParams.username}" = {
      extraGroups = [
        "audio"
        "rtkit"
        "video"
      ];
    };

    hardware.enableAllFirmware = true;

    # Enable the Real-Time Kit for improved performance
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      ## Should be default enabled
      wireplumber.enable = true;

      # Bluetooth headset behavior: ensure mic auto-engages (HSP/HFP) when an
      # app records, then restores A2DP after. Defaults match upstream but
      # pinning makes regressions visible.
      wireplumber.extraConfig."51-bluetooth-policy" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
          "bluetooth.use-persistent-storage" = true;
        };
        "monitor.bluez.properties" = {
          "bluez5.enable-msbc" = true;
          "bluez5.enable-sbc-xq" = true;
          "bluez5.hfphsp-backend" = "native";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
      # for pactl
      pulseaudio
    ];

    # EasyEffects exposes easyeffects_source as media.class=Audio/Source/Virtual
    # without a node.link-group. WirePlumber's bluetooth autoswitch can't walk
    # back through this virtual source to find the bluez_input loopback, so
    # the A2DP->HSP profile switch never fires when an app records via
    # easyeffects_source. Strip any saved per-app target that pins recording
    # apps to easyeffects_source so they fall back to the system default
    # source (the real bluez_input or microphone), letting autoswitch work.
    systemd.user.services.wireplumber-strip-easyeffects-input-targets = {
      description = "Strip stale easyeffects_source input targets from WirePlumber state";
      before = [ "wireplumber.service" "pipewire.service" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "strip-ee-input-targets" ''
          set -eu
          f="''${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/stream-properties"
          [ -f "$f" ] || exit 0
          if grep -q '^Input/Audio:.*"target":"easyeffects_source"' "$f"; then
            ${pkgs.gnused}/bin/sed -i.bak '/^Input\/Audio:.*"target":"easyeffects_source"/d' "$f"
            echo "Stripped easyeffects_source input targets from $f" >&2
          fi
        '';
      };
    };
  };
}
