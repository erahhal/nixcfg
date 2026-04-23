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

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5190 2>/dev/null || true";
      };

      script = ''
        # Find the interface with an IP on the NAS subnet (10.0.0.0/24)
        IFACE=$(${pkgs.iproute2}/bin/ip -4 -o addr show | ${pkgs.gawk}/bin/awk '/10\.0\.0\./ {print $2; exit}')

        if [ -n "$IFACE" ]; then
          ${pkgs.iproute2}/bin/ip route replace 10.0.0.0/24 dev "$IFACE" proto static scope link
          echo "Added LAN route: 10.0.0.0/24 dev $IFACE"
        else
          echo "Warning: No interface found on 10.0.0.0/24 subnet"
        fi

        # Ensure LAN traffic bypasses VPN routing (before Mullvad's rules at 5198)
        ${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5190 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule add to 10.0.0.0/24 lookup main priority 5190
        echo "Added policy rule: to 10.0.0.0/24 lookup main priority 5190"
      '';
    };

    fileSystems."/mnt/ellis" = {
      device = "10.0.0.42:/volume1/ellis";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/family-files" = {
      device = "10.0.0.42:/volume1/family-files";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/nas-home" = {
      device = "10.0.0.42:/volume1/homes";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };
  };
}
