## VRAM management for low-end GPUs via the dmem cgroup controller.
## Background: https://pixelcluster.github.io/VRAM-Mgmt-fixed/
##
## Pieces:
##  - CachyOS kernel: ships pixelcluster's dmem cgroup patches (not yet
##    upstream as of 2026-05).
##  - dmemcg-booster: systemd-managed daemon that activates the dmem
##    controller across the cgroup hierarchy. System + user units.
##  - foreground booster: tracks the focused window and promotes its
##    cgroup. niri-focused-booster (default) for Niri sessions; KDE's
##    plasma-foreground-booster is the alternative but is not packaged
##    here yet.
{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.dmemcg;
  dmemcg-booster = pkgs.callPackage ../../../pkgs/dmemcg-booster {};
  niri-focused-booster = pkgs.callPackage ../../../pkgs/niri-focused-booster {};
in
{
  key = "nixcfg/hardware/dmemcg";

  options.nixcfg.hardware.dmemcg = {
    enable = lib.mkEnableOption "dmem cgroup VRAM boost (CachyOS kernel + boosters)";

    foregroundBooster = lib.mkOption {
      type = lib.types.enum [ "niri" "none" ];
      default = "niri";
      description = ''
        Foreground-window tracker that promotes the focused app's cgroup.
        "niri" runs niri-focused-booster as a user service.
        "none" only activates the dmem controller (still useful for
        gamescope-launched games, which set the boost themselves).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    environment.systemPackages = [ dmemcg-booster ]
      ++ lib.optional (cfg.foregroundBooster == "niri") niri-focused-booster;

    # Ship the upstream unit files (dmemcg-booster-system.service +
    # dmemcg-booster-user.service) and enable them.
    systemd.packages = [ dmemcg-booster ];

    systemd.services.dmemcg-booster-system = {
      wantedBy = [ "multi-user.target" ];
    };

    systemd.user.services.dmemcg-booster-user = {
      wantedBy = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.niri-focused-booster = lib.mkIf (cfg.foregroundBooster == "niri") {
      description = "Boost dmem.low for the Niri-focused window";
      after = [ "graphical-session.target" "dmemcg-booster-user.service" ];
      wants = [ "dmemcg-booster-user.service" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = lib.getExe niri-focused-booster;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
