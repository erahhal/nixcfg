{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.networking.tailscale;
  # Reference the existing tailscale config
  tsCfg = config.services.tailscale;

  # Wrap tailscale to fix DNS cleanup bug on 'tailscale down'
  # Bug: https://github.com/tailscale/tailscale/issues/18441
  upFlags = tsCfg.extraUpFlags;

  tailscaleWrapped = pkgs.writeShellScriptBin "tailscale" ''
    if [ "$1" = "up" ]; then
      shift
      # Inject configured flags so bare 'tailscale up' works
      ${pkgs.tailscale}/bin/tailscale up \
        ${lib.concatStringsSep " \\\n        " upFlags} \
        "$@"
      EXIT_CODE=$?
    else
      ${pkgs.tailscale}/bin/tailscale "$@"
      EXIT_CODE=$?
    fi

    # If the command was 'down', fix the DNS configuration
    # Bug: https://github.com/tailscale/tailscale/issues/18441
    if [ "$1" = "down" ]; then
      IFIDX=$(cat /sys/class/net/tailscale0/ifindex 2>/dev/null)
      if [ -n "$IFIDX" ]; then
        ${pkgs.dbus}/bin/busctl call org.freedesktop.resolve1 /org/freedesktop/resolve1 \
          org.freedesktop.resolve1.Manager RevertLink i "$IFIDX" 2>/dev/null || true
      fi
    fi

    exit $EXIT_CODE
  '';

  # Build the tsup script from existing config. Tailscale does not auto-start
  # at boot (one VPN at a time), so bring the daemon up first, then connect.
  # systemctl needs root -- run `sudo tsup`.
  tsupScript = pkgs.writeShellScriptBin "tsup" ''
    ${pkgs.systemd}/bin/systemctl start tailscaled.service
    exec ${pkgs.tailscale}/bin/tailscale up \
      ${lib.concatStringsSep " \\\n      " tsCfg.extraUpFlags} \
      "$@"
  '';
in {
  options.nixcfg.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN with DNS fixes";
  };
  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # Per-host agenix secret (hosts/<host>/secrets/secrets.nix). mkIf so hosts
      # that enable tailscale without the secret declared just get no authKeyFile.
      authKeyFile = lib.mkIf (config.age.secrets ? "tailscale-key")
        config.age.secrets."tailscale-key".path;
      authKeyParameters = {
        preauthorized = true;
        baseURL = "https://vpn.homefree.host";
      };
      extraUpFlags = [
        "--accept-routes"
        "--netfilter-mode=nodivert"
        "--login-server=https://vpn.homefree.host"
        "--operator=${userParams.username}"
      ];
      # Disable logs/telemetry to Tailscale
      extraDaemonFlags = [
        "--no-logs-no-support"
      ];
    };

    # Add wrapped tailscale and tsup to system packages
    environment.systemPackages = [ tailscaleWrapped tsupScript ];

    # Do not start Tailscale at boot. The user runs one VPN at a time and
    # brings Tailscale up on demand with `tsup`. Keeping the daemon (and its
    # DNS/route helpers, which are lifecycle-bound to it below) from
    # auto-starting means an idle/logged-out Tailscale never touches resolved
    # or the routing tables at boot -- which is also what previously baked in
    # the DNS bootstrap deadlock (split-DNS pinning *.homefree.host, including
    # the control server vpn.homefree.host, to dead MagicDNS while logged out).
    systemd.services.tailscaled.wantedBy = lib.mkForce [];
    systemd.services.tailscaled-autoconnect = {
      wantedBy = lib.mkForce [];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Re-run tailscale-local-route whenever the network changes. The service
    # itself is oneshot and only runs at boot; without this, roaming off the
    # home LAN (or onto it) leaves the priority-5195 policy rule in a stale
    # state. Off-LAN that stale rule pins 10.0.0.0/24 to the main table, which
    # has no route for it, black-holing traffic that should flow through
    # Tailscale's accepted subnet route.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "tailscale-local-route-dispatch" ''
          # Only manage Tailscale routing while Tailscale is actually up;
          # otherwise this churns a 30s-waiting oneshot on every network event.
          ${pkgs.systemd}/bin/systemctl is-active --quiet tailscaled.service || exit 0
          case "$2" in
            up|down|vpn-up|vpn-down|dhcp4-change|dhcp6-change|connectivity-change)
              ${pkgs.systemd}/bin/systemctl restart --no-block \
                tailscale-local-route.service || true
              ;;
          esac
        '';
      }
    ];

    # Prevent Tailscale from routing local LAN traffic (10.0.0.0/24) through
    # the tunnel, so LAN services (NFS/SMB, Snapcast, etc.) work directly.
    systemd.services.tailscale-local-route = {
      description = "Exclude local network from Tailscale routing";
      after = [ "tailscaled.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      # Lifecycle-bound to tailscaled (not multi-user.target): runs only when
      # Tailscale is actually up, and stops/reverts when it stops. Tailscale
      # does not auto-start at boot.
      wantedBy = [ "tailscaled.service" ];
      partOf = [ "tailscaled.service" ];

      # NM dispatcher restarts this on every network event (up, dhcp4-change,
      # connectivity-change, ...), which bursts past systemd's default
      # StartLimitBurst=5/10s at boot. Raise the limit so legitimate event
      # storms don't latch the unit into a failed state.
      unitConfig = {
        StartLimitIntervalSec = 30;
        StartLimitBurst = 20;
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = pkgs.writeShellScript "tailscale-local-route-stop" ''
          ${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5195 2>/dev/null || true
        '';
      };

      script = ''
        # Wait for tailscale interface to be up
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip addr show tailscale0 >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        # Wait briefly for a 10.0.0.x address to appear on a real interface so
        # we don't race DHCP. tailscaled.service can finish before wlan0 has
        # acquired its DHCP lease; without this wait the awk check below sees
        # no LAN address, the script decides "off LAN", and 10.0.0.0/24 stays
        # routed through tailscale even after we land on the home network.
        # On a genuinely off-LAN host the loop just times out and falls
        # through to the off-LAN branch.
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip -4 -o addr show \
              | ${pkgs.gawk}/bin/awk '$2 != "tailscale0" && /10\.0\.0\./ {found=1} END {exit !found}'; then
            break
          fi
          sleep 1
        done

        # Always start clean
        ${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5195 2>/dev/null || true

        # Only pin 10.0.0.0/24 to the main table when an interface is actually
        # addressed on that subnet. Off-LAN, the main table has no route for
        # 10.0.0.0/24, so installing the rule blackholes traffic that should
        # flow through Tailscale's accepted subnet route (table 52) via the
        # home subnet router.
        IFACE=$(${pkgs.iproute2}/bin/ip -4 -o addr show \
          | ${pkgs.gawk}/bin/awk '$2 != "tailscale0" && /10\.0\.0\./ {print $2; exit}')
        if [ -n "$IFACE" ]; then
          ${pkgs.iproute2}/bin/ip rule add to 10.0.0.0/24 lookup main priority 5195
          echo "On LAN ($IFACE) -- added policy rule: to 10.0.0.0/24 lookup main priority 5195"
        else
          echo "Off LAN -- skipped policy rule; 10.0.0.0/24 will route via tailscale"
        fi
      '';
    };

    systemd.services.tailscale-split-dns = {
      description = "Configure split DNS routing for Tailscale domains";
      after = [ "tailscaled.service" "network-online.target" "tailscale-local-route.service" ];
      wants = [ "network-online.target" ];
      # Lifecycle-bound to tailscaled so it never pins *.homefree.host into
      # MagicDNS while Tailscale is down/logged-out (the deadlock source).
      wantedBy = [ "tailscaled.service" ];
      partOf = [ "tailscaled.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Revert the split-DNS pin when Tailscale stops, so a later re-auth
        # resolves the control server (vpn.homefree.host) via public DNS rather
        # than dead MagicDNS. '-' ignores failure when tailscale0 is already gone.
        ExecStop = "-${pkgs.systemd}/bin/resolvectl revert tailscale0";
      };

      script = ''
        # Wait for tailscale0 interface to be up
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip addr show tailscale0 >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        # Set routing domains so systemd-resolved forwards these queries to tailscale's DNS
        ${pkgs.systemd}/bin/resolvectl domain tailscale0 ~rahh.al ~homefree.host ~homefree.lan ~slacktopia.org ~slacktopia.lan
        echo "Split DNS configured: rahh.al and homefree.host homefree.lan slacktopia.org slacktopia.lan -> tailscale0"
      '';
    };
  };
}
