# Boot and kernel base configuration
{ config, ... }:
{
  time.timeZone = config.hostParams.system.timeZone;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 1024;
  };

  i18n.defaultLocale = "en_US.UTF-8";
}
