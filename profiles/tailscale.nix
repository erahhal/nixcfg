{ config, lib, pkgs, userParams, ... }:
let
  # Reference the existing tailscale config
  tsCfg = config.services.tailscale;

  # Wrap tailscale to fix DNS cleanup bug on 'tailscale down'
  # Bug: https://github.com/tailscale/tailscale/issues/18441
  # When 'tailscale down' is called, DNSDefaultRoute=true is left set without
  # DNS servers, causing systemd-resolved to fail DNS queries intermittently.
  tailscaleWrapped = pkgs.writeShellScriptBin "tailscale" ''
    # Run the real tailscale command
    ${pkgs.tailscale}/bin/tailscale "$@"
    EXIT_CODE=$?

    # If the command was 'down', fix the DNS configuration
    if [ "$1" = "down" ]; then
      IFIDX=$(cat /sys/class/net/tailscale0/ifindex 2>/dev/null)
      if [ -n "$IFIDX" ]; then
        # Call RevertLink to properly reset DNS DefaultRoute
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

  # Prevent Tailscale from routing local 10.0.0.0/24 traffic
  # This ensures NFS mounts to the local Synology NAS work correctly
  # Tailscale uses policy routing (table 52) at priority 5270, so we need
  # a policy rule with lower priority to route LAN traffic to main table first
  systemd.services.tailscale-local-route = {
    description = "Exclude local network from Tailscale routing";
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5200 2>/dev/null || true";
    };

    script = ''
      # Wait for tailscale interface to be up
      for i in {1..30}; do
        if ${pkgs.iproute2}/bin/ip addr show tailscale0 >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      # Add policy rule to route 10.0.0.0/24 via main table BEFORE tailscale's table 52
      # Priority 5200 is lower than tailscale's 5270, so it takes precedence
      ${pkgs.iproute2}/bin/ip rule del to 10.0.0.0/24 lookup main priority 5200 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add to 10.0.0.0/24 lookup main priority 5200
      echo "Added policy rule: to 10.0.0.0/24 lookup main priority 5200"
    '';
  };
}
