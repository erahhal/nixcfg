{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.services.nfs-mounts;

  nfs3Options = [
    "nfsvers=3"
    "async"
    "actimeo=60"
    "nocto"
  ];
in {
  options.nixcfg.services.nfs-mounts = {
    enable = lib.mkEnableOption "NFS mounts to Synology NAS";
  };
  config = lib.mkIf cfg.enable {
    services.rpcbind.enable = true;

    services.nfs = {
      idmapd.settings = {
        General = {
          Domain = "rahh.al";
        };
      };
    };

    fileSystems."/mnt/ellis" = {
      device = "10.0.0.42:/volume1/ellis";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/family-files" = {
      device = "10.0.0.42:/volume1/family-files";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/nas-home" = {
      device = "10.0.0.42:/volume1/homes";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/nas-usbshare" = {
      device = "10.0.0.42:/volumeUSB1/usbshare";
      fsType = "nfs";
      options = nfs3Options ++ [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };
  };
}
