{ config, lib, ... }:
let
  cfg = config.nixcfg.networking.wireless;
in {
  options.nixcfg.networking.wireless = {
    enable = lib.mkEnableOption "wireless network configuration";
  };
  config = lib.mkIf cfg.enable {
    networking.wireless.networks = {
    };
  };
}
