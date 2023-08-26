{ pkgs, ... }:
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-raspberrypi4.nix> ];

  # Boot

  boot = {
    loader.raspberryPi.firmwareConfig = ''
      gpu_mem=192
      dtparam=audio=on
    '';

    kernelParams = [
      # Enable serial console
      "console=ttyS1,115200n8"
    ];
  };

  # Network

  networking = {
    wireless.enable = false;
  };

  # Graphics

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa_drivers;
  };

  hardware.deviceTree = {
    base = pkgs.device-tree_rpi;
    overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
  };

  services.xserver = {
    enable = true;
    displayManager.slim.enable = true;
    desktopManager.gnome3.enable = true;
    videoDrivers = [ "modesetting" ];
  };

  # Audio

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Bluetooth

  systemd.services.btattach = {
    before = [ "bluetooth.service" ];
    after = [ "dev-ttyAMA0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
    };
  };
}
