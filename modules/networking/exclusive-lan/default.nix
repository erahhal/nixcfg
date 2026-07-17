{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.exclusive-lan;

  exclusive-lan = pkgs.writeShellScriptBin "70-wifi-wired-exclusive.sh" ''
    NMCLI=${pkgs.networkmanager}/bin/nmcli
    GREP=${pkgs.gnugrep}/bin/grep
    IP=${pkgs.iproute2}/bin/ip
    FLOCK=${pkgs.util-linux}/bin/flock

    export LC_ALL=C

    case "$2" in
        up|down|connectivity-change) ;;
        *) exit 0 ;;
    esac

    # When invoked from the boot reconcile service (not by nm-dispatcher),
    # wait for NM to finish activating autoconnect profiles first, so the
    # ethernet check below reflects settled state rather than a mid-DHCP
    # "connecting" device.
    if [ "$1" = "boot" ]; then
        ${pkgs.networkmanager}/bin/nm-online -s -q --timeout 30 || true
    fi

    # Single-instance lock. Both `nmcli radio wifi off` and `nmcli device
    # reapply` themselves emit dispatcher events (down, connectivity-change)
    # that re-fire this script. Without a lock, those re-entries race the
    # 2-second sleep below, see "no IPv4 default" mid-DHCP, and trigger a
    # cascade of reapplies that leaves the wired interface stuck without an
    # IPv4 address until NetworkManager is restarted by hand.
    exec 9>/run/exclusive-lan.lock
    $FLOCK -n 9 || exit 0

    ethernet_connected () {
        $NMCLI dev | $GREP "ethernet" | $GREP -q -w "connected"
    }

    wifi_enabled () {
        [ "$($NMCLI radio wifi 2>/dev/null)" = "enabled" ]
    }

    enable_disable_wifi ()
    {
        if ethernet_connected; then
            # Only act on the wifi-on -> wifi-off transition. A connectivity-
            # change event triggered by our own reapply will see wifi already
            # disabled and exit, breaking the feedback loop.
            wifi_enabled || return 0

            $NMCLI radio wifi off
            # NM route recalculation can drop the wired default route during
            # wifi shutdown (noprefixroute means the kernel won't auto-create
            # it). Wait for NM to settle, then reapply the wired connection if
            # the IPv4 default route is still missing -- this re-runs DHCP and
            # restores the route.
            sleep 2
            if ! $IP -4 route show default 2>/dev/null | $GREP -q .; then
                wired_dev=$($NMCLI -t -f DEVICE,TYPE,STATE dev 2>/dev/null \
                            | $GREP "ethernet:connected" | head -1 | cut -d: -f1)
                if [ -n "$wired_dev" ]; then
                    $NMCLI device reapply "$wired_dev" 2>/dev/null || true
                fi
            fi
        else
            wifi_enabled && return 0

            $NMCLI radio wifi on
            sleep 2
            $NMCLI device wifi rescan || true
        fi
    }

    enable_disable_wifi
  '';
in {
  options.nixcfg.networking.exclusive-lan = {
    enable = lib.mkEnableOption "mutually exclusive WiFi/wired networking";
  };
  config = lib.mkIf cfg.enable {
    networking = {
      wireless.enable = false;
      networkmanager.dispatcherScripts = [
        { source = "${exclusive-lan}/bin/70-wifi-wired-exclusive.sh"; }
      ];
    };

    # NM persists `nmcli radio wifi off` (WirelessEnabled=false in
    # /var/lib/NetworkManager/NetworkManager.state) across reboots. After a
    # docked shutdown followed by an undocked boot, no dispatcher event ever
    # fires (wifi is off, no ethernet carrier), so the script above never
    # gets a chance to re-enable wifi. Reconcile once at boot instead.
    # RemainAfterExit keeps `nixos-rebuild switch` from re-running it
    # mid-session (see ath11k-boot-fix history for why that matters).
    systemd.services.exclusive-lan-reconcile = {
      description = "Reconcile WiFi radio state with wired connectivity at boot";
      after = [ "NetworkManager.service" ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${exclusive-lan}/bin/70-wifi-wired-exclusive.sh boot up";
      };
    };
  };
}
