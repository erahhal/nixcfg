{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.xteink-unlocker;
  xteink-unlocker = pkgs.callPackage ../../../pkgs/xteink-unlocker { };
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # The helper answers NTP for the e-reader, which means binding :123 on the
  # hotspot address. A running time daemon holds the WILDCARD 0.0.0.0:123, and a
  # wildcard bind blocks a later specific-address bind on the same port -- the
  # helper then dies with "Address already in use (os error 98)" and the GUI
  # reports "Install failed". (DNS avoids this: the helper binds a high port and
  # redirects 53 -> 10053 through netfilter. NTP is a direct bind.)
  # So stop whichever time daemon is enabled for the duration of a flash. Losing
  # host time sync for those few minutes is harmless, and the helper is serving
  # spoofed time to the device anyway.
  timeDaemons =
    lib.optional config.services.ntp.enable "ntpd.service"
    ++ lib.optional config.services.chrony.enable "chronyd.service"
    ++ lib.optional config.services.timesyncd.enable "systemd-timesyncd.service";

  # NetworkManager's default shared-mode subnet, which is what the helper hands
  # the e-reader and what the GUI shows on the hotspot step.
  hotspotNet = "10.42.0.0/24";
  bridgeIp = "10.42.0.1";

  # The e-reader's traffic has to survive the host firewall, and by default it
  # does not: the hotspot interface is just wlan0, which isn't a trusted
  # interface, so nixos-fw ends in nixos-fw-log-refuse for anything unlisted.
  # Two ports get caught by that:
  #   10053 -- the helper doesn't bind :53, it binds :10053 and REDIRECTs 53
  #            there in nat PREROUTING. Since nat PREROUTING runs BEFORE the
  #            filter chain, the packet reaches INPUT with dport 10053, which no
  #            allowedUDPPorts entry covers, and is refused. The device's update
  #            check then never resolves and it just shows stock firmware.
  #   123   -- the spoofed NTP responder, same story.
  # (80/443 happen to be open already, but list them so this doesn't silently
  # depend on unrelated entries in networking.firewall.allowedTCPPorts.)
  # Opened only while the helper runs and only for the hotspot subnet.
  firewall = pkgs.writeShellScript "xteink-unlocker-firewall" ''
    set -u
    ipt="${pkgs.iptables}/bin/iptables"
    case "''${1:-}" in
      open)  op="-I"; pos="1" ;;
      close) op="-D"; pos=""  ;;
      *) echo "usage: $0 open|close" >&2; exit 2 ;;
    esac
    apply() {
      if [ "$op" = "-D" ]; then
        # Removing a rule that isn't there is the normal case for the
        # ExecStartPre sweep; iptables is loud about it, so keep that expected
        # noise out of the journal.
        "$ipt" -w "$@" 2>/dev/null || true
      else
        "$ipt" -w "$@" || true
      fi
    }
    # unquoted $pos: empty for -D, which takes no rule number
    apply "$op" nixos-fw $pos -s ${hotspotNet} -p udp \
      -m multiport --dports 53,123,10053 -j nixos-fw-accept
    apply "$op" nixos-fw $pos -s ${hotspotNet} -p tcp \
      -m multiport --dports 80,443 -j nixos-fw-accept

    # DNS spoofing alone is NOT enough to catch the device. The stock firmware
    # never resolves its update host -- a full flash shows zero DNS lookups for
    # api-prod.xteink.cc and yet issues GET /api/v1/check-update with
    # "host: api-prod.xteink.cc" -- so it dials a hardcoded/cached address
    # directly. Without this the request leaves for an address that isn't
    # reachable (the hotspot has no upstream) and the install just fails.
    # Pull every :80/:443 connection from the hotspot back to the helper.
    # PREROUTING only sees packets arriving on an interface, so this cannot
    # affect the host's own traffic.
    apply -t nat "$op" PREROUTING $pos -s ${hotspotNet} -p tcp \
      -m multiport --dports 80,443 -j DNAT --to-destination ${bridgeIp}
  '';
