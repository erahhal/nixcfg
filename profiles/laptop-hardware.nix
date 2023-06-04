{ pkgs, lib, config, inputs, ... }:

{
  # Thunderbolt
  services.hardware.bolt.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --------------------------------------------------------------------------------------
  # Console
  # --------------------------------------------------------------------------------------

  console = {
    earlySetup = true;
    # font = "Lat2-Terminus16";
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132b.psf.gz";
    # font = "latarcyrheb-sun32";
    # font = "solar24x32";
    keyMap = "us";
    # Use large console font in initrd
  };
}
