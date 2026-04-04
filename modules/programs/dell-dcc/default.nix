{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.dell-dcc;
in {
  options.nixcfg.programs.dell-dcc = {
    enable = lib.mkEnableOption "Dell Command Configure (cctk)";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dell-command-configure ];
  };
}
