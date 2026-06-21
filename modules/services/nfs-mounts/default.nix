{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.services.nfs-mounts;

  nfs3Options = [
    "nfsvers=3"
    "async"
    "actimeo=60"
    "nocto"
  ];
in {
  imports = [ ../../system/write-cache ];

  options.nixcfg.services.nfs-mounts = {
    enable = lib.mkEnableOption "NFS mounts to Synology NAS";
  };
  config = lib.mkIf cfg.enable {
    services.rpcbind.enable = true;

    services.nfs = {
      idmapd.settings = {
        General = {
          Domain = "rahh.al";
        };
      };
    };

    # Ensure a connected route exists for the NAS subnet.
    # NetworkManager sets noprefixroute on interface addresses, which prevents
    # the kernel from adding a connected route for the subnet automatically.
    # Without this route, LAN traffic to the NAS goes via the gateway (which
    # won't forward it back to the same subnet) and Mullvad's "lan allow"
    # feature (suppress_prefixlength 0) can't find a matching LAN route.
    systemd.services.nfs-lan-route = {
      description = "Ensure LAN route exists for NFS mounts";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # The NM dispatcher (below) restarts this on every network event, which
      # can burst past systemd's default StartLimitBurst=5/10s at boot.
      unitConfig = {
        StartLimitIntervalSec = 30;
        StartLimitBurst = 20;
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5190 2>/dev/null || true";
      };

      script = ''
        # Always start clean. This rule is higher-priority (lower number) than
        # other VPNs' 10.0.0.0/24 handling (e.g. Tailscale's accepted subnet
        # route), so a stale copy left over after roaming OFF the LAN pins the
        # subnet to the main table -- which has no route for it off-LAN -- and
        # black-holes traffic that should flow through the active VPN.
        ${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5190 2>/dev/null || true

        # Find the interface with an IP on the NAS subnet (10.0.0.0/24)
        IFACE=$(${pkgs.iproute2}/bin/ip -4 -o addr show | ${pkgs.gawk}/bin/awk '/10\.0\.0\./ {print $2; exit}')

        if [ -n "$IFACE" ]; then
          ${pkgs.iproute2}/bin/ip route replace 10.0.0.0/24 dev "$IFACE" proto static scope link
          echo "Added LAN route: 10.0.0.0/24 dev $IFACE"

          # On-LAN only: force NAS traffic out the local interface, bypassing VPN
          # routing (before Mullvad's rules at 5198). Off-LAN this rule must NOT
          # exist, or it black-holes 10.0.0.0/24 that should flow via the VPN.
          ${pkgs.iproute2}/bin/ip rule add to 10.0.0.0/24 lookup main priority 5190
          echo "On LAN ($IFACE) -- added policy rule: to 10.0.0.0/24 lookup main priority 5190"
        else
          echo "Off LAN -- skipped LAN route and policy rule; 10.0.0.0/24 routes via VPN"
        fi
      '';
    };

    # Re-run nfs-lan-route on every network change so the priority-5190 policy
    # rule is added when we land on the home LAN and removed when we roam off
    # it. Without this the rule is only evaluated at boot and goes stale --
    # which black-holes 10.0.0.0/24 over whichever VPN is active off-LAN.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "nfs-lan-route-dispatch" ''
          case "$2" in
            up|down|vpn-up|vpn-down|dhcp4-change|dhcp6-change|connectivity-change)
              ${pkgs.systemd}/bin/systemctl restart --no-block \
                nfs-lan-route.service || true
              ;;
          esac
        '';
      }
    ];

    fileSystems."/mnt/data" = {
      device = "10.0.0.1:/mnt/data";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };
  };
}
