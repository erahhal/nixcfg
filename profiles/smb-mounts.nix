{ config, pkgs, hostParams, userParams, ... }:

let
  # this line prevents hanging on network split
  automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
  options = ["${automount_opts},credentials=${config.age.secrets.samba-secrets.path},uid=${toString hostParams.uid},gid=${toString hostParams.gid}"];
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems = {
    "/mnt/ellis" = {
      device = "//10.0.0.42/ellis";
      fsType = "cifs";
      options = options;
    };
    "/mnt/family-files" = {
      device = "//10.0.0.42/family-files";
      fsType = "cifs";
      options = options;
    };
    "/mnt/nas-home" = {
      device = "//10.0.0.42/homes";
      fsType = "cifs";
      options = options;
    };
  };
}
