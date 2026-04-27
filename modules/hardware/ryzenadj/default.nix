{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.ryzenadj;
  level = config.hostParams.cpu.amd.ryzenadj;

  profiles = {
    medium = {
      stapm-limit = 28000;
      fast-limit = 35000;
      slow-limit = 28000;
      tctl-temp = 80;
      vrm-current = 100000;
      vrmmax-current = 100000;
    };
    high = {
      stapm-limit = 54000;
      fast-limit = 65000;
      slow-limit = 54000;
      tctl-temp = 95;
      vrm-current = 150000;
      vrmmax-current = 150000;
    };
  };

  profile = profiles.${level};

  args = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--${k}=${toString v}") profile);
in
{
  key = "nixcfg/hardware/ryzenadj";

  options.nixcfg.hardware.ryzenadj = {
    enable = lib.mkEnableOption "AMD CPU power tuning via ryzenadj";
  };

  config = lib.mkIf (cfg.enable && level != "off") {
    systemd.services.ryzenadj = {
      description = "Set AMD CPU Power Limits";
      wantedBy = [ "multi-user.target" ];
      after = [ "syslog.target" "systemd-modules-load.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj ${args}";
      };
    };
  };
}
