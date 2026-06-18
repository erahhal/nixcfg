{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.astrill;
  astrillvpn = pkgs.callPackage ../../../pkgs/astrillvpn { };
in {
  options.nixcfg.networking.astrill = {
    enable = lib.mkEnableOption "Astrill VPN";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ astrillvpn ];

    # astrill manages TUN devices, routes and firewall rules. The .deb does
    # `setcap cap_net_admin,cap_net_raw+ep` on the binary; replicate that here. The
    # NixOS wrapper also raises the caps into the ambient set, so the VPN connectors
    # astrill spawns (asovpnc/aswgvpnc/openweb) inherit them.
    security.wrappers.astrill = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      source = "${astrillvpn}/usr/local/Astrill/astrill";
    };

    # astrill spawns asproxy (its privileged proxy/StealthVPN helper) and checks it
    # holds the same caps, else it refuses with "ASProxy component has insufficient
    # privilege". The package symlinks the sibling astrill execs at this wrapper.
    security.wrappers.asproxy = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      source = "${astrillvpn}/usr/local/Astrill/.asproxy-real";
    };

    # Reconnect after suspend/hibernate (ships as astrill-reconnect.service in the .deb).
    systemd.services.astrill-reconnect = {
      description = "Astrill reconnect after sleep/hibernate";
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        # Route through the launcher so reconnect gets the same PATH + flags.
        ExecStart = "${astrillvpn}/bin/astrill /reconnect";
      };
    };
  };
}
