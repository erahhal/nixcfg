{ ... }:
{
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="04:7b:cb:16:02:3b", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="dock_eth0"
    ## USB ethernet adapter connected to thinkpad dock.  Doesn't seem to work.
    ## Using an adapter because the built-in ethernet fails
    SUBSYSTEM=="net", ACTION=="add", ATTR{idVendor}=="0x0bda", ATTR{idProduct}=="0x8153", ATTR{serial}=="E6E034000000", NAME="dock_eth1"
  '';
}
