{ pkgs, ... }:
{
  services.udev = {
    extraRules = ''
      # teensy
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", MODE:="0666"
      # SSK SSD usb drive
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="0583", TAG+="uaccess"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="0583", MODE:="0666"
    '';
  };
}
