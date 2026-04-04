{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.android;
in {
  options.nixcfg.programs.android = {
    enable = lib.mkEnableOption "Android tools";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-tools
    ];
  };
}
