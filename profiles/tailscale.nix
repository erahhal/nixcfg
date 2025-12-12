{ config, lib, pkgs, userParams, ... }:
let
  # Reference the existing tailscale config
  tsCfg = config.services.tailscale;

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
      ## @TODO: Add this as an option for corporate laptop
      # "--netfilter-mode=nodivert"
      "--login-server=https://vpn.homefree.host"
      "--operator=${userParams.username}"
    ];
    # Disable logs/telemetry to Tailscale
    extraDaemonFlags = [
      "--no-logs-no-support"
    ];
  };

  # Add tsup to system packages
  environment.systemPackages = [ tsupScript ];

  # Prevent Tailscale from routing local 10.0.0.0/24 traffic
  # This ensures NFS mounts to the local Synology NAS work correctly
  systemd.services.tailscale-local-route = {
    description = "Exclude local network from Tailscale routing";
    after = [ "tailscale.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # Run whenever network changes
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    # Add route with lower metric (higher priority) for local network
    # This works whether you're on wifi or ethernet
    script = ''
      # Wait for tailscale to be up
      for i in {1..30}; do
        if ${pkgs.iproute2}/bin/ip addr show tailscale0 >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      # Get the physical interface that has 10.0.0.x IP
      PHYS_IFACE=$(${pkgs.iproute2}/bin/ip -4 addr show | ${pkgs.gnugrep}/bin/grep -B 2 "inet 10\.0\.0\." | ${pkgs.gnugrep}/bin/grep -oP '^\d+: \K[^:]+' | head -n1)

      if [ -n "$PHYS_IFACE" ]; then
        echo "Adding route for 10.0.0.0/24 via $PHYS_IFACE"
        ${pkgs.iproute2}/bin/ip route add 10.0.0.0/24 dev "$PHYS_IFACE" metric 50 2>/dev/null || \
        ${pkgs.iproute2}/bin/ip route replace 10.0.0.0/24 dev "$PHYS_IFACE" metric 50
      else
        echo "Warning: No interface found with 10.0.0.x IP"
      fi
    '';
  };
}
