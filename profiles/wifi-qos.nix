{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking.wifi.qos;
in
{
  options.networking.wifi.qos = {
    enable = mkEnableOption "WiFi QoS traffic shaping with fq_codel";

    interface = mkOption {
      type = types.str;
      default = "wlan0";
      description = "WiFi interface to apply traffic shaping to";
    };
  };

  config = mkIf cfg.enable {
    # Enable fq_codel on WiFi to reduce bufferbloat during heavy transfers
    # This prioritizes small packets (DNS, ACKs) over bulk data, preventing
    # DNS timeouts when saturating the WiFi link with large file transfers
    systemd.services.wifi-qos = {
      description = "Enable fq_codel traffic shaping on WiFi";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # Restart if interface goes down and comes back up
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/tc qdisc replace dev ${cfg.interface} root fq_codel";
        ExecStop = "${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.interface} root";
        # Don't fail if interface doesn't exist yet
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip link show ${cfg.interface} >/dev/null 2>&1; do sleep 1; done'";
      };
    };
  };
}