in {
  options.nixcfg.programs.xteink-unlocker = {
    enable = lib.mkEnableOption "Xteink Unlocker (OTA CrossPoint Reader flasher)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ xteink-unlocker ];

    # The openings above are written against the iptables backend's nixos-fw
    # chain, which the nftables backend doesn't have. Fail loudly rather than
    # silently leaving the device's DNS refused again.
    assertions = [{
      assertion = !config.networking.nftables.enable;
      message = "nixcfg.programs.xteink-unlocker: the helper's firewall openings target the iptables chain nixos-fw; port them to nftables before enabling networking.nftables.";
    }];

    # The GUI drives a root helper over a unix socket, and its own "install helper"
    # button shells out to a hardcoded /usr/bin/pkexec -- which NixOS doesn't have
    # (pkexec lives in /run/wrappers/bin), and which can't be patched out because
    # it's a fixed-length string literal in a Rust binary.
    #
    # Symlinking /usr/bin/pkexec the way this repo does for astrill's /sbin/ip
    # would not actually fix it: pkexec resets PATH to the FHS default, so the
    # helper it spawns would find neither iptables nor nft and would fail to
    # install its port-redirect rules. Running the helper as a unit instead lets us
    # set PATH properly; the GUI probes the socket first, sees a healthy helper,
    # and never reaches the pkexec path.
    #
    # Deliberately in no .wants: while up, the helper reconfigures the Wi-Fi device
    # into a hotspot over NetworkManager's D-Bus API and answers DNS/NTP/HTTP(S)
    # for the e-reader, so it must only be up for an actual flash. Its lifetime is
    # tied to the GUI instead -- the desktop entry runs pkgs/xteink-unlocker's
    # launcher, which starts this unit, then stops it again on exit.
    systemd.services.xteink-unlocker-helper = {
      description = "Xteink Unlocker privileged helper";
      wantedBy = [ ];
      wants = [ "NetworkManager.service" ];
      after = [ "NetworkManager.service" "dbus.service" ];

      # Systemd stops these when the helper starts; ExecStopPost below puts them
      # back, since Conflicts= is one-way.
      conflicts = timeDaemons;

      # Everything the helper shells out to. It drives the hotspot itself over
      # NetworkManager's D-Bus API rather than nmcli, but it does spawn:
      #   ip  -- `ip -4 addr show`, to answer the GUI's bridge_ip poll. Without
      #          this the GUI sits on "Starting Wi-Fi Hotspot" forever, polling
      #          bridge_ip and getting `spawn ip: No such file or directory`,
      #          and never advances to arming the spoofing servers.
      #   iptables, falling back to nft -- the port-redirect rules.
      #   iw -- referenced by the binary; included so a wifi query can't fail
      #         the same silent way.
      path = [ pkgs.iproute2 pkgs.iptables pkgs.nftables pkgs.iw ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${xteink-unlocker}/bin/unlocker-helper";
        Restart = "no";
        # No PrivateTmp: the helper logs to /tmp/unlocker-helper.log and the GUI
        # reads that path back for its in-app log view, so the two must agree.
        PrivateTmp = false;

        # "-" on every close/restore step: a rule that's already gone, or a
        # masked time daemon, must never fail the helper's shutdown and strand
        # the firewall open.
        ExecStartPre = "-${firewall} close";   # drop rules a crashed run left behind
        ExecStartPost = "${firewall} open";
        # The time daemon must NOT be restarted inline here: that races
        # NetworkManager tearing the hotspot interface down, and ntpd segfaults
        # in io_open_sockets()/update_interfaces() enumerating a half-removed
        # interface -- leaving it failed, and the host with no time sync at all.
        # Schedule it a few seconds out, detached, so the network has settled
        # and the helper's own stop isn't held up waiting on it.
        ExecStopPost = [ "-${firewall} close" ]
          ++ map (u: "-${pkgs.systemd}/bin/systemd-run --collect --on-active=10 ${systemctl} start ${u}") timeDaemons;
      };
    };

    # Let the launcher drive that unit without turning the flow into two password
    # prompts. Starting asks for the user's own password (_KEEP so a restart in the
    # same session is free); stopping is allowed outright, because a stop is the
    # safe direction -- it tears the hotspot and the DNS/NTP spoofing back down,
    # and having it prompt would strand the helper running whenever the GUI is
    # closed after the auth cookie has expired. Scoped to this one unit.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "xteink-unlocker-helper.service" &&
            subject.isInGroup("wheel")) {
          var verb = action.lookup("verb");
          if (verb == "start" || verb == "restart") {
            return polkit.Result.AUTH_SELF_KEEP;
          }
          if (verb == "stop") {
            return polkit.Result.YES;
          }
        }
      });
    '';

    # No tmpfiles rule for the helper's hardcoded /var/db/... rollback state:
    # NixOS already creates /var/db 0755 root root by default.
  };
}
