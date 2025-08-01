{ pkgs, lib, ... }:

{
  # Thunderbolt
  services.hardware.bolt.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --------------------------------------------------------------------------------------
  # Console
  # --------------------------------------------------------------------------------------

  # Use maximum resolution in systemd-boot for hidpi
  boot.loader.systemd-boot.consoleMode = "max";

  console = {
    keyMap = "us";
    earlySetup = true;
    # font = "${pkgs.terminus_font}/share/consolefonts/ter-132b.psf.gz";
    # font = "ter-powerline-v24b";
    # packages = [
    #   pkgs.terminus_font
    #   pkgs.powerline-fonts
    # ];

    colors = [
      "000000" #"1f1f1F"
      "d73737"
      "60ac39"
      "cfb017"
      "6684e1"
      "b854d4"
      "1fad83"
      "a6a28c"
      "7d7a68"
      "d73737"
      "60ac39"
      "cfb017"
      "6684e1"
      "b854d4"
      "1fad83"
      "fefbec"
    ];
  };

  ## after boot, use graphical console TTY that supports TrueType fonts and glyphs
  services.kmscon = {
    enable = false;
    hwRender = true;
    fonts =  [
      {
        name = "DejaVu Sans Mono";
        package = pkgs.nerd-fonts.droid-sans-mono;
      }
    ];
    extraOptions = ''
      --login ${pkgs.shadow}/bin/login --xkb-layout us --term xterm-256color --font-name "DejaVu Sans Mono" --font-size 19
    '';
  };
}
