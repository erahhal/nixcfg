{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.networking.tailscale;
  # Reference the existing tailscale config
  tsCfg = config.services.tailscale;

  ## The primary tailnet keeps the stock services.tailscale daemon, socket,
  ## and tailscale0 interface. Each extraTailnets entry runs as its own
  ## tailscaled instance with a separate state dir, socket, and ts-<name>
  ## interface so node keys and routes never mix between control servers.
  primaryName = "homefree";
  extraNames = lib.attrNames cfg.extraTailnets;

  instanceSocket = name: "/run/tailscale-${name}/tailscaled.sock";
  instanceIface = name: "ts-${name}";
  instanceUnit = name: "tailscaled-${name}.service";

  instanceUpFlags = name: tn: [
    "--accept-routes"
    "--netfilter-mode=nodivert"
    "--login-server=${tn.loginServer}"
    "--operator=${userParams.username}"
  ] ++ tn.extraUpFlags;

  # Wrap tailscale to fix DNS cleanup bug on 'tailscale down'
  # Bug: https://github.com/tailscale/tailscale/issues/18441
  # socketArgs selects the per-tailnet daemon; iface is that daemon's tun
  # device; upFlags are injected so a bare '<cmd> up' works.
  mkWrapped = { cmdName, socketArgs ? "", iface, upFlags }: pkgs.writeShellScriptBin cmdName ''
    if [ "$1" = "up" ]; then
      shift
      # Inject configured flags so bare '${cmdName} up' works
      ${pkgs.tailscale}/bin/tailscale ${socketArgs} up \
        ${lib.concatStringsSep " \\\n        " upFlags} \
        "$@"
      EXIT_CODE=$?
    else
      ${pkgs.tailscale}/bin/tailscale ${socketArgs} "$@"
      EXIT_CODE=$?
    fi

    # If the command was 'down', fix the DNS configuration
    # Bug: https://github.com/tailscale/tailscale/issues/18441
    if [ "$1" = "down" ]; then
      IFIDX=$(cat /sys/class/net/${iface}/ifindex 2>/dev/null)
      if [ -n "$IFIDX" ]; then
        ${pkgs.dbus}/bin/busctl call org.freedesktop.resolve1 /org/freedesktop/resolve1 \
          org.freedesktop.resolve1.Manager RevertLink i "$IFIDX" 2>/dev/null || true
      fi
    fi

    exit $EXIT_CODE
  '';

  tailscaleWrapped = mkWrapped {
    cmdName = "tailscale";
    iface = "tailscale0";
    upFlags = tsCfg.extraUpFlags;
  };

  # Per-tailnet CLI for the extra instances, e.g. 'tailscale-slacktopia status'
  instanceCommands = lib.mapAttrsToList (name: tn: mkWrapped {
    cmdName = "tailscale-${name}";
    socketArgs = "--socket=${instanceSocket name}";
    iface = instanceIface name;
    upFlags = instanceUpFlags name tn;
  }) cfg.extraTailnets;

  allUnits = [ "tailscaled.service" ] ++ map instanceUnit extraNames;

  # Build the tsup script from existing config. Tailscale does not auto-start
  # at boot (one VPN at a time), so bring the daemon up first, then connect.
  # systemctl needs root -- run `sudo tsup`.
  #
  # Usage: tsup [tailnet] [tailscale-up flags...]
  # With no tailnet name, connects to the primary (${primaryName}). Other
  # active tailnet instances are stopped first: the tailnets' IPv6 ranges may
  # overlap, so only one runs at a time until that is sorted out.
  mkTsupBranch = { name, unit, socketArgs ? "", upFlags }: ''
    ${name})
      for OTHER in ${lib.concatStringsSep " " (lib.remove unit allUnits)}; do
        if ${pkgs.systemd}/bin/systemctl is-active --quiet "$OTHER"; then
          echo "Stopping $OTHER (one tailnet at a time until IPv6 ranges are deconflicted)"
          ${pkgs.systemd}/bin/systemctl stop "$OTHER"
        fi
      done
      ${pkgs.systemd}/bin/systemctl start ${unit}
      exec ${pkgs.tailscale}/bin/tailscale ${socketArgs} up \
        ${lib.concatStringsSep " \\\n        " upFlags} \
        "$@"
      ;;
  '';
  tsupScript = pkgs.writeShellScriptBin "tsup" ''
    TAILNET=${primaryName}
    case "$1" in
      ${lib.concatStringsSep "|" ([ primaryName ] ++ extraNames)})
        TAILNET="$1"
        shift
        ;;
      -h|--help)
        echo "Usage: tsup [tailnet] [tailscale-up flags...]"
        echo "Tailnets: ${lib.concatStringsSep " " ([ "${primaryName} (default)" ] ++ extraNames)}"
        exit 0
        ;;
    esac
    case "$TAILNET" in
      ${mkTsupBranch {
        name = primaryName;
        unit = "tailscaled.service";
        upFlags = tsCfg.extraUpFlags;
      }}
      ${lib.concatStrings (lib.mapAttrsToList (name: tn: mkTsupBranch {
        inherit name;
        unit = instanceUnit name;
        socketArgs = "--socket=${instanceSocket name}";
        upFlags = instanceUpFlags name tn;
      }) cfg.extraTailnets)}
    esac
  '';
