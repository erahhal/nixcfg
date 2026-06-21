{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.netbird;
in {
  options.nixcfg.networking.netbird.enable =
    lib.mkEnableOption "NetBird VPN client (self-hosted netbird.homefree.host)";

  config = lib.mkIf cfg.enable {
    services.netbird.clients.wt0 = {
      # Port used to listen to wireguard connections
      port = 51821;

      # Set this to true if you want the GUI client
      ui.enable = false;

      # This opens ports required for direct connection without a relay
      openFirewall = true;

      # This opens necessary firewall ports in the Netbird client's network interface
      openInternalFirewall = true;

      # NOTE: the management server (https://netbird.homefree.host) is NOT set
      # here. NetBird's config.json `ManagementURL` is a serialized `url.URL`
      # struct, not a string, so seeding it via the module's `config` option
      # (raw JSON) writes a string the daemon refuses to unmarshal and it
      # crash-loops. The URL must be written by NetBird itself: pass it once via
      # `netbird-wt0 up --management-url https://netbird.homefree.host` (or via
      # the setup key login below), after which it persists in
      # /var/lib/netbird-wt0/config.json.

      # Automated login via setup key. The module builds a LoadCredential from
      # setupKeyFile unconditionally when login.enable is true, so gate the
      # whole login block on the agenix secret (nixcfg-secrets flake) being
      # declared — otherwise eval fails coercing a null path. Until the secret
      # lands, the client runs but won't auto-register.
      login = lib.mkIf (config.age.secrets ? "netbird-setup-key") {
        enable = true;
        setupKeyFile = config.age.secrets."netbird-setup-key".path;
      };
    };
  };
}
