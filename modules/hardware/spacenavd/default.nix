{ config, lib, ... }:
let
  cfg = config.nixcfg.hardware.spacenavd;
in
{
  key = "nixcfg/hardware/spacenavd";

  options.nixcfg.hardware.spacenavd.enable = lib.mkEnableOption "SpaceNavigator 3D mouse support";

  config = lib.mkIf cfg.enable {
    hardware.spacenavd.enable = true;
  };
}
