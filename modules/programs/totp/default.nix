{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.totp;
  totp = pkgs.callPackage ../../../pkgs/totp { };
in {
  options.nixcfg.programs.totp = {
    enable = lib.mkEnableOption "TOTP utility";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ totp ];
  };
}