in {
  options.nixcfg.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN with DNS fixes";

    extraTailnets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          loginServer = lib.mkOption {
            type = lib.types.str;
            example = "https://vpn.slacktopia.org";
            description = "Control server URL (headscale) for this tailnet.";
          };
          splitDnsDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "slacktopia.org" "slacktopia.lan" ];
            description = "Domains routed to this tailnet's DNS via systemd-resolved while it is up.";
          };
          extraUpFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional flags for 'tailscale up' on this tailnet.";
          };
        };
      });
      default = { };
      description = ''
        Additional tailnets beyond the primary (${primaryName}). Each runs as
        its own tailscaled instance (tailscaled-<name>.service, interface
        ts-<name>) with separate login state. Connect with 'sudo tsup <name>';
        manage with the generated 'tailscale-<name>' command. First 'up' on a
        new tailnet prints an interactive auth URL (no auth key is wired up
        for extra tailnets).
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = lib.flatten (map (name: [
      {
        # tun interface names are capped at 15 chars ("ts-" + name)
        assertion = builtins.stringLength name <= 12;
        message = "nixcfg.networking.tailscale.extraTailnets: name '${name}' too long; interface ts-${name} exceeds the 15-char limit";
      }
      {
        assertion = name != primaryName;
        message = "nixcfg.networking.tailscale.extraTailnets: '${primaryName}' is the primary tailnet; configure it via services.tailscale instead";
      }
    ]) extraNames);

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

    # Add wrapped tailscale, per-tailnet commands, and tsup to system packages
    environment.systemPackages = [ tailscaleWrapped tsupScript ] ++ instanceCommands;

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

    systemd.services = {
      # Do not start Tailscale at boot. The user runs one VPN at a time and
      # brings Tailscale up on demand with `tsup`. Keeping the daemon (and its
      # DNS/route helpers, which are lifecycle-bound to it below) from
      # auto-starting means an idle/logged-out Tailscale never touches resolved
      # or the routing tables at boot -- which is also what previously baked in
      # the DNS bootstrap deadlock (split-DNS pinning *.homefree.host, including
      # the control server vpn.homefree.host, to dead MagicDNS while logged out).
      tailscaled.wantedBy = lib.mkForce [ ];
      tailscaled-autoconnect = {
        wantedBy = lib.mkForce [ ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };

      # Prevent Tailscale from routing local LAN traffic (10.0.0.0/24) through
      # the tunnel, so LAN services (NFS/SMB, Snapcast, etc.) work directly.
      # Primary tailnet only: the home LAN subnet route is advertised on the
      # ${primaryName} tailnet.
      tailscale-local-route = {
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

      tailscale-split-dns = {
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
    }
    # One tailscaled instance per extra tailnet. Never started at boot
    # (same one-VPN-at-a-time policy as the primary); `tsup <name>` starts it.
    # --port=0 picks a random WireGuard port so it can't collide with the
    # primary's 41641 if both ever run at once.
    // lib.mapAttrs' (name: tn: lib.nameValuePair "tailscaled-${name}" {
      description = "Tailscale node agent (${name} tailnet)";
      after = [ "network-pre.target" "systemd-resolved.service" ];
      wants = [ "network-pre.target" ];
      path = [
        config.networking.resolvconf.package
        pkgs.procps
        pkgs.iproute2
        pkgs.iptables
        pkgs.getent
        pkgs.kmod
      ];
      serviceConfig = {
        Type = "notify";
        Restart = "on-failure";
        RuntimeDirectory = "tailscale-${name}";
        RuntimeDirectoryMode = "0755";
        StateDirectory = "tailscale-${name}";
        StateDirectoryMode = "0700";
        CacheDirectory = "tailscale-${name}";
        CacheDirectoryMode = "0750";
        ExecStart = lib.concatStringsSep " " ([
          "${tsCfg.package}/bin/tailscaled"
          "--state=/var/lib/tailscale-${name}/tailscaled.state"
          "--socket=${instanceSocket name}"
          "--port=0"
          "--tun=${instanceIface name}"
        ] ++ tsCfg.extraDaemonFlags);
      };
    }) cfg.extraTailnets
    # Per-instance split DNS, lifecycle-bound like the primary's so the pin
    # reverts when that tailnet stops.
    // lib.mapAttrs' (name: tn: lib.nameValuePair "tailscale-split-dns-${name}" {
      description = "Configure split DNS routing for ${name} tailnet domains";
      after = [ (instanceUnit name) "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ (instanceUnit name) ];
      partOf = [ (instanceUnit name) ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "-${pkgs.systemd}/bin/resolvectl revert ${instanceIface name}";
      };

      script = ''
        # Wait for the tailnet interface to be up
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip addr show ${instanceIface name} >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        ${pkgs.systemd}/bin/resolvectl domain ${instanceIface name} \
          ${lib.concatMapStringsSep " " (d: "~${d}") tn.splitDnsDomains}
        echo "Split DNS configured: ${lib.concatStringsSep " " tn.splitDnsDomains} -> ${instanceIface name}"
      '';
    }) (lib.filterAttrs (name: tn: tn.splitDnsDomains != [ ]) cfg.extraTailnets);
  };
}
