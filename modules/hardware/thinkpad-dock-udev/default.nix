{ config, lib, ... }:
let
  cfg = config.nixcfg.hardware.thinkpad-dock-udev;
in {
  options.nixcfg.hardware.thinkpad-dock-udev = {
    enable = lib.mkEnableOption "ThinkPad dock udev rules for ethernet naming";
  };
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="04:7b:cb:16:02:3b", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="dock_eth0"
      ## USB ethernet adapter connected to thinkpad dock
      SUBSYSTEM=="net", ACTION=="add", ATTR{idVendor}=="0x0bda", ATTR{idProduct}=="0x8153", ATTR{serial}=="E6E034000000", NAME="dock_eth1"
    '';
  };
}
