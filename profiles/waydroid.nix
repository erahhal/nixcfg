# https://nixos.wiki/wiki/WayDroid
#
# sudo waydroid init
# sudo systemctl start waydroid-container
# Then run app using launcher: Waydroid
#
# Download f-droid then install:
# waydroid app install fdroid.apk

{ userParams, ...}:
{
  virtualisation = {
    waydroid.enable = true;
    lxd.enable = true;
  };

  ## Make Steam use nvidia-offload
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home.activation.waydroid = lib.hm.dag.entryAfter [ "installPackages" ] ''
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.height 1920
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.width 1080
    '';
  };
}
