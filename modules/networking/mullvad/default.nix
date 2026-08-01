{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.mullvad;
  onOff = b: if b then "on" else "off";
in {
  options.nixcfg.networking.mullvad = {
    enable = lib.mkEnableOption "Mullvad VPN";

    # The daemon persists its own settings to /etc/mullvad-vpn/settings.json
    # and there is no NixOS option surface for them, so the three that decide
    # whether a misfire strands the machine are declared here and reconciled
    # by mullvad-defaults.service below.
    #
    # Why this exists: hitting connect with no account logged in does NOT fail
    # harmlessly. The daemon enters its error state and blocks ALL traffic
    # ("Mullvad is blocking all network traffic until you... 1. Login to a
    # Mullvad account with available time... 2. Disconnect"), and there is no
    # setting to suppress that — blocking on a failed tunnel is the entire
    # point of the daemon's leak prevention. That happened on logistikon
    # (2026-07-31) and took the LAN, DNS and every locally-hosted LLM with it,
    # leaving nothing to debug the box with.
    #
    # What CAN be controlled is the *shape* of the block. Upstream's
    # talpid-core firewall applies `FirewallPolicy::Blocked { allow_lan, .. }`
    # and adds LAN allow rules when allow_lan is set, so allowLan keeps the
    # local network reachable even in the blocked state. (Loopback is
    # unconditional in every policy — add_loopback_rules() runs in finalize()
    # before any policy rules — which is why anything addressed as 127.0.0.1
    # survives regardless of these settings.)
    allowLan = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow local network traffic. Applies while connected AND while the
        daemon is blocking, so an accidental or failed connect cannot cut the
        machine off from its own LAN. Set false only if LAN isolation matters
        more than not stranding the host.
      '';
    };

    lockdownMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Block all traffic whenever the VPN is disconnected ("lockdown mode").
        Off by default: on, it turns every daemon hiccup into a total outage.
      '';
    };

    autoConnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Connect automatically on daemon start. Off by default — with no
        account logged in this would block all traffic on every boot.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # CLI documentation: https://mullvad.net/en/help/how-use-mullvad-cli/

    # mullvad account set <account number>
    # mullvad lan set allow
    # mullvad relay set location ca
    # mullvad dns set custom 10.0.0.1
    # mullvad dns set default
    # mullvad connect
    # mullvad disconnect
    #
    # If the daemon is blocking and you are not logged in, `mullvad disconnect`
    # clears it. That still works with the network down — the CLI talks to the
    # daemon over the /run/mullvad-vpn unix socket, not over the network.

    environment.systemPackages = with pkgs; [
      mullvad
      mullvad-compass
    ];

    services.mullvad-vpn = {
      enable = true;
    };

    # Reconcile the settings above on every daemon start. They live in the
    # daemon's own settings.json, which it rewrites itself, so this converges
    # the file rather than owning it — a store symlink would break the daemon's
    # writes. Idempotent, and persisted, so it only has to win once per boot.
    # NOTE: this is authoritative. Changing these by hand with `mullvad lan
    # set` / `lockdown-mode set` / `auto-connect set` lasts until the next
    # daemon restart; change the options instead.
    systemd.services.mullvad-defaults = {
      description = "Reconcile declarative Mullvad daemon settings";
      after = [ "mullvad-daemon.service" ];
      requires = [ "mullvad-daemon.service" ];
      # Re-run when the daemon is restarted, so a rebuild that restarts the
      # daemon re-applies these too.
      partOf = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.mullvad pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # The daemon starts accepting RPC a moment after the unit goes active,
        # and the CLI errors out rather than waiting, so poll the socket.
        for _ in $(seq 1 60); do
          if mullvad status >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        mullvad lan set ${if cfg.allowLan then "allow" else "block"}
        mullvad lockdown-mode set ${onOff cfg.lockdownMode}
        mullvad auto-connect set ${onOff cfg.autoConnect}
      '';
    };
  };
}
