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

    # EasyEffects stores its chosen output device by node name in dconf, and
    # re-links its output chain to nothing if that node is gone. Sink names are
    # not stable: when WirePlumber starts applying a UCM profile to a card (an
    # alsa-ucm-conf / wireplumber bump is enough), a sink renames from
    # alsa_output.<pci>.HiFi__hw_Generic_1__sink to
    # alsa_output.<pci>.HiFi__Speaker__sink. The saved name then points at
    # nothing, and every app routed through easyeffects_sink goes silent with no
    # error anywhere: the stream plays into EasyEffects and dead-ends, while the
    # hardware sink sits IDLE and unmuted at full volume.
    #
    # Repair the saved name rather than pinning one, since the correct value is
    # per-host (PCI path) and changes across upgrades. No-op in steady state.
    systemd.user.services.easyeffects-fix-stale-output-device =
      lib.mkIf config.hostParams.desktop.easyeffects.enable {
        description = "Repoint EasyEffects at a live sink if its saved one is gone";
        after = [ "pipewire.service" "wireplumber.service" ];
        before = [ "easyeffects.service" ];
        # Also pulled in by wireplumber.service so the check re-runs when
        # PipeWire restarts mid-session (a nixos-rebuild switch does this),
        # which is when the rename actually lands. EasyEffects binds the
        # GSettings key, so it picks up the rewrite live without a restart.
        wantedBy = [ "graphical-session.target" "wireplumber.service" ];
        path = with pkgs; [ dconf pulseaudio coreutils gnugrep gawk ];
        serviceConfig = {
          Type = "oneshot";
          # dconf writes go through the session bus; a user unit does not
          # reliably inherit DBUS_SESSION_BUS_ADDRESS.
          Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
          ExecStart = pkgs.writeShellScript "fix-ee-output-device" ''
            set -eu
            key=/com/github/wwmm/easyeffects/streamoutputs/output-device

            # Device enumeration is async, so checking immediately after
            # pipewire.service comes up races an empty sink list and would
            # "repair" against nothing. Wait for a real hardware sink.
            sinks=""
            for _ in $(seq 1 30); do
              sinks=$(pactl list sinks short 2>/dev/null | awk '{print $2}' || true)
              case "$sinks" in *alsa_output.*) break ;; esac
              sleep 0.5
            done
            case "$sinks" in
              *alsa_output.*) ;;
              *) echo "no hardware sink appeared; leaving $key alone" >&2; exit 0 ;;
            esac

            current=$(dconf read "$key" 2>/dev/null | tr -d "'" || true)
            # Empty means EasyEffects follows the default sink; nothing to fix.
            [ -n "$current" ] || exit 0
            # Saved sink still exists: steady state, the common case.
            if printf '%s\n' "$sinks" | grep -qxF "$current"; then exit 0; fi

            # Stale. Prefer the current default sink, but never point EasyEffects
            # at its own virtual sink -- that feeds its output back to its input.
            target=$(pactl get-default-sink 2>/dev/null || true)
            case "$target" in
              ""|easyeffects_sink)
                target=$(printf '%s\n' "$sinks" | grep -m1 '^alsa_output\.' || true) ;;
            esac
            if [ -z "$target" ] || [ "$target" = easyeffects_sink ]; then
              echo "no usable replacement sink; leaving $key at '$current'" >&2
              exit 0
            fi

            dconf write "$key" "'$target'"
            echo "EasyEffects output device '$current' is gone; repointed to '$target'" >&2
          '';
        };
      };
  };
}
