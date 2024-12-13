{ config, pkgs, userParams, ... }:
{
  environment.systemPackages = [ pkgs.restic ];

  # --------------------------------------------------------------------------------------
  # Raw Snapshots
  # --------------------------------------------------------------------------------------

  systemd.services.snapshot-to-nas = {
    enable = true;
    description = "Sync backup snapshot to nas";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.rsync}/bin/rsync -avh --delete /home/${userParams.username}/DockerData /mnt/ellis/Backups/snapshots/sicmundus/
    '';
  };
  systemd.timers.snapshot-to-nas = {
    wantedBy = [ "timers.target" ];
    partOf = [ "snapshot-to-nas.service" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "snapshot-to-nas.service";
    };
  };

  # --------------------------------------------------------------------------------------
  # Incremental Backups
  # --------------------------------------------------------------------------------------

  services.restic.backups = {
    to-nas =  {
      initialize = true;
      passwordFile = config.age.secrets.restic-password.path;
      # What to backup
      paths = [
        "/home/${userParams.username}/DockerData"
        "/mnt/homeassistant-backups"
      ];
      # the name of the repository
      repository = "/mnt/ellis/Backups/restic/sicmundus";
      timerConfig = {
        OnCalendar = "daily";
      };

      # Keep 7 daily, 5 weekly, and 10 annual backups
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-yearly 10"
      ];
    };

    backblaze =  {
      initialize = true;
      passwordFile = config.age.secrets.restic-password.path;
      environmentFile = config.age.secrets.restic-environment.path;
      # What to backup
      paths = [
        "/home/${userParams.username}/DockerData"
        "/mnt/ellis/Code"
        "/mnt/ellis/Companies"
        "/mnt/ellis/Documents"
        "/mnt/ellis/Kat"
        "/mnt/ellis/Private"
        "/mnt/ellis/Projects"
        "/mnt/ellis/Recipes"
        "/mnt/ellis/Backup_nas.hbk"
        "/mnt/ellis/Backups/oneplus7pro-backup-apps"
        "/mnt/ellis/Backups/oneplus7pro-backup-signal"
        "/mnt/nas-home/erahhal/Photos"
        "/mnt/homeassistant-backups"
      ];
      # the name of the repository
      repository = "b2:sicmundus";
      timerConfig = {
        OnCalendar = "daily";
      };

      # Keep 7 daily, 5 weekly, and 10 annual backups
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-yearly 10"
      ];
    };
  };
}
