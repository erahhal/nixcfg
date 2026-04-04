{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.wifi-qos;
in {
  options.nixcfg.networking.wifi-qos = {
    enable = lib.mkEnableOption "WiFi QoS traffic shaping with fq_codel";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "wlan0";
      description = "WiFi interface to apply traffic shaping to";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.wifi-qos = {
      description = "Enable fq_codel traffic shaping on WiFi";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/tc qdisc replace dev ${cfg.interface} root fq_codel";
        ExecStop = "${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.interface} root";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip link show ${cfg.interface} >/dev/null 2>&1; do sleep 1; done'";
      };
    };
  };
}
