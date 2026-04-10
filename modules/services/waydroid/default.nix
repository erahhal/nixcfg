{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.services.waydroid;
in {
  options.nixcfg.services.waydroid = {
    enable = lib.mkEnableOption "Waydroid Android container";
  };
  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;

    home-manager.users.${userParams.username} = { osConfig, lib, pkgs, ... }: {
      home.activation.waydroid = lib.hm.dag.entryAfter [ "installPackages" ] ''
        ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.width ${toString osConfig.hostParams.virtualisation.waydroid.width}
        ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.height ${toString osConfig.hostParams.virtualisation.waydroid.height}
      '';
    };
  };
}
