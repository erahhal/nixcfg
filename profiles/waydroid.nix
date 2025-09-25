# https://nixos.wiki/wiki/WayDroid
#
# sudo waydroid init
# sudo systemctl start waydroid-container
# Then run app using launcher: Waydroid
#
# Download f-droid then install:
# waydroid app install fdroid.apk

{ config, userParams, ...}:
{
  virtualisation = {
    waydroid.enable = config.hostParams.virtualisation.waydroid.enable;
    # lxd.enable = true;
  };

  ## Give waydroid network access
  # networking.firewall.allowedTCPPorts = [
  #   53 67
  # ];
  # networking.firewall.allowedUDPPorts = [
  #   53 67
  # ];
  # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  home-manager.users.${userParams.username} = { osConfig, lib, pkgs, ... }: {
    home.activation.waydroid = lib.hm.dag.entryAfter [ "installPackages" ] ''
      ## Settings allow small gaps around windows
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.width ${toString osConfig.hostParams.virtualisation.waydroid.width}
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.height ${toString osConfig.hostParams.virtualisation.waydroid.height}
    '';
  };
}
