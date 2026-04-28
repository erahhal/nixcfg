{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.laptop;
in {
  options.nixcfg.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware support (Thunderbolt, Bluetooth, console)";
  };
  config = lib.mkIf cfg.enable {
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
      font = "ter-powerline-v32b";
      # font = "latarcyrheb-sun32";
      packages = [
        pkgs.terminus_font
        pkgs.powerline-fonts
      ];

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
      enable = true;
      hwRender = true;
      useXkbConfig = true;
      term = "xterm-256color";
      fonts =  [
        {
          name = "DejaVu Sans Mono";
          package = pkgs.nerd-fonts.droid-sans-mono;
        }
      ];
      extraConfig = ''
        backspace-delete
        use-original-mode
      '';
      extraOptions = "--font-size 19";
    };

    # kmscon aliases itself as autovt@.service, so it claims tty1 at boot. greetd
    # then takes tty1 over, but the kernel's active VT can migrate to tty2 (where
    # the second kmsconvt is running) and never switches back, leaving the greeter
    # session non-active on seat0 — so niri can't become DRM master and the
    # screen stays black. Keep kmscon off tty1 so greetd owns it from boot.
    systemd.services."kmsconvt@tty1".enable = false;
  };
}
