{ config, lib, pkgs, userParams, ... }:
let
  # Reference the existing tailscale config
  tsCfg = config.services.tailscale;

  # Wrap tailscale to fix DNS cleanup bug on 'tailscale down'
  # Bug: https://github.com/tailscale/tailscale/issues/18441
  # When 'tailscale down' is called, DNSDefaultRoute=true is left set without
  # DNS servers, causing systemd-resolved to fail DNS queries intermittently.
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

  # Build the tsup script from existing config
  tsupScript = pkgs.writeShellScriptBin "tsup" ''
    exec ${pkgs.tailscale}/bin/tailscale up \
      ${lib.concatStringsSep " \\\n      " tsCfg.extraUpFlags} \
      "$@"
  '';
in
{
  config = lib.mkIf config.hostParams.networking.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale/key";
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
    # tailscaleWrapped takes precedence over the original due to package ordering
    environment.systemPackages = [ tailscaleWrapped tsupScript ];

    # Ensure tailscaled-autoconnect waits for network/DNS to be ready
    # The upstream NixOS module only depends on tailscaled.service, which
    # can start before DNS resolution is available
    systemd.services.tailscaled-autoconnect = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Prevent Tailscale from routing traffic to the Synology NAS (10.0.0.42)
    # through the tunnel, so NFS/SMB mounts work via LAN when at home.
    # Only the NAS IP is excluded (not the whole /24) so that split DNS
    # queries to 10.0.0.1 can still go through Tailscale's tunnel.
    systemd.services.tailscale-local-route = {
      description = "Exclude local network from Tailscale routing";
      after = [ "tailscaled.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.iproute2}/bin/ip rule del to 10.0.0.42/32 lookup main priority 5200 2>/dev/null || true";
      };

      script = ''
        # Wait for tailscale interface to be up
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip addr show tailscale0 >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        # Add policy rule to route 10.0.0.42/32 via main table BEFORE tailscale's table 52
        # Priority 5200 is lower than tailscale's 5270, so it takes precedence
        ${pkgs.iproute2}/bin/ip rule del to 10.0.0.42/32 lookup main priority 5200 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule add to 10.0.0.42/32 lookup main priority 5200
        echo "Added policy rule: to 10.0.0.42/32 lookup main priority 5200"
      '';
    };

    systemd.services.tailscale-split-dns = {
      description = "Configure split DNS routing for Tailscale domains";
      after = [ "tailscaled.service" "network-online.target" "tailscale-local-route.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
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
        # ~ prefix = routing domain (not search domain): only used when querying these domains
        ${pkgs.systemd}/bin/resolvectl domain tailscale0 ~rahh.al ~homefree.host
        echo "Split DNS configured: rahh.al and homefree.host -> tailscale0"
      '';
    };
  };
}
